import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditAction } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { randomBytes, createHash } from 'crypto';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import type { SafeUser } from '../common/types';
import { LoginDto, ChangePasswordDto } from './dto';

/** عتبات قفل الحساب: 5 محاولات فاشلة ⇒ قفل 15 دقيقة */
const MAX_FAILED_ATTEMPTS = 5;
const LOCK_MINUTES = 15;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly audit: AuditService,
  ) {}

  /**
   * منطق المصادقة المشترك: جلب المستخدم، فحص القفل، التحقق من كلمة المرور،
   * وتحديث عدّاد المحاولات الفاشلة (قفل عند التكرار، تصفير عند النجاح).
   */
  private async authenticate(email: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
      include: { department: { select: { id: true, name: true } } },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      const minutes = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
      throw new UnauthorizedException(
        `الحساب مقفل مؤقتًا بسبب محاولات دخول فاشلة متكررة — أعد المحاولة بعد ${minutes} دقيقة`,
      );
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      const attempts = user.failedLoginAttempts + 1;
      const lock = attempts >= MAX_FAILED_ATTEMPTS;
      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          failedLoginAttempts: lock ? 0 : attempts,
          ...(lock ? { lockedUntil: new Date(Date.now() + LOCK_MINUTES * 60 * 1000) } : {}),
        },
      });
      if (lock) {
        await this.audit.log({
          action: AuditAction.LOGIN,
          userId: user.id,
          entityType: 'User',
          entityId: user.id,
          summary: `قفل مؤقت للحساب ${user.email} بعد ${MAX_FAILED_ATTEMPTS} محاولات دخول فاشلة (${LOCK_MINUTES} دقيقة)`,
        });
        throw new UnauthorizedException(
          `كلمة المرور غير صحيحة — قُفل الحساب ${LOCK_MINUTES} دقيقة بعد تكرار المحاولات`,
        );
      }
      throw new UnauthorizedException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    if (user.failedLoginAttempts > 0 || user.lockedUntil) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: 0, lockedUntil: null },
      });
    }
    return user;
  }

  /** تسجيل الدخول: تحقق من البيانات → إصدار JWT → تسجيل الحدث في سجل التدقيق */
  async login(dto: LoginDto): Promise<{ accessToken: string; user: SafeUser }> {
    const user = await this.authenticate(dto.email, dto.password);

    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      departmentId: user.departmentId,
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    await this.audit.log({
      action: AuditAction.LOGIN,
      userId: user.id,
      entityType: 'User',
      entityId: user.id,
      summary: `تسجيل دخول: ${user.name} (${user.email})`,
    });

    const { passwordHash: _hash, ...safeUser } = user;
    return { accessToken, user: safeUser as SafeUser };
  }

  /** توليد زوج (access + refresh) — برومت P0-2 */
  async loginWithRefresh(
    dto: LoginDto,
    meta?: { userAgent?: string; ipAddress?: string },
  ): Promise<{ accessToken: string; refreshToken: string; user: SafeUser }> {
    const user = await this.authenticate(dto.email, dto.password);

    const accessExpiresIn = (process.env.JWT_ACCESS_EXPIRES_IN || process.env.JWT_EXPIRES_IN || '15m') as any;
    const accessToken = await this.jwt.signAsync(
      {
        sub: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        departmentId: user.departmentId,
      },
      { expiresIn: accessExpiresIn },
    );

    const refreshToken = await this.generateRefreshToken(user.id, meta);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    await this.audit.log({
      action: AuditAction.LOGIN,
      userId: user.id,
      entityType: 'User',
      entityId: user.id,
      summary: `تسجيل دخول (مع رمز التحديث): ${user.name} (${user.email})`,
    });

    const { passwordHash: _hash, ...safeUser } = user;
    return { accessToken, refreshToken, user: safeUser as SafeUser };
  }

  /** توليد refresh token وحفظه مشفّراً في DB عبر SHA-256 */
  async generateRefreshToken(
    userId: string,
    meta?: { userAgent?: string; ipAddress?: string },
  ): Promise<string> {
    const rawToken = randomBytes(48).toString('hex');
    const hashedToken = createHash('sha256').update(rawToken).digest('hex');
    const days = parseInt(process.env.JWT_REFRESH_EXPIRES_IN_DAYS || '30', 10);

    await this.prisma.refreshToken.create({
      data: {
        token: hashedToken,
        userId,
        userAgent: meta?.userAgent,
        ipAddress: meta?.ipAddress,
        expiresAt: new Date(Date.now() + days * 24 * 60 * 60 * 1000),
      },
    });

    return rawToken;
  }

  /** تدوير الـ refresh token (rotation) — يبطل القديم ويصدر جديد */
  async refreshTokens(
    rawRefreshToken: string,
    meta?: { userAgent?: string; ipAddress?: string },
  ): Promise<{ accessToken: string; refreshToken: string }> {
    if (!rawRefreshToken || typeof rawRefreshToken !== 'string') {
      throw new UnauthorizedException('رمز التحديث غير صالح');
    }

    const hashedToken = createHash('sha256').update(rawRefreshToken).digest('hex');

    const stored = await this.prisma.refreshToken.findUnique({
      where: { token: hashedToken },
      include: { user: true },
    });

    if (!stored) throw new UnauthorizedException('رمز التحديث غير صالح');
    if (stored.revokedAt) throw new UnauthorizedException('تم إبطال رمز التحديث — احتمال سرقة');
    if (stored.expiresAt < new Date()) throw new UnauthorizedException('انتهت صلاحية رمز التحديث');
    if (!stored.user || !stored.user.isActive) throw new UnauthorizedException('المستخدم غير متاح');

    // إبطال القديم + توليد جديد (rotation)
    const newRawToken = await this.generateRefreshToken(stored.userId, meta);

    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: {
        revokedAt: new Date(),
        replacedBy: newRawToken, // ربط للمراجعة
      },
    });

    const accessExpiresIn = (process.env.JWT_ACCESS_EXPIRES_IN || process.env.JWT_EXPIRES_IN || '15m') as any;
    const accessToken = await this.jwt.signAsync(
      {
        sub: stored.user.id,
        email: stored.user.email,
        name: stored.user.name,
        role: stored.user.role,
        departmentId: stored.user.departmentId,
      },
      { expiresIn: accessExpiresIn },
    );

    return { accessToken, refreshToken: newRawToken };
  }

  /** مهمة مجدولة (Cron Job): تنظيف رموز التحديث المنتهية الصلاحية أو المبطلة كل 24 ساعة */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async cleanupExpiredTokens(): Promise<number> {
    const now = new Date();
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: now } },
          { revokedAt: { not: null } },
        ],
      },
    });
    return result.count;
  }

  /** تسجيل خروج — إبطال refresh token محدد */
  async logout(rawRefreshToken?: string): Promise<{ success: boolean; message: string }> {
    if (rawRefreshToken && typeof rawRefreshToken === 'string') {
      const hashedToken = createHash('sha256').update(rawRefreshToken).digest('hex');
      await this.prisma.refreshToken.updateMany({
        where: { token: hashedToken, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { success: true, message: 'تم تسجيل الخروج بنجاح' };
  }

  /** إبطال كل رموز مستخدم (للأمان عند تغيير كلمة المرور) */
  async revokeAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /** بيانات المستخدم الحالي (من الرمز) */
  async me(userId: string): Promise<SafeUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { department: { select: { id: true, name: true } } },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('الحساب غير متاح');
    }
    const { passwordHash: _hash, ...safe } = user;
    return safe as SafeUser;
  }

  /**
   * تغيير كلمة المرور الذاتي — المسار الوحيد لتبديل كلمة مرور حساب قائم:
   * تحقق من الحالية → سياسة قوية للجديدة → إبطال كل جلسات المستخدم فورًا.
   */
  async changePassword(userId: string, dto: ChangePasswordDto): Promise<{ success: boolean; message: string }> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.isActive) throw new UnauthorizedException('الحساب غير متاح');

    const currentValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!currentValid) throw new UnauthorizedException('كلمة المرور الحالية غير صحيحة');

    if (await bcrypt.compare(dto.newPassword, user.passwordHash)) {
      throw new BadRequestException('كلمة المرور الجديدة مطابقة للحالية — اختر كلمة مرور مختلفة');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash: await bcrypt.hash(dto.newPassword, 10) },
      }),
      // إبطال كل رموز التحديث الحية — الجلسات الحالية تنتهي مع انتهاء رمز الوصول (15 دقيقة كحد أقصى)
      this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    await this.audit.log({
      action: AuditAction.UPDATE,
      userId,
      entityType: 'User',
      entityId: userId,
      summary: `تغيير كلمة المرور الذاتي وإبطال كل الجلسات: ${user.email}`,
    });

    return { success: true, message: 'تم تغيير كلمة المرور وإبطال الجلسات الأخرى — سجّل الدخول من جديد' };
  }
}
