import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { CorrespondenceType, Priority, ReplyStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { MailService } from '../mail/mail.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CorrespondencesQueryService } from '../correspondences/correspondences-query.service';
import { RepliesService } from './replies.service';
import type { AuthUser } from '../common/types';

describe('RepliesService Concurrency and Conditional Updates', () => {
  let service: RepliesService;

  const gm: AuthUser = {
    id: 'user-gm-1',
    email: 'gm@al-fadaa.com',
    name: 'المدير العام',
    role: 'GM',
  };

  const sampleReply = {
    id: 'reply-1',
    authorId: 'author-1',
    status: ReplyStatus.SUBMITTED,
    body: 'نص المسودة المقترحة',
    correspondenceId: 'corr-1',
    correspondence: {
      id: 'corr-1',
      refNumber: 'INC-2026-00001',
      subject: 'طلب توريد',
      type: CorrespondenceType.INCOMING,
      senderEmail: 'client@example.com',
      departmentId: null,
      priority: Priority.NORMAL,
    },
    author: {
      id: 'author-1',
      name: 'مهندس المشروع',
      email: 'eng@al-fadaa.com',
    },
  };

  const mockTx = {
    reply: {
      updateMany: jest.fn(),
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      findFirst: jest.fn(),
    },
    correspondence: {
      update: jest.fn(),
      create: jest.fn(),
    },
    referral: {
      updateMany: jest.fn(),
    },
    task: {
      update: jest.fn(),
    },
    attachment: {
      create: jest.fn(),
    },
  };

  const prismaMock = {
    reply: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
    },
    attachment: {
      findMany: jest.fn().mockResolvedValue([]),
    },
    $transaction: jest.fn().mockImplementation(async (callback) => {
      return callback(mockTx);
    }),
  };

  const auditMock = { log: jest.fn().mockResolvedValue(undefined) };
  const notifMock = {
    notifyReplyApproved: jest.fn().mockResolvedValue(undefined),
    notifyReplySent: jest.fn().mockResolvedValue(undefined),
  };
  const mailMock = {
    sendReply: jest.fn().mockResolvedValue({ messageId: '<msg-1>' }),
    sendReplyTracked: jest.fn().mockResolvedValue(undefined),
  };
  const refNumbersMock = { generate: jest.fn().mockResolvedValue('OUT-2026-00001') };
  const configMock = { get: jest.fn().mockReturnValue('info@al-fadaa.com') };
  const correspondencesMock = {
    findOne: jest.fn(),
    canView: jest.fn().mockResolvedValue(true),
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        RepliesService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: RefNumberService, useValue: refNumbersMock },
        { provide: CorrespondencesQueryService, useValue: { canView: jest.fn().mockResolvedValue(true) } },
          { provide: CorrespondencesService, useValue: correspondencesMock },
        { provide: MailService, useValue: mailMock },
        { provide: AuditService, useValue: auditMock },
        { provide: NotificationsService, useValue: notifMock },
        { provide: ConfigService, useValue: configMock },
      ],
    }).compile();

    service = moduleRef.get(RepliesService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('approve — سباق الاعتماد المتزامن', () => {
    it('الطلب الأول ينجح في حجز الاعتماد وتحديث الحالة', async () => {
      prismaMock.reply.findUnique.mockResolvedValue(sampleReply);
      mockTx.reply.updateMany.mockResolvedValue({ count: 1 });
      mockTx.reply.findUniqueOrThrow.mockResolvedValue({
        ...sampleReply,
        status: ReplyStatus.APPROVED,
      });

      const result = await service.approve('reply-1', gm);
      expect(result.status).toBe(ReplyStatus.APPROVED);
      expect(mockTx.reply.updateMany).toHaveBeenCalledWith({
        where: { id: 'reply-1', status: ReplyStatus.SUBMITTED },
        data: expect.objectContaining({ status: ReplyStatus.APPROVED }),
      });
    });

    it('الطلب المتزامن الثاني يجد 0 صفوف متأثرة ويرمي BadRequestException لمنع ازدواج الاعتماد', async () => {
      prismaMock.reply.findUnique.mockResolvedValue(sampleReply);
      mockTx.reply.updateMany.mockResolvedValue({ count: 0 });
      mockTx.reply.findUnique.mockResolvedValue({
        ...sampleReply,
        status: ReplyStatus.APPROVED,
      });

      await expect(service.approve('reply-1', gm)).rejects.toThrow(BadRequestException);
      await expect(service.approve('reply-1', gm)).rejects.toThrow(
        'تم تغيير حالة الرد للتو من قِبل مستخدم آخر',
      );
    });
  });

  describe('send — سباق الإرسال المتزامن', () => {
    const approvedReply = {
      ...sampleReply,
      status: ReplyStatus.APPROVED,
      sentAt: null,
    };

    it('الطلب الأول ينجح في حجز sentAt وتوليد رقم صادر رسمي', async () => {
      prismaMock.reply.findUnique.mockResolvedValue(approvedReply);
      prismaMock.reply.findFirst.mockResolvedValue(null);
      mockTx.reply.updateMany.mockResolvedValue({ count: 1 });
      mockTx.correspondence.create.mockResolvedValue({ id: 'out-1', refNumber: 'OUT-2026-00001' });

      const result = await service.send('reply-1', gm);
      expect(result.success).toBe(true);
      expect(result.refNumber).toBe('OUT-2026-00001');
      expect(mockTx.reply.updateMany).toHaveBeenCalledWith({
        where: { id: 'reply-1', status: ReplyStatus.APPROVED, sentAt: null },
        data: expect.objectContaining({ sentAt: expect.any(Date) }),
      });
      expect(mailMock.sendReplyTracked).toHaveBeenCalledTimes(1);
    });

    it('الطلب المتزامن الثاني يجد 0 صفوف متأثرة ويرمي BadRequestException لمنع تكرار الإرسال بالبريد', async () => {
      prismaMock.reply.findUnique.mockResolvedValue(approvedReply);
      mockTx.reply.updateMany.mockResolvedValue({ count: 0 });
      mockTx.reply.findUnique.mockResolvedValue({
        ...approvedReply,
        sentAt: new Date(),
      });

      await expect(service.send('reply-1', gm)).rejects.toThrow(BadRequestException);
      await expect(service.send('reply-1', gm)).rejects.toThrow(
        'تم إرسال هذا الرد للتو من قِبل مستخدم آخر',
      );
      // تأكيد عدم تكرار الإرسال بالبريد للعميل
      expect(mailMock.sendReply).not.toHaveBeenCalled();
    });
  });
});
