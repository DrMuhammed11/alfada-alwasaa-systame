import { Test, TestingModule } from '@nestjs/testing';
import { AuditAction, NotificationType, OutboxMailStatus, Role } from '@prisma/client';
import { MailRetryService } from './mail-retry.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditService } from '../audit/audit.service';
import type { SendReplyOptions } from './mail.service';

describe('OutboxMail Persistent Retry & Distributed Queue', () => {
  let service: MailRetryService;
  let inMemoryDb: any[] = [];
  let prismaMock: any;
  let notificationsMock: any;
  let auditMock: any;

  const sampleMail: SendReplyOptions = {
    to: 'partner@example.com',
    subject: 'موافقة على المقترح',
    body: 'نحيطكم علماً بالموافقة على العرض المقدم.',
    refNumber: 'OUT-2026-00099',
  };

  beforeEach(async () => {
    inMemoryDb = [];

    prismaMock = {
      outboxMail: {
        create: jest.fn().mockImplementation(async ({ data }: any) => {
          const record = {
            id: `outbox-${inMemoryDb.length + 1}`,
            ...data,
            createdAt: new Date(),
            sentAt: null,
          };
          inMemoryDb.push(record);
          return record;
        }),
        findFirst: jest.fn().mockImplementation(async ({ where }: any) => {
          return inMemoryDb.find((m) => {
            if (where?.refNumber && m.refNumber !== where.refNumber) return false;
            if (where?.status?.in && !where.status.in.includes(m.status)) return false;
            return true;
          }) || null;
        }),
        findUnique: jest.fn().mockImplementation(async ({ where }: any) => {
          return inMemoryDb.find((m) => m.id === where.id) || null;
        }),
        findMany: jest.fn().mockImplementation(async ({ where }: any) => {
          return inMemoryDb.filter((m) => {
            if (where?.status && m.status !== where.status) return false;
            if (where?.nextRetryAt?.lte && !(m.nextRetryAt <= where.nextRetryAt.lte)) return false;
            return true;
          });
        }),
        update: jest.fn().mockImplementation(async ({ where, data }: any) => {
          const item = inMemoryDb.find((m) => m.id === where.id);
          if (item) {
            Object.assign(item, data);
          }
          return item;
        }),
        updateMany: jest.fn().mockImplementation(async ({ where, data }: any) => {
          const matched = inMemoryDb.filter((m) => {
            if (where.id && m.id !== where.id) return false;
            if (where.status && m.status !== where.status) return false;
            return true;
          });
          matched.forEach((m) => Object.assign(m, data));
          return { count: matched.length };
        }),
        count: jest.fn().mockImplementation(async () => inMemoryDb.length),
      },
      user: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'gm-user-1', name: 'المدير العام', role: Role.GM, isActive: true },
        ]),
      },
    };

    notificationsMock = {
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    auditMock = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MailRetryService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: NotificationsService, useValue: notificationsMock },
        { provide: AuditService, useValue: auditMock },
      ],
    }).compile();

    service = module.get<MailRetryService>(MailRetryService);
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  it('1. عند فشل الإرسال، يجب حفظ الرسالة في جدول OutboxMail بحالة QUEUED ومحاولة رقم 1', async () => {
    await service.enqueue(sampleMail, 'SMTP Connection Timeout', 3);

    expect(prismaMock.outboxMail.create).toHaveBeenCalledTimes(1);
    expect(inMemoryDb.length).toBe(1);
    expect(inMemoryDb[0].status).toBe(OutboxMailStatus.QUEUED);
    expect(inMemoryDb[0].attempts).toBe(1);
    expect(inMemoryDb[0].refNumber).toBe('OUT-2026-00099');
    expect(inMemoryDb[0].lastError).toBe('SMTP Connection Timeout');
  });

  it('2. دورة الاسترداد بعد إعادة تشغيل الخدمة واستعادة SMTP بنجاح', async () => {
    // محاكاة وجود رسالة مخزنة سابقة في جدول قاعدة البيانات بسبب انقطاع الخادم
    inMemoryDb.push({
      id: 'outbox-existing-1',
      replyId: null,
      refNumber: sampleMail.refNumber,
      to: sampleMail.to,
      subject: sampleMail.subject,
      body: sampleMail.body,
      html: null,
      attachments: null,
      attempts: 1,
      maxAttempts: 3,
      nextRetryAt: new Date(Date.now() - 5000), // مستحق للمعالجة
      status: OutboxMailStatus.QUEUED,
      lastError: 'Network Down',
      createdAt: new Date(),
      sentAt: null,
    });

    // محاكاة استعادة عمل SMTP بنجاح
    const mockSender = jest.fn().mockResolvedValue(true);
    service.registerSender(mockSender);

    // تشغيل دورة المعالجة المجدولة
    await service.processQueue();

    // التحقق من استدعاء دالة الإرسال وتحديث الحالة في قاعدة البيانات إلى SENT
    expect(mockSender).toHaveBeenCalledTimes(1);
    const updated = inMemoryDb.find((m) => m.id === 'outbox-existing-1');
    expect(updated.status).toBe(OutboxMailStatus.SENT);
    expect(updated.sentAt).toBeDefined();
  });

  it('3. إشعار المدير العام وتوثيق الفشل النهائي في سجل التدقيق عند استنفاد المحاولات', async () => {
    // رسالة بالمحاولة الأخيرة (المحاولة 2 من 3)
    inMemoryDb.push({
      id: 'outbox-fail-target',
      replyId: null,
      refNumber: sampleMail.refNumber,
      to: sampleMail.to,
      subject: sampleMail.subject,
      body: sampleMail.body,
      html: null,
      attachments: null,
      attempts: 2,
      maxAttempts: 3,
      nextRetryAt: new Date(Date.now() - 1000),
      status: OutboxMailStatus.QUEUED,
      lastError: 'Temporary 500',
      createdAt: new Date(),
      sentAt: null,
    });

    // محاكاة استمرار فشل الإرسال
    const failingSender = jest.fn().mockRejectedValue(new Error('Permanent SMTP 550 User Unknown'));
    service.registerSender(failingSender);

    await service.processQueue();

    const failedItem = inMemoryDb.find((m) => m.id === 'outbox-fail-target');
    expect(failedItem.status).toBe(OutboxMailStatus.FAILED);
    expect(failedItem.attempts).toBe(3);

    // التحقق من إرسال إشعار عاجل للمدير العام
    expect(notificationsMock.notifyMany).toHaveBeenCalledWith(
      ['gm-user-1'],
      expect.objectContaining({
        type: NotificationType.REPLY_SENT,
        title: expect.stringContaining('تعذر إرسال رد رسمي للعميل'),
        body: expect.stringContaining('OUT-2026-00099'),
      }),
    );

    // التحقق من توثيق الفشل النهائي في سجل التدقيق
    expect(auditMock.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: AuditAction.SEND,
        entityType: 'OutboxMail',
        entityId: 'outbox-fail-target',
        metadata: expect.objectContaining({
          permanentFailure: true,
          refNumber: 'OUT-2026-00099',
        }),
      }),
    );
  });

  it('4. إمكانية الإيقاف المؤقت وإعادة المحاولة اليدوية من قبل الإدارة', async () => {
    inMemoryDb.push({
      id: 'outbox-admin-test',
      refNumber: 'OUT-TEST-ADMIN',
      to: 'client@test.com',
      subject: 'Test',
      body: 'Content',
      attempts: 3,
      maxAttempts: 3,
      nextRetryAt: new Date(),
      status: OutboxMailStatus.FAILED,
      createdAt: new Date(),
    });

    // 1. إعادة المحاولة يدوياً
    const retryResult = await service.retryManually('outbox-admin-test');
    expect(retryResult.status).toBe(OutboxMailStatus.QUEUED);
    expect(retryResult.attempts).toBe(0);

    // 2. إيقاف الإرسال مؤقتاً
    const pauseResult = await service.pauseMail('outbox-admin-test');
    expect(pauseResult.status).toBe(OutboxMailStatus.PAUSED);
  });
});
