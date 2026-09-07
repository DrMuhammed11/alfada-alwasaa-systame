import { AsyncLocalStorage } from 'node:async_hooks';
import type { AuthUser } from '../types';

export interface RequestContextData {
  requestId?: string;
  userId?: string;
  role?: string;
  ip?: string;
  userAgent?: string;
}

/**
 * سياق الطلب عبر AsyncLocalStorage — يجعل (IP / المتصفح / المستخدم)
 * متاحًا في أي طبقة دون تمرير كائن الطلب يدويًا.
 * تستهلكه خدمة سجل التدقيق تلقائيًا لكل حدث.
 */
export const requestContextStorage = new AsyncLocalStorage<RequestContextData>();

export function getRequestContext(): RequestContextData {
  return requestContextStorage.getStore() ?? {};
}

/** يُستدعى من JwtStrategy لربط المستخدم بسياق الطلب بعد التحقق من الرمز */
export function setContextUser(user: AuthUser): void {
  const store = requestContextStorage.getStore();
  if (store) {
    store.userId = user.id;
    store.role = user.role;
  }
}
