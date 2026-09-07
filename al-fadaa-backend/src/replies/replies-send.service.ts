import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as path from 'path';
import {
  AuditAction,
  CorrespondenceStatus,
  CorrespondenceType,
  NotificationType,
  Priority,
  ReferralStatus,
  ReplyStatus,
  Role,
  TaskStatus,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { AuthUser } from '../common/types';
import { DirectReplyDto } from './dto';
import { USER_BRIEF, REPLY_INCLUDE, ReplyRow } from './replies.constants';
import {
  CorrespondenceAction,
  assertTransition,
} from '../workflow/correspondence-state-machine';
import { canSendReply } from '../security/business-policies';

import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { OutboxEventType } from '../outbox/outbox.types';

@Injectable()
export class RepliesSendService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly refNumbers: RefNumberService,
    private readonly correspondences: CorrespondencesService,
    private readonly mail: MailService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
  ) {}

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
        reply.status = ReplyStatus.APPROVED;
      }
    }

    const policy = canSendReply(user, reply, reply.correspondence);
    if (!policy.allowed) {
      throw new BadRequestException(policy.reason);
    }
    const corr = reply.correspondence;
    const rootCorr = corr.parentId
      ? ((await this.prisma.correspondence.findUnique({ where: { id: corr.parentId } })) ?? corr)
      : corr;
    const rootRefNumber = rootCorr.refNumber;

    const replyAttachments = await this.prisma.attachment.findMany({
      where: { replyId: reply.id },
    });

    const cleanSubject = rootCorr.subject
      .replace(/^(?:رد|Re):\s*/i, '')
      .replace(/^\[(?:INC|OUT|INT)-\d{4}-\S+\]\s*/i, '')
      .trim();
    const mailSubject = `رد: [${rootRefNumber}] ${cleanSubject}`;

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
          subject: mailSubject,
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
        data: {
          status: corr?.status
            ? assertTransition(
                corr.status,
                CorrespondenceAction.SEND_REPLY,
              )
            : CorrespondenceStatus.SENT,
          sentAt: now,
        },
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

      if (this.outbox) {
        const sentRecipients = [reply.authorId];
        if (reply.taskId && reply.task?.assignedById) {
          sentRecipients.push(reply.task.assignedById);
        }
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_SENT,
          payload: {
            audit: {
              action: AuditAction.SEND,
              entityType: 'Correspondence',
              entityId: corr.id,
              summary: `إرسال الرد ${outRefNumber} (الإصدار ${reply.version}) على المراسلة ${corr.refNumber} إلى ${corr.senderName ?? corr.senderEmail}`,
              metadata: { outRefNumber, messageId: outMessageId, to: corr.senderEmail, sentVersion: reply.version },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_SENT,
              recipientIds: sentRecipients,
              title: `أُرسل الرد ${outRefNumber} للعميل (${corr.senderEmail ?? ''})`,
              body: `المراسلة الواردة ${rootRefNumber} — الرد الصادر ${outRefNumber}`,
              link: `/correspondences/${corr.id}`,
              entityType: 'Correspondence',
              entityId: corr.id,
            },
          },
        });
      }
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.SEND,
        entityType: 'Correspondence',
        entityId: corr.id,
        summary: `إرسال الرد ${outRefNumber} (الإصدار ${reply.version}) على المراسلة ${corr.refNumber} إلى ${corr.senderName ?? corr.senderEmail}`,
        metadata: { outRefNumber, messageId: outMessageId, to: corr.senderEmail, sentVersion: reply.version },
      });

      // إشعار الكاتب ومنشئ التكليف بأن الرد أُرسل للعميل
      const sentRecipients = [reply.authorId];
      if (reply.taskId && reply.task?.assignedById) {
        sentRecipients.push(reply.task.assignedById);
      }
      await this.notifications.notifyReplySent({
        recipientIds: sentRecipients,
        outRefNumber,
        inRefNumber: rootRefNumber,
        toEmail: corr.senderEmail ?? '',
        correspondenceId: corr.id,
      });
    }

    // الإرسال من البريد الرسمي الموحد (console في التطوير / SMTP في الإنتاج)
    const uploadDir = process.env.UPLOAD_DIR || './uploads';
    await this.mail.sendReply({
      to: corr.senderEmail,
      subject: mailSubject,
      body: reply.body,
      refNumber: rootRefNumber,
      messageId: outMessageId,
      inReplyTo: corr.messageId ?? undefined,
      references: corr.messageId ?? undefined,
      attachments: replyAttachments.map((a) => ({
        filename: a.fileName,
        path: `${uploadDir}/${a.storedName}`,
        contentType: a.mimeType,
      })),
      replyId: reply.id,
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

    const rootCorr = corr.parentId
      ? ((await this.prisma.correspondence.findUnique({ where: { id: corr.parentId } })) ?? corr)
      : corr;
    const rootRefNumber = rootCorr.refNumber;

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

    const cleanSubject = rootCorr.subject
      .replace(/^(?:رد|Re):\s*/i, '')
      .replace(/^\[(?:INC|OUT|INT)-\d{4}-\S+\]\s*/i, '')
      .trim();
    const mailSubject = `رد: [${rootRefNumber}] ${cleanSubject}`;

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
          data: { replyId: reply.id, correspondenceId: null },
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
      refNumber: rootRefNumber,
      messageId: outMessageId,
      inReplyTo: corr.messageId ?? undefined,
      references: corr.messageId ?? undefined,
      attachments: directAttachments.map((a) => ({
        filename: a.fileName,
        path: path.join(uploadDir, a.storedName),
      })),
      replyId: result.id,
    });

    // 8. إشعار المعنيين
    await this.notifications.notifyReplySent({
      recipientIds: [user.id],
      outRefNumber,
      inRefNumber: rootRefNumber,
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
}
