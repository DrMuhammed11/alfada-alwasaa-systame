import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import {
  ApprovalStepStatus,
  AuditAction,
  CorrespondenceStatus,
  NotificationType,
  Priority,
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
import { RepliesVersioningService } from './replies-versioning.service';

@Injectable()
export class RepliesApprovalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    @Optional() private readonly outbox?: OutboxService,
    @Optional() private readonly outboxProcessor?: OutboxProcessor,
    @Optional() private readonly versioning?: RepliesVersioningService,
  ) {}

  /**
   * رفع المسودة للاعتماد — صاحبها فقط
   * ينشئ خطوات المسار المتتابعة وفق الأولوية، ويشعر صاحب المستوى الأول فقط
   */
  async submit(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: {
        ...REPLY_INCLUDE,
        correspondence: true,
      },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    if (reply.authorId !== user.id) {
      throw new ForbiddenException('فقط صاحب المسودة يمكنه رفعها للاعتماد');
    }
    if (reply.status !== ReplyStatus.DRAFT) {
      throw new BadRequestException('المسودة مرفوعة مسبقًا أو معتمدة');
    }

    const now = new Date();
    const priority = reply.correspondence.priority ?? Priority.NORMAL;

    // 1. تحديد خطوات المسار بناءً على الإعدادات أو الافتراضي
    const workflowSteps = await this.getWorkflowStepsForPriority(priority);

    const updated = await this.prisma.$transaction(async (tx) => {
      // حذف أي خطوات اعتماد سابقة إن وُجدت (مثلاً من محاولة سابقة رُفضت)
      if (tx.approvalStep) {
        await tx.approvalStep.deleteMany({
          where: { replyId: id },
        });

        // إنشاء خطوات المستويات المتتابعة
        for (const ws of workflowSteps) {
          await tx.approvalStep.create({
            data: {
              replyId: id,
              level: ws.level,
              requiredRole: ws.requiredRole,
              status: ApprovalStepStatus.PENDING,
            },
          });
        }
      }

      // حفظ نسخة غير قابلة للتعديل عند الرفع إن لم تكن محفوظة
      if (tx.replyVersion) {
        const existingVer = await tx.replyVersion.findUnique({
          where: { replyId_version: { replyId: id, version: reply.version } },
        });
        if (!existingVer) {
          await tx.replyVersion.create({
            data: {
              replyId: id,
              version: reply.version,
              body: reply.body,
              authorId: reply.authorId,
            },
          });
        }
      }

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

      // حساب مستلمي المستوى الأول فقط
      const level1Role = workflowSteps[0]?.requiredRole ?? Role.DEPT_MANAGER;
      const level1Recipients = await this.getLevelApproverIds(level1Role, reply);

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_SUBMITTED,
          payload: {
            audit: {
              action: AuditAction.SUBMIT,
              entityType: 'Reply',
              entityId: id,
              summary: `رفع مسودة الرد للاعتماد (المستوى 1 من ${workflowSteps.length}) على المراسلة ${reply.correspondence.refNumber}`,
              metadata: {
                correspondenceId: reply.correspondenceId,
                version: reply.version,
                level: 1,
                totalLevels: workflowSteps.length,
              },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_SUBMITTED,
              recipientIds: level1Recipients,
              title: `مسودة رد مرفوعة للاعتماد (المستوى 1) على ${reply.correspondence.refNumber}`,
              body: `رفع «${reply.author.name}» مسودة رد للاعتماد على المراسلة ${reply.correspondence.refNumber}`,
              link: `/correspondences/${reply.correspondenceId}`,
              entityType: 'Reply',
              entityId: r.id,
            },
          },
        });
      }

      return { reply: r, level1Recipients };
    });

    const level1Role = workflowSteps[0]?.requiredRole ?? Role.DEPT_MANAGER;
    const level1Recipients = updated.level1Recipients;

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.SUBMIT,
        entityType: 'Reply',
        entityId: id,
        summary: `رفع مسودة الرد للاعتماد (المستوى 1 من ${workflowSteps.length}) على المراسلة ${reply.correspondence.refNumber}`,
        metadata: {
          correspondenceId: reply.correspondenceId,
          version: reply.version,
          level: 1,
          totalLevels: workflowSteps.length,
        },
      });

      await this.notifications.notifyReplySubmitted({
        recipientIds: level1Recipients,
        authorName: reply.author.name,
        refNumber: reply.correspondence.refNumber,
        subject: reply.correspondence.subject,
        correspondenceId: reply.correspondenceId,
        replyId: updated.reply.id,
      });
    }

    return updated.reply;
  }

  /**
   * اعتماد الرد — يمر تتابعيًا:
   * عند اعتماد مستوى يُنشَّط التالي، ويصبح الرد APPROVED بعد آخر مستوى فقط
   */
  async approve(id: string, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: { ...REPLY_INCLUDE, correspondence: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    // جلب خطوات الاعتماد المرتبة للمسودة
    const steps = this.prisma.approvalStep
      ? await this.prisma.approvalStep.findMany({
          where: { replyId: id },
          orderBy: { level: 'asc' },
        })
      : [];

    const activeStep = steps.find((s) => s.status === ApprovalStepStatus.PENDING);

    // التحقق من صلاحية المعتمد أو وكيله النشط
    const eligibility = await this.checkApproverEligibility(reply, user, activeStep?.requiredRole);
    if (!eligibility.allowed) {
      if (eligibility.reason === 'يمكنك اعتماد ردود مراسلات قسمك أو المحالة إليك فقط') {
        throw new ForbiddenException(eligibility.reason);
      }
      throw new BadRequestException(eligibility.reason ?? 'غير مصرح لك باعتماد هذا الرد');
    }

    const currentLevel = activeStep?.level ?? 1;
    const nextStep = activeStep
      ? steps.find((s) => s.level > activeStep.level && s.status === ApprovalStepStatus.PENDING)
      : null;
    const isFinalLevel = !nextStep;
    const now = new Date();

    const updated = await this.prisma.$transaction(async (tx) => {
      // 1. تحديث الخطوة الحالية
      if (activeStep && tx.approvalStep) {
        await tx.approvalStep.update({
          where: { id: activeStep.id },
          data: {
            status: ApprovalStepStatus.APPROVED,
            approverId: user.id,
            decidedAt: now,
          },
        });
      }

      if (isFinalLevel) {
        // اعتماد نهائي بعد اكتمال كافة المستويات
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

        // إغلاق الإحالات المفتوحة
        await tx.referral.updateMany({
          where: {
            correspondenceId: reply.correspondenceId,
            status: ReferralStatus.OPEN,
          },
          data: { status: ReferralStatus.ANSWERED, answeredAt: now },
        });
      } else {
        // مستوى وسيط: الرد يبقى SUBMITTED والمراسلة تبقى PENDING_APPROVAL
        await tx.reply.update({
          where: { id },
          data: { updatedAt: now },
        });
      }

      const r = await tx.reply.findUniqueOrThrow({
        where: { id },
        include: REPLY_INCLUDE,
      });

      const summaryText = isFinalLevel
        ? `اعتماد الرد النهائي على المراسلة ${reply.correspondence.refNumber}`
        : `اعتماد الرد للمستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber}`;

      const finalSummary = eligibility.actingOnBehalfOf
        ? `${summaryText} (نيابة عن ${eligibility.actingOnBehalfOf.name})`
        : summaryText;

      const auditMetadata: Record<string, any> = {
        approver: user.email,
        correspondenceId: reply.correspondenceId,
        level: currentLevel,
        isFinal: isFinalLevel,
        version: reply.version,
        ...(nextStep ? { nextLevel: nextStep.level } : {}),
        ...(eligibility.actingOnBehalfOf
          ? {
              delegatorId: eligibility.actingOnBehalfOf.id,
              delegatorName: eligibility.actingOnBehalfOf.name,
              delegateUserId: user.id,
            }
          : {}),
      };

      if (this.outbox) {
        if (isFinalLevel) {
          await this.outbox.emit(tx, {
            type: OutboxEventType.REPLY_APPROVED,
            payload: {
              audit: {
                action: AuditAction.APPROVE,
                entityType: 'Reply',
                entityId: id,
                summary: finalSummary,
                metadata: auditMetadata,
                userId: user.id,
              },
              notification: {
                type: NotificationType.REPLY_APPROVED,
                userId: reply.authorId,
                title: `اعتُمد ردك النهائي على المراسلة ${reply.correspondence.refNumber}`,
                body: `اعتمد ${user.name} الرد الذي أعددته على المراسلة ${reply.correspondence.refNumber}`,
                link: `/correspondences/${reply.correspondenceId}`,
                entityType: 'Reply',
                entityId: id,
              },
            },
          });
        } else if (nextStep) {
          const nextRecipients = await this.getLevelApproverIds(nextStep.requiredRole, reply);
          await this.outbox.emit(tx, {
            type: OutboxEventType.REPLY_SUBMITTED,
            payload: {
              audit: {
                action: AuditAction.APPROVE,
                entityType: 'Reply',
                entityId: id,
                summary: finalSummary,
                metadata: auditMetadata,
                userId: user.id,
              },
              notification: {
                type: NotificationType.REPLY_SUBMITTED,
                recipientIds: nextRecipients,
                title: `مسودة رد بانتظار اعتمادك (المستوى ${nextStep.level})`,
                body: `اعتُمد المستوى ${currentLevel} وبانتظار اعتمادك على المراسلة ${reply.correspondence.refNumber}`,
                link: `/correspondences/${reply.correspondenceId}`,
                entityType: 'Reply',
                entityId: id,
              },
            },
          });
        }
      }

      return r;
    });

    const summaryText = isFinalLevel
      ? `اعتماد الرد النهائي على المراسلة ${reply.correspondence.refNumber}`
      : `اعتماد الرد للمستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber}`;
    const finalSummary = eligibility.actingOnBehalfOf
      ? `${summaryText} (نيابة عن ${eligibility.actingOnBehalfOf.name})`
      : summaryText;

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.APPROVE,
        entityType: 'Reply',
        entityId: id,
        summary: finalSummary,
        metadata: {
          approver: user.email,
          correspondenceId: reply.correspondenceId,
          level: currentLevel,
          isFinal: isFinalLevel,
          version: reply.version,
          ...(nextStep ? { nextLevel: nextStep.level } : {}),
          ...(eligibility.actingOnBehalfOf
            ? {
                delegatorId: eligibility.actingOnBehalfOf.id,
                delegatorName: eligibility.actingOnBehalfOf.name,
                delegateUserId: user.id,
              }
            : {}),
        },
      });

      if (isFinalLevel) {
        await this.notifications.notifyReplyApproved({
          toUserId: reply.authorId,
          approverName: user.name,
          refNumber: reply.correspondence.refNumber,
          correspondenceId: reply.correspondenceId,
          replyId: id,
        });
      } else if (nextStep) {
        const nextRecipients = await this.getLevelApproverIds(nextStep.requiredRole, reply);
        await this.notifications.notifyMany(nextRecipients, {
          type: NotificationType.REPLY_SUBMITTED,
          title: `مسودة رد بانتظار اعتمادك (المستوى ${nextStep.level})`,
          body: `اعتُمد المستوى ${currentLevel} وبانتظار اعتمادك على المراسلة ${reply.correspondence.refNumber}`,
          link: `/correspondences/${reply.correspondenceId}`,
          entityType: 'Reply',
          entityId: id,
        });
      }
    }

    return updated;
  }

  /**
   * رفض الرد مع سبب — يعود للموظف مع تصفير المستويات الأعلى
   * وإشعار الكاتب والمعتمد السابق باحتمالية الإعادة
   */
  async reject(id: string, dto: RejectReplyDto, user: AuthUser): Promise<ReplyRow> {
    const reply = await this.prisma.reply.findUnique({
      where: { id },
      include: { ...REPLY_INCLUDE, correspondence: true },
    });
    if (!reply) throw new NotFoundException('الرد غير موجود');

    const steps = this.prisma.approvalStep
      ? await this.prisma.approvalStep.findMany({
          where: { replyId: id },
          orderBy: { level: 'asc' },
        })
      : [];

    const activeStep = steps.find((s) => s.status === ApprovalStepStatus.PENDING);

    const eligibility = await this.checkApproverEligibility(reply, user, activeStep?.requiredRole);
    if (!eligibility.allowed) {
      throw new BadRequestException(eligibility.reason ?? 'غير مصرح لك برفض هذا الرد');
    }

    const now = new Date();
    const currentLevel = activeStep?.level ?? 1;
    const previousStep = steps.find(
      (s) => s.level === currentLevel - 1 && s.status === ApprovalStepStatus.APPROVED,
    );

    const updated = await this.prisma.$transaction(async (tx) => {
      if (activeStep && tx.approvalStep) {
        // تحديث الخطوة الحالية إلى مرفوضة
        await tx.approvalStep.update({
          where: { id: activeStep.id },
          data: {
            status: ApprovalStepStatus.REJECTED,
            approverId: user.id,
            decidedAt: now,
            note: dto.note,
          },
        });

        // تصفير أو حذف المستويات الأعلى اللاحقة
        await tx.approvalStep.deleteMany({
          where: { replyId: id, level: { gt: currentLevel } },
        });
      }

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

      const rejectSummary = eligibility.actingOnBehalfOf
        ? `رفض الرد في المستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note} (نيابة عن ${eligibility.actingOnBehalfOf.name})`
        : `رفض الرد في المستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note}`;

      if (this.outbox) {
        await this.outbox.emit(tx, {
          type: OutboxEventType.REPLY_REJECTED,
          payload: {
            audit: {
              action: AuditAction.REJECT,
              entityType: 'Reply',
              entityId: id,
              summary: rejectSummary,
              metadata: {
                level: currentLevel,
                note: dto.note,
                reviewer: user.email,
                correspondenceId: reply.correspondenceId,
                version: reply.version,
                ...(eligibility.actingOnBehalfOf
                  ? {
                      delegatorId: eligibility.actingOnBehalfOf.id,
                      delegatorName: eligibility.actingOnBehalfOf.name,
                      delegateUserId: user.id,
                    }
                  : {}),
              },
              userId: user.id,
            },
            notification: {
              type: NotificationType.REPLY_REJECTED,
              userId: reply.authorId,
              title: `رُفض ردك في المستوى ${currentLevel} على ${reply.correspondence.refNumber}`,
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

    const rejectSummary = eligibility.actingOnBehalfOf
      ? `رفض الرد في المستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note} (نيابة عن ${eligibility.actingOnBehalfOf.name})`
      : `رفض الرد في المستوى ${currentLevel} على المراسلة ${reply.correspondence.refNumber} — سبب: ${dto.note}`;

    if (this.outboxProcessor) {
      this.outboxProcessor.trigger();
    } else {
      await this.audit.log({
        action: AuditAction.REJECT,
        entityType: 'Reply',
        entityId: id,
        summary: rejectSummary,
        metadata: {
          level: currentLevel,
          note: dto.note,
          reviewer: user.email,
          correspondenceId: reply.correspondenceId,
          version: reply.version,
          ...(eligibility.actingOnBehalfOf
            ? {
                delegatorId: eligibility.actingOnBehalfOf.id,
                delegatorName: eligibility.actingOnBehalfOf.name,
                delegateUserId: user.id,
              }
            : {}),
        },
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

    // إشعار معتمد المستوى السابق بالإلغاء والإعادة المحتملة
    if (previousStep?.approverId && previousStep.approverId !== user.id) {
      await this.notifications.notify({
        userId: previousStep.approverId,
        type: NotificationType.REPLY_REJECTED,
        title: `تم رفض الرد في المستوى ${currentLevel} وإعادته للتعديل`,
        body: `تم رفض الرد الذي اعتمدته سابقًا في المستوى ${previousStep.level} من قِبل ${user.name} بسبب: «${dto.note}»`,
        link: `/correspondences/${reply.correspondenceId}`,
        entityType: 'Reply',
        entityId: id,
      });
    }

    return updated;
  }

  /** جلب خطوات مسار الاعتماد المضبوطة للأولوية أو الافتراضية */
  private async getWorkflowStepsForPriority(priority: Priority): Promise<{ level: number; requiredRole: Role }[]> {
    const config = this.prisma.approvalWorkflowConfig
      ? await this.prisma.approvalWorkflowConfig.findUnique({
          where: { priority },
        })
      : null;

    if (config && Array.isArray(config.steps) && config.steps.length > 0) {
      return (config.steps as any[]).map((s) => ({
        level: s.level,
        requiredRole: s.requiredRole as Role,
      }));
    }

    // القواعد المقترحة الافتراضية
    if (priority === Priority.URGENT) {
      return [
        { level: 1, requiredRole: Role.DEPT_MANAGER },
        { level: 2, requiredRole: Role.DEPUTY_GM },
        { level: 3, requiredRole: Role.GM },
      ];
    } else if (priority === Priority.HIGH) {
      return [
        { level: 1, requiredRole: Role.DEPT_MANAGER },
        { level: 2, requiredRole: Role.DEPUTY_GM },
      ];
    } else {
      // توافق خلفي كامل: مستوى واحد
      return [{ level: 1, requiredRole: Role.DEPT_MANAGER }];
    }
  }

  /** حساب معرفات معتمدي المستوى بناءً على الدور المعين ونطاق القسم */
  private async getLevelApproverIds(requiredRole: Role, reply: any): Promise<string[]> {
    const recipients = new Set<string>();

    if (requiredRole === Role.DEPT_MANAGER) {
      if (reply.taskId) {
        const taskRow = await this.prisma.task.findUnique({
          where: { id: reply.taskId },
          select: { assignedById: true },
        });
        if (taskRow && taskRow.assignedById !== reply.authorId) {
          recipients.add(taskRow.assignedById);
        }
      }
      const openReferrals = this.prisma.referral
        ? await this.prisma.referral.findMany({
            where: { correspondenceId: reply.correspondenceId, status: ReferralStatus.OPEN },
            select: { fromUserId: true },
          })
        : [];
      for (const ref of openReferrals) {
        if (ref.fromUserId !== reply.authorId) {
          recipients.add(ref.fromUserId);
        }
      }
      if (recipients.size === 0 && reply.correspondence?.departmentId) {
        const dept = await this.prisma.department.findUnique({
          where: { id: reply.correspondence.departmentId },
          select: { managerId: true },
        });
        if (dept?.managerId && dept.managerId !== reply.authorId) {
          recipients.add(dept.managerId);
        }
      }
    } else {
      const users = await this.prisma.user.findMany({
        where: { role: requiredRole, isActive: true },
        select: { id: true },
      });
      for (const u of users) {
        if (u.id !== reply.authorId) {
          recipients.add(u.id);
        }
      }
    }

    return Array.from(recipients);
  }

  /**
   * التحقق من أهلية المعتمد (مع دعم الوكالة والتفويض النشط)
   */
  private async checkApproverEligibility(
    reply: ReplyRow & { correspondence: { id: string; departmentId: string | null; refNumber: string; status: CorrespondenceStatus } },
    user: AuthUser,
    requiredRole?: Role,
  ): Promise<{ allowed: boolean; actingOnBehalfOf?: { id: string; name: string } | null; reason?: string }> {
    if (reply.authorId === user.id && user.role !== Role.ADMIN) {
      return { allowed: false, reason: 'لا يمكنك اعتماد أو رفض رد أعددته بنفسك' };
    }

    const openReferrals = this.prisma.referral
      ? await this.prisma.referral.findMany({
          where: { correspondenceId: reply.correspondence.id, toUserId: user.id },
          select: { toUserId: true, fromUserId: true },
        })
      : [];

    // 1. فحص مباشر للمستخدم
    const directPolicy = canApproveReply(
      user,
      reply,
      reply.correspondence as any,
      openReferrals,
    );

    const matchesRole =
      !requiredRole ||
      user.role === requiredRole ||
      user.role === Role.ADMIN ||
      (requiredRole === Role.DEPT_MANAGER && (user.role === Role.GM || user.role === Role.DEPUTY_GM)) ||
      (requiredRole === Role.DEPUTY_GM && user.role === Role.GM);

    if (directPolicy.allowed && matchesRole) {
      return { allowed: true };
    }

    // 2. فحص ما إذا كان المستخدم وكيلاً نشطًا لمفوِّض يملك الصلاحية
    if (this.prisma.delegation) {
      const now = new Date();
      const activeDelegations = await this.prisma.delegation.findMany({
        where: {
          delegateId: user.id,
          active: true,
          startsAt: { lte: now },
          endsAt: { gte: now },
        },
        include: { delegator: true },
      });

      for (const d of activeDelegations) {
        if (reply.authorId === user.id) continue;

        const delegatorUser: AuthUser = {
          id: d.delegator.id,
          name: d.delegator.name,
          email: d.delegator.email,
          role: d.delegator.role,
          departmentId: d.delegator.departmentId,
        };

        const delegatorReferrals = await this.prisma.referral.findMany({
          where: { correspondenceId: reply.correspondence.id, toUserId: d.delegatorId },
          select: { toUserId: true, fromUserId: true },
        });

        const delegatorPolicy = canApproveReply(
          delegatorUser,
          reply,
          reply.correspondence as any,
          delegatorReferrals,
        );

        const delegatorMatchesRole =
          !requiredRole ||
          d.delegator.role === requiredRole ||
          d.delegator.role === Role.ADMIN ||
          (requiredRole === Role.DEPT_MANAGER && (d.delegator.role === Role.GM || d.delegator.role === Role.DEPUTY_GM)) ||
          (requiredRole === Role.DEPUTY_GM && d.delegator.role === Role.GM);

        if (delegatorPolicy.allowed && delegatorMatchesRole) {
          return {
            allowed: true,
            actingOnBehalfOf: { id: d.delegator.id, name: d.delegator.name },
          };
        }
      }
    }

    return {
      allowed: false,
      reason: directPolicy.reason ?? 'ليس لديك صلاحية اعتماد هذا المستوى من الرد',
    };
  }
}
