import { BadRequestException } from '@nestjs/common';
import { CorrespondenceStatus, Role } from '@prisma/client';
import { CorrespondencesService } from './correspondences.service';
import type { AuthUser } from '../common/types';

describe('CorrespondencesService - Optimistic Concurrency Control (OCC) & Race Conditions', () => {
  let service: CorrespondencesService;
  let mockPrisma: any;
  let mockAudit: any;
  let mockNotifications: any;
  let mockRefNumbers: any;
  let mockOutbox: any;

  // مستودع وهمي يمثل سجل قاعدة البيانات بحالة وتعديل حقيقي
  let inMemoryCorrespondence: {
    id: string;
    refNumber: string;
    status: CorrespondenceStatus;
    version: number;
    closedAt: Date | null;
    archivedAt: Date | null;
  };

  const adminUser: AuthUser = {
    id: 'admin-1',
    email: 'admin@al-fadaa.com',
    name: 'المدير العام',
    role: Role.GM,
  };

  beforeEach(() => {
    inMemoryCorrespondence = {
      id: 'corr-concurrency-1',
      refNumber: 'INC-2026-00099',
      status: CorrespondenceStatus.RECEIVED,
      version: 1,
      closedAt: null,
      archivedAt: null,
    };

    mockAudit = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    mockNotifications = {
      notifyRole: jest.fn().mockResolvedValue(undefined),
      notifyMany: jest.fn().mockResolvedValue(undefined),
    };

    mockRefNumbers = {
      generate: jest.fn().mockResolvedValue('INC-2026-00100'),
    };

    mockOutbox = {
      emit: jest.fn().mockResolvedValue({ id: 'outbox-1' }),
    };

    const mockTx = {
      correspondence: {
        updateMany: jest.fn(async ({ where, data }) => {
          // محاكاة شرط WHERE الذري: { id, version, status }
          if (where.id !== inMemoryCorrespondence.id) {
            return { count: 0 };
          }
          if (where.version !== undefined && where.version !== inMemoryCorrespondence.version) {
            return { count: 0 };
          }
          if (where.status && where.status.in && !where.status.in.includes(inMemoryCorrespondence.status)) {
            return { count: 0 };
          }

          // تطبيق التعديل وتحديث النسخة
          if (data.status) {
            inMemoryCorrespondence.status = data.status;
          }
          if (data.version && data.version.increment) {
            inMemoryCorrespondence.version += data.version.increment;
          }
          return { count: 1 };
        }),
        findUnique: jest.fn(async ({ where }) => {
          if (where.id === inMemoryCorrespondence.id) {
            return { ...inMemoryCorrespondence };
          }
          return null;
        }),
        findUniqueOrThrow: jest.fn(async ({ where }) => {
          if (where.id === inMemoryCorrespondence.id) {
            return {
              ...inMemoryCorrespondence,
              attachments: [],
              referrals: [],
              tasks: [],
              replies: [],
              createdBy: { id: adminUser.id, name: adminUser.name, email: adminUser.email, role: adminUser.role },
            };
          }
          throw new Error('Not found');
        }),
      },
      eventOutbox: {
        create: jest.fn().mockResolvedValue({ id: 'outbox-tx-1' }),
      },
    };

    mockPrisma = {
      correspondence: {
        findUnique: jest.fn(async ({ where }) => {
          if (where.id === inMemoryCorrespondence.id) {
            // إرجاع لقطة (snapshot) للحالة اللحظية
            return { ...inMemoryCorrespondence };
          }
          return null;
        }),
      },
      $transaction: jest.fn(async (cb: (tx: any) => Promise<any>) => {
        return cb(mockTx);
      }),
    };

    service = new CorrespondencesService(
      mockPrisma,
      mockRefNumbers,
      mockAudit,
      mockNotifications,
      mockOutbox,
      undefined,
      undefined,
    );
  });

  it('يجب أن يمنع سباق العمليات (Race Condition) عند محاولة إغلاق متزامنة عبر Promise.all ويرفض الطلب المتأخر', async () => {
    // محاكاة قراءة متزامنة لنفس النسخة (version 1) قبل تنفيذ المعاملات
    // كلاهما يرى المراسلة بنسخة 1 وحالة RECEIVED
    const initialSnapshot = { ...inMemoryCorrespondence };
    mockPrisma.correspondence.findUnique.mockResolvedValue(initialSnapshot);

    // إطلاق طلبي إغلاق متزامنين في نفس اللحظة
    const [result1, result2] = await Promise.allSettled([
      service.close('corr-concurrency-1', adminUser),
      service.close('corr-concurrency-1', adminUser),
    ]);

    // يجب أن ينجح طلب واحد فقط
    const fulfilled = [result1, result2].filter((r) => r.status === 'fulfilled');
    const rejected = [result1, result2].filter((r) => r.status === 'rejected');

    expect(fulfilled.length).toBe(1);
    expect(rejected.length).toBe(1);

    // التحقق من رسالة الخطأ الصريحة المحددة في الدليل الإرشادي
    const rejectionReason = (rejected[0] as PromiseRejectedResult).reason;
    expect(rejectionReason).toBeInstanceOf(BadRequestException);
    expect(rejectionReason.message).toBe('عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة');

    // التحقق من أن حالة السجل أصبحت CLOSED ورقم النسخة أصبح 2
    expect(inMemoryCorrespondence.status).toBe(CorrespondenceStatus.CLOSED);
    expect(inMemoryCorrespondence.version).toBe(2);

    // التحقق من أن حدث الـ Outbox سُجل مرة واحدة فقط
    expect(mockOutbox.emit).toHaveBeenCalledTimes(1);
  });

  it('يجب أن يرفض الطلب فوراً إذا كان رقم النسخة قديماً (Stale Object Version)', async () => {
    // محاكاة حالة تم فيها تحديث العنصر مسبقاً وأصبح version = 2
    inMemoryCorrespondence.version = 2;
    inMemoryCorrespondence.status = CorrespondenceStatus.UNDER_REVIEW;

    // تم إرسال طلب استند إلى لقطة قديمة برقم version = 1
    mockPrisma.correspondence.findUnique.mockResolvedValueOnce({
      ...inMemoryCorrespondence,
      version: 1, // العميل يملك نسخة قديمة
    });

    await expect(service.close('corr-concurrency-1', adminUser)).rejects.toThrow(
      new BadRequestException('عملية أخرى نُفِّذت للتو على هذا العنصر، حدّث الشاشة وأعد المحاولة'),
    );

    // لم يتم تغيير النسخة أو الحالة
    expect(inMemoryCorrespondence.version).toBe(2);
    expect(inMemoryCorrespondence.status).toBe(CorrespondenceStatus.UNDER_REVIEW);
  });
});
