import { Injectable } from '@nestjs/common';
import { CorrespondenceStatus, ReferralStatus, ReplyStatus, TaskStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * استخراج وتفتيش الكيانات التابعة اليتيمة والمعلقة على مراسلات غير ملائمة:
   * 1. إحالات مفتوحة على مراسلات ليست بحالة REFERRED (مثل CLOSED أو ARCHIVED)
   * 2. تكليفات معلقة (PENDING / IN_PROGRESS) على مراسلات مغلقة أو مؤرشفة
   * 3. مسودات ردود (DRAFT / SUBMITTED) على مراسلات مغلقة أو مؤرشفة
   */
  async findOrphans() {
    const orphanReferrals = await this.prisma.referral.findMany({
      where: {
        status: ReferralStatus.OPEN,
        correspondence: {
          status: { not: CorrespondenceStatus.REFERRED },
        },
      },
      include: {
        toUser: { select: { id: true, name: true, email: true, role: true } },
        fromUser: { select: { id: true, name: true, email: true } },
        correspondence: {
          select: { id: true, refNumber: true, subject: true, status: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const orphanTasks = await this.prisma.task.findMany({
      where: {
        status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
        correspondence: {
          status: { in: [CorrespondenceStatus.CLOSED, CorrespondenceStatus.ARCHIVED] },
        },
      },
      include: {
        assignedTo: { select: { id: true, name: true, email: true, role: true } },
        assignedBy: { select: { id: true, name: true, email: true } },
        correspondence: {
          select: { id: true, refNumber: true, subject: true, status: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const orphanReplies = await this.prisma.reply.findMany({
      where: {
        status: { in: [ReplyStatus.DRAFT, ReplyStatus.SUBMITTED] },
        correspondence: {
          status: { in: [CorrespondenceStatus.CLOSED, CorrespondenceStatus.ARCHIVED] },
        },
      },
      include: {
        author: { select: { id: true, name: true, email: true, role: true } },
        correspondence: {
          select: { id: true, refNumber: true, subject: true, status: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      summary: {
        totalOrphans: orphanReferrals.length + orphanTasks.length + orphanReplies.length,
        openReferralsCount: orphanReferrals.length,
        pendingTasksCount: orphanTasks.length,
        draftRepliesCount: orphanReplies.length,
      },
      orphanReferrals,
      orphanTasks,
      orphanReplies,
    };
  }

  /** استرجاع مسارات الاعتماد المضبوطة لكافة درجات الأولوية */
  async getApprovalWorkflows() {
    const configs = await this.prisma.approvalWorkflowConfig.findMany({
      orderBy: { priority: 'asc' },
    });
    return configs;
  }

  /** تحديث مسار اعتماد لأولوية معينة مع التحقق من صحة التسلسل الهرمي */
  async setApprovalWorkflow(priority: any, steps: { level: number; requiredRole: any }[]) {
    // 1. فرز الخطوات حسب المستوى
    const sorted = [...steps].sort((a, b) => a.level - b.level);

    // 2. التحقق من تسلسل المستويات (1, 2, 3...)
    for (let i = 0; i < sorted.length; i++) {
      if (sorted[i].level !== i + 1) {
        throw new Error(`خطوات الاعتماد يجب أن تبدأ من المستوى 1 وتكون متسلسلة دون فجوات (الخطوة المتوقعة: ${i + 1})`);
      }
    }

    // 3. التحقق من صلاحية الأدوار (لا يجوز أن يكون المعتمد موظفًا عاديًا)
    const roleRank: Record<string, number> = {
      EMPLOYEE: 0,
      DEPT_MANAGER: 1,
      DEPUTY_GM: 2,
      GM: 3,
      ADMIN: 4,
    };

    for (let i = 0; i < sorted.length; i++) {
      const step = sorted[i];
      if (step.requiredRole === 'EMPLOYEE') {
        throw new Error('لا يمكن تعيين دور الموظف (EMPLOYEE) كمعتمد في مسار الاعتماد');
      }
      if (i > 0) {
        const prev = sorted[i - 1];
        if ((roleRank[step.requiredRole] ?? 0) < (roleRank[prev.requiredRole] ?? 0)) {
          throw new Error(
            `خطأ في التسلسل الهرمي: لا يجوز أن يكون دور المستوى ${step.level} (${step.requiredRole}) أدنى من المستوى ${prev.level} (${prev.requiredRole})`,
          );
        }
      }
    }

    return this.prisma.approvalWorkflowConfig.upsert({
      where: { priority },
      create: { priority, steps: sorted },
      update: { steps: sorted },
    });
  }
}
