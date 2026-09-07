import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditAction, CorrespondenceStatus, Prisma, Role, ReferralStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { CreateReferralDto, MyReferralsQueryDto } from './dto';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CorrespondenceAction,
  assertTransition,
  getNextStatus,
} from '../workflow/correspondence-state-machine';
import { canRefer } from '../security/business-policies';

const USER_BRIEF = { id: true, name: true, email: true } as const;

const REFERRAL_INCLUDE = {
  fromUser: { select: USER_BRIEF },
  toUser: { select: USER_BRIEF },
  correspondence: { select: { id: true, refNumber: true, subject: true, status: true, priority: true } },
} satisfies Prisma.ReferralInclude;

export type ReferralRow = Prisma.ReferralGetPayload<{ include: typeof REFERRAL_INCLUDE }>;

@Injectable()
export class ReferralsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly correspondences: CorrespondencesService,
    private readonly notifications: NotificationsService,
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

    const referral = await this.prisma.$transaction(async (tx) => {
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
      await tx.correspondence.update({
        where: { id: correspondenceId },
        data: {
          status: getNextStatus(corr.status, CorrespondenceAction.REFER) ?? CorrespondenceStatus.REFERRED,
          departmentId:
            user.role === Role.DEPT_MANAGER
              ? corr.departmentId // عند إحالة مدير القسم لا نغير قسم المراسلة (هو قسمه أصلاً)
              : toUser!.role === Role.DEPT_MANAGER && toUser!.departmentId
                ? toUser!.departmentId
                : corr.departmentId,
        },
      });
      return created;
    });

    await this.audit.log({
      action: AuditAction.REFER,
      entityType: 'Correspondence',
      entityId: correspondenceId,
      summary: `أحال ${user.name} المراسلة ${corr.refNumber} إلى ${toUser!.name}`,
      metadata: { toUserId: toUser!.id, note: dto.note ?? null },
    });

    // إشعار الجهة المحال إليها فورًا
    await this.notifications.notifyReferralReceived({
      toUserId: toUser!.id,
      actorName: user.name,
      refNumber: corr.refNumber,
      subject: corr.subject,
      correspondenceId: corr.id,
      note: referral.note,
      dueDate: referral.dueDate,
    });

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

  /** إغلاق الإحالة — الجهة المحال إليها أو الإدارة العليا */
  async close(id: string, user: AuthUser) {
    const referral = await this.prisma.referral.findUnique({ where: { id } });
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

    const updated = await this.prisma.referral.update({
      where: { id },
      data: { status: ReferralStatus.CLOSED, closedAt: new Date() },
      include: REFERRAL_INCLUDE,
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
