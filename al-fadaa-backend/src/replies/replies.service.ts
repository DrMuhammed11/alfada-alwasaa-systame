import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as path from 'path';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  Prisma,
  Priority,
  ReferralStatus,
  ReplyStatus,
  Role,
  TaskStatus,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  CorrespondencesService,
} from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import type { AuthUser, Paginated } from '../common/types';
import { buildPageMeta } from '../common/types';
import { CreateReplyDto, DirectReplyDto, RepliesQueryDto, UpdateReplyDto, RejectReplyDto } from './dto';
import { NotificationsService } from '../notifications/notifications.service';

const USER_BRIEF = { id: true, name: true, email: true } as const;

const REPLY_INCLUDE = {
  author: { select: USER_BRIEF },
  reviewedBy: { select: USER_BRIEF },
  approvedBy: { select: USER_BRIEF },
  task: { select: { id: true, title: true, status: true } },
  correspondence: { select: { id: true, refNumber: true, subject: true, status: true } },
  attachments: true,
} satisfies Prisma.ReplyInclude;

export type ReplyRow = Prisma.ReplyGetPayload<{ include: typeof REPLY_INCLUDE }>;

@Injectable()
export class RepliesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly correspondences: CorrespondencesService,
    private readonly mail: MailService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  // ─────────────── إنشاء وتعديل المسودات ───────────────

  /** إنشاء مسودة رد — بعد التحقق من نطاق رؤية المراسلة وصلاحية صياغتها */
  async create(dto: CreateReplyDto, user: AuthUser): Promise<ReplyRow> {
    await this.correspondences.findOne(dto.correspondenceId, user); // 404 / 403
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: dto.correspondenceId },
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');

    const draftable: CorrespondenceStatus[] = [
      CorrespondenceStatus.RECEIVED,
      CorrespondenceStatus.REFERRED,
      CorrespondenceStatus.IN_PROGRESS,
      CorrespondenceStatus.PENDING_APPROVAL,
      CorrespondenceStatus.SENT,
    ];
    if (!draftable.includes(corr.status)) {
      throw new BadRequestException(
        `لا يمكن إعداد رد على مراسلة في حالة «${corr.status}»`,
      );
    }

    let taskId: string | null = dto.taskId ?? null;
    if (taskId) {
      const task = await this.prisma.task.findUnique({ where: { id: taskId } });
      if (!task || task.correspondenceId !== corr.id) {
        throw new BadRequestException('التكليف المحدد لا ينتمي لهذه المراسلة');
      }
      if (task.assignedToId !== user.id && user.role === Role.EMPLOYEE) {
        throw new ForbiddenException('يمكنك إعداد الرد لتكليفاتك فقط');
      }
    }

    const reply = await this.prisma.reply.create({
      data: {
        correspondenceId: corr.id,
        taskId,
        authorId: user.id,
        body: dto.body,
      },
      include: REPLY_INCLUDE,
    });

    // أول مسودة → المراسلة تدخل مرحلة «جاري إعداد الرد»
    if (corr.status === CorrespondenceStatus.REFERRED) {
      await this.prisma.correspondence.update({
        where: { id: corr.id },
        data: { status: CorrespondenceStatus.IN_PROGRESS },
      });
    }

    await this.audit.log({
      action: AuditAction.CREATE,
      entityType: 'Reply',
      entityId: reply.id,
      summary: `إنشاء مسودة رد على المراسلة ${corr.refNumber}`,
      metadata: { correspondenceRef: corr.refNumber },
    });
    return reply;
  }

  /** تعديل المسودة — صاحبها فقط، وفي حالتي DRAFT أو REJECTED (بعد الرفض) */
  async update(id: string, dto: UpdateReplyDto, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: REPLY_INCLUDE,
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    if (reply.authorId !== user.id) {
      throw new ForbiddenException('فقط صاحب المسودة يمكنه تعديلها');
    }
    if (reply.status !== ReplyStatus.DRAFT && reply.status !== ReplyStatus.REJECTED) {
      throw new BadRequestException('لا يمكن تعديل رد مرفوع للاعتماد أو معتمد');
    }

    const updated = await this.prisma.reply.update({
      where: { id },
      data: {
        body: dto.body,
        status: ReplyStatus.DRAFT,
        version: { increment: 1 },
        submittedAt: null,
        reviewedById: null,
        reviewNote: null,
      },
      include: REPLY_INCLUDE,
    });

    await this.audit.log({
      action: AuditAction.UPDATE,
      entityType: 'Reply',
      entityId: id,
      summary: `تعديل مسودة الرد (الإصدار ${updated.version}) على المراسلة ${reply.correspondence.refNumber}`,
    });
    return updated;
  }

  // ─────────────── دورة الاعتماد ───────────────

  /** رفع المسودة للاعتماد — صاحبها فقط */
  async submit(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: REPLY_INCLUDE,
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    if (reply.authorId !== user.id) {
      throw new ForbiddenException('فقط صاحب المسودة يمكنه رفعها للاعتماد');
    }
    if (reply.status !== ReplyStatus.DRAFT) {
      throw new BadRequestException('المسودة مرفوعة مسبقًا أو معتمدة');
    }

    const now = new Date();
    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.reply.updateMany({
        where: { id, status: ReplyStatus.DRAFT },
        data: { status: ReplyStatus.SUBMITTED, submittedAt: now },
      });
      if (res.count === 0) {
        const current = await tx.reply.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('الرد غير موجود');
        throw new BadRequestException(
          `المسودة مرفوعة مسبقًا أو تم تغيير حالتها للتو من قِبل مستخدم آخر (الحالة الحالية: «${current.status}»)`,
        );
      }
      const r = await tx.reply.findUniqueOrThrow({
        where: { id },
        include: REPLY_INCLUDE,
      });
      await tx.correspondence.update({
        where: { id: r.correspondenceId },
        data: { status: CorrespondenceStatus.PENDING_APPROVAL },
      });
      if (r.taskId) {
        await tx.task.update({
          where: { id: r.taskId },
          data: { status: TaskStatus.SUBMITTED, submittedAt: now },
        });
      }
      return r;
    });

    await this.audit.log({
      action: AuditAction.SUBMIT,
      entityType: 'Reply',
      entityId: id,
      summary: `رفع مسودة الرد للاعتماد على المراسلة ${reply.correspondence.refNumber}`,
      metadata: { correspondenceId: reply.correspondenceId },
    });

    // تنبيه المستحقين للاعتماد: منشئ التكليف + مُحوّلو الإحالات المفتوحة
    // (مع إزالة التكرار واستثناء كاتب المسودة نفسه)
    const approvalRecipients = new Set<string>();
    if (updated.taskId) {
      const taskRow = await this.prisma.task.findUnique({
        where: { id: updated.taskId },
        select: { assignedById: true },
      });
      if (taskRow && taskRow.assignedById !== reply.authorId) {
        approvalRecipients.add(taskRow.assignedById);
      }
    }
    const openReferrals = await this.prisma.referral.findMany({
      where: { correspondenceId: reply.correspondenceId, status: ReferralStatus.OPEN },
      select: { fromUserId: true },
    });
    for (const referral of openReferrals) {
      if (referral.fromUserId !== reply.authorId) {
        approvalRecipients.add(referral.fromUserId);
      }
    }
    await this.notifications.notifyReplySubmitted({
      recipientIds: [...approvalRecipients],
      authorName: reply.author.name,
      refNumber: reply.correspondence.refNumber,
      subject: reply.correspondence.subject,
      correspondenceId: reply.correspondenceId,
      replyId: updated.id,
    });

    return updated;
  }

  /** اعتماد الرد — لا يجوز اعتماد رد صاغه المعتمد بنفسه */
  async approve(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: { ...REPLY_INCLUDE, correspondence: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    await this.assertApprover(reply, user);

    const now = new Date();
    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.reply.updateMany({
        where: { id, status: { in: [ReplyStatus.SUBMITTED, ReplyStatus.DRAFT, ReplyStatus.REJECTED] } },
        data: {
          status: ReplyStatus.APPROVED,
          approvedById: user.id,
          approvedAt: now,
        },
      });
      if (res.count === 0) {
        const current = await tx.reply.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('الرد غير موجود');
        throw new BadRequestException(
          `تم تغيير حالة الرد للتو من قِبل مستخدم آخر (الحالة الحالية: «${current.status}»)`,
        );
      }
      const r = await tx.reply.findUniqueOrThrow({
        where: { id },
        include: REPLY_INCLUDE,
      });
      await tx.correspondence.update({
        where: { id: reply.correspondenceId },
        data: { status: CorrespondenceStatus.APPROVED },
      });
      // الإحالات المفتوحة أصبحت مجابة
      await tx.referral.updateMany({
        where: {
          correspondenceId: reply.correspondenceId,
          status: ReferralStatus.OPEN,
        },
        data: { status: ReferralStatus.ANSWERED, answeredAt: now },
      });
      return r;
    });

    await this.audit.log({
      action: AuditAction.APPROVE,
      entityType: 'Reply',
      entityId: id,
      summary: `اعتماد الرد على المراسلة ${reply.correspondence.refNumber} (بقلم ${reply.author.name})`,
      metadata: { approver: user.email, correspondenceId: reply.correspondenceId },
    });

    // إشعار الكاتب بالاعتماد
    await this.notifications.notifyReplyApproved({
      toUserId: reply.authorId,
      approverName: user.name,
      refNumber: reply.correspondence.refNumber,
      correspondenceId: reply.correspondenceId,
      replyId: id,
    });

    return updated;
  }

  /** رفض الرد مع سبب — يعود للموظف لتعديله */
  async reject(id: string, dto: RejectReplyDto, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: { ...REPLY_INCLUDE, correspondence: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    await this.assertApprover(reply, user);

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.reply.updateMany({
        where: { id, status: { in: [ReplyStatus.SUBMITTED, ReplyStatus.DRAFT, ReplyStatus.APPROVED] }, sentAt: null },
        data: {
          status: ReplyStatus.REJECTED,
          reviewedById: user.id,
          reviewNote: dto.note,
        },
      });
      if (res.count === 0) {
        const current = await tx.reply.findUnique({
          where: { id },
          select: { status: true },
        });
        if (!current) throw new NotFoundException('الرد غير موجود');
        throw new BadRequestException(
          `تم تغيير حالة الرد للتو من قِبل مستخدم آخر (الحالة الحالية: «${current.status}»)`,
        );
      }
      const r = await tx.reply.findUniqueOrThrow({
        where: { id },
        include: REPLY_INCLUDE,
      });
      await tx.correspondence.update({
        where: { id: reply.correspondenceId },
        data: { status: CorrespondenceStatus.IN_PROGRESS },
      });
      if (r.taskId) {
        await tx.task.update({
          where: { id: r.taskId },
          data: { status: TaskStatus.IN_PROGRESS },
        });
      }
      return r;
    });

    await this.audit.log({
      action: AuditAction.REJECT,
      entityType: 'Reply',
      entityId: id,
      summary: `رفض الرد على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note}`,
      metadata: { note: dto.note, reviewer: user.email, correspondenceId: reply.correspondenceId },
    });

    // إشعار الكاتب بالرفض مع السبب — ليعود للمسودة فورًا
    await this.notifications.notifyReplyRejected({
      toUserId: reply.authorId,
      reviewerName: user.name,
      refNumber: reply.correspondence.refNumber,
      note: dto.note,
      correspondenceId: reply.correspondenceId,
      replyId: id,
    });

    return updated;
  }

  /** قواعد صلاحية المعتمد: ليس الكاتب (إلا للمدير ومسؤول النظام) + نطاق مدير القسم */
  private async assertApprover(
    reply: ReplyRow & { correspondence: { id: string; departmentId: string | null; refNumber: string } },
    user: AuthUser,
  ): Promise<void> {
    const isExecutive = user.role === Role.GM || user.role === Role.ADMIN;
    if (!isExecutive && reply.status !== ReplyStatus.SUBMITTED) {
      throw new BadRequestException('الرد غير مرفوع للاعتماد');
    }
    if (reply.authorId === user.id && !isExecutive) {
      throw new BadRequestException('لا يمكنك اعتماد أو رفض رد أعددته بنفسك');
    }
    if (user.role === Role.DEPT_MANAGER) {
      const inMyDept =
        !!user.departmentId && reply.correspondence.departmentId === user.departmentId;
      const referredToMe =
        (await this.prisma.referral.count({
          where: { correspondenceId: reply.correspondence.id, toUserId: user.id },
        })) > 0;
      if (!inMyDept && !referredToMe) {
        throw new ForbiddenException(
          'يمكنك اعتماد ردود مراسلات قسمك أو المحالة إليك فقط',
        );
      }
    }
  }

  // ─────────────── الإرسال الموحّد ───────────────

  /**
   * الإرسال النهائي — حصري للمدير العام (صلاحية CORR_SEND):
   *  1. توليد رقم صادر OUT-2026-XXXXX
   *  2. إنشاء سجل الصادر المرتبط بالوارد (سلسلة المراسلة)
   *  3. وسم الوارد والرد والمرفقات
   *  4. إقفال التكليف والإحالات
   *  5. الإرسال الفعلي من بريد الشركة الموحد info@al-fadaa.com
   */
  async send(id: string, user: AuthUser): Promise<{ success: boolean; sent: true; refNumber: string }> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: {
        correspondence: true,
        task: true,
        author: { select: USER_BRIEF },
      },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    const isExecutive = user.role === Role.GM || user.role === Role.ADMIN;
    if (reply.status !== ReplyStatus.APPROVED) {
      if (isExecutive && (reply.status === ReplyStatus.DRAFT || reply.status === ReplyStatus.SUBMITTED)) {
        await this.prisma.reply.update({
          where: { id },
          data: {
            status: ReplyStatus.APPROVED,
            approvedById: user.id,
            approvedAt: new Date(),
          },
        });
      } else {
        throw new BadRequestException('لا يمكن إرسال رد غير معتمد');
      }
    }
    if (reply.sentAt) {
      throw new BadRequestException('تم إرسال هذا الرد مسبقًا');
    }
    const corr = reply.correspondence;
    if (corr.type !== CorrespondenceType.INCOMING) {
      throw new BadRequestException('الإرسال متاح للردود على المراسلات الواردة');
    }
    if (!corr.senderEmail) {
      throw new BadRequestException(
        'لا يوجد بريد إلكتروني للمرسل — حدّث بيانات المراسلة أولًا',
      );
    }

    const replyAttachments = await this.prisma.attachment.findMany({
      where: { replyId: reply.id },
    });

    const now = new Date();
    let outRefNumber = '';
    let outMessageId = '';

    await this.prisma.$transaction(async (tx) => {
      // 1. حجز الرد المشروط بالحالة (APPROVED و sentAt === null)
      const res = await tx.reply.updateMany({
        where: { id, status: ReplyStatus.APPROVED, sentAt: null },
        data: { sentAt: now },
      });
      if (res.count === 0) {
        const current = await tx.reply.findUnique({
          where: { id },
          select: { status: true, sentAt: true },
        });
        if (!current) throw new NotFoundException('الرد غير موجود');
        if (current.sentAt) {
          throw new BadRequestException('تم إرسال هذا الرد للتو من قِبل مستخدم آخر');
        }
        throw new BadRequestException(
          `لا يمكن إرسال الرد — حالته الحالية «${current.status}» ونُفِّذت للتو عملية أخرى عليه`,
        );
      }

      // 2. شرط التحقق: ممنوع فقط إذا كان هناك رد معتمد آخر بانتظار الإرسال لم يُرسل بعد
      const pendingOtherApproved = await tx.reply.findFirst({
        where: {
          correspondenceId: corr.id,
          status: ReplyStatus.APPROVED,
          sentAt: null,
          id: { not: reply.id },
        },
      });
      if (pendingOtherApproved) {
        throw new BadRequestException(
          'يوجد رد معتمد آخر بانتظار الإرسال لهذه المراسلة لم يُرسل بعد',
        );
      }

      outRefNumber = await this.refNumbers.generate('OUT');
      const mailFrom = this.config.get<string>('MAIL_FROM') ?? 'info@alfadaalwasaa.com';
      const mailDomain = mailFrom.includes('@') ? mailFrom.split('@')[1] : 'alfadaalwasaa.com';
      outMessageId = `<${outRefNumber.toLowerCase()}.${Date.now()}@${mailDomain}>`;

      // سجل الصادر الرسمي المرتبط بالوارد مع ربط بنيوي بسجل الرد (sourceReplyId)
      const outCorr = await tx.correspondence.create({
        data: {
          refNumber: outRefNumber,
          type: CorrespondenceType.OUTGOING,
          subject: `رد: ${corr.subject}`,
          body: reply.body,
          priority: corr.priority ?? Priority.NORMAL,
          status: CorrespondenceStatus.SENT,
          senderName: 'شركة الفضاء الواسع',
          senderEmail: this.config.get<string>('MAIL_FROM') ?? 'info@al-fadaa.com',
          parentId: corr.id,
          createdById: user.id,
          departmentId: corr.departmentId,
          sentAt: now,
          sourceReplyId: reply.id,
          messageId: outMessageId,
        },
      });

      // ربط مرفقات الرد بسجل الصادر ليظهر للمستعرضين ضمن الخيط
      for (const att of replyAttachments) {
        await tx.attachment.create({
          data: {
            correspondenceId: outCorr.id,
            fileName: att.fileName,
            storedName: att.storedName,
            mimeType: att.mimeType,
            size: att.size,
            uploadedById: att.uploadedById,
          },
        });
      }

      await tx.correspondence.update({
        where: { id: corr.id },
        data: { status: CorrespondenceStatus.SENT, sentAt: now },
      });
      if (reply.taskId) {
        await tx.task.update({
          where: { id: reply.taskId },
          data: { status: TaskStatus.DONE, doneAt: now },
        });
      }
      await tx.referral.updateMany({
        where: { correspondenceId: corr.id, status: { not: ReferralStatus.CLOSED } },
        data: { status: ReferralStatus.CLOSED, closedAt: now },
      });
    });

    await this.audit.log({
      action: AuditAction.SEND,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `إرسال الرد ${outRefNumber} على المراسلة ${corr.refNumber} إلى ${corr.senderName ?? corr.senderEmail}`,
      metadata: { outRefNumber, messageId: outMessageId, to: corr.senderEmail },
    });

    // الإرسال من البريد الرسمي الموحد (console في التطوير / SMTP في الإنتاج)
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    await this.mail.sendReply({
      to: corr.senderEmail,
      subject: `رد: ${corr.subject}`,
      body: reply.body,
      refNumber: outRefNumber,
      messageId: outMessageId,
      inReplyTo: corr.messageId ?? undefined,
      references: corr.messageId ?? undefined,
      attachments: replyAttachments.map((a) => ({
        filename: a.fileName,
        path: path.join(uploadDir, a.storedName),
      })),
    });

    // إشعار الكاتب ومنشئ التكليف بأن الرد أُرسل للعميل
    const sentRecipients = [reply.authorId];
    if (reply.taskId && reply.task?.assignedById) {
      sentRecipients.push(reply.task.assignedById);
    }
    await this.notifications.notifyReplySent({
      recipientIds: sentRecipients,
      outRefNumber,
      inRefNumber: corr.refNumber,
      toEmail: corr.senderEmail ?? '',
      correspondenceId: corr.id,
    });

    return { success: true, sent: true, refNumber: outRefNumber };
  }

  /**
   * إرسال رد مباشر وفوري للعميل عبر البريد الإلكتروني (مثل Gmail/Outlook)
   * مع توثيق الصادر وربطه بالمحادثة وتحديث توقيتها لتتصدر صندوق البريد فوراً
   */
  async sendDirect(
    dto: DirectReplyDto,
    user: AuthUser,
  ): Promise<{ success: boolean; sent: true; refNumber: string; reply: ReplyRow }> {
    await this.correspondences.findOne(dto.correspondenceId, user);
    const corr = await this.prisma.correspondence.findUnique({
      where: { id: dto.correspondenceId },
    });
    if (!corr) throw new NotFoundException('المراسلة غير موجودة');
    if (corr.type !== CorrespondenceType.INCOMING) {
      throw new BadRequestException('الرد المباشر متاح للمراسلات الواردة فقط');
    }
    if (!corr.senderEmail) {
      throw new BadRequestException('لا يوجد بريد إلكتروني للمرسل في هذه المراسلة — حدّث البريد أولًا');
    }

    // شرط الرفض: ممنوع فقط إذا كان هناك رد معتمد على هذه المراسلة لم يُرسل بعد
    const pendingApproved = await this.prisma.reply.findFirst({
      where: {
        correspondenceId: corr.id,
        status: ReplyStatus.APPROVED,
        sentAt: null,
      },
    });
    if (pendingApproved) {
      throw new BadRequestException('يوجد رد معتمد بانتظار الإرسال لهذه المراسلة لم يُرسل بعد');
    }

    const outRefNumber = await this.refNumbers.generate('OUT');
    const now = new Date();
    const mailFrom = this.config.get<string>('MAIL_FROM') ?? 'info@alfadaalwasaa.com';
    const mailDomain = mailFrom.includes('@') ? mailFrom.split('@')[1] : 'alfadaalwasaa.com';
    const outMessageId = `<${outRefNumber.toLowerCase()}.${Date.now()}@${mailDomain}>`;

    const mailSubject = corr.subject.startsWith('رد:') || corr.subject.startsWith('Re:')
      ? corr.subject
      : `رد: [${corr.refNumber}] ${corr.subject}`;

    const directAttachments = (dto.attachmentIds && dto.attachmentIds.length > 0)
      ? await this.prisma.attachment.findMany({
          where: { id: { in: dto.attachmentIds } },
        })
      : [];

    // تنفيذ المسار كمعاملة واحدة تتبع نفس ترتيب دالة send القائمة بالضبط
    const result = await this.prisma.$transaction(async (tx) => {
      // التحقق داخل المعاملة من عدم وجود رد معتمد معلق
      const pendingApprovedInTx = await tx.reply.findFirst({
        where: {
          correspondenceId: corr.id,
          status: ReplyStatus.APPROVED,
          sentAt: null,
        },
      });
      if (pendingApprovedInTx) {
        throw new BadRequestException('يوجد رد معتمد بانتظار الإرسال لهذه المراسلة لم يُرسل بعد');
      }

      // التحقق من أن المراسلة ما زالت مفتوحة ولم تُغلق أو تُؤرشف للتو
      const currentCorr = await tx.correspondence.findUnique({
        where: { id: corr.id },
        select: { status: true },
      });
      if (
        !currentCorr ||
        currentCorr.status === CorrespondenceStatus.CLOSED ||
        currentCorr.status === CorrespondenceStatus.ARCHIVED
      ) {
        throw new BadRequestException('لا يمكن الرد المباشر على مراسلة مغلقة أو مؤرشفة');
      }

      // 1. إنشاء سجل رد بحالة APPROVED فورًا (المؤلف هو نفسه المعتمد بتفويض الإرسال المباشر)
      const reply = await tx.reply.create({
        data: {
          correspondenceId: corr.id,
          authorId: user.id,
          reviewedById: user.id,
          approvedById: user.id,
          body: dto.body,
          status: ReplyStatus.APPROVED,
          submittedAt: now,
          approvedAt: now,
          sentAt: now,
        },
        include: REPLY_INCLUDE,
      });

      // 2. إنشاء مراسلة فرعية صادرة برقم صادر رسمي مع ربط بنيوي بسجل الرد
      const outCorr = await tx.correspondence.create({
        data: {
          refNumber: outRefNumber,
          type: CorrespondenceType.OUTGOING,
          subject: mailSubject,
          body: dto.body,
          priority: corr.priority ?? Priority.NORMAL,
          status: CorrespondenceStatus.SENT,
          senderName: 'شركة الفضاء الواسع',
          senderEmail: this.config.get<string>('MAIL_FROM') ?? 'info@al-fadaa.com',
          parentId: corr.id,
          createdById: user.id,
          departmentId: corr.departmentId,
          sentAt: now,
          sourceReplyId: reply.id,
          messageId: outMessageId,
        },
      });

      // ربط المرفقات بالرد وبالمراسلة الفرعية الصادرة
      for (const att of directAttachments) {
        await tx.attachment.update({
          where: { id: att.id },
          data: { replyId: reply.id },
        });
        await tx.attachment.create({
          data: {
            correspondenceId: outCorr.id,
            fileName: att.fileName,
            storedName: att.storedName,
            mimeType: att.mimeType,
            size: att.size,
            uploadedById: att.uploadedById,
          },
        });
      }

      // 3. تحديث المراسلة الواردة
      await tx.correspondence.update({
        where: { id: corr.id },
        data: {
          status: CorrespondenceStatus.SENT,
          sentAt: now,
          updatedAt: now,
        },
      });

      // 4. إغلاق الإحالات المفتوحة إن وجدت
      await tx.referral.updateMany({
        where: { correspondenceId: corr.id, status: { not: ReferralStatus.CLOSED } },
        data: { status: ReferralStatus.CLOSED, closedAt: now },
      });

      // 5. إغلاق التكليفات المفتوحة إن وجدت
      await tx.task.updateMany({
        where: { correspondenceId: corr.id, status: { not: TaskStatus.DONE } },
        data: { status: TaskStatus.DONE, doneAt: now },
      });

      return reply;
    });

    // 6. توثيق في سجل التدقيق مع بيان الاعتماد والإرسال المباشر بتفويض الإدارة
    await this.audit.log({
      action: AuditAction.SEND,
      entityType: 'Correspondence',
      entityId: corr.id,
      summary: `إرسال رد رسمي مباشر ${outRefNumber} على المراسلة ${corr.refNumber} إلى ${corr.senderName ?? corr.senderEmail} (اعتماد وإرسال مباشر بتفويض الإدارة)`,
      metadata: {
        correspondenceRef: corr.refNumber,
        outRefNumber,
        messageId: outMessageId,
        to: corr.senderEmail,
        directSend: true,
        authorizedSender: user.email,
        selfApproved: true,
      },
    });

    // 7. إرسال البريد عبر mail.sendReply
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    await this.mail.sendReply({
      to: corr.senderEmail,
      subject: mailSubject,
      body: dto.body,
      refNumber: outRefNumber,
      messageId: outMessageId,
      inReplyTo: corr.messageId ?? undefined,
      references: corr.messageId ?? undefined,
      attachments: directAttachments.map((a) => ({
        filename: a.fileName,
        path: path.join(uploadDir, a.storedName),
      })),
    });

    // 8. إشعار المعنيين
    await this.notifications.notifyReplySent({
      recipientIds: [user.id],
      outRefNumber,
      inRefNumber: corr.refNumber,
      toEmail: corr.senderEmail,
      correspondenceId: corr.id,
    });

    // 9. إعادة كائن استجابة يطابق ما ينتظره الفرونت
    return {
      success: true,
      sent: true,
      refNumber: outRefNumber,
      reply: result,
    };
  }

  // ─────────────── الاستعراض ───────────────

  /** ردودي أو ردود مراسلة محددة (مع فرض نطاق الرؤية) */
  async findAll(dto: RepliesQueryDto, user: AuthUser): Promise<Paginated<ReplyRow>> {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;

    let where: Prisma.ReplyWhereInput = {};
    if (dto.correspondenceId) {
      await this.correspondences.findOne(dto.correspondenceId, user);
      where = { correspondenceId: dto.correspondenceId };
    } else {
      where = { authorId: user.id };
    }
    if (dto.status) where.status = dto.status;

    const [total, data] = await this.prisma.$transaction([
      this.prisma.reply.count({ where }),
      this.prisma.reply.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: REPLY_INCLUDE,
      }),
    ]);
    return { data, meta: buildPageMeta(page, limit, total) };
  }

  async findOne(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: REPLY_INCLUDE,
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');
    if (reply.authorId !== user.id) {
      await this.correspondences.findOne(reply.correspondenceId, user);
    }
    return reply;
  }
}
