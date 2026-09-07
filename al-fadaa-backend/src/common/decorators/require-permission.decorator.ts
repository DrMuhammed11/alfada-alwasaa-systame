import { SetMetadata } from '@nestjs/common';
import { Permission } from '../../security/permissions';

export const PERMISSIONS_KEY = 'requiredPermissions';

/**
 * تحديد الصلاحيات المطلوبة لمسار ما — يُنفَّذ عبر PermissionsGuard.
 * يكفي امتلاك إحدى الصلاحيات المذكورة.
 * مثال: ‎@RequirePermission(Permission.CORR_SEND)‎
 */
export const RequirePermission = (...permissions: Permission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
