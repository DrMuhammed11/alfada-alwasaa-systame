import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { setContextUser } from '../common/context/request-context';
import type { AuthUser } from '../common/types';

export interface JwtPayload {
  sub: string;
  email: string;
  name: string;
  role: AuthUser['role'];
  departmentId?: string | null;
}

/** استراتيجية JWT — تتحقق من كل رمز Bearer وتُلحق المستخدم بـ request.user */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_SECRET') ?? 'alfadaa-dev-secret',
    });
  }

  /** تُنفَّذ لكل طلب موثَّق — نتيجتها تصبح request.user */
  async validate(payload: JwtPayload): Promise<AuthUser> {
    const user: AuthUser = {
      id: payload.sub,
      email: payload.email,
      name: payload.name,
      role: payload.role,
      departmentId: payload.departmentId ?? null,
    };
    if (!user.id) throw new UnauthorizedException('رمز المصادقة غير صالح');
    // ربط المستخدم بسياق الطلب — تستفيد منه خدمة سجل التدقيق تلقائيًا
    setContextUser(user);
    return user;
  }
}
