import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthUser } from '../types';

/**
 * يستخرج المستخدم الحالي من الطلب.
 * ‎@CurrentUser()‎ → كائن المستخدم كاملًا
 * ‎@CurrentUser('id')‎ → حقل واحد فقط
 */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as AuthUser | undefined;
    return data ? user?.[data] : user;
  },
);
