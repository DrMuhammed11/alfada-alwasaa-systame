import { Role } from '@prisma/client';

/**
 * صلاحيات النظام — مطابقة لمصفوفة الصلاحيات المعتمدة
 * (المخطط 04: هيكل الأدوار والصلاحيات)
 */
export enum Permission {
  USERS_MANAGE = 'USERS_MANAGE',
  DEPARTMENTS_MANAGE = 'DEPARTMENTS_MANAGE',
  CORR_VIEW_ALL = 'CORR_VIEW_ALL',
  CORR_REGISTER = 'CORR_REGISTER',
  CORR_REFER = 'CORR_REFER',
  CORR_ARCHIVE = 'CORR_ARCHIVE',
  TASK_ASSIGN = 'TASK_ASSIGN',
  REPLY_DRAFT = 'REPLY_DRAFT',
  REPLY_SUBMIT = 'REPLY_SUBMIT',
  REPLY_APPROVE = 'REPLY_APPROVE',
  CORR_SEND = 'CORR_SEND',
  AUDIT_VIEW = 'AUDIT_VIEW',
  CONTENT_MANAGE = 'CONTENT_MANAGE',
}

/** مصفوفة الصلاحيات: كل دور ← الصلاحيات الممنوحة له */
export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  ADMIN: [
    Permission.USERS_MANAGE,
    Permission.DEPARTMENTS_MANAGE,
    Permission.AUDIT_VIEW,
    Permission.CORR_VIEW_ALL,
    Permission.CONTENT_MANAGE,
    // الإدارة العليا تعامل كمعتمِد ومرسل مطلق في سياسات الأعمال
    Permission.REPLY_APPROVE,
    Permission.CORR_SEND,
  ],
  GM: [
    Permission.USERS_MANAGE,       // إدارة المستخدمين — مشتركة مع ADMIN وفق المخطط
    Permission.CORR_VIEW_ALL,
    Permission.CORR_REGISTER,
    Permission.CORR_REFER,
    Permission.CORR_ARCHIVE,
    Permission.TASK_ASSIGN,
    Permission.REPLY_DRAFT,
    Permission.REPLY_SUBMIT,
    Permission.REPLY_APPROVE,
    Permission.CORR_SEND,
    Permission.AUDIT_VIEW,
  ],
  DEPUTY_GM: [
    Permission.CORR_VIEW_ALL,
    Permission.CORR_REFER,
    Permission.TASK_ASSIGN,
    Permission.REPLY_DRAFT,
    Permission.REPLY_SUBMIT,
    Permission.REPLY_APPROVE,
    Permission.CORR_SEND,   // إرسال بالتوكيل — وفق المخطط
    Permission.AUDIT_VIEW,  // قراءة فقط — وفق المخطط
  ],
  DEPT_MANAGER: [
    Permission.CORR_REFER,    // إحالة داخل القسم فقط — وفق المخطط
    Permission.TASK_ASSIGN,
    Permission.REPLY_DRAFT,
    Permission.REPLY_SUBMIT,
    Permission.REPLY_APPROVE,
    Permission.AUDIT_VIEW,    // قراءة فقط — وفق المخطط
  ],
  EMPLOYEE: [Permission.REPLY_DRAFT, Permission.REPLY_SUBMIT],
};

/** أسماء عربية للصلاحيات — للعرض ورسائل الرفض */
export const PERMISSION_LABELS: Record<Permission, string> = {
  USERS_MANAGE: 'إدارة المستخدمين',
  DEPARTMENTS_MANAGE: 'إدارة الأقسام',
  CORR_VIEW_ALL: 'الاطلاع على كل المراسلات',
  CORR_REGISTER: 'تسجيل المراسلات الواردة',
  CORR_REFER: 'إحالة المراسلات',
  CORR_ARCHIVE: 'إغلاق وأرشفة المراسلات',
  TASK_ASSIGN: 'تكليف الموظفين',
  REPLY_DRAFT: 'إعداد مسودات الردود',
  REPLY_SUBMIT: 'رفع الردود للاعتماد',
  REPLY_APPROVE: 'اعتماد الردود ورفضها',
  CORR_SEND: 'إرسال الردود للعملاء',
  AUDIT_VIEW: 'الاطلاع على سجل التدقيق',
  CONTENT_MANAGE: 'إدارة محتويات الموقع الإلكتروني',
};

export function hasPermission(role: Role, permission: Permission): boolean {
  return (ROLE_PERMISSIONS[role] ?? []).includes(permission);
}
