import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
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

@Injectable()
export class RepliesApprovalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
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
        where: { id, status: ReplyStatus.SUBMITTED },
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
        where: { id, status: ReplyStatus.SUBMITTED },
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
