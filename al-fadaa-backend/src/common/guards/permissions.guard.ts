import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/require-permission.decorator';
import { PERMISSION_LABELS, ROLE_PERMISSIONS, Permission } from '../../security/permissions';
import type { AuthUser } from '../types';

/**
 * حارس الصلاحيات — يعمل مع ‎@RequirePermission(...)‎
 * يسمح بالمرور إذا امتلك دور المستخدم إحدى الصلاحيات المطلوبة.
 * المسارات غير الموسومة بـ RequirePermission تمر (بعد توثيق JWT).
 */
@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<Permission[] | undefined>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!required || required.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthUser | undefined;
    if (!user) return false;

    const granted = ROLE_PERMISSIONS[user.role] ?? [];
    const ok = required.some((p) => granted.includes(p));
    if (!ok) {
      const needed = required.map((p) => PERMISSION_LABELS[p] ?? p).join(' أو ');
      throw new ForbiddenException(`ليست لديك صلاحية تنفيذ هذا الإجراء (المطلوب: ${needed})`);
    }
    return true;
  }
}
