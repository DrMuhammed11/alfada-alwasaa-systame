import { Test, TestingModule } from '@nestjs/testing';
import { CorrespondenceStatus, Priority } from '@prisma/client';
import { IncomingMailMatcherService } from './incoming-mail-matcher.service';
import { PrismaService } from '../prisma/prisma.service';

describe('WhatsApp-Style Sender Threading (مطابقة محادثات نفس الشخص)', () => {
  let service: IncomingMailMatcherService;
  let prisma: {
    correspondence: {
      findFirst: jest.Mock;
      findUnique: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      correspondence: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        IncomingMailMatcherService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<IncomingMailMatcherService>(IncomingMailMatcherService);
  });

  it('يجب أن يربط الرسالة الجديدة بخيط المحادثة النشط القائم لنفس المرسل (senderEmail)', async () => {
    const mockParsedMail: any = {
      headers: new Map(),
    };

    // المحاكاة: لا يوجد تطابق برؤوس In-Reply-To أو الصادر الأخير أو رقم القيد بالموضوع
    // ولكن يوجد معاملة نشطة لنفس البريد
    prisma.correspondence.findFirst
      .mockResolvedValueOnce(null) // inReplyTo / references
      .mockResolvedValueOnce(null) // last outgoing
      .mockResolvedValueOnce({ id: 'active-corr-1', parentId: null }); // senderEmail match

    prisma.correspondence.findUnique.mockResolvedValueOnce({
      id: 'active-corr-1',
      refNumber: 'INC-2026-00001',
      subject: 'طلب عرض سعر',
      priority: Priority.HIGH,
      status: CorrespondenceStatus.IN_PROGRESS,
    });

    const result = await service.findThreadRoot(
      mockParsedMail,
      'client@example.com',
      'رسالة إضافية بدون رقم قيد',
      'مرحباً، هل من جديد؟',
    );

    expect(result).toBeDefined();
    expect(result?.id).toBe('active-corr-1');
    expect(result?.refNumber).toBe('INC-2026-00001');
  });

  it('يجب أن يربط الرسالة بالمحادثة السابقة لنفس المرسل حتى لو كانت مغلقة لإعادة فتحها كمحادثة واحدة', async () => {
    const mockParsedMail: any = {
      headers: new Map(),
    };

    prisma.correspondence.findFirst
      .mockResolvedValueOnce(null) // last outgoing
      .mockResolvedValueOnce(null) // active senderEmail
      .mockResolvedValueOnce({ id: 'closed-corr-1', parentId: null }); // any previous senderEmail

    prisma.correspondence.findUnique.mockResolvedValueOnce({
      id: 'closed-corr-1',
      refNumber: 'INC-2026-00002',
      subject: 'معاملة سابقة مغلقة',
      priority: Priority.NORMAL,
      status: CorrespondenceStatus.CLOSED,
    });

    const result = await service.findThreadRoot(
      mockParsedMail,
      'client@example.com',
      'مراسلة جديدة كلياً بعد إغلاق السابقة',
      'أريد خدمة جديدة',
    );

    expect(result).toBeDefined();
    expect(result?.id).toBe('closed-corr-1');
    expect(result?.status).toBe(CorrespondenceStatus.CLOSED);
  });

  it('يجب أن يُرجع null إذا كان المرسل جديداً ولا يملك أي محادثات سابقة', async () => {
    const mockParsedMail: any = {
      headers: new Map(),
    };

    prisma.correspondence.findFirst.mockResolvedValue(null);

    const result = await service.findThreadRoot(
      mockParsedMail,
      'new-client@example.com',
      'طلب لأول مرة',
      'نص الرسالة',
    );

    expect(result).toBeNull();
  });
});
