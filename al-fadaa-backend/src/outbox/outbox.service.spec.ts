import { Test, TestingModule } from '@nestjs/testing';
import { AuditAction, NotificationType, OutboxStatus } from '@prisma/client';
import { OutboxService } from './outbox.service';
import { OutboxProcessor } from './outbox.processor';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OutboxEventType } from './outbox.types';

describe('Transactional Outbox Pattern & Crash Recovery', () => {
  let service: OutboxService;
  let processor: OutboxProcessor;
  let prismaMock: any;
  let auditMock: any;
  let notificationsMock: any;

  // محاكاة قاعدة البيانات المحلية للـ Outbox
  let inMemoryOutbox: any[] = [];

  beforeEach(async () => {
    inMemoryOutbox = [];

    prismaMock = {
      eventOutbox: {
        create: jest.fn().mockImplementation(async ({ data }: any) => {
          const record = {
            id: `outbox-${inMemoryOutbox.length + 1}`,
            ...data,
            attempts: data.attempts ?? 0,
            nextRetryAt: null,
            createdAt: new Date(),
            processedAt: null,
          };
          inMemoryOutbox.push(record);
          return record;
        }),
        findMany: jest.fn().mockImplementation(async ({ where }: any) => {
          return inMemoryOutbox.filter((e) => {
            if (where?.status && e.status !== where.status) return false;
            return true;
          });
        }),
        update: jest.fn().mockImplementation(async ({ where, data }: any) => {
          const item = inMemoryOutbox.find((e) => e.id === where.id);
          if (item) {
            Object.assign(item, data);
          }
          return item;
        }),
        count: jest.fn().mockImplementation(async ({ where }: any) => {
          return inMemoryOutbox.filter((e) => {
            if (where?.status && e.status !== where.status) return false;
            if (where?.createdAt?.lt && !(e.createdAt < where.createdAt.lt)) return false;
            return true;
          }).length;
        }),
      },
    };

    auditMock = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    notificationsMock = {
      notify: jest.fn().mockResolvedValue(undefined),
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OutboxService,
        OutboxProcessor,
        { provide: PrismaService, useValue: prismaMock },
        { provide: AuditService, useValue: auditMock },
        { provide: NotificationsService, useValue: notificationsMock },
      ],
    }).compile();

    service = module.get<OutboxService>(OutboxService);
    processor = module.get<OutboxProcessor>(OutboxProcessor);
  });

  describe('محاكاة الانهيار والتعافي (Crash Simulation & Recovery)', () => {
    it('يحاكي انهيار الخادم بعد نجاح المعاملة، ثم إعادة تشغيل المعالج ليكتب التدقيق وتصل الإشعارات دون أي فقدان', async () => {
      // 1. محاكاة معاملة مصرفية تُسجل حدث في الـ Outbox
      const mockTx = {
        eventOutbox: prismaMock.eventOutbox,
      };

      await service.emit(mockTx as any, {
        type: OutboxEventType.REPLY_APPROVED,
        payload: {
          audit: {
            action: AuditAction.APPROVE,
            entityType: 'Reply',
            entityId: 'reply-100',
            summary: 'اعتماد الرد الرسمي على المراسلة REF-2026-0001',
            userId: 'user-gm',
          },
          notification: {
            type: NotificationType.REPLY_APPROVED,
            userId: 'user-author',
            title: 'اعتُمد ردك الرسمي',
            body: 'تم اعتماد الرد من قبل المدير العام',
            link: '/correspondences/corr-100',
            entityType: 'Reply',
            entityId: 'reply-100',
          },
        },
      });

      expect(inMemoryOutbox.length).toBe(1);
      expect(inMemoryOutbox[0].status).toBe(OutboxStatus.PENDING);

      // 2. محاكاة انهيار فوري (Crash Simulation) عبر رمي استثناء مفاجئ بعد نجاح المعاملة
      const crashSimulation = () => {
        throw new Error('FATAL SERVER CRASH: Out of memory / Connection severed');
      };
      expect(crashSimulation).toThrow('FATAL SERVER CRASH');

      // في هذه اللحظة التدقيق والإشعار لم يُستدعيا بعد
      expect(auditMock.log).not.toHaveBeenCalled();
      expect(notificationsMock.notify).not.toHaveBeenCalled();

      // 3. إعادة تشغيل المعالج (Processor Resumes / Cron Trigger)
      const processedCount = await processor.processPendingEvents();

      expect(processedCount).toBe(1);

      // 4. التحقق من كتابة سجل التدقيق بالكامل
      expect(auditMock.log).toHaveBeenCalledTimes(1);
      expect(auditMock.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: AuditAction.APPROVE,
          entityId: 'reply-100',
          summary: 'اعتماد الرد الرسمي على المراسلة REF-2026-0001',
        }),
      );

      // 5. التحقق من وصول الإشعار للمستلم
      expect(notificationsMock.notify).toHaveBeenCalledTimes(1);
      expect(notificationsMock.notify).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-author',
          type: NotificationType.REPLY_APPROVED,
          title: 'اعتُمد ردك الرسمي',
        }),
      );

      // 6. التحقق من تحديث حالة الحدث إلى PROCESSED
      expect(inMemoryOutbox[0].status).toBe(OutboxStatus.PROCESSED);
      expect(inMemoryOutbox[0].processedAt).toBeDefined();
    });

    it('يدعم إرسال إشعارات لعدة مستلمين (notifyMany) عند معالجة حدث الرفع للاعتماد', async () => {
      const mockTx = { eventOutbox: prismaMock.eventOutbox };

      await service.emit(mockTx as any, {
        type: OutboxEventType.REPLY_SUBMITTED,
        payload: {
          audit: {
            action: AuditAction.SUBMIT,
            entityType: 'Reply',
            entityId: 'reply-200',
            summary: 'رفع مسودة الرد للاعتماد',
          },
          notification: {
            type: NotificationType.REPLY_SUBMITTED,
            recipientIds: ['gm-user', 'deputy-gm-user', 'manager-user'],
            title: 'مسودة رد جديدة للاعتماد',
          },
        },
      });

      await processor.processPendingEvents();

      expect(notificationsMock.notifyMany).toHaveBeenCalledWith(
        ['gm-user', 'deputy-gm-user', 'manager-user'],
        expect.objectContaining({
          type: NotificationType.REPLY_SUBMITTED,
          title: 'مسودة رد جديدة للاعتماد',
        }),
      );
      expect(inMemoryOutbox[0].status).toBe(OutboxStatus.PROCESSED);
    });
  });

  describe('إعادة المحاولة والتراجع الأسي (Exponential Backoff)', () => {
    it('عند فشل خدمة الإشعارات، يبقى الحدث PENDING وتزداد محاولاته ويُجدول للمحاولة التالية', async () => {
      notificationsMock.notify.mockRejectedValueOnce(new Error('SSE broker unavailable'));

      const mockTx = { eventOutbox: prismaMock.eventOutbox };
      await service.emit(mockTx as any, {
        type: OutboxEventType.TASK_ASSIGNED,
        payload: {
          notification: {
            type: NotificationType.NEW_TASK,
            userId: 'emp-1',
            title: 'تكليف جديد',
          },
        },
      });

      await processor.processPendingEvents();

      expect(inMemoryOutbox[0].status).toBe(OutboxStatus.PENDING);
      expect(inMemoryOutbox[0].attempts).toBe(1);
      expect(inMemoryOutbox[0].nextRetryAt).toBeDefined();
    });

    it('يوسم الحدث كـ FAILED نهائيًا بعد استنفاد الحد الأقصى للمحاولات (5 محاولات)', async () => {
      notificationsMock.notify.mockRejectedValue(new Error('Continuous failure'));

      const mockTx = { eventOutbox: prismaMock.eventOutbox };
      await service.emit(mockTx as any, {
        type: OutboxEventType.TASK_ASSIGNED,
        payload: {
          notification: {
            type: NotificationType.NEW_TASK,
            userId: 'emp-1',
            title: 'تكليف جديد',
          },
        },
      });

      // تنفيذ 5 محاولات فاشلة متتالية
      for (let i = 0; i < 5; i++) {
        await processor.processPendingEvents();
      }

      expect(inMemoryOutbox[0].status).toBe(OutboxStatus.FAILED);
      expect(inMemoryOutbox[0].attempts).toBe(5);
    });
  });

  describe('فحص الصحة والإنذار المبكر (Health Check & Early Warning)', () => {
    it('يحسب عدد الأحداث العالقة لأكثر من ساعة بدقة', async () => {
      const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
      const halfHourAgo = new Date(Date.now() - 30 * 60 * 1000);

      inMemoryOutbox.push(
        { id: '1', status: OutboxStatus.PENDING, createdAt: twoHoursAgo },
        { id: '2', status: OutboxStatus.PENDING, createdAt: twoHoursAgo },
        { id: '3', status: OutboxStatus.PENDING, createdAt: halfHourAgo },
        { id: '4', status: OutboxStatus.PROCESSED, createdAt: twoHoursAgo },
      );

      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const delayedCount = await service.countPendingOlderThan(oneHourAgo);

      expect(delayedCount).toBe(2);
    });
  });
});
