import { Role } from '@prisma/client';

/** المستخدم المستخرج من رمز JWT — متاح في الطلبات عبر ‎@CurrentUser()‎ */
export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: Role;
  departmentId?: string | null;
}

/** بيانات المستخدم الآمنة للعرض (بدون كلمة المرور المشفرة) */
export interface SafeUser {
  id: string;
  name: string;
  email: string;
  role: Role;
  phone: string | null;
  jobTitle: string | null;
  isActive: boolean;
  departmentId: string | null;
  department: { id: string; name: string } | null;
  lastLoginAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

/** شكل الاستجابة الموحد للقوائم المقسّمة إلى صفحات */
export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Paginated<T> {
  data: T[];
  meta: PageMeta;
}

export function buildPageMeta(page: number, limit: number, total: number): PageMeta {
  return { page, limit, total, totalPages: Math.max(1, Math.ceil(total / limit)) };
}
