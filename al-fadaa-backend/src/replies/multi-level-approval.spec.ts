import { Test, TestingModule } from '@nestjs/testing';
import {
  ApprovalStepStatus,
  CorrespondenceStatus,
  NotificationType,
  Priority,
  ReplyStatus,
  Role,
} from '@prisma/client';
import { RepliesApprovalService } from './replies-approval.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { AuthUser } from '../common/types';

describe('نظام مسارات الاعتماد متعدد المستويات (Multi-Level Approval Workflows)', () => {
  let service: RepliesApprovalService;

  const mockPrisma: any = {
    reply: {
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    correspondence: {
      update: jest.fn(),
    },
    task: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    referral: {
      findMany: jest.fn(),
      updateMany: jest.fn(),
    },
    user: {
      findMany: jest.fn(),
    },
    department: {
      findUnique: jest.fn(),
    },
    approvalStep: {
      create: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    },
    approvalWorkflowConfig: {
      findUnique: jest.fn(),
    },
    replyVersion: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    delegation: {
      findMany: jest.fn(),
    },
    $transaction: jest.fn(async (cb) => {
      if (typeof cb === 'function') {
        return cb(mockPrisma);
      }
      return cb;
    }),
  };

  const mockAudit = {
    log: jest.fn().mockResolvedValue(undefined),
  };

  const mockNotifications = {
    notify: jest.fn().mockResolvedValue(undefined),
    notifyMany: jest.fn().mockResolvedValue(undefined),
    notifyReplySubmitted: jest.fn().mockResolvedValue(undefined),
    notifyReplyApproved: jest.fn().mockResolvedValue(undefined),
    notifyReplyRejected: jest.fn().mockResolvedValue(undefined),
  };

  const authorUser: AuthUser = {
    id: 'emp-1',
    name: 'أحمد الموظف',
    email: 'emp@al-fadaa.com',
    role: Role.EMPLOYEE,
  };

  const deptManagerUser: AuthUser = {
    id: 'mgr-1',
    name: 'سالم مدير القسم',
    email: 'mgr@al-fadaa.com',
    role: Role.DEPT_MANAGER,
    departmentId: 'dept-1',
  };

  const deputyUser: AuthUser = {
    id: 'deputy-1',
    name: 'نائب المدير العام',
    email: 'deputy@al-fadaa.com',
    role: Role.DEPUTY_GM,
  };

  const gmUser: AuthUser = {
    id: 'gm-1',
    name: 'المدير العام',
    email: 'gm@al-fadaa.com',
    role: Role.GM,
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RepliesApprovalService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAudit },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<RepliesApprovalService>(RepliesApprovalService);
  });

  describe('سيناريو الاعتماد الثلاثي (URGENT) مع الرفض في المستوى الثاني ثم الاكتمال', () => {
    const baseReply = {
      id: 'reply-1',
      authorId: authorUser.id,
      body: 'نص المسودة الأولي المقترح',
      status: ReplyStatus.DRAFT,
      version: 1,
      correspondenceId: 'corr-1',
      correspondence: {
        id: 'corr-1',
        refNumber: 'INC-2026-00001',
        subject: 'معاملة عاجلة جداً',
        priority: Priority.URGENT,
        status: CorrespondenceStatus.IN_PROGRESS,
        departmentId: 'dept-1',
      },
      author: authorUser,
      approvalSteps: [],
      attachments: [],
    };

    it('1. رفع المسودة (submit) ينشئ خطوات المسار الثلاثة المتتابعة ويشعر المستوى الأول فقط', async () => {
      mockPrisma.reply.findUnique.mockResolvedValue(baseReply);
      mockPrisma.reply.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.reply.findUniqueOrThrow.mockResolvedValue({
        ...baseReply,
        status: ReplyStatus.SUBMITTED,
      });
      mockPrisma.task.findUnique.mockResolvedValue(null);
      mockPrisma.referral.findMany.mockResolvedValue([]);
      mockPrisma.department.findUnique.mockResolvedValue({ managerId: deptManagerUser.id });

      const res = await service.submit('reply-1', authorUser);

      expect(res.status).toBe(ReplyStatus.SUBMITTED);
      // التحقق من إنشاء المستويات الثلاثة
      expect(mockPrisma.approvalStep.create).toHaveBeenCalledTimes(3);
      expect(mockPrisma.approvalStep.create).toHaveBeenNthCalledWith(1, {
        data: expect.objectContaining({ level: 1, requiredRole: Role.DEPT_MANAGER }),
      });
      expect(mockPrisma.approvalStep.create).toHaveBeenNthCalledWith(2, {
        data: expect.objectContaining({ level: 2, requiredRole: Role.DEPUTY_GM }),
      });
      expect(mockPrisma.approvalStep.create).toHaveBeenNthCalledWith(3, {
        data: expect.objectContaining({ level: 3, requiredRole: Role.GM }),
      });

      // التحقق من إشعار المستوى الأول فقط
      expect(mockNotifications.notifyReplySubmitted).toHaveBeenCalledWith(
        expect.objectContaining({
          recipientIds: [deptManagerUser.id],
        }),
      );
    });

    it('2. اعتماد المستوى الأول (DEPT_MANAGER) ينشط المستوى الثاني وتبقى المراسلة PENDING_APPROVAL', async () => {
      const submittedReply = {
        ...baseReply,
        status: ReplyStatus.SUBMITTED,
      };
      mockPrisma.reply.findUnique.mockResolvedValue(submittedReply);
      mockPrisma.approvalStep.findMany.mockResolvedValue([
        { id: 'step-1', level: 1, requiredRole: Role.DEPT_MANAGER, status: ApprovalStepStatus.PENDING },
        { id: 'step-2', level: 2, requiredRole: Role.DEPUTY_GM, status: ApprovalStepStatus.PENDING },
        { id: 'step-3', level: 3, requiredRole: Role.GM, status: ApprovalStepStatus.PENDING },
      ]);
      mockPrisma.referral.findMany.mockResolvedValue([]);
      mockPrisma.user.findMany.mockResolvedValue([{ id: deputyUser.id }]);
      mockPrisma.reply.findUniqueOrThrow.mockResolvedValue(submittedReply);

      const res = await service.approve('reply-1', deptManagerUser);

      expect(mockPrisma.approvalStep.update).toHaveBeenCalledWith({
        where: { id: 'step-1' },
        data: expect.objectContaining({
          status: ApprovalStepStatus.APPROVED,
          approverId: deptManagerUser.id,
        }),
      });

      // الرد ما زال SUBMITTED لأن هناك مستويات لاحقة
      expect(res.status).toBe(ReplyStatus.SUBMITTED);
      // إشعار المستوى الثاني (النائب)
      expect(mockNotifications.notifyMany).toHaveBeenCalledWith(
        [deputyUser.id],
        expect.objectContaining({
          title: expect.stringContaining('المستوى 2'),
        }),
      );
    });

    it('3. رفض المستوى الثاني (DEPUTY_GM) يعيد الرد REJECTED للكاتب ويصفي الخطوات اللاحقة ويشعر المعتمد السابق', async () => {
      const submittedReply = {
        ...baseReply,
        status: ReplyStatus.SUBMITTED,
        correspondence: {
          ...baseReply.correspondence,
          status: CorrespondenceStatus.PENDING_APPROVAL,
        },
      };
      mockPrisma.reply.findUnique.mockResolvedValue(submittedReply);
      mockPrisma.approvalStep.findMany.mockResolvedValue([
        { id: 'step-1', level: 1, requiredRole: Role.DEPT_MANAGER, status: ApprovalStepStatus.APPROVED, approverId: deptManagerUser.id },
        { id: 'step-2', level: 2, requiredRole: Role.DEPUTY_GM, status: ApprovalStepStatus.PENDING },
        { id: 'step-3', level: 3, requiredRole: Role.GM, status: ApprovalStepStatus.PENDING },
      ]);
      mockPrisma.referral.findMany.mockResolvedValue([]);
      mockPrisma.reply.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.reply.findUniqueOrThrow.mockResolvedValue({
        ...submittedReply,
        status: ReplyStatus.REJECTED,
      });

      const res = await service.reject('reply-1', { note: 'يرجى تدقيق البند المالي' }, deputyUser);

      expect(res.status).toBe(ReplyStatus.REJECTED);
      // تحديث الخطوة إلى REJECTED
      expect(mockPrisma.approvalStep.update).toHaveBeenCalledWith({
        where: { id: 'step-2' },
        data: expect.objectContaining({
          status: ApprovalStepStatus.REJECTED,
          note: 'يرجى تدقيق البند المالي',
        }),
      });
      // حذف الخطوات الأعلى
      expect(mockPrisma.approvalStep.deleteMany).toHaveBeenCalledWith({
        where: { replyId: 'reply-1', level: { gt: 2 } },
      });
      // إشعار الموظف بالرفض
      expect(mockNotifications.notifyReplyRejected).toHaveBeenCalledWith(
        expect.objectContaining({
          toUserId: authorUser.id,
          note: 'يرجى تدقيق البند المالي',
        }),
      );
      // إشعار معتمد المستوى الأول السابق
      expect(mockNotifications.notify).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: deptManagerUser.id,
          title: expect.stringContaining('تم رفض الرد في المستوى 2'),
        }),
      );
    });

    it('4. بعد الرفع مجدداً واعتماد المستويات الثلاثة كاملة يصبح الرد APPROVED وتكتمل المعاملة', async () => {
      const submittedReply = {
        ...baseReply,
        status: ReplyStatus.SUBMITTED,
        correspondence: {
          ...baseReply.correspondence,
          status: CorrespondenceStatus.PENDING_APPROVAL,
        },
      };
      mockPrisma.reply.findUnique.mockResolvedValue(submittedReply);
      // نفترض أن المستوى 1 و 2 معتمدان، والآن اعتماد المستوى الثالث والأخير
      mockPrisma.approvalStep.findMany.mockResolvedValue([
        { id: 'step-1', level: 1, requiredRole: Role.DEPT_MANAGER, status: ApprovalStepStatus.APPROVED, approverId: deptManagerUser.id },
        { id: 'step-2', level: 2, requiredRole: Role.DEPUTY_GM, status: ApprovalStepStatus.APPROVED, approverId: deputyUser.id },
        { id: 'step-3', level: 3, requiredRole: Role.GM, status: ApprovalStepStatus.PENDING },
      ]);
      mockPrisma.referral.findMany.mockResolvedValue([]);
      mockPrisma.reply.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.reply.findUniqueOrThrow.mockResolvedValue({
        ...submittedReply,
        status: ReplyStatus.APPROVED,
        approvedById: gmUser.id,
      });

      const res = await service.approve('reply-1', gmUser);

      // اعتماد نهائي بعد اكتمال آخر مستوى
      expect(mockPrisma.approvalStep.update).toHaveBeenCalledWith({
        where: { id: 'step-3' },
        data: expect.objectContaining({
          status: ApprovalStepStatus.APPROVED,
          approverId: gmUser.id,
        }),
      });
      expect(res.status).toBe(ReplyStatus.APPROVED);
      expect(mockPrisma.correspondence.update).toHaveBeenCalledWith({
        where: { id: 'corr-1' },
        data: expect.objectContaining({ status: CorrespondenceStatus.APPROVED }),
      });
      expect(mockNotifications.notifyReplyApproved).toHaveBeenCalledWith(
        expect.objectContaining({
          toUserId: authorUser.id,
          approverName: gmUser.name,
        }),
      );
    });
  });
});
