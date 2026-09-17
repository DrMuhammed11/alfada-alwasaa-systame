import { Test, TestingModule } from '@nestjs/testing';
import {
  CorrespondenceStatus,
  CorrespondenceType,
  Priority,
  Role,
} from '@prisma/client';
import { BadRequestException } from '@nestjs/common';
import { CorrespondencesService } from './correspondences.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OutboxService } from '../outbox/outbox.service';
import { OutboxProcessor } from '../outbox/outbox.processor';
import { RefNumberService } from './ref-number.service';
import { AuthUser } from '../common/types';

describe('Document Lineage & Cascading Closure Safeguard (شجرة الأنساب وحوكمة الإغلاق)', () => {
  let service: CorrespondencesService;

  const gmUser: AuthUser = {
    id: 'gm-user-1',
    name: 'المدير العام',
    email: 'gm@al-fadaa.com',
    role: Role.GM,
  };

  const sampleParent: any = {
    id: 'parent-corr-1',
    refNumber: 'INC-2026-00010',
    type: CorrespondenceType.INCOMING,
    subject: 'طلب اعتماد مشروع تجاري كبير',
    body: 'نرجو التكرم بالدراسة والاعتماد',
    status: CorrespondenceStatus.REFERRED,
    priority: Priority.HIGH,
    parentId: null,
    children: [{ id: 'child-corr-1' }],
    referrals: [],
    tasks: [],
    replies: [],
    createdAt: new Date(),
  };

  const sampleChild: any = {
    id: 'child-corr-1',
    refNumber: 'INT-2026-00005',
    type: CorrespondenceType.INTERNAL,
    subject: 'دراسة الجدوى القانونية للمشروع',
    body: 'مطلوب الرأي القانوني خلال 24 ساعة',
    status: CorrespondenceStatus.UNDER_REVIEW,
    priority: Priority.HIGH,
    parentId: 'parent-corr-1',
    children: [],
    referrals: [],
    tasks: [],
    replies: [],
    createdAt: new Date(),
  };

  const mockPrisma = {
    correspondence: {
      findUnique: jest.fn().mockImplementation(({ where }) => {
        if (where.id === 'parent-corr-1') return Promise.resolve(sampleParent);
        if (where.id === 'child-corr-1') return Promise.resolve(sampleChild);
        return Promise.resolve(null);
      }),
      findMany: jest.fn().mockImplementation(({ where }) => {
        if (where?.parentId === 'parent-corr-1') {
          return Promise.resolve(
            sampleChild.status !== CorrespondenceStatus.CLOSED &&
              sampleChild.status !== CorrespondenceStatus.ARCHIVED
              ? [sampleChild]
              : [],
          );
        }
        return Promise.resolve([]);
      }),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      findUniqueOrThrow: jest.fn().mockResolvedValue({ ...sampleParent, status: CorrespondenceStatus.CLOSED }),
    },
    $transaction: jest.fn().mockImplementation((cb) => cb(mockPrisma)),
  };

  const mockAudit = { log: jest.fn().mockResolvedValue(undefined) };
  const mockNotifications = { notifyUser: jest.fn() };
  const mockOutbox = { emit: jest.fn().mockResolvedValue(undefined) };
  const mockOutboxProcessor = { trigger: jest.fn(), triggerImmediate: jest.fn().mockResolvedValue(undefined) };
  const mockRefNumber = { generate: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    sampleChild.status = CorrespondenceStatus.UNDER_REVIEW;
    sampleParent.status = CorrespondenceStatus.REFERRED;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CorrespondencesService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAudit },
        { provide: NotificationsService, useValue: mockNotifications },
        { provide: OutboxService, useValue: mockOutbox },
        { provide: OutboxProcessor, useValue: mockOutboxProcessor },
        { provide: RefNumberService, useValue: mockRefNumber },
      ],
    }).compile();

    service = module.get<CorrespondencesService>(CorrespondencesService);
  });

  it('يجب استرجاع شجرة الأنساب الكاملة والمؤشرات البيانية للمعاملة', async () => {
    const lineage = await service.getLineage('child-corr-1', gmUser);

    expect(lineage.rootId).toBe('parent-corr-1');
    expect(lineage.currentNodeId).toBe('child-corr-1');
    expect(lineage.totalNodes).toBe(2);
    expect(lineage.tree).toBeDefined();
    expect(lineage.tree.refNumber).toBe('INC-2026-00010');
    expect(lineage.tree.children.length).toBe(1);
    expect(lineage.tree.children[0].refNumber).toBe('INT-2026-00005');
  });

  it('يجب حظر إغلاق المعاملة الأم إذا كانت المعاملات الفرعية التابعة لها ما زالت نشطة (Cascading Closure Safeguard)', async () => {
    // محاولة إغلاق المعاملة الأم parent-corr-1 بينما child-corr-1 ما زالت UNDER_REVIEW
    await expect(service.close('parent-corr-1', gmUser)).rejects.toThrow(
      BadRequestException,
    );

    await expect(service.close('parent-corr-1', gmUser)).rejects.toThrow(
      /توجد معاملات فرعية تابعة لها ما زالت نشطة/,
    );
  });

  it('يجب السماح بإغلاق المعاملة الأم بعد إنجاز وإغلاق المعاملة الفرعية التابعة لها', async () => {
    // إغلاق المعاملة الفرعية أولاً
    sampleChild.status = CorrespondenceStatus.CLOSED;

    const res = await service.close('parent-corr-1', gmUser);
    expect(res).toBeDefined();
    expect(res.status).toBe(CorrespondenceStatus.CLOSED);
  });
});
