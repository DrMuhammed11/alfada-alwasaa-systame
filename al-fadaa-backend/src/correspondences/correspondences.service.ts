import {
  BadRequestException,
  forwardRef,
  Inject,
  Injectable,
  NotFoundException,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  NotificationType,
  Prisma,
  Priority,
  ReferralStatus,
  ReplyStatus,
  Role,
  TaskStatus,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser, Paginated } from '../common/types';
import {
  CorrespondencesQueryDto,
  CreateIncomingDto,
  CreateInternalDto,
  PublicInquiryDto,
  UpdateCorrespondenceDto,
} from './dto';
import { RefNumberService } from './ref-number.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CorrespondenceAction,
  assertTransition,
  getAllowedStatusesForAction,
} from '../workflow/correspondence-state-machine';
import {
  canCloseCorrespondence,
  canArchiveCorrespondence,
} from '../security/business-policies';
import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { OutboxEventType } from '../outbox/outbox.types';
import {
  CorrespondenceDetailRow,
  CorrespondenceListRow,
  DETAIL_INCLUDE,
  LIST_INCLUDE,
  USER_BRIEF,
} from './correspondences.constants';
import { CorrespondencesQueryService } from './correspondences-query.service';
import { MailService } from '../mail/mail.service';

export {
  USER_BRIEF,
  LIST_INCLUDE,
  DETAIL_INCLUDE,
  CorrespondenceListRow,
  CorrespondenceDetailRow,
} from './correspondences.constants';

@Injectable()
export class CorrespondencesService {
  private readonly queryService: CorrespondencesQueryService;

  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
    @Optional() queryService?: CorrespondencesQueryService,
    @Optional() @Inject(forwardRef(() => MailService)) private readonly mail?: MailService,
  ) {
    this.queryService = queryService ?? new CorrespondencesQueryService(this.prisma);
  }

  // ─────────────── الإنشاء ───────────────

  /** تسجيل مراسلة واردة وصلت إلى بريد الشركة الموحد */
  async createIncoming(dto: CreateIncomingDto, user: AuthUser) {
    const refNumber = await this.refNumbers.generate('INC');
    const corr = await this.prisma.correspondence.create({
      data: {
        refNumber,
        type: CorrespondenceType.INCOMING,
        subject: dto.subject.trim(),
        body: dto.body ?? '',
        priority: dto.priority ?? Priority.NORMAL,
        status: CorrespondenceStatus.RECEIVED,
        senderName: dto.senderName.trim(),
        senderEmail: dto.senderEmail?.toLowerCase().trim(),
        senderPhone: dto.senderPhone,
        receivedAt: dto.receivedAt ? new Date(dto.receivedAt) : new Date(),
        createdById: user.id,
        messageId: dto.messageId ?? undefined,
        channel: dto.channel ?? undefined,
      },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `تسجيل مراسلة واردة ${refNumber} من «${corr.senderName}»`,
      metadata: {
        subject: corr.subject,
        senderEmail: corr.senderEmail,
        priority: corr.priority,
        messageId: dto.messageId,
      },
    });

    // تنبيه جميع مدراء العموم النشطين فعليًا بالوارد الجديد دون استثناء
    const gmUsers = await this.prisma.user.findMany({
      where: { role: Role.GM, isActive: true },
      select: { id: true },
    });
    const gmRecipients = gmUsers.map((g) => g.id);
    if (gmRecipients.length > 0) {
      await this.notifications.notifyIncomingRegistered({
        recipientIds: gmRecipients,
        refNumber,
        senderName: corr.senderName ?? '',
        subject: corr.subject,
        priority: corr.priority,
        correspondenceId: corr.id,
      });
    }

    return corr;
  }

  /** إنشاء تعميم داخلي بين الأقسام — ينشر فورًا دون دورة اعتماد */
  async createInternal(dto: CreateInternalDto, user: AuthUser) {
    const refNumber = await this.refNumbers.generate('INT');
    const corr = await this.prisma.correspondence.create({
      data: {
        refNumber,
        type: CorrespondenceType.INTERNAL,
        subject: dto.subject.trim(),
        body: dto.body,
        priority: dto.priority ?? Priority.NORMAL,
        status: CorrespondenceStatus.SENT,
        sentAt: new Date(),
        createdById: user.id,
        departmentId:
          user.role === 'DEPT_MANAGER' ? (user.departmentId ?? null) : null,
      },
    });

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `إنشاء تعميم داخلي ${refNumber}: ${corr.subject}`,
    });
    return corr;
  }

  // ─────────────── تفويض الاستعراض والفحص ───────────────

  /** استعراض المراسلات الجذرية بنطاق الرؤية والفلترة والترقيم */
  findAll(
    dto: CorrespondencesQueryDto,
    user: AuthUser,
  ): Promise<Paginated<CorrespondenceListRow>> {
    return this.queryService.findAll(dto, user);
  }

  /** تفاصيل مراسلة — مع فرض نطاق الرؤية نفسه */
  findOne(id: string, user: AuthUser): Promise<CorrespondenceDetailRow> {
    return this.queryService.findOne(id, user);
  }

  /** فحص صلاحية الاطلاع على مراسلة محددة (تُستخدم أيضًا من وحدات أخرى) */
  canView(
    corr: { id: string; departmentId: string | null },
    user: AuthUser,
  ): Promise<boolean> {
    return this.queryService.canView(corr, user);
  }

  // ─────────────── التعديل والإدارة ───────────────

  /** تعديل البيانات الأساسية — مسموح قبل بدء الإحالة فقط */
  async update(
    id: string,
    dto: UpdateCorrespondenceDto,
    user: AuthUser,
  ): Promise<CorrespondenceDetailRow> {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    if (
      corr.status !== CorrespondenceStatus.RECEIVED &&
      corr.status !== CorrespondenceStatus.UNDER_REVIEW
    ) {
      throw new BadRequestException(
        'لا يمكن تعديل بيانات المراسلة بعد بدء الإحالة — التعديلات تتم من الرد',
      );
    }

    const data: Prisma.CorrespondenceUpdateInput = {};
    if (dto.subject) data.subject = dto.subject.trim();
    if (dto.body !== undefined) data.body = dto.body;
    if (dto.priority) data.priority = dto.priority;
    if (dto.senderName !== undefined) data.senderName = dto.senderName;
    if (dto.senderEmail !== undefined) data.senderEmail = dto.senderEmail;
    if (dto.senderPhone !== undefined) data.senderPhone = dto.senderPhone;
    if (
      dto.status === CorrespondenceStatus.UNDER_REVIEW &&
      corr.status === CorrespondenceStatus.RECEIVED
    ) {
      data.status = assertTransition(corr.status, CorrespondenceAction.REVIEW);
    }

    const updated = await this.prisma.correspondence.update({
      where: { id },
      data,
      include: DETAIL_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Correspondence',
      entityId: id,
      summary: `تعديل بيانات المراسلة ${corr.refNumber}`,
      metadata: { updatedFields: Object.keys(dto) },
    });
    return updated;
  }

  /** إغلاق المراسلة (بدون رد أو بعد اكتمال المعالجة) */
  async close(id: string, user: AuthUser, options?: { force?: boolean }) {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    const policy = canCloseCorrespondence(user, corr);
    if (!policy.allowed) throw new BadRequestException(policy.reason);

    const closable = getAllowedStatusesForAction(CorrespondenceAction.CLOSE);

    const updated = await this.prisma.$transaction(async (tx) => {
      // 1. فحص الكيانات التابعة النشطة (إحالات مفتوحة / تكليفات جارية / مسودات رد)
      const openReferrals = tx.referral?.findMany
        ? await tx.referral.findMany({
            where: { correspondenceId: id, status: ReferralStatus.OPEN },
            include: { toUser: { select: { name: true } } },
          })
        : [];

      const activeTasks = tx.task?.findMany
        ? await tx.task.findMany({
            where: {
              correspondenceId: id,
              status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
            },
            include: { assignedTo: { select: { name: true } } },
          })
        : [];

      const activeReplies = tx.reply?.findMany
        ? await tx.reply.findMany({
            where: {
              correspondenceId: id,
              status: { in: [ReplyStatus.DRAFT, ReplyStatus.SUBMITTED] },
            },
            select: { id: true, status: true },
          })
        : [];

      // إذا وُجدت أي مسودة رد قيد التحرير أو الاعتماد ➔ يُرفض الإغلاق دائماً
      if (activeReplies.length > 0) {
        throw new BadRequestException('لا يمكن إغلاق المراسلة: توجد مسودة رد قيد التحرير أو الاعتماد');
      }

      const activeReasons: string[] = [];
      for (const ref of openReferrals) {
        activeReasons.push(`إحالة مفتوحة لدى ${ref.toUser?.name || 'مستخدم'}`);
      }
      for (const task of activeTasks) {
        activeReasons.push(`تكليف جارٍ لدى ${task.assignedTo?.name || 'مستخدم'}`);
      }

      if (activeReasons.length > 0) {
        if (!options?.force) {
          throw new BadRequestException(`لا يمكن إغلاق المراسلة: توجد ${activeReasons.join(' + ')}`);
        }

        // عند الإغلاق القسري الصريح (force: true):
        // أ. إغلاق الإحالات المفتوحة تلقائياً
        if (tx.referral?.updateMany) {
          await tx.referral.updateMany({
            where: { correspondenceId: id, status: ReferralStatus.OPEN },
            data: { status: ReferralStatus.CLOSED, closedAt: new Date() },
          });
        }

        // ب. إلغاء التكليفات المعلقة تلقائياً
        if (tx.task?.updateMany) {
          await tx.task.updateMany({
            where: {
              correspondenceId: id,
              status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
            },
            data: { status: TaskStatus.CANCELLED },
          });
        }

        // ج. تسجيل تدقيق مستقل لكل كيان تم إنهاؤه
        for (const ref of openReferrals) {
          await this.audit.log({
            action: AuditAction.CLOSE,
            entityType: 'Referral',
            entityId: ref.id,
            summary: `إغلاق إداري آلي للإحالة لـ${ref.toUser?.name || ''} عند إغلاق المراسلة ${corr.refNumber}`,
            userId: user.id,
          });
        }
        for (const task of activeTasks) {
          await this.audit.log({
            action: AuditAction.CLOSE,
            entityType: 'Task',
            entityId: task.id,
            summary: `إلغاء إداري آلي للتكليف لـ${task.assignedTo?.name || ''} عند إغلاق المراسلة ${corr.refNumber}`,
            userId: user.id,
          });
        }
      }

      // في الإغلاق النظيف: إغلاق الإحالات التي كانت ANSWERED لتصبح CLOSED رسمياً
      if (tx.referral?.updateMany) {
        await tx.referral.updateMany({
          where: { correspondenceId: id, status: ReferralStatus.ANSWERED },
          data: { status: ReferralStatus.CLOSED, closedAt: new Date() },
        });
      }

      // 2. التحديث الذري للمراسلة
      const res = await tx.correspondence.updateMany({
        where: {
          id,
          ...(corr.version !== undefined ? { version: corr.version } : {}),
          status: { in: closable },
        },
        data: {
          status: CorrespondenceStatus.CLOSED,
          closedAt: new Date(),
          ...(corr.version !== undefined ? { version: { increment: 1 } } : {}),
        },
      });
      if (res.count === 0) {
        const current = await tx.correspondence.findUnique({
          where: { id },
          select: { status: true, version: true },
        });
        if (!current) throw new NotFoundException('المراسلة غير موجودة');
        throw new BadRequestException(
          'عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة',
        );
      }

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.CORRESPONDENCE_CLOSED,
          payload: {
            audit: {
              action: AuditAction.CLOSE,
              entityType: 'Correspondence',
              entityId: id,
              summary: `إغلاق المراسلة ${corr.refNumber}`,
              userId: user.id,
            },
          },
        });
      }

      return tx.correspondence.findUniqueOrThrow({
        where: { id },
        include: DETAIL_INCLUDE,
      });
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.CLOSE,
        entityType: 'Correspondence',
        entityId: id,
        summary: `إغلاق المراسلة ${corr.refNumber}`,
      });
    }

    return updated;
  }

  /** أرشفة المراسلة — الخطوة الأخيرة في دورة الحياة */
  async archive(id: string, user: AuthUser) {
    const corr = await this.prisma.correspondence.findUnique({ where: { id } });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    const policy = canArchiveCorrespondence(user, corr);
    if (!policy.allowed) throw new BadRequestException(policy.reason);

    const archivable = getAllowedStatusesForAction(CorrespondenceAction.ARCHIVE);

    const updated = await this.prisma.$transaction(async (tx) => {
      // فحص الكيانات التابعة النشطة في الأرشفة
      const openReferrals = tx.referral?.findMany
        ? await tx.referral.findMany({
            where: { correspondenceId: id, status: ReferralStatus.OPEN },
            include: { toUser: { select: { name: true } } },
          })
        : [];

      const activeTasks = tx.task?.findMany
        ? await tx.task.findMany({
            where: {
              correspondenceId: id,
              status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
            },
            include: { assignedTo: { select: { name: true } } },
          })
        : [];

      const activeReplies = tx.reply?.findMany
        ? await tx.reply.findMany({
            where: {
              correspondenceId: id,
              status: { in: [ReplyStatus.DRAFT, ReplyStatus.SUBMITTED] },
            },
            select: { id: true, status: true },
          })
        : [];

      if (activeReplies.length > 0) {
        throw new BadRequestException('لا يمكن أرشفة المراسلة: توجد مسودة رد قيد التحرير أو الاعتماد');
      }

      const archiveReasons: string[] = [];
      for (const ref of openReferrals) {
        archiveReasons.push(`إحالة مفتوحة لدى ${ref.toUser?.name || 'مستخدم'}`);
      }
      for (const task of activeTasks) {
        archiveReasons.push(`تكليف جارٍ لدى ${task.assignedTo?.name || 'مستخدم'}`);
      }

      if (archiveReasons.length > 0) {
        throw new BadRequestException(`لا يمكن أرشفة المراسلة: توجد ${archiveReasons.join(' + ')}`);
      }

      const res = await tx.correspondence.updateMany({
        where: {
          id,
          ...(corr.version !== undefined ? { version: corr.version } : {}),
          status: { in: archivable },
        },
        data: {
          status: CorrespondenceStatus.ARCHIVED,
          ...(corr.version !== undefined ? { version: { increment: 1 } } : {}),
        },
      });
      if (res.count === 0) {
        const current = await tx.correspondence.findUnique({
          where: { id },
          select: { status: true, version: true },
        });
        if (!current) throw new NotFoundException('المراسلة غير موجودة');
        throw new BadRequestException(
          'عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة',
        );
      }

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.CORRESPONDENCE_ARCHIVED,
          payload: {
            audit: {
              action: AuditAction.ARCHIVE,
              entityType: 'Correspondence',
              entityId: id,
              summary: `أرشفة المراسلة ${corr.refNumber}`,
              userId: user.id,
            },
          },
        });
      }

      return tx.correspondence.findUniqueOrThrow({
        where: { id },
        include: DETAIL_INCLUDE,
      });
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.ARCHIVE,
        entityType: 'Correspondence',
        entityId: id,
        summary: `أرشفة المراسلة ${corr.refNumber}`,
      });
    }

    return updated;
  }

  // ─────────────── استقبال وتتبع استفسارات الموقع الإلكتروني ───────────────

  /** تسجيل طلب عرض سعر أو استشارة واردة من موقع الشركة الإلكتروني */
  async createPublicInquiry(dto: PublicInquiryDto) {
    const systemUser = await this.prisma.user.findFirst({
      where: { role: { in: [Role.ADMIN, Role.GM, Role.EMPLOYEE] }, isActive: true },
      select: { id: true, email: true, name: true, role: true },
    });
    if (!systemUser) {
      throw new BadRequestException('نظام استقبال الطلبات غير متاح حالياً');
    }

    const subject = `طلب عرض سعر أو استشارة: ${dto.service.trim()}`;
    const body = dto.message?.trim()
      ? `الخدمة المطلوبة: ${dto.service.trim()}\n\nتفاصيل الطلب:\n${dto.message.trim()}`
      : `طلب وارد عبر الموقع الإلكتروني بخصوص: ${dto.service.trim()}`;

    // 1. إنشاء المراسلة الواردة الرسمية
    const corr = await this.createIncoming(
      {
        subject,
        body,
        senderName: dto.name.trim(),
        senderPhone: dto.phone.trim(),
        senderEmail: dto.email?.trim().toLowerCase(),
        priority: Priority.NORMAL,
        channel: 'website',
      },
      systemUser as AuthUser,
    );

    // 2. التوزيع الآلي الذكي على القسم المختص
    let targetDeptCode = 'CS'; // الافتراضي: قسم خدمة العملاء والردود
    const serviceLower = dto.service.toLowerCase();
    if (
      serviceLower.includes('اتصال') ||
      serviceLower.includes('انترنت') ||
      serviceLower.includes('إنترنت') ||
      serviceLower.includes('شبك') ||
      serviceLower.includes('تقني') ||
      serviceLower.includes('مايكروويف')
    ) {
      targetDeptCode = 'IT'; // قسم تقنية المعلومات
    } else if (
      serviceLower.includes('مقاول') ||
      serviceLower.includes('طرق') ||
      serviceLower.includes('جسور') ||
      serviceLower.includes('حفريات') ||
      serviceLower.includes('إنشائ') ||
      serviceLower.includes('هندس')
    ) {
      targetDeptCode = 'ENG'; // القسم الهندسي
    }

    const targetDept = await this.prisma.department.findUnique({
      where: { code: targetDeptCode },
      select: { id: true, name: true, code: true, managerId: true },
    });

    if (targetDept) {
      // ربط المراسلة بالقسم وتحديث حالتها
      await this.prisma.correspondence.update({
        where: { id: corr.id },
        data: {
          departmentId: targetDept.id,
          status: targetDept.managerId ? CorrespondenceStatus.REFERRED : CorrespondenceStatus.RECEIVED,
        },
      });

      // إذا وُجد مدير للقسم، إنشاء إحالة رسمية تلقائية وإشعار فوري
      if (targetDept.managerId) {
        await this.prisma.referral.create({
          data: {
            correspondenceId: corr.id,
            fromUserId: systemUser.id,
            toUserId: targetDept.managerId,
            note: `إحالة آلية فورية لطلب عرض سعر / استشارة وارد من الموقع الإلكتروني بخصوص: ${dto.service.trim()}`,
            status: ReferralStatus.OPEN,
          },
        });

        await this.notifications.notify({
          userId: targetDept.managerId,
          type: NotificationType.NEW_REFERRAL,
          title: `طلب موقع جديد: ${dto.service.trim()}`,
          body: `ورد طلب عرض سعر من ${dto.name.trim()} (${dto.phone.trim()}). رُقم القيد: ${corr.refNumber}`,
          entityId: corr.id,
          entityType: 'Correspondence',
        });
      }
    }

    // توليد رمز تتبع مشفر غير قابل للتخمين للعميل
    const publicTrackingToken = crypto.randomBytes(16).toString('hex');
    await this.prisma.correspondence.update({
      where: { id: corr.id },
      data: { publicTrackingToken },
    });

    // 3. إرسال بريد توثيقي فوري للعميل عند توفر بريده الإلكتروني
    if (this.mail && dto.email?.trim()) {
      const clientEmail = dto.email.trim().toLowerCase();
      const trackingUrl = `https://www.alfadaalwasaa.com/#contact?ref=${encodeURIComponent(corr.refNumber)}&token=${encodeURIComponent(publicTrackingToken)}`;
      const html = `<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="utf-8">
  <title>شركة الفضاء الواسع — إشعار استلام طلب</title>
</head>
<body style="margin: 0; padding: 24px; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f1f5f9; color: #1e293b; direction: rtl; text-align: right;">
  <div style="max-width: 620px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(10,52,83,0.1); border: 1px solid #e2e8f0;">
    <div style="background: linear-gradient(135deg, #051e31 0%, #0a3453 100%); padding: 32px 24px; text-align: center; border-bottom: 4px solid #c6954a;">
      <h1 style="margin: 0; color: #ffffff; font-size: 22px; font-weight: 800;">شركة الفضاء الواسع</h1>
      <p style="margin: 6px 0 0; color: #dcb26b; font-size: 13px; font-weight: 600; letter-spacing: 2px;">AL-FADA AL-WASAA</p>
      <div style="margin-top: 14px; display: inline-block; background: rgba(198,149,74,0.15); border: 1px solid rgba(198,149,74,0.4); border-radius: 20px; padding: 4px 16px;">
        <span style="color: #ffffff; font-size: 12px; font-weight: 700;">إشعار استلام وتوثيق معاملة رسمية</span>
      </div>
    </div>
    <div style="padding: 32px 28px;">
      <p style="font-size: 16px; font-weight: 700; color: #0a3453; margin-top: 0;">عزيزنا العميل: ${dto.name.trim()}</p>
      <p style="font-size: 14px; line-height: 1.8; color: #334155;">
        نشكر تواصلكم مع <strong>شركة الفضاء الواسع لخدمات الاتصالات والمقاولات</strong>. نفيدكم بأنه تم استلام وتوثيق طلبكم رسمياً في نظام إدارة المراسلات المعتمد وإحالته للإدارة الفنية المختصة لدراسته وإعداد العرض المناسب.
      </p>
      <div style="background: #f8fafc; border-radius: 12px; border: 1px solid #cbd5e1; padding: 20px; margin: 24px 0; text-align: center;">
        <span style="display: block; font-size: 12px; font-weight: 600; color: #64748b; margin-bottom: 6px;">الرقم المرجعي المعتمد لمعاملتكم</span>
        <span style="display: inline-block; font-size: 24px; font-weight: 900; color: #0a3453; letter-spacing: 1px; font-family: monospace; background: #e2e8f0; padding: 6px 18px; border-radius: 8px; border: 1px dashed #94a3b8;">
          ${corr.refNumber}
        </span>
        <div style="margin-top: 14px; font-size: 13px; color: #475569;">
          <div><strong>الخدمة المطلوبة:</strong> ${dto.service.trim()}</div>
          <div style="margin-top: 4px;"><strong>رمز التتبع الآمن (خاص بكم):</strong> <code style="color: #c6954a; font-weight: 700;">${publicTrackingToken}</code></div>
          <div style="margin-top: 4px;"><strong>حالة الطلب:</strong> <span style="color: #0284c7; font-weight: 700;">محالة — قيد الدراسة والتسعير لدى الإدارة المختصة</span></div>
        </div>
      </div>
      <div style="text-align: center; margin: 30px 0 10px;">
        <a href="${trackingUrl}" target="_blank" style="display: inline-block; background: #c6954a; color: #051e31; text-decoration: none; padding: 14px 32px; border-radius: 30px; font-weight: 800; font-size: 14px; box-shadow: 0 4px 14px rgba(198,149,74,0.4);">
          متابعة حالة المعاملة عبر الموقع
        </a>
      </div>
      <p style="text-align: center; font-size: 11px; color: #94a3b8; margin-top: 8px;">
        يمكنكم الاستعلام في أي وقت باستخدام رقم القيد ورمز التتبع الآمن
      </p>
    </div>
    <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748b; line-height: 1.6;">
      <div>شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة</div>
      <div style="margin-top: 4px;">هاتف: +967 777 472 071 | بريد: info@alfadaalwasaa.com</div>
      <div style="margin-top: 8px; font-size: 11px; color: #94a3b8;">هذه رسالة آلية تم توليدها بواسطة نظام المراسلات الإلكتروني — يرجى عدم الرد المباشر على هذا البريد.</div>
    </div>
  </div>
</body>
</html>`;

      this.mail.sendReply({
        to: clientEmail,
        subject: `تأكيد استلام طلبكم برقم قيد [${corr.refNumber}] — شركة الفضاء الواسع`,
        body: `عزيزنا ${dto.name.trim()}، تم استلام وتوثيق طلبكم بخصوص (${dto.service.trim()}) بنجاح برقم قيد معتمد: ${corr.refNumber}. رمز التتبع الآمن: ${publicTrackingToken}. يمكنكم المتابعة عبر: ${trackingUrl}`,
        refNumber: corr.refNumber,
        html,
      }).catch((e) => {
        console.error('فشل إرسال بريد التأكيد التلقائي للعميل:', e);
      });
    }

    return {
      success: true,
      refNumber: corr.refNumber,
      trackingToken: publicTrackingToken,
      message: 'تم استلام طلبكم بنجاح ومحال للمراجعة والرد من الفريق المختص',
    };
  }

  /** استعلام عام عن حالة مراسلة برقمها المرجعي للعملاء وإظهار الرد الرسمي المعتمد بشرط توفر رمز التتبع الصحيح */
  async trackPublicInquiry(refNumber: string, token?: string) {
    if (!token || !token.trim()) {
      throw new UnauthorizedException('رمز التتبع الخاص بالمعاملة مطلوب لعرض تفاصيل وحالة الطلب');
    }

    const corr = await this.prisma.correspondence.findUnique({
      where: { refNumber: refNumber.trim().toUpperCase() },
      select: {
        refNumber: true,
        subject: true,
        status: true,
        receivedAt: true,
        publicTrackingToken: true,
        replies: {
          where: {
            OR: [
              { status: ReplyStatus.APPROVED },
              { sentAt: { not: null } },
            ],
          },
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            body: true,
            sentAt: true,
            approvedAt: true,
            createdAt: true,
          },
        },
        children: {
          where: {
            type: CorrespondenceType.OUTGOING,
          },
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            refNumber: true,
            body: true,
            sentAt: true,
            createdAt: true,
          },
        },
      },
    });
    if (!corr) {
      throw new NotFoundException('لم يتم العثور على مراسلة بهذا الرقم المرجعي');
    }

    // التحقق الصارم من رمز التتبع
    if (!corr.publicTrackingToken || corr.publicTrackingToken !== token.trim()) {
      throw new UnauthorizedException('رمز التتبع غير صحيح — لا يمكن عرض تفاصيل المعاملة');
    }

    const latestReply = corr.children[0]
      ? {
          refNumber: corr.children[0].refNumber,
          body: corr.children[0].body,
          sentAt: corr.children[0].sentAt ?? corr.children[0].createdAt,
        }
      : corr.replies[0]
      ? {
          refNumber: undefined,
          body: corr.replies[0].body,
          sentAt: corr.replies[0].sentAt ?? corr.replies[0].approvedAt ?? corr.replies[0].createdAt,
        }
      : null;

    return {
      refNumber: corr.refNumber,
      subject: corr.subject,
      status: corr.status,
      receivedAt: corr.receivedAt,
      reply: latestReply,
    };
  }
}

