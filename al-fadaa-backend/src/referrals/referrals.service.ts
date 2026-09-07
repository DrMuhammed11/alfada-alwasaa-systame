import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { AuditAction, CorrespondenceStatus, NotificationType, Prisma, Role, ReferralStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { OutboxEventType } from '../outbox/outbox.types';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { CreateReferralDto, MyReferralsQueryDto } from './dto';
import {
  CorrespondenceAction,
  assertTransition,
  getNextStatus,
  getAllowedStatusesForAction,
} from '../workflow/correspondence-state-machine';
import { canRefer } from '../security/business-policies';

const REFERRAL_INCLUDE = {
  fromUser: { select: { id: true, name: true, email: true, role: true, departmentId: true } },
  toUser: { select: { id: true, name: true, email: true, role: true, departmentId: true } },
  correspondence: {
    select: { id: true, refNumber: true, subject: true, type: true, priority: true, status: true },
  },
} satisfies Prisma.ReferralInclude;

export type ReferralRow = Prisma.ReferralGetPayload<{ include: typeof REFERRAL_INCLUDE }>;

@Injectable()
export class ReferralsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly correspondences: CorrespondencesService,
    private readonly notifications: NotificationsService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
  ) {}

  /**
   * إحالة مراسلة — قاعدة العمل:
   *  - المدير العام  → نائبه أو مديري الأقسام
   *  - نائب المدير   → مديري الأقسام
   * وعند إحالة مدير قسم تُربط المراسلة بقسمه تلقائيًا (لنطاق رؤية القسم).
   */
  async create(correspondenceId: string, dto: CreateReferralDto, user: AuthUser) {
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: correspondenceId },
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    // سد ثغرة الرؤية: فحص صلاحية اطلاع المستخدم على المراسلة قبل كل شيء
    const canView = await this.correspondences.canView(corr, user);
    if (!canView) {
      throw new ForbiddenException('ليست لديك صلاحية الاطلاع على هذه المراسلة');
    }

    assertTransition(corr.status, CorrespondenceAction.REFER);

    const toUser = await this.prisma.user.findUnique({
      where: { id: dto.toUserId },
    });

    const policy = canRefer(user, toUser, corr);
    if (!policy.allowed) {
      throw new BadRequestException(policy.reason);
    }

    // منع تكرار الإحالة لنفس المستخدم ما دامت لديه إحالة مفتوحة (OPEN) على نفس المراسلة
    const existingOpen = await this.prisma.referral.findFirst({
      where: {
        correspondenceId,
        toUserId: dto.toUserId,
        status: ReferralStatus.OPEN,
      },
    });
    if (existingOpen) {
      throw new BadRequestException('توجد إحالة مفتوحة سابقة لهذا المستخدم على هذه المراسلة بالفعل');
    }

    const referable = getAllowedStatusesForAction(CorrespondenceAction.REFER);

    const referral = await this.prisma.$transaction(async (tx) => {
      // فحص ذري داخل المعاملة لمنع سباقات الإحالة المتزامنة لنفس المستخدم
      const existingOpenTx = await tx.referral.findFirst({
        where: {
          correspondenceId,
          toUserId: dto.toUserId,
          status: ReferralStatus.OPEN,
        },
      });
      if (existingOpenTx) {
        throw new BadRequestException('توجد إحالة مفتوحة سابقة لهذا المستخدم على هذه المراسلة بالفعل');
      }

      // 1. التحديث الذري المشروط بالإصدار لمنع TOCTOU وسباقات الإحالة المتزامنة
      const updateRes = await tx.correspondence.updateMany({
        where: {
          id: correspondenceId,
          ...(corr.version !== undefined ? { version: corr.version } : {}),
          status: { in: referable },
        },
        data: {
          ...(corr.version !== undefined ? { version: { increment: 1 } } : {}),
          status: getNextStatus(corr.status, CorrespondenceAction.REFER) ?? CorrespondenceStatus.REFERRED,
          departmentId:
            user.role === Role.DEPT_MANAGER
              ? corr.departmentId // عند إحالة مدير القسم لا نغير قسم المراسلة (هو قسمه أصلاً)
              : toUser!.role === Role.DEPT_MANAGER && toUser!.departmentId
                ? toUser!.departmentId
                : corr.departmentId,
        },
      });

      if (updateRes.count === 0) {
        const current = await tx.correspondence.findUnique({
          where: { id: correspondenceId },
          select: { status: true, version: true },
        });
        if (!current) throw new NotFoundException('المراسلة غير موجودة');
        throw new BadRequestException(
          'عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة',
        );
      }

      const created = await tx.referral.create({
        data: {
          correspondenceId,
          fromUserId: user.id,
          toUserId: toUser!.id,
          note: dto.note,
          dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        },
        include: REFERRAL_INCLUDE,
      });

      // 2. تسجيل الحدث في الـ Outbox داخل نفس المعاملة (Transactional Outbox)
      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REFERRAL_CREATED,
          payload: {
            audit: {
              action: AuditAction.REFER,
              entityType: 'Correspondence',
              entityId: correspondenceId,
              summary: `أحال ${user.name} المراسلة ${corr.refNumber} إلى ${toUser!.name}`,
              metadata: { toUserId: toUser!.id, note: dto.note ?? null },
              userId: user.id,
            },
            notification: {
              type: NotificationType.NEW_REFERRAL,
              userId: toUser!.id,
              title: `إحالة جديدة من ${user.name}`,
              body: dto.note
                ? `الموضوع: «${corr.subject}» — ملاحظة: ${dto.note}`
                : `الموضوع: «${corr.subject}»`,
              link: `/correspondences/${corr.id}`,
              entityType: 'Correspondence',
              entityId: corr.id,
            },
          },
        });
      }

      return created;
    });

    // 3. تفعيل معالج الـ Outbox فوراً، مع مسار تراجع في غيابه
    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.REFER,
        entityType: 'Correspondence',
        entityId: correspondenceId,
        summary: `أحال ${user.name} المراسلة ${corr.refNumber} إلى ${toUser!.name}`,
        metadata: { toUserId: toUser!.id, note: dto.note ?? null },
      });

      await this.notifications.notifyReferralReceived({
        toUserId: toUser!.id,
        actorName: user.name,
        refNumber: corr.refNumber,
        subject: corr.subject,
        correspondenceId: corr.id,
        note: referral.note,
        dueDate: referral.dueDate,
      });
    }

    return referral;
  }

  /** الإحالات الواردة إليّ */
  async findMine(dto: MyReferralsQueryDto, user: AuthUser): Promise<Paginated<ReferralRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const where: Prisma.ReferralWhereInput = {
      toUserId: user.id,
      ...(dto.status ? { status: dto.status } : {}),
    };
    const [total, data] = await this.prisma.$transaction([
      this.prisma.referral.count({ where }),
      this.prisma.referral.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: REFERRAL_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  /** سجل إحالات مراسلة معينة — مع فرض نطاق الرؤية */
  async findForCorrespondence(correspondenceId: string, user: AuthUser) {
    await this.correspondences.findOne(correspondenceId, user); // 404 / 403 إن لم تكن له رؤية
    return this.prisma.referral.findMany({
      where: { correspondenceId },
      include: REFERRAL_INCLUDE,
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * إجابة إحالة واحدة (ANSWERED مع توثيق answeredAt)
   * وتحديث حالة المراسلة إلى IN_PROGRESS إن لم تبقَ أي إحالات مفتوحة (OPEN).
   * ويُشعر كافة مرسلي الإحالات المفتوحة ذات الصلة لا آخرهم فقط.
   */
  async answerReferral(referralId: string, user: AuthUser): Promise<ReferralRow> {
    const referral = await this.prisma.referral.findUnique({
      where: { id: referralId },
      include: { correspondence: true },
    });
    if (!referral) throw new NotFoundException('الإحالة غير موجودة');

    let isRecipient = referral.toUserId === user.id;
    let actingOnBehalfOf: { id: string; name: string } | null = null;
    if (!isRecipient && this.prisma.delegation) {
      const now = new Date();
      const delegation = await this.prisma.delegation.findFirst({
        where: {
          delegatorId: referral.toUserId,
          delegateId: user.id,
          active: true,
          startsAt: { lte: now },
          endsAt: { gte: now },
        },
        include: { delegator: { select: { id: true, name: true } } },
      });
      if (delegation) {
        isRecipient = true;
        actingOnBehalfOf = delegation.delegator;
      }
    }

    const privilegedRoles: Role[] = [Role.ADMIN, Role.GM, Role.DEPUTY_GM];
    const isPrivileged = privilegedRoles.includes(user.role);
    if (!isRecipient && !isPrivileged) {
      throw new ForbiddenException('فقط الجهة المحال إليها أو الإدارة العليا تملك إجابة الإحالة');
    }

    if (referral.status === ReferralStatus.ANSWERED || referral.status === ReferralStatus.CLOSED) {
      throw new BadRequestException('تمت إجابة هذه الإحالة أو إغلاقها مسبقًا');
    }

    if (
      referral.correspondence?.status === CorrespondenceStatus.CLOSED ||
      referral.correspondence?.status === CorrespondenceStatus.ARCHIVED
    ) {
      throw new BadRequestException('المراسلة مغلقة — لا يمكن تسليم عمل عليها');
    }

    const correspondenceId = referral.correspondenceId;

    const result = await this.prisma.$transaction(async (tx) => {
      const parentCorr = await tx.correspondence.findUnique({
        where: { id: correspondenceId },
        select: { status: true },
      });
      if (
        parentCorr?.status === CorrespondenceStatus.CLOSED ||
        parentCorr?.status === CorrespondenceStatus.ARCHIVED
      ) {
        throw new BadRequestException('المراسلة مغلقة — لا يمكن تسليم عمل عليها');
      }

      // 1. تحديث الإحالة لتصبح ANSWERED مع توثيق answeredAt
      const updated = await tx.referral.update({
        where: { id: referralId },
        data: {
          status: ReferralStatus.ANSWERED,
          answeredAt: new Date(),
        },
        include: REFERRAL_INCLUDE,
      });

      // 2. التحقق من بقاء أي إحالات مفتوحة (OPEN) أخرى على نفس المراسلة
      const remainingOpenCount = await tx.referral.count({
        where: {
          correspondenceId,
          status: ReferralStatus.OPEN,
        },
      });

      // 3. إذا لم تبقَ أي إحالات OPEN، تنتقل المراسلة إلى IN_PROGRESS
      if (remainingOpenCount === 0) {
        await tx.correspondence.updateMany({
          where: {
            id: correspondenceId,
            status: CorrespondenceStatus.REFERRED,
          },
          data: {
            status: CorrespondenceStatus.IN_PROGRESS,
            ...(referral.correspondence.version !== undefined ? { version: { increment: 1 } } : {}),
          },
        });
      }

      // 4. استخراج معرّفات مرسلي الإحالات المفتوحة ذات الصلة ومرسل هذه الإحالة
      const relatedReferrals = await tx.referral.findMany({
        where: { correspondenceId },
        select: { fromUserId: true, status: true },
      });

      const recipientSet = new Set<string>();
      if (referral.fromUserId && referral.fromUserId !== user.id) {
        recipientSet.add(referral.fromUserId);
      }
      for (const r of relatedReferrals) {
        if (r.fromUserId && r.fromUserId !== user.id) {
          recipientSet.add(r.fromUserId);
        }
      }
      const recipientIds = Array.from(recipientSet);

      // 5. تسجيل الحدث في الـ Outbox داخل نفس المعاملة (Transactional Outbox)
      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REFERRAL_ANSWERED,
          payload: {
            audit: {
              action: AuditAction.UPDATE,
              entityType: 'Referral',
              entityId: referralId,
              summary: actingOnBehalfOf
                ? `أجاب ${user.name} على الإحالة الخاصة بالمراسلة ${updated.correspondence.refNumber} (نيابة عن ${actingOnBehalfOf.name})`
                : `أجاب ${user.name} على الإحالة الخاصة بالمراسلة ${updated.correspondence.refNumber}`,
              metadata: {
                referralId,
                remainingOpenCount,
                ...(actingOnBehalfOf
                  ? { delegatorId: actingOnBehalfOf.id, delegatorName: actingOnBehalfOf.name, delegateUserId: user.id }
                  : {}),
                correspondenceNewStatus:
                  remainingOpenCount === 0
                    ? CorrespondenceStatus.IN_PROGRESS
                    : undefined,
              },
              userId: user.id,
            },
            notification: {
              type: NotificationType.NEW_REFERRAL,
              recipientIds,
              title: `تمت إجابة الإحالة للمراسلة ${updated.correspondence.refNumber}`,
              body: actingOnBehalfOf
                ? `أجاب «${user.name}» (نيابة عن ${actingOnBehalfOf.name}) على الإحالة في المراسلة «${updated.correspondence.subject}»`
                : `أجاب «${user.name}» على الإحالة الموجهة إليه في المراسلة «${updated.correspondence.subject}»`,
              link: `/correspondences/${correspondenceId}`,
              entityType: 'Correspondence',
              entityId: correspondenceId,
            },
          },
        });
      }

      return { updated, recipientIds };
    });

    // 6. تشغيل المعالج الفوري أو المسار المباشر
    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.UPDATE,
        entityType: 'Referral',
        entityId: referralId,
        summary: actingOnBehalfOf
          ? `أجاب ${user.name} على الإحالة الخاصة بالمراسلة ${result.updated.correspondence.refNumber} (نيابة عن ${actingOnBehalfOf.name})`
          : `أجاب ${user.name} على الإحالة الخاصة بالمراسلة ${result.updated.correspondence.refNumber}`,
        metadata: {
          referralId,
          ...(actingOnBehalfOf
            ? { delegatorId: actingOnBehalfOf.id, delegatorName: actingOnBehalfOf.name, delegateUserId: user.id }
            : {}),
        },
      });

      if (result.recipientIds.length > 0) {
        await this.notifications.notifyMany(result.recipientIds, {
          type: NotificationType.NEW_REFERRAL,
          title: `تمت إجابة الإحالة للمراسلة ${result.updated.correspondence.refNumber}`,
          body: actingOnBehalfOf
            ? `أجاب «${user.name}» (نيابة عن ${actingOnBehalfOf.name}) على الإحالة في المراسلة «${result.updated.correspondence.subject}»`
            : `أجاب «${user.name}» على الإحالة الموجهة إليه في المراسلة «${result.updated.correspondence.subject}»`,
          link: `/correspondences/${correspondenceId}`,
          entityType: 'Correspondence',
          entityId: correspondenceId,
        });
      }
    }

    return result.updated;
  }

  /** إغلاق الإحالة — الجهة المحال إليها أو الإدارة العليا */
  async close(id: string, user: AuthUser) {
    const referral = await this.prisma.referral.findUnique({
      where: { id },
      include: { correspondence: true },
    });
    if (!referral) throw new NotFoundException('الإحالة غير موجودة');

    const isRecipient = referral.toUserId === user.id;
    const privilegedRoles: Role[] = [Role.ADMIN, Role.GM, Role.DEPUTY_GM];
    const isPrivileged = privilegedRoles.includes(user.role);
    if (!isRecipient && !isPrivileged) {
      throw new ForbiddenException('فقط الجهة المحال إليها أو الإدارة العليا تملك إغلاق الإحالة');
    }
    if (referral.status === ReferralStatus.CLOSED) {
      throw new BadRequestException('الإحالة مغلقة مسبقًا');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.referral.update({
        where: { id },
        data: { status: ReferralStatus.CLOSED, closedAt: new Date() },
        include: REFERRAL_INCLUDE,
      });

      const remainingOpen = await tx.referral.count({
        where: {
          correspondenceId: referral.correspondenceId,
          status: ReferralStatus.OPEN,
        },
      });

      if (remainingOpen === 0) {
        await tx.correspondence.updateMany({
          where: {
            id: referral.correspondenceId,
            status: CorrespondenceStatus.REFERRED,
          },
          data: {
            status: CorrespondenceStatus.IN_PROGRESS,
            ...(referral.correspondence.version !== undefined ? { version: { increment: 1 } } : {}),
          },
        });
      }

      return res;
    });

    await this.audit.log({
      action: AuditAction.CLOSE,
      entityType: 'Referral',
      entityId: id,
      summary: `إغلاق الإحالة الخاصة بالمراسلة ${updated.correspondence.refNumber}`,
    });
    return updated;
  }
}
