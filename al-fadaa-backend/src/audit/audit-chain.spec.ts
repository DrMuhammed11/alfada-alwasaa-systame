import { Test, TestingModule } from '@nestjs/testing';
import { AuditAction } from '@prisma/client';
import {
  AuditService,
  GENESIS_HASH,
  computeAuditHash,
} from './audit.service';
import { PrismaService } from '../prisma/prisma.service';

describe('Cryptographic Audit Chain & Tamper-Proof Integrity (سجل التدقيق المشفر)', () => {
  let service: AuditService;

  const mockLogs: any[] = [];

  const mockPrisma = {
    auditLog: {
      findFirst: jest.fn().mockImplementation(() => {
        if (mockLogs.length === 0) return Promise.resolve(null);
        return Promise.resolve(mockLogs[mockLogs.length - 1]);
      }),
      create: jest.fn().mockImplementation(({ data }) => {
        const entry = { id: `log-${mockLogs.length + 1}`, ...data };
        mockLogs.push(entry);
        return Promise.resolve(entry);
      }),
      findMany: jest.fn().mockImplementation(({ orderBy, take } = {}) => {
        // محاكاة سلوك Prisma الحقيقي: احترام orderBy desc وtake
        let arr = [...mockLogs];
        if (orderBy?.createdAt === 'desc') arr = arr.reverse();
        if (take) arr = arr.slice(0, take);
        return Promise.resolve(arr);
      }),
      count: jest.fn().mockImplementation(() => Promise.resolve(mockLogs.length)),
    },
    $transaction: jest.fn().mockImplementation((args) => Promise.all(args)),
  };

  beforeEach(async () => {
    mockLogs.length = 0;
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuditService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AuditService>(AuditService);
  });

  it('يجب أن تقوم دالة computeAuditHash بحساب بصمة SHA-256 محكمة ومتطابقة للمدخلات المتطابقة', () => {
    const payload = {
      previousHash: GENESIS_HASH,
      action: AuditAction.CREATE,
      userId: 'u-123',
      entityType: 'Correspondence',
      entityId: 'c-1',
      createdAt: '2026-09-17T07:00:00.000Z',
      summary: 'إنشاء مراسلة',
    };

    const hash1 = computeAuditHash(payload);
    const hash2 = computeAuditHash(payload);

    expect(hash1).toBe(hash2);
    expect(hash1).toMatch(/^[a-f0-9]{64}$/); // SHA-256 hex string length 64
  });

  it('يجب ربط كل سجل تدقيق بالسجل السابق بسلسلة هاش مشفرة (Hash Chaining)', async () => {
    // 1. تسجيل الحدث الأول
    await service.log({
      action: AuditAction.LOGIN,
      summary: 'تسجيل دخول المدير',
      userId: 'admin-1',
    });

    expect(mockLogs.length).toBe(1);
    expect(mockLogs[0].previousHash).toBe(GENESIS_HASH);
    expect(mockLogs[0].recordHash).toBeDefined();

    // 2. تسجيل الحدث الثاني
    await service.log({
      action: AuditAction.CREATE,
      summary: 'إنشاء وارد جديد INC-2026-0001',
      entityType: 'Correspondence',
      entityId: 'c-1',
      userId: 'admin-1',
    });

    expect(mockLogs.length).toBe(2);
    expect(mockLogs[1].previousHash).toBe(mockLogs[0].recordHash);
    expect(mockLogs[1].recordHash).toBeDefined();

    // 3. تسجيل الحدث الثالث
    await service.log({
      action: AuditAction.REFER,
      summary: 'إحالة المراسلة للشؤون القانونية',
      entityType: 'Referral',
      entityId: 'ref-1',
      userId: 'admin-1',
    });

    expect(mockLogs.length).toBe(3);
    expect(mockLogs[2].previousHash).toBe(mockLogs[1].recordHash);
  });

  it('يجب أن تؤكد verifyIntegrity سلامة السلسلة وخلوها من التلاعب بنسبة 100% عندما تكون البيانات سليمة', async () => {
    await service.log({ action: AuditAction.LOGIN, summary: 'دخول' });
    await service.log({ action: AuditAction.CREATE, summary: 'إنشاء' });
    await service.log({ action: AuditAction.APPROVE, summary: 'اعتماد' });

    const report = await service.verifyIntegrity();

    expect(report.isTamperFree).toBe(true);
    expect(report.chainStatus).toBe('VERIFIED_INTACT');
    expect(report.totalVerified).toBe(3);
    expect(report.brokenRecordId).toBeNull();
  });

  it('يجب أن تكتشف verifyIntegrity التلاعب فوراً إذا تم تعديل أي حقل داخل سجل سابق يدوياً', async () => {
    await service.log({ action: AuditAction.LOGIN, summary: 'دخول' });
    await service.log({ action: AuditAction.CREATE, summary: 'إنشاء وارد' });
    await service.log({ action: AuditAction.CLOSE, summary: 'إغلاق المعاملة' });

    // محاكاة تلاعب خبيث في قاعدة البيانات: تغيير محتوى السجل الثاني
    mockLogs[1].summary = 'تعديل خبيث على الملخص بدون إعادة توقيع الهاش';

    const report = await service.verifyIntegrity();

    expect(report.isTamperFree).toBe(false);
    expect(report.chainStatus).toBe('TAMPER_DETECTED');
    expect(report.brokenRecordId).toBe(mockLogs[1].id);
    expect(report.details).toContain('تم اكتشاف تلاعب في محتوى السجل');
  });

  it('يجب أن تكتشف verifyIntegrity انقطاع السلسلة إذا تم حذف سجل من المنتصف', async () => {
    await service.log({ action: AuditAction.LOGIN, summary: 'دخول' });
    await service.log({ action: AuditAction.CREATE, summary: 'إنشاء وارد' });
    await service.log({ action: AuditAction.CLOSE, summary: 'إغلاق المعاملة' });

    // محاكاة حذف السجل رقم 2 لإخفاء أثر عملية
    mockLogs.splice(1, 1);

    const report = await service.verifyIntegrity();

    expect(report.isTamperFree).toBe(false);
    expect(report.chainStatus).toBe('TAMPER_DETECTED');
    expect(report.details).toContain('تم اكتشاف انقطاع في سلسلة التدقيق');
  });
});
