import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import {
  AuditAction,
  CorrespondenceStatus,
  ReferralStatus,
  ReplyStatus,
  Role,
  TaskStatus,
} from '@prisma/client';
import { CorrespondencesService } from './correspondences.service';
import { ReferralsService } from '../referrals/referrals.service';
import { TasksService } from '../tasks/tasks.service';
import { AdminService } from '../admin/admin.service';
import type { AuthUser } from '../common/types';

describe('Active Children Validation & Orphan Prevention Specifications', () => {
  const adminUser: AuthUser = {
    id: 'user-admin',
    name: 'مسؤول النظام',
    email: 'admin@al-fadaa.com',
    role: Role.ADMIN,
  };

  const gmUser: AuthUser = {
    id: 'user-gm',
    name: 'المدير العام',
    email: 'gm@al-fadaa.com',
    role: Role.GM,
  };

  const deputyUser: AuthUser = {
    id: 'user-deputy',
    name: 'نائب المدير',
    email: 'deputy@al-fadaa.com',
    role: Role.DEPUTY_GM,
  };

  const employeeUser: AuthUser = {
    id: 'user-emp',
    name: 'أحمد المهندس',
    email: 'ahmed@al-fadaa.com',
    role: Role.EMPLOYEE,
  };

  describe('CorrespondencesService: فحص الكيانات التابعة عند الإغلاق والأرشفة', () => {
    let service: CorrespondencesService;
    let mockPrisma: any;
    let mockAudit: any;
    let mockNotifications: any;
    let mockRefNumbers: any;
    let mockOutbox: any;

    let inMemoryCorr: any;
    let inMemoryReferrals: any[];
    let inMemoryTasks: any[];
    let inMemoryReplies: any[];

    beforeEach(() => {
      inMemoryCorr = {
        id: 'corr-test-1',
        refNumber: 'INC-2026-00050',
        status: CorrespondenceStatus.RECEIVED,
        version: 1,
      };

      inMemoryReferrals = [];
      inMemoryTasks = [];
      inMemoryReplies = [];

      mockAudit = {
        log: jest.fn().mockResolvedValue(undefined),
      };
      mockNotifications = {
        notifyMany: jest.fn().mockResolvedValue(undefined),
      };
      mockRefNumbers = {
        generate: jest.fn().mockResolvedValue('INC-2026-00051'),
      };
      mockOutbox = {
        emit: jest.fn().mockResolvedValue({ id: 'outbox-1' }),
      };

      const mockTx = {
        referral: {
          findMany: jest.fn(async ({ where }) => {
            return inMemoryReferrals.filter((r) => {
              if (where.correspondenceId && r.correspondenceId !== where.correspondenceId) return false;
              if (where.status && r.status !== where.status) return false;
              return true;
            });
          }),
          updateMany: jest.fn(async ({ where, data }) => {
            let count = 0;
            for (const r of inMemoryReferrals) {
              if (where.correspondenceId && r.correspondenceId !== where.correspondenceId) continue;
              if (where.status && r.status !== where.status) continue;
              if (data.status) r.status = data.status;
              if (data.closedAt) r.closedAt = data.closedAt;
              count++;
            }
            return { count };
          }),
        },
        task: {
          findMany: jest.fn(async ({ where }) => {
            return inMemoryTasks.filter((t) => {
              if (where.correspondenceId && t.correspondenceId !== where.correspondenceId) return false;
              if (where.status?.in && !where.status.in.includes(t.status)) return false;
              return true;
            });
          }),
          updateMany: jest.fn(async ({ where, data }) => {
            let count = 0;
            for (const t of inMemoryTasks) {
              if (where.correspondenceId && t.correspondenceId !== where.correspondenceId) continue;
              if (where.status?.in && !where.status.in.includes(t.status)) continue;
              if (data.status) t.status = data.status;
              count++;
            }
            return { count };
          }),
        },
        reply: {
          findMany: jest.fn(async ({ where }) => {
            return inMemoryReplies.filter((rep) => {
              if (where.correspondenceId && rep.correspondenceId !== where.correspondenceId) return false;
              if (where.status?.in && !where.status.in.includes(rep.status)) return false;
              return true;
            });
          }),
        },
        correspondence: {
          updateMany: jest.fn(async ({ where, data }) => {
            if (where.id !== inMemoryCorr.id) return { count: 0 };
            if (where.status?.in && !where.status.in.includes(inMemoryCorr.status)) return { count: 0 };
            if (data.status) inMemoryCorr.status = data.status;
            if (data.closedAt) inMemoryCorr.closedAt = data.closedAt;
            if (data.version?.increment) inMemoryCorr.version += data.version.increment;
            return { count: 1 };
          }),
          findUnique: jest.fn(async () => inMemoryCorr),
          findUniqueOrThrow: jest.fn(async () => ({
            ...inMemoryCorr,
            attachments: [],
            referrals: inMemoryReferrals,
            tasks: inMemoryTasks,
            replies: inMemoryReplies,
            createdBy: adminUser,
          })),
        },
      };

      mockPrisma = {
        correspondence: {
          findUnique: jest.fn(async () => inMemoryCorr),
        },
        $transaction: jest.fn(async (cb: any) => cb(mockTx)),
      };

      service = new CorrespondencesService(
        mockPrisma,
        mockRefNumbers,
        mockAudit,
        mockNotifications,
        mockOutbox,
      );
    });

    it('يرفض إغلاق مراسلة إذا كانت تحوي إحالة مفتوحة (OPEN) ويذكر اسم المحال إليه بدقة', async () => {
      inMemoryReferrals.push({
        id: 'ref-1',
        correspondenceId: inMemoryCorr.id,
        status: ReferralStatus.OPEN,
        toUser: { name: 'نائب المدير' },
      });

      await expect(service.close(inMemoryCorr.id, gmUser)).rejects.toThrow(
        new BadRequestException('لا يمكن إغلاق المراسلة: توجد إحالة مفتوحة لدى نائب المدير'),
      );
    });

    it('يرفض إغلاق مراسلة إذا كانت تحوي تكليفاً قيد التنفيذ (IN_PROGRESS) ويذكر اسم المكلّف بدقة', async () => {
      inMemoryTasks.push({
        id: 'task-1',
        correspondenceId: inMemoryCorr.id,
        status: TaskStatus.IN_PROGRESS,
        assignedTo: { name: 'أحمد المهندس' },
      });

      await expect(service.close(inMemoryCorr.id, gmUser)).rejects.toThrow(
        new BadRequestException('لا يمكن إغلاق المراسلة: توجد تكليف جارٍ لدى أحمد المهندس'),
      );
    });

    it('يرفض إغلاق مراسلة إذا كانت تحوي مسودة رد (DRAFT أو SUBMITTED)', async () => {
      inMemoryReplies.push({
        id: 'reply-1',
        correspondenceId: inMemoryCorr.id,
        status: ReplyStatus.DRAFT,
      });

      await expect(service.close(inMemoryCorr.id, gmUser)).rejects.toThrow(
        new BadRequestException('لا يمكن إغلاق المراسلة: توجد مسودة رد قيد التحرير أو الاعتماد'),
      );
    });

    it('يرفض إغلاق مراسلة تحوي تركيبة مركبة (إحالة مفتوحة + تكليف جارٍ) ويسرد كافة الموانع معاً', async () => {
      inMemoryReferrals.push({
        id: 'ref-1',
        correspondenceId: inMemoryCorr.id,
        status: ReferralStatus.OPEN,
        toUser: { name: 'نائب المدير' },
      });
      inMemoryTasks.push({
        id: 'task-1',
        correspondenceId: inMemoryCorr.id,
        status: TaskStatus.PENDING,
        assignedTo: { name: 'أحمد المهندس' },
      });

      await expect(service.close(inMemoryCorr.id, gmUser)).rejects.toThrow(
        new BadRequestException(
          'لا يمكن إغلاق المراسلة: توجد إحالة مفتوحة لدى نائب المدير + تكليف جارٍ لدى أحمد المهندس',
        ),
      );
    });

    it('ينفذ الإغلاق النظيف بنجاح عند عدم وجود أعمال نشطة، ويغلق الإحالات التي كانت ANSWERED آلياً', async () => {
      inMemoryReferrals.push({
        id: 'ref-done-1',
        correspondenceId: inMemoryCorr.id,
        status: ReferralStatus.ANSWERED,
        toUser: { name: 'نائب المدير' },
      });

      const res = await service.close(inMemoryCorr.id, gmUser);
      expect(res.status).toBe(CorrespondenceStatus.CLOSED);
      expect(inMemoryCorr.status).toBe(CorrespondenceStatus.CLOSED);

      // تحويل الإحالة المكتملة إلى CLOSED رسمياً
      expect(inMemoryReferrals[0].status).toBe(ReferralStatus.CLOSED);
      expect(inMemoryReferrals[0].closedAt).toBeDefined();
    });

    it('يدعم الإغلاق القسري الصريح (force: true) ويقوم بإغلاق الإحالات وإلغاء التكليفات وتسجيل تدقيق مستقل لكل منها', async () => {
      inMemoryReferrals.push({
        id: 'ref-force-1',
        correspondenceId: inMemoryCorr.id,
        status: ReferralStatus.OPEN,
        toUser: { name: 'نائب المدير' },
      });
      inMemoryTasks.push({
        id: 'task-force-1',
        correspondenceId: inMemoryCorr.id,
        status: TaskStatus.IN_PROGRESS,
        assignedTo: { name: 'أحمد المهندس' },
      });

      const res = await service.close(inMemoryCorr.id, gmUser, { force: true });
      expect(res.status).toBe(CorrespondenceStatus.CLOSED);

      // التحقق من إغلاق الإحالة وإلغاء التكليف
      expect(inMemoryReferrals[0].status).toBe(ReferralStatus.CLOSED);
      expect(inMemoryTasks[0].status).toBe(TaskStatus.CANCELLED);

      // التحقق من تسجيل سجل تدقيق مستقل لكل كيان
      expect(mockAudit.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: AuditAction.CLOSE,
          entityType: 'Referral',
          entityId: 'ref-force-1',
        }),
      );
      expect(mockAudit.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: AuditAction.CLOSE,
          entityType: 'Task',
          entityId: 'task-force-1',
        }),
      );
    });

    it('يرفض أرشفة مراسلة تحوي إحالة مفتوحة أو تكليفاً جارياً', async () => {
      inMemoryCorr.status = CorrespondenceStatus.CLOSED; // قابلة للأرشفة
      inMemoryReferrals.push({
        id: 'ref-archive-1',
        correspondenceId: inMemoryCorr.id,
        status: ReferralStatus.OPEN,
        toUser: { name: 'نائب المدير' },
      });

      await expect(service.archive(inMemoryCorr.id, adminUser)).rejects.toThrow(
        new BadRequestException('لا يمكن أرشفة المراسلة: توجد إحالة مفتوحة لدى نائب المدير'),
      );
    });
  });

  describe('حماية الكيانات التابعة من تسليم عمل على مراسلة مغلقة/مؤرشفة', () => {
    it('يرفض إجابة إحالة إذا كانت المراسلة الأم مغلقة (CLOSED)', async () => {
      const mockPrismaReferrals: any = {
        referral: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'ref-closed-1',
            toUserId: deputyUser.id,
            status: ReferralStatus.OPEN,
            correspondence: {
              id: 'corr-c-1',
              status: CorrespondenceStatus.CLOSED,
            },
          }),
        },
      };

      const refService = new ReferralsService(
        mockPrismaReferrals,
        { log: jest.fn() } as any,
        { canView: jest.fn().mockResolvedValue(true) } as any,
        { notifyMany: jest.fn() } as any,
      );

      await expect(refService.answerReferral('ref-closed-1', deputyUser)).rejects.toThrow(
        new BadRequestException('المراسلة مغلقة — لا يمكن تسليم عمل عليها'),
      );
    });

    it('يرفض تسليم أو بدء تكليف إذا كانت المراسلة الأم مؤرشفة (ARCHIVED)', async () => {
      const mockPrismaTasks: any = {
        task: {
          findUnique: jest.fn().mockResolvedValue({
            id: 'task-archived-1',
            assignedToId: employeeUser.id,
            status: TaskStatus.PENDING,
            correspondence: {
              id: 'corr-a-1',
              status: CorrespondenceStatus.ARCHIVED,
            },
          }),
        },
      };

      const tasksService = new TasksService(
        mockPrismaTasks,
        { log: jest.fn() } as any,
        { notifyMany: jest.fn() } as any,
        { canView: jest.fn().mockResolvedValue(true) } as any,
      );

      await expect(
        tasksService.updateStatus('task-archived-1', { status: TaskStatus.IN_PROGRESS }, employeeUser),
      ).rejects.toThrow(new BadRequestException('المراسلة مغلقة — لا يمكن تسليم عمل عليها'));
    });
  });

  describe('نقطة تفتيش اليتامى للأدمن: AdminService.findOrphans', () => {
    it('تستخرج الكيانات اليتيمة بدقة (إحالات مفتوحة على مراسلات مغلقة، تكليفات معلقة، مسودات مهملة)', async () => {
      const mockPrismaAdmin: any = {
        referral: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'orphan-ref-1', status: ReferralStatus.OPEN, correspondence: { status: CorrespondenceStatus.CLOSED } },
          ]),
        },
        task: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'orphan-task-1', status: TaskStatus.IN_PROGRESS, correspondence: { status: CorrespondenceStatus.CLOSED } },
          ]),
        },
        reply: {
          findMany: jest.fn().mockResolvedValue([
            { id: 'orphan-reply-1', status: ReplyStatus.DRAFT, correspondence: { status: CorrespondenceStatus.ARCHIVED } },
          ]),
        },
      };

      const adminService = new AdminService(mockPrismaAdmin);
      const res = await adminService.findOrphans();

      expect(res.summary.totalOrphans).toBe(3);
      expect(res.summary.openReferralsCount).toBe(1);
      expect(res.summary.pendingTasksCount).toBe(1);
      expect(res.summary.draftRepliesCount).toBe(1);
      expect(res.orphanReferrals.length).toBe(1);
      expect(res.orphanTasks.length).toBe(1);
      expect(res.orphanReplies.length).toBe(1);
    });
  });
});
