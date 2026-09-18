import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { createHash } from 'crypto';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

/**
 * اختبارات وحدة لنظام Refresh Token مع التدوير (Rotation) والإبطال (Blacklist) (P0-2)
 */
describe('AuthService - Refresh Token & Blacklist (P0-2)', () => {
  let service: AuthService;

  const passwordHash = bcrypt.hashSync('Alfadaa@2026', 4);
  const activeUser = {
    id: 'user-refresh-1',
    name: 'مستخدم تجريبي',
    email: 'user@al-fadaa.com',
    passwordHash,
    role: 'EMPLOYEE' as const,
    isActive: true,
    departmentId: 'dept-1',
    lastLoginAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    phone: null,
    jobTitle: null,
    department: { id: 'dept-1', name: 'القسم التجريبي' },
  };

  const prismaMock = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    refreshToken: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
  };

  const jwtMock = {
    signAsync: jest.fn().mockResolvedValue('new-access-token'),
  };

  const auditMock = {
    log: jest.fn().mockResolvedValue(undefined),
  };

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
    jwtMock.signAsync.mockResolvedValue('new-access-token');
    auditMock.log.mockResolvedValue(undefined);
  });

  describe('loginWithRefresh', () => {
    it('يسجل الدخول بنجاح ويعيد accessToken و refreshToken مشفّراً ومحفوظاً', async () => {
      prismaMock.user.findUnique.mockResolvedValue({ ...activeUser });
      prismaMock.user.update.mockResolvedValue({ ...activeUser });
      prismaMock.refreshToken.create.mockResolvedValue({ id: 'ref-1' });

      const result = await service.loginWithRefresh(
        { email: 'user@al-fadaa.com', password: 'Alfadaa@2026' },
        { userAgent: 'Jest-Agent', ipAddress: '127.0.0.1' },
      );

      expect(result.accessToken).toBe('new-access-token');
      expect(result.refreshToken).toBeDefined();
      expect(typeof result.refreshToken).toBe('string');
      expect(result.refreshToken.length).toBe(96); // 48 bytes hex = 96 chars
      expect(result.user.email).toBe('user@al-fadaa.com');
      expect(result.user).not.toHaveProperty('passwordHash');

      // التحقق من حفظ الرمز مشفّراً بـ SHA-256 في قاعدة البيانات
      const expectedHash = createHash('sha256').update(result.refreshToken).digest('hex');
      expect(prismaMock.refreshToken.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            token: expectedHash,
            userId: activeUser.id,
            userAgent: 'Jest-Agent',
            ipAddress: '127.0.0.1',
          }),
        }),
      );
    });
  });

  describe('refreshTokens (Rotation)', () => {
    it('يقوم بتدوير الرمز بنجاح: يبطل القديم ويصدر رمزاً جديداً', async () => {
      const rawOldToken = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
      const oldHashedToken = createHash('sha256').update(rawOldToken).digest('hex');

      const storedToken = {
        id: 'token-uuid-1',
        token: oldHashedToken,
        userId: activeUser.id,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24), // صالح لمدة يوم
        user: { ...activeUser },
      };

      prismaMock.refreshToken.findUnique.mockResolvedValue(storedToken);
      prismaMock.refreshToken.create.mockResolvedValue({ id: 'token-uuid-2' });
      prismaMock.refreshToken.update.mockResolvedValue({ ...storedToken, revokedAt: new Date() });

      const result = await service.refreshTokens(rawOldToken, {
        userAgent: 'Jest-Agent-2',
        ipAddress: '127.0.0.1',
      });

      expect(result.accessToken).toBe('new-access-token');
      expect(result.refreshToken).toBeDefined();
      expect(result.refreshToken).not.toBe(rawOldToken);

      // التحقق من إبطال الرمز القديم وتدويره
      expect(prismaMock.refreshToken.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: storedToken.id },
          data: expect.objectContaining({
            revokedAt: expect.any(Date),
            replacedBy: result.refreshToken,
          }),
        }),
      );

      // التحقق من توليد رمز جديد في DB
      expect(prismaMock.refreshToken.create).toHaveBeenCalled();
    });

    it('يرفض تدوير رمز غير موجود في قاعدة البيانات (401)', async () => {
      prismaMock.refreshToken.findUnique.mockResolvedValue(null);

      await expect(service.refreshTokens('invalid-non-existent-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('يرفض تدوير رمز مبطل مسبقاً (Replay Attack / Revoked Token)', async () => {
      const rawToken = 'revoked-token-1234567890';
      const hashedToken = createHash('sha256').update(rawToken).digest('hex');

      prismaMock.refreshToken.findUnique.mockResolvedValue({
        id: 'token-revoked-1',
        token: hashedToken,
        userId: activeUser.id,
        revokedAt: new Date(), // مبطل!
        expiresAt: new Date(Date.now() + 1000 * 60),
        user: { ...activeUser },
      });

      await expect(service.refreshTokens(rawToken)).rejects.toThrow(
        'تم إبطال رمز التحديث — احتمال سرقة',
      );
    });

    it('يرفض تدوير رمز منتهي الصلاحية (Expired Token)', async () => {
      const rawToken = 'expired-token-1234567890';
      const hashedToken = createHash('sha256').update(rawToken).digest('hex');

      prismaMock.refreshToken.findUnique.mockResolvedValue({
        id: 'token-expired-1',
        token: hashedToken,
        userId: activeUser.id,
        revokedAt: null,
        expiresAt: new Date(Date.now() - 1000 * 60), // انتهى قبل دقيقة
        user: { ...activeUser },
      });

      await expect(service.refreshTokens(rawToken)).rejects.toThrow(
        'انتهت صلاحية رمز التحديث',
      );
    });

    it('يرفض التدوير إذا كان المستخدم معطلاً', async () => {
      const rawToken = 'valid-token-inactive-user';
      const hashedToken = createHash('sha256').update(rawToken).digest('hex');

      prismaMock.refreshToken.findUnique.mockResolvedValue({
        id: 'token-inactive-user-1',
        token: hashedToken,
        userId: activeUser.id,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 1000 * 60),
        user: { ...activeUser, isActive: false },
      });

      await expect(service.refreshTokens(rawToken)).rejects.toThrow('المستخدم غير متاح');
    });
  });

  describe('logout', () => {
    it('يبطل الرمز المحدد عند تسجيل الخروج', async () => {
      const rawToken = 'token-to-logout-123';
      const hashedToken = createHash('sha256').update(rawToken).digest('hex');

      prismaMock.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      const response = await service.logout(rawToken);

      expect(response.success).toBe(true);
      expect(prismaMock.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { token: hashedToken, revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('يتعامل بسلاسة عند تسجيل الخروج بدون تمرير رمز', async () => {
      const response = await service.logout();
      expect(response.success).toBe(true);
      expect(prismaMock.refreshToken.updateMany).not.toHaveBeenCalled();
    });
  });

  describe('revokeAllUserTokens', () => {
    it('يبطل جميع رموز المستخدم النشطة', async () => {
      prismaMock.refreshToken.updateMany.mockResolvedValue({ count: 3 });

      await service.revokeAllUserTokens('user-123');

      expect(prismaMock.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-123', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });
  });
});
