import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesQueryService } from './correspondences-query.service';
import { AuthUser } from '../common/types';
import { CorrespondenceStatus, CorrespondenceType, Priority, Role } from '@prisma/client';

describe('Advanced Search (Full-Text & Multi-filter)', () => {
  let queryService: CorrespondencesQueryService;
  let prisma: {
    correspondence: {
      count: jest.Mock;
      findMany: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  const mockAdminUser: AuthUser = {
    id: 'user-admin-1',
    email: 'admin@al-fadaa.com',
    role: Role.ADMIN,
    name: 'مسؤول النظام',
  };

  const mockEmployeeUser: AuthUser = {
    id: 'user-emp-1',
    email: 'emp@al-fadaa.com',
    role: Role.EMPLOYEE,
    name: 'موظف تجريبي',
  };

  beforeEach(async () => {
    prisma = {
      correspondence: {
        count: jest.fn().mockResolvedValue(2),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'corr-1',
            refNumber: 'INC-2026-00010',
            subject: 'عقد توريد أجهزة حاسوب',
            body: 'تفاصيل توريد أجهزة لفرع الرياض',
            type: CorrespondenceType.INCOMING,
            status: CorrespondenceStatus.RECEIVED,
            priority: Priority.HIGH,
            createdAt: new Date('2026-03-01T10:00:00Z'),
            referrals: [],
            tasks: [],
            attachments: [{ id: 'att-1' }],
          },
          {
            id: 'corr-2',
            refNumber: 'INT-2026-00020',
            subject: 'تعميم إداري بخصوص الإجازات',
            body: 'نص التعميم الإداري',
            type: CorrespondenceType.INTERNAL,
            status: CorrespondenceStatus.IN_PROGRESS,
            priority: Priority.NORMAL,
            createdAt: new Date('2026-03-05T10:00:00Z'),
            referrals: [],
            tasks: [],
            attachments: [],
          },
        ]),
      },
      $transaction: jest.fn().mockImplementation((promises) => Promise.all(promises)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CorrespondencesQueryService,
        {
          provide: PrismaService,
          useValue: prisma,
        },
      ],
    }).compile();

    queryService = module.get<CorrespondencesQueryService>(CorrespondencesQueryService);
  });

  it('يبحث بالنص الشامل عبر الموضوع والمحتوى والردود والبيانات', async () => {
    const result = await queryService.search(
      { q: 'توريد' },
      mockAdminUser,
    );

    expect(prisma.correspondence.count).toHaveBeenCalledTimes(1);
    const countArg = prisma.correspondence.count.mock.calls[0][0];

    // التأكد من أن استعلام البحث يشمل الموضوع والمحتوى والردود
    const orFilter = countArg.where.AND.find((f: any) => f.OR);
    expect(orFilter).toBeDefined();
    expect(orFilter.OR).toEqual(
      expect.arrayContaining([
        { subject: { contains: 'توريد', mode: 'insensitive' } },
        { body: { contains: 'توريد', mode: 'insensitive' } },
        { replies: { some: { body: { contains: 'توريد', mode: 'insensitive' } } } },
      ]),
    );

    expect(result.data).toHaveLength(2);
    expect(result.meta.total).toBe(2);
  });

  it('يطبق فلتر النطاق الزمني والتاريخ (from / to)', async () => {
    await queryService.search(
      {
        from: '2026-01-01T00:00:00.000Z',
        to: '2026-03-31T23:59:59.000Z',
      },
      mockAdminUser,
    );

    const countArg = prisma.correspondence.count.mock.calls[0][0];
    const dateFilter = countArg.where.AND.find((f: any) => f.createdAt);
    expect(dateFilter).toBeDefined();
    expect(dateFilter.createdAt.gte).toEqual(new Date('2026-01-01T00:00:00.000Z'));
    expect(dateFilter.createdAt.lte).toEqual(new Date('2026-03-31T23:59:59.000Z'));
  });

  it('يطبق فلتر وجود المرفقات (hasAttachments: true)', async () => {
    await queryService.search(
      { hasAttachments: true },
      mockAdminUser,
    );

    const countArg = prisma.correspondence.count.mock.calls[0][0];
    const attFilter = countArg.where.AND.find((f: any) => f.attachments);
    expect(attFilter).toBeDefined();
    expect(attFilter.attachments).toEqual({ some: {} });
  });

  it('يطبق حوكمة نطاق الرؤية للموظف العادي فلا يعيد سوى ما يخصه', async () => {
    await queryService.search(
      { q: 'أجهزة' },
      mockEmployeeUser,
    );

    const countArg = prisma.correspondence.count.mock.calls[0][0];
    const scopeFilter = countArg.where.AND[0];
    expect(scopeFilter.OR).toBeDefined();
    expect(scopeFilter.OR).toEqual(
      expect.arrayContaining([
        { tasks: { some: { assignedToId: 'user-emp-1' } } },
        { referrals: { some: { toUserId: 'user-emp-1' } } },
        { replies: { some: { authorId: 'user-emp-1' } } },
      ]),
    );
  });
});
