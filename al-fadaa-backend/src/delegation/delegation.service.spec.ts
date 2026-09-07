import { Test, TestingModule } from '@nestjs/testing';
import { Role } from '@prisma/client';
import { BadRequestException } from '@nestjs/common';
import { DelegationService } from './delegation.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { AuthUser } from '../common/types';

describe('خدمة التفويض والوكالة التشغيلية (DelegationService)', () => {
  let service: DelegationService;

  const mockPrisma: any = {
    user: {
      findUnique: jest.fn(),
    },
    delegation: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      count: jest.fn(),
    },
    reply: {
      count: jest.fn(),
    },
  };

  const mockAudit = {
    log: jest.fn().mockResolvedValue(undefined),
  };

  const mockNotifications = {
    notify: jest.fn().mockResolvedValue(undefined),
  };

  const deputyUser: AuthUser = {
    id: 'deputy-1',
    name: 'نائب المدير العام',
    email: 'deputy@al-fadaa.com',
    role: Role.DEPUTY_GM,
  };

  const managerUser: AuthUser = {
    id: 'mgr-1',
    name: 'مدير قسم الهندسة',
    email: 'eng.mgr@al-fadaa.com',
    role: Role.DEPT_MANAGER,
    departmentId: 'dept-1',
  };

  const employeeUser: AuthUser = {
    id: 'emp-1',
    name: 'أحمد الموظف',
    email: 'emp@al-fadaa.com',
    role: Role.EMPLOYEE,
    departmentId: 'dept-1',
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DelegationService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAudit },
        { provide: NotificationsService, useValue: mockNotifications },
      ],
    }).compile();

    service = module.get<DelegationService>(DelegationService);
  });

  describe('قيود إنشاء التفويض (Creation Constraints)', () => {
    it('يمنع تفويض الصلاحيات للنفس', async () => {
      await expect(
        service.create(
          {
            delegateId: deputyUser.id,
            startsAt: new Date().toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
          },
          deputyUser,
        ),
      ).rejects.toThrow('لا يمكن تفويض الصلاحيات لنفسك');
    });

    it('يمنع الموظف العادي من تفويض الصلاحيات', async () => {
      mockPrisma.user.findUnique.mockResolvedValueOnce({
        id: employeeUser.id,
        role: Role.EMPLOYEE,
        isActive: true,
      });

      await expect(
        service.create(
          {
            delegateId: managerUser.id,
            startsAt: new Date().toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
          },
          employeeUser,
        ),
      ).rejects.toThrow('فقط الإدارة العليا ومدراء الأقسام يملكون صلاحية التفويض');
    });

    it('يمنع التفويض الدائري أو المتبادل بين نفس المستخدمين', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce({ id: deputyUser.id, role: Role.DEPUTY_GM, isActive: true })
        .mockResolvedValueOnce({ id: managerUser.id, role: Role.DEPT_MANAGER, isActive: true });

      // وجود تفويض نشط عكسي من المدير إلى النائب
      mockPrisma.delegation.findFirst.mockResolvedValueOnce({
        id: 'del-rev',
        delegatorId: managerUser.id,
        delegateId: deputyUser.id,
        active: true,
      });

      await expect(
        service.create(
          {
            delegateId: managerUser.id,
            startsAt: new Date().toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
          },
          deputyUser,
        ),
      ).rejects.toThrow('لا يمكن إنشاء تفويض دائري متبادل بين نفس المستخدمين');
    });

    it('يمنع تداخل فترتين نشطتين لنفس المفوِّض', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce({ id: deputyUser.id, role: Role.DEPUTY_GM, isActive: true })
        .mockResolvedValueOnce({ id: managerUser.id, role: Role.DEPT_MANAGER, isActive: true });

      mockPrisma.delegation.findFirst
        .mockResolvedValueOnce(null) // لا يوجد دائري
        .mockResolvedValueOnce({ id: 'existing-del', active: true }); // يوجد تداخل

      await expect(
        service.create(
          {
            delegateId: managerUser.id,
            startsAt: new Date().toISOString(),
            endsAt: new Date(Date.now() + 86400000).toISOString(),
          },
          deputyUser,
        ),
      ).rejects.toThrow('يوجد تفويض نشط آخر يتداخل مع هذه الفترة لنفس المفوِّض');
    });
  });

  describe('إنشاء التفويض الناجح وإشعار الوكيل', () => {
    it('ينشئ التفويض بنجاح ويوثقه في سجل التدقيق ويشعر الوكيل بالصلاحيات', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce({ id: deputyUser.id, name: deputyUser.name, role: Role.DEPUTY_GM, isActive: true })
        .mockResolvedValueOnce({ id: managerUser.id, name: managerUser.name, role: Role.DEPT_MANAGER, isActive: true });

      mockPrisma.delegation.findFirst.mockResolvedValue(null);
      const createdDelegation = {
        id: 'del-100',
        delegatorId: deputyUser.id,
        delegateId: managerUser.id,
        active: true,
        startsAt: new Date(),
        endsAt: new Date(Date.now() + 86400000),
        delegator: deputyUser,
        delegate: managerUser,
      };
      mockPrisma.delegation.create.mockResolvedValue(createdDelegation);

      const res = await service.create(
        {
          delegateId: managerUser.id,
          startsAt: new Date().toISOString(),
          endsAt: new Date(Date.now() + 86400000).toISOString(),
          reason: 'إجازة سنوية',
        },
        deputyUser,
      );

      expect(res.id).toBe('del-100');
      expect(mockAudit.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'CREATE',
          entityType: 'Delegation',
          summary: expect.stringContaining('تفويض صلاحيات'),
        }),
      );
      expect(mockNotifications.notify).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: managerUser.id,
          title: expect.stringContaining('تم تفويضك رسميًا'),
        }),
      );
    });
  });

  describe('انتهاء فترة التفويض وإرسال الإشعار التلخيصي', () => {
    it('عند انتهاء التفويض، يُلغى التفعيل وتُرسل رسالة ملخص إداري بما جرى للمفوِّض', async () => {
      const expiredDelegation = {
        id: 'del-expired',
        delegatorId: deputyUser.id,
        delegateId: managerUser.id,
        startsAt: new Date(Date.now() - 1000000),
        endsAt: new Date(Date.now() - 1000),
        active: true,
        delegator: { name: deputyUser.name },
        delegate: { name: managerUser.name },
      };

      mockPrisma.delegation.findMany.mockResolvedValue([expiredDelegation]);
      mockPrisma.delegation.update.mockResolvedValue({ ...expiredDelegation, active: false });
      mockPrisma.auditLog.count.mockResolvedValue(4); // اعتمد 4 ردود
      mockPrisma.reply.count.mockResolvedValue(1); // بقيت مسودة واحدة

      await service.handleExpiredDelegations();

      expect(mockPrisma.delegation.update).toHaveBeenCalledWith({
        where: { id: 'del-expired' },
        data: { active: false },
      });

      expect(mockNotifications.notify).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: deputyUser.id,
          title: 'انتهاء فترة التفويض وعودة الصلاحيات',
          body: expect.stringContaining('اعتمد «مدير قسم الهندسة» نيابة عنك 4 ردود، وبقيت 1 مسودة بانتظارك'),
        }),
      );
    });
  });
});
