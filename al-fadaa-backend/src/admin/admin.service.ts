import { Injectable, Optional } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import {
  CorrespondenceStatus,
  CorrespondenceType,
  OutboxMailStatus,
  Priority,
  ReferralStatus,
  ReplyStatus,
  TaskStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { MailRetryService } from '../mail/mail-retry.service';
import { AdminAnalyticsQueryDto } from './dto/admin-analytics-query.dto';
import { parseDateEnd, parseDateStart } from '../common/utils/dates';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly mailRetry?: MailRetryService,
  ) {}

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

  /**
   * حالة النسخ الاحتياطي: الإعداد، أمر الرفع الخارجي، وقائمة النسخ الموجودة محليًا
   * (الاسم، الحجم، آخر تعديل) — الأحدث أولًا.
   */
  getBackupStatus() {
    const enabled = process.env.BACKUP_ENABLED === 'true';
    const dir = process.env.BACKUP_DIR || './backups';
    const retentionDays = Number(process.env.BACKUP_RETENTION_DAYS) || 7;
    const uploadCommand = process.env.BACKUP_UPLOAD_COMMAND || '';

    const files: { name: string; sizeBytes: number; modifiedAt: string }[] = [];
    try {
      if (fs.existsSync(dir)) {
        for (const name of fs.readdirSync(dir)) {
          if (!name.endsWith('.sql.gz')) continue;
          const stat = fs.statSync(path.join(dir, name));
          files.push({
            name,
            sizeBytes: stat.size,
            modifiedAt: stat.mtime.toISOString(),
          });
        }
      }
    } catch {
      // مجلد غير مقروء — تُعاد قائمة فارغة
    }
    files.sort((a, b) => b.modifiedAt.localeCompare(a.modifiedAt));

    return {
      enabled,
      directory: dir,
      retentionDays,
      offsiteConfigured: uploadCommand.trim().length > 0,
      files: files.slice(0, 30),
      totalFiles: files.length,
    };
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

  /** استعراض رسائل الصادر وحالات المحاولات */
  async getOutboxList(filter: {
    status?: OutboxMailStatus;
    refNumber?: string;
    page?: number;
    limit?: number;
  }) {
    if (this.mailRetry) {
      return this.mailRetry.getOutboxList(filter);
    }
    return { items: [], total: 0, page: 1, limit: 20, totalPages: 0 };
  }

  /** إعادة محاولة إرسال رسالة صادر يدويًا */
  async retryOutboxMail(id: string) {
    if (!this.mailRetry) throw new Error('خدمة استرداد البريد غير مهيأة');
    return this.mailRetry.retryManually(id);
  }

  /**
   * إعادة جدولة كل رسائل الصادر الفاشلة نهائيًا — تُستدعى من زر
   * «إعادة إرسال البريد المعلق» في لوحة الإدارة.
   */
  async resendFailedMails() {
    if (!this.mailRetry || !this.prisma) {
      throw new Error('خدمة استرداد البريد غير مهيأة');
    }
    const failed = await this.prisma.outboxMail.findMany({
      where: { status: OutboxMailStatus.FAILED },
      select: { id: true },
    });
    for (const mail of failed) {
      await this.mailRetry.retryManually(mail.id);
    }
    return {
      success: true,
      requeued: failed.length,
      message:
        failed.length > 0
          ? `أُعيدت جدولة ${failed.length} رسالة فاشلة لإعادة الإرسال`
          : 'لا توجد رسائل فاشلة لإعادة الإرسال',
    };
  }

  /** إيقاف إعادة المحاولة مؤقتًا */
  async pauseOutboxMail(id: string) {
    if (!this.mailRetry) throw new Error('خدمة استرداد البريد غير مهيأة');
    return this.mailRetry.pauseMail(id);
  }

  /** استخراج مؤشرات الأداء والإحصائيات التحليلية للوحة الإدارة */
  async getAnalytics(dto: AdminAnalyticsQueryDto) {
    const now = new Date();
    let startDate: Date | undefined;
    let endDate: Date | undefined;

    if (dto.from) {
      startDate = parseDateStart(dto.from);
    } else if (dto.period && dto.period !== 'all') {
      const days = dto.period === '7d' ? 7 : dto.period === '90d' ? 90 : dto.period === 'year' ? 365 : 30;
      startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    }

    if (dto.to) {
      endDate = parseDateEnd(dto.to);
    }

    const dateFilter: Prisma.DateTimeFilter | undefined =
      startDate || endDate
        ? {
            ...(startDate ? { gte: startDate } : {}),
            ...(endDate ? { lte: endDate } : {}),
          }
        : undefined;

    const baseWhere: Prisma.CorrespondenceWhereInput = {
      parentId: null,
      ...(dateFilter ? { createdAt: dateFilter } : {}),
      ...(dto.departmentId ? { departmentId: dto.departmentId } : {}),
    };

    // 1. التلخيص العام للمراسلات والأولويات
    const [
      total,
      incoming,
      outgoing,
      internal,
      closed,
      archived,
      urgentCount,
      highCount,
      normalCount,
      lowCount,
      allCorrespondences,
      departments,
    ] = await Promise.all([
      this.prisma.correspondence.count({ where: baseWhere }),
      this.prisma.correspondence.count({ where: { ...baseWhere, type: CorrespondenceType.INCOMING } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, type: CorrespondenceType.OUTGOING } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, type: CorrespondenceType.INTERNAL } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, status: CorrespondenceStatus.CLOSED } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, status: CorrespondenceStatus.ARCHIVED } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, priority: Priority.URGENT } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, priority: Priority.HIGH } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, priority: Priority.NORMAL } }),
      this.prisma.correspondence.count({ where: { ...baseWhere, priority: Priority.LOW } }),
      this.prisma.correspondence.findMany({
        where: baseWhere,
        select: {
          id: true,
          createdAt: true,
          type: true,
          status: true,
          departmentId: true,
        },
      }),
      this.prisma.department.findMany({
        select: { id: true, name: true, code: true },
      }),
    ]);

    // 2. تحليل المهام ومؤشرات الالتزام بالـ SLA
    const taskWhere: Prisma.TaskWhereInput = {
      ...(dateFilter ? { createdAt: dateFilter } : {}),
      ...(dto.departmentId ? { correspondence: { departmentId: dto.departmentId } } : {}),
    };

    const tasks = await this.prisma.task.findMany({
      where: taskWhere,
      select: {
        id: true,
        status: true,
        dueDate: true,
        doneAt: true,
        correspondence: { select: { departmentId: true } },
      },
    });

    let onTimeTasks = 0;
    let overdueTasks = 0;
    let pendingTasks = 0;

    for (const t of tasks) {
      if (t.status === TaskStatus.DONE) {
        if (t.dueDate && t.doneAt && t.doneAt > t.dueDate) {
          overdueTasks++;
        } else {
          onTimeTasks++;
        }
      } else if (t.status === TaskStatus.PENDING || t.status === TaskStatus.IN_PROGRESS) {
        pendingTasks++;
        if (t.dueDate && t.dueDate < now) {
          overdueTasks++;
        }
      }
    }

    const evaluatedTasks = onTimeTasks + overdueTasks;
    const slaComplianceRate =
      evaluatedTasks > 0
        ? Math.round((onTimeTasks / evaluatedTasks) * 1000) / 10
        : 100.0;

    // 3. أداء الأقسام
    const deptMap: Record<
      string,
      {
        id: string;
        name: string;
        code: string;
        correspondences: number;
        tasksTotal: number;
        tasksCompleted: number;
        tasksPending: number;
      }
    > = {};

    for (const d of departments) {
      deptMap[d.id] = {
        id: d.id,
        name: d.name,
        code: d.code,
        correspondences: 0,
        tasksTotal: 0,
        tasksCompleted: 0,
        tasksPending: 0,
      };
    }

    for (const c of allCorrespondences) {
      if (c.departmentId && deptMap[c.departmentId]) {
        deptMap[c.departmentId].correspondences++;
      }
    }

    for (const t of tasks) {
      const depId = t.correspondence?.departmentId;
      if (depId && deptMap[depId]) {
        deptMap[depId].tasksTotal++;
        if (t.status === TaskStatus.DONE) {
          deptMap[depId].tasksCompleted++;
        } else {
          deptMap[depId].tasksPending++;
        }
      }
    }

    const departmentPerformance = Object.values(deptMap).map((item) => ({
      ...item,
      complianceRate:
        item.tasksTotal > 0
          ? Math.round((item.tasksCompleted / item.tasksTotal) * 1000) / 10
          : 100.0,
    }));

    // 4. السلسلة الزمنية للرسم البياني
    const trendMap: Record<string, { date: string; incoming: number; outgoing: number; closed: number }> = {};
    for (const c of allCorrespondences) {
      const dateKey = c.createdAt.toISOString().slice(0, 10);
      if (!trendMap[dateKey]) {
        trendMap[dateKey] = { date: dateKey, incoming: 0, outgoing: 0, closed: 0 };
      }
      if (c.type === CorrespondenceType.INCOMING) trendMap[dateKey].incoming++;
      if (c.type === CorrespondenceType.OUTGOING) trendMap[dateKey].outgoing++;
      if (c.status === CorrespondenceStatus.CLOSED) trendMap[dateKey].closed++;
    }

    const trend = Object.values(trendMap).sort((a, b) => a.date.localeCompare(b.date));

    return {
      period: dto.period ?? '30d',
      summary: {
        total,
        incoming,
        outgoing,
        internal,
        closed,
        archived,
        active: total - (closed + archived),
      },
      sla: {
        totalTasks: tasks.length,
        onTimeTasks,
        overdueTasks,
        pendingTasks,
        complianceRate: slaComplianceRate,
      },
      priorities: {
        urgent: urgentCount,
        high: highCount,
        normal: normalCount,
        low: lowCount,
      },
      departmentPerformance,
      trend,
    };
  }
}

