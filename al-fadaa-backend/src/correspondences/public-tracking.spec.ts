import { NotFoundException, UnauthorizedException } from '@nestjs/common';
import { CorrespondencesService } from './correspondences.service';
import { PrismaService } from '../prisma/prisma.service';

describe('Public Tracking Token Security', () => {
  let service: CorrespondencesService;
  const mockPrisma = {
    correspondence: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeAll(() => {
    service = new CorrespondencesService(
      mockPrisma as unknown as PrismaService,
      null as any,
      null as any,
      null as any,
      null as any,
      null as any,
    );
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('يرفض الطلب بـ UnauthorizedException إذا لم يُرسل رمز التتبع (token مفقود)', async () => {
    await expect(service.trackPublicInquiry('INC-2026-00001', undefined)).rejects.toThrow(
      UnauthorizedException,
    );
    await expect(service.trackPublicInquiry('INC-2026-00001', '')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('يرفض الطلب بـ UnauthorizedException إذا كان رمز التتبع خاطئًا', async () => {
    mockPrisma.correspondence.findUnique.mockResolvedValue({
      refNumber: 'INC-2026-00001',
      subject: 'طلب عرض سعر',
      status: 'RECEIVED',
      receivedAt: new Date(),
      publicTrackingToken: 'correct-secret-token-123',
      replies: [],
      children: [],
    });

    await expect(
      service.trackPublicInquiry('INC-2026-00001', 'wrong-token-999'),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('يرفض الطلب بـ NotFoundException إذا لم تكن المراسلة موجودة', async () => {
    mockPrisma.correspondence.findUnique.mockResolvedValue(null);

    await expect(
      service.trackPublicInquiry('INC-9999-99999', 'any-token'),
    ).rejects.toThrow(NotFoundException);
  });

  it('ينجح ويعيد البيانات والرد عند توفير رمز التتبع الصحيح', async () => {
    const receivedDate = new Date();
    mockPrisma.correspondence.findUnique.mockResolvedValue({
      refNumber: 'INC-2026-00001',
      subject: 'طلب تركيب شبكة اتصالات',
      status: 'ANSWERED',
      receivedAt: receivedDate,
      publicTrackingToken: 'correct-secret-token-123',
      replies: [],
      children: [
        {
          refNumber: 'OUT-2026-00005',
          body: 'يسرنا تقديم عرض الأسعار المعتمد',
          sentAt: new Date(),
          createdAt: new Date(),
        },
      ],
    });

    const result = await service.trackPublicInquiry('INC-2026-00001', 'correct-secret-token-123');
    expect(result).toBeDefined();
    expect(result.refNumber).toBe('INC-2026-00001');
    expect(result.subject).toBe('طلب تركيب شبكة اتصالات');
    expect(result.reply).toBeDefined();
    expect(result.reply?.refNumber).toBe('OUT-2026-00005');
    expect(result.reply?.body).toContain('عرض الأسعار المعتمد');
  });
});
