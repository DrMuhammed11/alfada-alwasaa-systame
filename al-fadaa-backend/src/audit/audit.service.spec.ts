import { Test } from '@nestjs/testing';
import { AuditAction } from '@prisma/client';
import { AuditService } from './audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { requestContextStorage } from '../common/context/request-context';

/** اختبارات وحدة لخدمة سجل التدقيق — التقاط IP والمتصفح من سياق الطلب تلقائيًا */
describe('AuditService', () => {
  let service: AuditService;
  const createMock = jest.fn().mockResolvedValue({});

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        AuditService,
        { provide: PrismaService, useValue: { auditLog: { create: createMock } } },
      ],
    }).compile();
    service = moduleRef.get(AuditService);
  });

  beforeEach(() => createMock.mockClear());

  it('يلتقط هوية المستخدم وIP والمتصفح من سياق الطلب تلقائيًا', async () => {
    await requestContextStorage.run(
      { userId: 'user-9', ip: '192.168.1.10', userAgent: 'jest-test' },
      async () => {
        await service.log({
          action: AuditAction.REFER,
          summary: 'اختبار إحالة',
          entityType: 'Correspondence',
          entityId: 'corr-1',
        });
      },
    );

    expect(createMock).toHaveBeenCalledTimes(1);
    expect(createMock).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: AuditAction.REFER,
        userId: 'user-9',
        ipAddress: '192.168.1.10',
        userAgent: 'jest-test',
        entityType: 'Correspondence',
        entityId: 'corr-1',
      }),
    });
  });

  it('يتيح تجاوز هوية المستخدم صراحةً (تسجيل الدخول قبل وجود JWT)', async () => {
    await requestContextStorage.run({ ip: '10.0.0.5' }, async () => {
      await service.log({
        action: AuditAction.LOGIN,
        userId: 'user-77',
        summary: 'تسجيل دخول',
      });
    });

    expect(createMock).toHaveBeenCalledWith({
      data: expect.objectContaining({
        action: AuditAction.LOGIN,
        userId: 'user-77',
        ipAddress: '10.0.0.5',
      }),
    });
  });

  it('لا يرمي استثناءً إذا فشلت الكتابة — حتى لا تتعطل العملية التجارية', async () => {
    createMock.mockRejectedValueOnce(new Error('DB down'));
    await expect(
      service.log({ action: AuditAction.CREATE, summary: 'حدث يجب ألا يفشل الطلب بسببه' }),
    ).resolves.not.toThrow();
  });
});
