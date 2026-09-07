import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import {
  NotificationType,
  ReferralStatus,
  Role,
  SlaReminderType,
  TaskStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DepartmentOverdueEscalation, SlaItemSummary } from './sla.types';

@Injectable()
export class SlaService {
  private readonly logger = new Logger('SlaService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  /**
   * الفحص الدوري كل ساعة لاقتراب المواعيد النهائية وحالات التأخير
   */
  @Cron(CronExpression.EVERY_HOUR)
  async runHourlyChecks(): Promise<void> {
    const now = new Date();
    this.logger.log(`[SLA Engine] بدء الفحص الدوري للساعة: ${now.toISOString()}`);
    try {
      await this.checkApproachingDeadlines(now);
      await this.checkOverdueItems(now);
    } catch (err) {
      this.logger.error(`[SLA Engine] خطأ في الفحص الدوري: ${(err as Error).message}`);
    }
  }

  /**
   * التصعيد الأسبوعي المجمّع للمدير العام (افتراضياً كل أسبوع صباح الأحد)
   */
  @Cron(process.env.ESCALATION_CRON || CronExpression.EVERY_WEEK)
  async runWeeklyEscalation(): Promise<void> {
    const now = new Date();
    this.logger.log(`[SLA Engine] بدء التصعيد الأسبوعي المجمّع للمدير العام: ${now.toISOString()}`);
    try {
      await this.escalateOverdueToGM(now);
    } catch (err) {
      this.logger.error(`[SLA Engine] خطأ في التصعيد الأسبوعي: ${(err as Error).message}`);
    }
  }

  /**
   * 1. التذكير باقتراب موعد الاستحقاق (خلال 24 ساعة افتراضياً)
   * إشعار لطيف للمكلف أو المحال إليه
   */
  async checkApproachingDeadlines(now = new Date()): Promise<number> {
    const hoursBefore = Number(this.config.get('REMINDER_HOURS_BEFORE') ?? 24);
    const windowEnd = new Date(now.getTime() + hoursBefore * 60 * 60 * 1000);

    let remindersSent = 0;

    // أ. إحالات تقترب مهلتها
    const approachingReferrals = await this.prisma.referral.findMany({
      where: {
        status: ReferralStatus.OPEN,
        dueDate: {
          gt: now,
          lte: windowEnd,
        },
      },
      include: {
        toUser: true,
        correspondence: { select: { id: true, refNumber: true, subject: true } },
      },
    });

    for (const ref of approachingReferrals) {
      const alreadySent = await this.prisma.slaState.findUnique({
        where: {
          entityType_entityId_lastReminderType: {
            entityType: 'Referral',
            entityId: ref.id,
            lastReminderType: SlaReminderType.APPROACHING,
          },
        },
      });

      if (!alreadySent) {
        await this.notifications.notifyMany([ref.toUserId], {
          type: NotificationType.NEW_REFERRAL,
          title: `تذكير: اقتراب موعد إنجاز إحالة (${ref.correspondence.refNumber})`,
          body: `الموعد النهائي للإحالة الخاصة بالمراسلة «${ref.correspondence.subject}» ينتهي خلال ${hoursBefore} ساعة.`,
          link: `/correspondences/${ref.correspondence.id}`,
          entityType: 'Referral',
          entityId: ref.id,
        });

        await this.prisma.slaState.create({
          data: {
            entityType: 'Referral',
            entityId: ref.id,
            lastReminderType: SlaReminderType.APPROACHING,
            lastSentAt: now,
          },
        });
        remindersSent++;
      }
    }

    // ب. تكليفات تقترب مهلتها
    const approachingTasks = await this.prisma.task.findMany({
      where: {
        status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
        dueDate: {
          gt: now,
          lte: windowEnd,
        },
      },
      include: {
        assignedTo: true,
        correspondence: { select: { id: true, refNumber: true, subject: true } },
      },
    });

    for (const task of approachingTasks) {
      const alreadySent = await this.prisma.slaState.findUnique({
        where: {
          entityType_entityId_lastReminderType: {
            entityType: 'Task',
            entityId: task.id,
            lastReminderType: SlaReminderType.APPROACHING,
          },
        },
      });

      if (!alreadySent) {
        await this.notifications.notifyMany([task.assignedToId], {
          type: NotificationType.NEW_TASK,
          title: `تذكير: اقتراب موعد استحقاق التكليف (${task.title})`,
          body: `يتبقى أقل من ${hoursBefore} ساعة على موعد تسليم العمل على المراسلة «${task.correspondence.refNumber}».`,
          link: `/correspondences/${task.correspondence.id}`,
          entityType: 'Task',
          entityId: task.id,
        });

        await this.prisma.slaState.create({
          data: {
            entityType: 'Task',
            entityId: task.id,
            lastReminderType: SlaReminderType.APPROACHING,
            lastSentAt: now,
          },
        });
        remindersSent++;
      }
    }

    return remindersSent;
  }

  /**
   * 2. تنبيه عند التأخير (dueDate < now)
   * إشعار حازم للمكلف والمشرف
   */
  async checkOverdueItems(now = new Date()): Promise<number> {
    let overdueAlertsSent = 0;

    // أ. إحالات متأخرة
    const overdueReferrals = await this.prisma.referral.findMany({
      where: {
        status: ReferralStatus.OPEN,
        dueDate: {
          lt: now,
        },
      },
      include: {
        toUser: true,
        fromUser: true,
        correspondence: { select: { id: true, refNumber: true, subject: true } },
      },
    });

    for (const ref of overdueReferrals) {
      const alreadySent = await this.prisma.slaState.findUnique({
        where: {
          entityType_entityId_lastReminderType: {
            entityType: 'Referral',
            entityId: ref.id,
            lastReminderType: SlaReminderType.OVERDUE,
          },
        },
      });

      if (!alreadySent) {
        const recipients = [ref.toUserId];
        if (ref.fromUserId && ref.fromUserId !== ref.toUserId) {
          recipients.push(ref.fromUserId);
        }

        await this.notifications.notifyMany(recipients, {
          type: NotificationType.NEW_REFERRAL,
          title: `تنبيه تأخير: تجاوز الموعد النهائي للإحالة (${ref.correspondence.refNumber})`,
          body: `تأخرت الإحالة المسندة إلى «${ref.toUser?.name}» على المراسلة «${ref.correspondence.subject}». يرجى سرعة الإنجاز.`,
          link: `/correspondences/${ref.correspondence.id}`,
          entityType: 'Referral',
          entityId: ref.id,
        });

        await this.prisma.slaState.create({
          data: {
            entityType: 'Referral',
            entityId: ref.id,
            lastReminderType: SlaReminderType.OVERDUE,
            lastSentAt: now,
          },
        });
        overdueAlertsSent++;
      }
    }

    // ب. تكليفات متأخرة
    const overdueTasks = await this.prisma.task.findMany({
      where: {
        status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
        dueDate: {
          lt: now,
        },
      },
      include: {
        assignedTo: true,
        assignedBy: true,
        correspondence: { select: { id: true, refNumber: true, subject: true } },
      },
    });

    for (const task of overdueTasks) {
      const alreadySent = await this.prisma.slaState.findUnique({
        where: {
          entityType_entityId_lastReminderType: {
            entityType: 'Task',
            entityId: task.id,
            lastReminderType: SlaReminderType.OVERDUE,
          },
        },
      });

      if (!alreadySent) {
        const recipients = [task.assignedToId];
        if (task.assignedById && task.assignedById !== task.assignedToId) {
          recipients.push(task.assignedById);
        }

        await this.notifications.notifyMany(recipients, {
          type: NotificationType.NEW_TASK,
          title: `تنبيه تأخير: تجاوز الموعد المحدد للتكليف (${task.title})`,
          body: `التكليف «${task.title}» المسند للموظف «${task.assignedTo?.name}» متأخر عن موعد تسليمه.`,
          link: `/correspondences/${task.correspondence.id}`,
          entityType: 'Task',
          entityId: task.id,
        });

        await this.prisma.slaState.create({
          data: {
            entityType: 'Task',
            entityId: task.id,
            lastReminderType: SlaReminderType.OVERDUE,
            lastSentAt: now,
          },
        });
        overdueAlertsSent++;
      }
    }

    return overdueAlertsSent;
  }

  /**
   * 3. التصعيد الأسبوعي للمدير العام:
   * تجميع كافة المتأخرات حسب الأقسام وإرسال إشعار مجمّع واحد لكل قسم
   */
  async escalateOverdueToGM(now = new Date()): Promise<number> {
    const gmUsers = await this.prisma.user.findMany({
      where: { role: Role.GM, isActive: true },
      select: { id: true },
    });
    if (gmUsers.length === 0) return 0;
    const gmUserIds = gmUsers.map((u) => u.id);

    // جمع كافة التكليفات المتأخرة
    const overdueTasks = await this.prisma.task.findMany({
      where: {
        status: { in: [TaskStatus.PENDING, TaskStatus.IN_PROGRESS] },
        dueDate: { lt: now },
      },
      include: {
        assignedTo: { select: { id: true, name: true, departmentId: true, department: { select: { id: true, name: true } } } },
        correspondence: { select: { id: true, refNumber: true, departmentId: true, department: { select: { id: true, name: true } } } },
      },
    });

    // جمع كافة الإحالات المتأخرة
    const overdueReferrals = await this.prisma.referral.findMany({
      where: {
        status: ReferralStatus.OPEN,
        dueDate: { lt: now },
      },
      include: {
        toUser: { select: { id: true, name: true, departmentId: true, department: { select: { id: true, name: true } } } },
        correspondence: { select: { id: true, refNumber: true, departmentId: true, department: { select: { id: true, name: true } } } },
      },
    });

    // تجميع حسب القسم
    const departmentMap = new Map<string, DepartmentOverdueEscalation>();

    const getOrCreateDept = (id: string, name: string) => {
      if (!departmentMap.has(id)) {
        departmentMap.set(id, {
          departmentId: id,
          departmentName: name,
          count: 0,
          maxDaysOverdue: 0,
          items: [],
        });
      }
      return departmentMap.get(id)!;
    };

    for (const task of overdueTasks) {
      if (!task.dueDate) continue;
      const deptId = task.assignedTo?.departmentId || task.correspondence?.departmentId || 'general';
      const deptName = task.assignedTo?.department?.name || task.correspondence?.department?.name || 'الإدارة العامة';
      const dept = getOrCreateDept(deptId, deptName);

      const daysOverdue = Math.max(1, Math.ceil((now.getTime() - task.dueDate.getTime()) / (1000 * 60 * 60 * 24)));
      dept.count++;
      if (daysOverdue > dept.maxDaysOverdue) {
        dept.maxDaysOverdue = daysOverdue;
      }
      dept.items.push({
        entityType: 'Task',
        entityId: task.id,
        correspondenceId: task.correspondence.id,
        correspondenceRef: task.correspondence.refNumber,
        title: task.title,
        assignedUserId: task.assignedTo.id,
        assignedUserName: task.assignedTo.name,
        departmentId: deptId,
        departmentName: deptName,
        dueDate: task.dueDate,
        daysOverdue,
      });
    }

    for (const ref of overdueReferrals) {
      if (!ref.dueDate) continue;
      const deptId = ref.toUser?.departmentId || ref.correspondence?.departmentId || 'general';
      const deptName = ref.toUser?.department?.name || ref.correspondence?.department?.name || 'الإدارة العامة';
      const dept = getOrCreateDept(deptId, deptName);

      const daysOverdue = Math.max(1, Math.ceil((now.getTime() - ref.dueDate.getTime()) / (1000 * 60 * 60 * 24)));
      dept.count++;
      if (daysOverdue > dept.maxDaysOverdue) {
        dept.maxDaysOverdue = daysOverdue;
      }
      dept.items.push({
        entityType: 'Referral',
        entityId: ref.id,
        correspondenceId: ref.correspondence.id,
        correspondenceRef: ref.correspondence.refNumber,
        title: `إحالة ${ref.correspondence.refNumber}`,
        assignedUserId: ref.toUser.id,
        assignedUserName: ref.toUser.name,
        departmentId: deptId,
        departmentName: deptName,
        dueDate: ref.dueDate,
        daysOverdue,
      });
    }

    let escalationsSent = 0;

    // إرسال إشعار مجمّع واحد لكل قسم للمدير العام
    for (const [deptId, deptData] of departmentMap.entries()) {
      if (deptData.count > 0) {
        await this.notifications.notifyMany(gmUserIds, {
          type: NotificationType.NEW_TASK,
          title: `تقرير تصعيد أسبوعي: ${deptData.count} مهام متأخرة في قسم «${deptData.departmentName}»`,
          body: `يوجد ${deptData.count} تكليف وإحالة متأخرة في ${deptData.departmentName}، أقدمها متأخر بـ${deptData.maxDaysOverdue} يومًا.`,
          link: `/admin/sla-overview`,
          entityType: 'Department',
          entityId: deptId,
        });

        // تسجيل التصعيد في SlaState لكافة العناصر المشمولة
        for (const item of deptData.items) {
          await this.prisma.slaState.upsert({
            where: {
              entityType_entityId_lastReminderType: {
                entityType: item.entityType,
                entityId: item.entityId,
                lastReminderType: SlaReminderType.ESCALATED,
              },
            },
            create: {
              entityType: item.entityType,
              entityId: item.entityId,
              lastReminderType: SlaReminderType.ESCALATED,
              lastSentAt: now,
            },
            update: {
              lastSentAt: now,
            },
          });
        }

        escalationsSent++;
      }
    }

    return escalationsSent;
  }
}
