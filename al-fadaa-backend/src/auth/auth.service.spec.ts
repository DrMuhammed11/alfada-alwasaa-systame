import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { createHash } from 'crypto';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

/** اختبارات وحدة لخدمة المصادقة — بدون قاعدة بيانات (Prisma مزيّف) */
describe('AuthService', () => {
  let service: AuthService;

  const passwordHash = bcrypt.hashSync('Alfadaa@2026', 4);
  const activeUser = {
    id: 'user-1',
    name: 'المدير العام',
    email: 'gm@al-fadaa.com',
    passwordHash,
    role: 'GM' as const,
    isActive: true,
    departmentId: 'dept-gen',
    lastLoginAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    phone: null,
    jobTitle: null,
    department: { id: 'dept-gen', name: 'الإدارة العامة' },
  };

  const prismaMock: any = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    $transaction: jest.fn().mockImplementation((cb: any) => {
      if (typeof cb === 'function') {
        return cb(prismaMock);
      }
      return Promise.all(cb);
    }),
  };
  const jwtMock = { signAsync: jest.fn().mockResolvedValue('fake-jwt-token') };
  const auditMock = { log: jest.fn().mockResolvedValue(undefined) };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: JwtService, useValue: jwtMock },
        { provide: AuditService, useValue: auditMock },
      ],
    }).compile();
    service = moduleRef.get(AuthService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
    jwtMock.signAsync.mockResolvedValue('fake-jwt-token');
    auditMock.log.mockResolvedValue(undefined);
    prismaMock.$transaction.mockImplementation((cb: any) => {
      if (typeof cb === 'function') {
        return cb(prismaMock);
      }
      return Promise.all(cb);
    });
  });

  describe('login', () => {
    it('يسمح بالدخول ببيانات صحيحة ويعيد رمز JWT', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ ...activeUser });
      prismaMock.user.update.mockResolvedValue({ ...activeUser });
      prismaMock.refreshToken.create.mockResolvedValue({});

      const result = await service.login({
        email: 'gm@al-fadaa.com',
        password: 'Alfadaa@2026',
      });

      expect(result.accessToken).toBe('fake-jwt-token');
      expect(result.user.email).toBe('gm@al-fadaa.com');
      expect(result.user).not.toHaveProperty('passwordHash');
      expect(prismaMock.user.update).toHaveBeenCalled();
      expect(auditMock.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'LOGIN', userId: 'user-1' }),
      );
    });

    it('يرفض كلمة مرور خاطئة (401)', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ ...activeUser });
      await expect(
        service.login({ email: 'gm@al-fadaa.com', password: 'Wrong@12345' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('يرفض بريدًا غير موجود (401) — دون كشف السبب', async () => {
      prismaMock.user.findUnique.mockResolvedValue(null);
      await expect(
        service.login({ email: 'nobody@al-fadaa.com', password: 'Whatever@1' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('يرفض حسابًا معطلًا (401)', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ ...activeUser, isActive: false });
      await expect(
        service.login({ email: 'gm@al-fadaa.com', password: 'Alfadaa@2026' }),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('refreshTokens (P0-4 أمن الجلسات وتدوير التوكن)', () => {
    const rawOldToken = 'old-raw-token-sample-string-1234567890';
    const hashedOldToken = createHash('sha256').update(rawOldToken).digest('hex');

    const validStoredToken = {
      id: 'token-uuid-1',
      token: hashedOldToken,
      userId: 'user-1',
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30),
      revokedAt: null,
      replacedBy: null,
      user: { ...activeUser },
    };

    it('(ج) replacedBy يخزن hash التوكن الجديد وليس التوكن الخام', async () => {
      prismaMock.refreshToken.findUnique.mockResolvedValue({ ...validStoredToken });
      let capturedReplacedBy: string | null = null;
      prismaMock.refreshToken.updateMany.mockImplementation(({ data }: any) => {
        if (data?.replacedBy) {
          capturedReplacedBy = data.replacedBy;
        }
        return Promise.resolve({ count: 1 });
      });
      prismaMock.refreshToken.create.mockResolvedValue({});

      const result = await service.refreshTokens(rawOldToken);

      expect(result.accessToken).toBe('fake-jwt-token');
      expect(result.refreshToken).toBeDefined();
      expect(capturedReplacedBy).not.toBeNull();
      // تأكيد أن القيمة المخزنة ليست التوكن الخام
      expect(capturedReplacedBy).not.toBe(result.refreshToken);
      // تأكيد أنها هاش SHA-256 (64 محرف سداسي عشري)
      expect(capturedReplacedBy).toHaveLength(64);
      expect(capturedReplacedBy).toBe(createHash('sha256').update(result.refreshToken).digest('hex'));
    });

    it('(أ) تجديدان متزامنان بنفس التوكن — واحد فقط ينجح والآخر يرفض (401)', async () => {
      prismaMock.refreshToken.findUnique.mockResolvedValue({ ...validStoredToken });
      let callCount = 0;
      prismaMock.refreshToken.updateMany.mockImplementation(() => {
        callCount++;
        // الطلب الأول يحدث بنجاح (count=1)، الطلب الثاني يجد count=0 بسبب السباق
        return Promise.resolve({ count: callCount === 1 ? 1 : 0 });
      });
      prismaMock.refreshToken.create.mockResolvedValue({});

      // الطلب الأول
      const firstResult = await service.refreshTokens(rawOldToken);
      expect(firstResult.accessToken).toBe('fake-jwt-token');

      // الطلب الثاني المتزامن
      await expect(service.refreshTokens(rawOldToken)).rejects.toThrow(UnauthorizedException);
    });

    it('(ب) استخدام توكن ملغى يبطل كل الجلسات (Family Revocation) ويسجل التدقيق token-reuse-detected', async () => {
      prismaMock.refreshToken.findUnique.mockResolvedValue({
        ...validStoredToken,
        revokedAt: new Date(Date.now() - 60000), // ملغى مسبقاً
      });
      prismaMock.refreshToken.updateMany.mockResolvedValue({ count: 2 });

      await expect(service.refreshTokens(rawOldToken)).rejects.toThrow(UnauthorizedException);

      // تأكيد إبطال كل جلسات المستخدم الأخرى غير الملغاة
      expect(prismaMock.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: expect.objectContaining({ revokedAt: expect.any(Date) }),
      });

      // تأكيد تسجيل حدث تدقيق نوعه token-reuse-detected
      expect(auditMock.log).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          summary: expect.stringContaining('token-reuse-detected'),
        }),
      );
    });
  });
});
