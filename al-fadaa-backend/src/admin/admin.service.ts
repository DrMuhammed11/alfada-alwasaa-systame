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
}
