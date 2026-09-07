import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
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

  const prismaMock = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
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
  });

  it('يسمح بالدخول ببيانات صحيحة ويعيد رمز JWT', async () => {
    prismaMock.user.findUnique.mockResolvedValue({ ...activeUser });
    prismaMock.user.update.mockResolvedValue({ ...activeUser });

    const result = await service.login({
      email: 'gm@al-fadaa.com',
      password: 'Alfadaa@2026',
    });

    expect(result.accessToken).toBe('fake-jwt-token');
    expect(result.user.email).toBe('gm@al-fadaa.com');
    // لا تُعاد كلمة المرور المشفرة إطلاقًا
    expect(result.user).not.toHaveProperty('passwordHash');
    // حُدِّث وقت آخر دخول
    expect(prismaMock.user.update).toHaveBeenCalled();
    // سُجِّل حدث الدخول في سجل التدقيق
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
