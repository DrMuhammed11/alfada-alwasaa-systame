import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuditAction } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import type { SafeUser } from '../common/types';
import { LoginDto } from './dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly audit: AuditService,
  ) {}

  /** تسجيل الدخول: تحقق من البيانات → إصدار JWT → تسجيل الحدث في سجل التدقيق */
  async login(dto: LoginDto): Promise<{ accessToken: string; user: SafeUser }> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
      include: { department: { select: { id: true, name: true } } },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

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
}
