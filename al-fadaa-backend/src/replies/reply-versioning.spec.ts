import { Test, TestingModule } from '@nestjs/testing';
import { ReplyStatus } from '@prisma/client';
import { BadRequestException } from '@nestjs/common';
import { RepliesVersioningService, computeLineDiff } from './replies-versioning.service';
import { RepliesService } from './replies.service';
import { PrismaService } from '../prisma/prisma.service';
import { RefNumberService } from '../correspondences/ref-number.service';
import { CorrespondencesService } from '../correspondences/correspondences.service';
import { MailService } from '../mail/mail.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ConfigService } from '@nestjs/config';
import type { AuthUser } from '../common/types';

describe('تاريخ إصدارات الردود وفرق التغييرات (Reply Versioning & Line Diff)', () => {
  describe('خوارزمية المقارنة السطرية (computeLineDiff)', () => {
    it('تحسب السطور المضافة والمحذوفة والثابتة بدقة دون مكتبات خارجية', () => {
      const oldText = 'السطر الأول\nالسطر الثاني الملغى\nالسطر المشترك';
      const newText = 'السطر الأول\nالسطر الجديد المعدل\nالسطر المشترك\nسطر إضافي أخير';

      const diff = computeLineDiff(oldText, newText);

      expect(diff).toEqual([
        { type: 'unchanged', line: 'السطر الأول' },
        { type: 'removed', line: 'السطر الثاني الملغى' },
        { type: 'added', line: 'السطر الجديد المعدل' },
        { type: 'unchanged', line: 'السطر المشترك' },
        { type: 'added', line: 'سطر إضافي أخير' },
      ]);
    });
  });

  describe('دورة حياة الإصدارات والتجميد النهائي للردود', () => {
    let repliesService: RepliesService;

    const mockPrisma: any = {
      reply: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      correspondence: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      task: {
        findUnique: jest.fn(),
      },
      replyVersion: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
      },
      counter: {
        upsert: jest.fn(),
      },
    };

    const mockAudit = { log: jest.fn().mockResolvedValue(undefined) };
    const mockNotifications = { notify: jest.fn().mockResolvedValue(undefined) };

    const authorUser: AuthUser = {
      id: 'emp-1',
      name: 'أحمد الموظف',
      email: 'emp@al-fadaa.com',
      role: 'EMPLOYEE' as any,
    };

    beforeEach(async () => {
      jest.clearAllMocks();
      const module: TestingModule = await Test.createTestingModule({
        providers: [
          RepliesService,
          RepliesVersioningService,
          { provide: PrismaService, useValue: mockPrisma },
          { provide: RefNumberService, useValue: {} },
          { provide: CorrespondencesService, useValue: { findOne: jest.fn() } },
          { provide: MailService, useValue: {} },
          { provide: AuditService, useValue: mockAudit },
          { provide: NotificationsService, useValue: mockNotifications },
          { provide: ConfigService, useValue: { get: jest.fn() } },
        ],
      }).compile();

      repliesService = module.get<RepliesService>(RepliesService);
    });

    it('سيناريو: إنشاء المسودة ينشئ الإصدار 1 ويحفظ نسخة غير قابلة للتعديل', async () => {
      mockPrisma.correspondence.findUnique.mockResolvedValue({
        id: 'corr-1',
        status: 'IN_PROGRESS',
        refNumber: 'INC-2026-001',
      });
      const createdReply = {
        id: 'reply-1',
        correspondenceId: 'corr-1',
        body: 'نص المسودة الأصلي',
        authorId: authorUser.id,
        version: 1,
        status: ReplyStatus.DRAFT,
      };
      mockPrisma.reply.create.mockResolvedValue(createdReply);

      const res = await repliesService.create(
        { correspondenceId: 'corr-1', body: 'نص المسودة الأصلي' },
        authorUser,
      );

      expect(res.id).toBe('reply-1');
      expect(mockPrisma.replyVersion.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            replyId: 'reply-1',
            version: 1,
            body: 'نص المسودة الأصلي',
            authorId: authorUser.id,
          }),
        }),
      );
    });

    it('سيناريو: تعديل المسودة بعد الرفض ينقلها إلى DRAFT ويزيد version بمقدار 1 ويحفظ نسخة جديدة', async () => {
      const rejectedReply = {
        id: 'reply-1',
        correspondenceId: 'corr-1',
        body: 'نص المسودة القديم',
        authorId: authorUser.id,
        version: 1,
        status: ReplyStatus.REJECTED,
        sentAt: null,
        correspondence: { refNumber: 'INC-2026-001' },
      };
      mockPrisma.reply.findUnique.mockResolvedValue(rejectedReply);
      mockPrisma.reply.update.mockResolvedValue({
        ...rejectedReply,
        status: ReplyStatus.DRAFT,
        version: 2,
        body: 'نص المسودة المعدل بعد الرفض',
      });

      const res = await repliesService.update(
        'reply-1',
        { body: 'نص المسودة المعدل بعد الرفض' },
        authorUser,
      );

      expect(mockPrisma.reply.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'reply-1' },
          data: expect.objectContaining({
            status: ReplyStatus.DRAFT,
            version: 2,
            body: 'نص المسودة المعدل بعد الرفض',
          }),
        }),
      );
      // حفظ نسخة الإصدار 2
      expect(mockPrisma.replyVersion.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            replyId: 'reply-1',
            version: 2,
            body: 'نص المسودة المعدل بعد الرفض',
          }),
        }),
      );
    });

    it('التجميد النهائي: يمنع تعديل أي رد أُرسل رسميًا للعميل', async () => {
      const sentReply = {
        id: 'reply-sent',
        correspondenceId: 'corr-1',
        body: 'الرد المعتمد والمرسل',
        authorId: authorUser.id,
        version: 2,
        status: ReplyStatus.APPROVED,
        sentAt: new Date(), // مرسل!
      };
      mockPrisma.reply.findUnique.mockResolvedValue(sentReply);

      await expect(
        repliesService.update('reply-sent', { body: 'محاولة تعديل بعد الإرسال' }, authorUser),
      ).rejects.toThrow('الرد أُرسل رسميًا وهو ثابت نهائيًا');
    });
  });
});
