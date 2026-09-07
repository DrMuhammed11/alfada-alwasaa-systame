import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
  NotificationType,
  ReferralStatus,
  ReplyStatus,
  Role,
  TaskStatus,
} from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser } from '../common/types';
import { RejectReplyDto } from './dto';
import { REPLY_INCLUDE, ReplyRow } from './replies.constants';
import {
  CorrespondenceAction,
  assertTransition,
} from '../workflow/correspondence-state-machine';
import { canApproveReply } from '../security/business-policies';

import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { OutboxEventType } from '../outbox/outbox.types';

@Injectable()
export class RepliesApprovalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
  ) {}

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
    // حساب مستحقي الاعتماد مسبقاً لحفظهم في الـ Outbox داخل نفس المعاملة
    const approvalRecipients = new Set<string>();
    if (reply.taskId) {
      const taskRow = await this.prisma.task.findUnique({
        where: { id: reply.taskId },
        select: { assignedById: true },
      });
      if (taskRow && taskRow.assignedById !== reply.authorId) {
        approvalRecipients.add(taskRow.assignedById);
      }
    }
    const openReferrals = this.prisma.referral
      ? await this.prisma.referral.findMany({
          where: { correspondenceId: reply.correspondenceId, status: ReferralStatus.OPEN },
          select: { fromUserId: true },
        })
      : [];
    for (const referral of openReferrals) {
      if (referral.fromUserId !== reply.authorId) {
        approvalRecipients.add(referral.fromUserId);
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const res = await tx.reply.updateMany({
        where: {
          id,
          ...(reply.version !== undefined ? { version: reply.version } : {}),
          status: ReplyStatus.DRAFT,
        },
        data: {
          status: ReplyStatus.SUBMITTED,
          submittedAt: now,
          ...(reply.version !== undefined ? { version: { increment: 1 } } : {}),
        },
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
        data: {
          status: r.correspondence?.status
            ? assertTransition(
                r.correspondence.status,
                CorrespondenceAction.SUBMIT_REPLY,
              )
            : CorrespondenceStatus.PENDING_APPROVAL,
        },
      });
      if (r.taskId) {
        await tx.task.update({
          where: { id: r.taskId },
          data: { status: TaskStatus.SUBMITTED, submittedAt: now },
        });
      }

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_SUBMITTED,
          payload: {
            audit: {
              action: AuditAction.SUBMIT,
              entityType: 'Reply',
              entityId: id,
              summary: `رفع مسودة الرد للاعتماد على المراسلة ${reply.correspondence.refNumber}`,
              metadata: { correspondenceId: reply.correspondenceId },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_SUBMITTED,
              recipientIds: [...approvalRecipients],
              title: `مسودة رد مرفوعة للاعتماد على ${reply.correspondence.refNumber}`,
              body: `رفع «${reply.author.name}» مسودة رد للاعتماد على المراسلة ${reply.correspondence.refNumber}`,
              link: `/correspondences/${reply.correspondenceId}`,
              entityType: 'Reply',
              entityId: r.id,
            },
          },
        });
      }

      return r;
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.SUBMIT,
        entityType: 'Reply',
        entityId: id,
        summary: `رفع مسودة الرد للاعتماد على المراسلة ${reply.correspondence.refNumber}`,
        metadata: { correspondenceId: reply.correspondenceId },
      });

      await this.notifications.notifyReplySubmitted({
        recipientIds: [...approvalRecipients],
        authorName: reply.author.name,
        refNumber: reply.correspondence.refNumber,
        subject: reply.correspondence.subject,
        correspondenceId: reply.correspondenceId,
        replyId: updated.id,
      });
    }

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
        where: {
          id,
          ...(reply.version !== undefined ? { version: reply.version } : {}),
          status: ReplyStatus.SUBMITTED,
        },
        data: {
          status: ReplyStatus.APPROVED,
          approvedById: user.id,
          approvedAt: now,
          ...(reply.version !== undefined ? { version: { increment: 1 } } : {}),
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
        data: {
          status: reply.correspondence?.status
            ? assertTransition(
                reply.correspondence.status,
                CorrespondenceAction.APPROVE_REPLY,
              )
            : CorrespondenceStatus.APPROVED,
        },
      });
      // الإحالات المفتوحة أصبحت مجابة
      await tx.referral.updateMany({
        where: {
          correspondenceId: reply.correspondenceId,
          status: ReferralStatus.OPEN,
        },
        data: { status: ReferralStatus.ANSWERED, answeredAt: now },
      });

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_APPROVED,
          payload: {
            audit: {
              action: AuditAction.APPROVE,
              entityType: 'Reply',
              entityId: id,
              summary: `اعتماد الرد على المراسلة ${reply.correspondence.refNumber} (بقلم ${reply.author.name})`,
              metadata: { approver: user.email, correspondenceId: reply.correspondenceId },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_APPROVED,
              userId: reply.authorId,
              title: `اعتُمد ردك على المراسلة ${reply.correspondence.refNumber}`,
              body: `اعتمد ${user.name} الرد الذي أعددته على المراسلة ${reply.correspondence.refNumber}`,
              link: `/correspondences/${reply.correspondenceId}`,
              entityType: 'Reply',
              entityId: id,
            },
          },
        });
      }

      return r;
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.APPROVE,
        entityType: 'Reply',
        entityId: id,
        summary: `اعتماد الرد على المراسلة ${reply.correspondence.refNumber} (بقلم ${reply.author.name})`,
        metadata: { approver: user.email, correspondenceId: reply.correspondenceId },
      });

      await this.notifications.notifyReplyApproved({
        toUserId: reply.authorId,
        approverName: user.name,
        refNumber: reply.correspondence.refNumber,
        correspondenceId: reply.correspondenceId,
        replyId: id,
      });
    }

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
        where: {
          id,
          ...(reply.version !== undefined ? { version: reply.version } : {}),
          status: ReplyStatus.SUBMITTED,
        },
        data: {
          status: ReplyStatus.REJECTED,
          reviewedById: user.id,
          reviewNote: dto.note,
          ...(reply.version !== undefined ? { version: { increment: 1 } } : {}),
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
        data: {
          status: reply.correspondence?.status
            ? assertTransition(
                reply.correspondence.status,
                CorrespondenceAction.REJECT_REPLY,
              )
            : CorrespondenceStatus.IN_PROGRESS,
        },
      });
      if (r.taskId) {
        await tx.task.update({
          where: { id: r.taskId },
          data: { status: TaskStatus.IN_PROGRESS },
        });
      }

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_REJECTED,
          payload: {
            audit: {
              action: AuditAction.REJECT,
              entityType: 'Reply',
              entityId: id,
              summary: `رفض الرد على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note}`,
              metadata: { note: dto.note, reviewer: user.email, correspondenceId: reply.correspondenceId },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_REJECTED,
              userId: reply.authorId,
              title: `رُفض ردك على المراسلة ${reply.correspondence.refNumber}`,
              body: `سبب الرفض: ${dto.note}`,
              link: `/correspondences/${reply.correspondenceId}`,
              entityType: 'Reply',
              entityId: id,
            },
          },
        });
      }

      return r;
    });

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.REJECT,
        entityType: 'Reply',
        entityId: id,
        summary: `رفض الرد على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note}`,
        metadata: { note: dto.note, reviewer: user.email, correspondenceId: reply.correspondenceId },
      });

      await this.notifications.notifyReplyRejected({
        toUserId: reply.authorId,
        reviewerName: user.name,
        refNumber: reply.correspondence.refNumber,
        note: dto.note,
        correspondenceId: reply.correspondenceId,
        replyId: id,
      });
    }

    return updated;
  }

  /** قواعد صلاحية المعتمد: ليس الكاتب (إلا للمدير ومسؤول النظام) + نطاق مدير القسم */
  private async assertApprover(
    reply: ReplyRow & { correspondence: { id: string; departmentId: string | null; refNumber: string; status: CorrespondenceStatus } },
    user: AuthUser,
  ): Promise<void> {
    const openReferrals = this.prisma.referral
      ? await this.prisma.referral.findMany({
          where: { correspondenceId: reply.correspondence.id, toUserId: user.id },
          select: { toUserId: true, fromUserId: true },
        })
      : [];

    const policy = canApproveReply(
      user,
      reply,
      reply.correspondence as any,
      openReferrals,
    );

    if (!policy.allowed) {
      if (policy.reason === 'يمكنك اعتماد ردود مراسلات قسمك أو المحالة إليك فقط') {
        throw new ForbiddenException(policy.reason);
      }
      throw new BadRequestException(policy.reason);
    }
  }
}
