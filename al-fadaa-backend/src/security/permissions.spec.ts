import { Role } from '@prisma/client';
import {
  hasPermission,
  Permission,
  ROLE_PERMISSIONS,
} from './permissions';

/**
 * اختبارات مصفوفة الصلاحيات —
 * تطابق المصفوفة المعتمدة في المخطط الرابع (هيكل الأدوار والصلاحيات).
 */
describe('مصفوفة الصلاحيات', () => {
  it('المدير العام ونائبه يملكان صلاحية الإرسال — الموظف ومدير القسم لا', () => {
    // GM: إرسال نهائي | DEPUTY_GM: إرسال بالتوكيل — وفق المخطط
    expect(hasPermission(Role.GM, Permission.CORR_SEND)).toBe(true);
    expect(hasPermission(Role.DEPUTY_GM, Permission.CORR_SEND)).toBe(true);
    expect(hasPermission(Role.DEPT_MANAGER, Permission.CORR_SEND)).toBe(false);
    expect(hasPermission(Role.EMPLOYEE, Permission.CORR_SEND)).toBe(false);
    // ADMIN يعامل كمعتمِد ومرسل مطلق في سياسات الأعمال — حُدِّث ليطابق المصفوفة
    expect(hasPermission(Role.ADMIN, Permission.CORR_SEND)).toBe(true);
  });

  it('الموظف يعدّ المسودات ويرفعها فقط — لا يعتمد ولا يحيل', () => {
    expect(hasPermission(Role.EMPLOYEE, Permission.REPLY_DRAFT)).toBe(true);
    expect(hasPermission(Role.EMPLOYEE, Permission.REPLY_SUBMIT)).toBe(true);
    expect(hasPermission(Role.EMPLOYEE, Permission.REPLY_APPROVE)).toBe(false);
    expect(hasPermission(Role.EMPLOYEE, Permission.CORR_REFER)).toBe(false);
  });

  it('مدير القسم يعتمد الردود ويكلّف ويحيل داخل قسمه — وفق المخطط', () => {
    expect(hasPermission(Role.DEPT_MANAGER, Permission.REPLY_APPROVE)).toBe(true);
    expect(hasPermission(Role.DEPT_MANAGER, Permission.TASK_ASSIGN)).toBe(true);
    // مدير القسم يملك صلاحية الإحالة داخل قسمه فقط — وفق المخطط الرابع
    expect(hasPermission(Role.DEPT_MANAGER, Permission.CORR_REFER)).toBe(true);
    // مدير القسم لا يرسل للعميل ولا يدير مستخدمين
    expect(hasPermission(Role.DEPT_MANAGER, Permission.CORR_SEND)).toBe(false);
    expect(hasPermission(Role.DEPT_MANAGER, Permission.USERS_MANAGE)).toBe(false);
  });

  it('مسؤول النظام يدير المستخدمين والأقسام ويطّلع على سجل التدقيق', () => {
    expect(hasPermission(Role.ADMIN, Permission.USERS_MANAGE)).toBe(true);
    expect(hasPermission(Role.ADMIN, Permission.DEPARTMENTS_MANAGE)).toBe(true);
    expect(hasPermission(Role.ADMIN, Permission.AUDIT_VIEW)).toBe(true);
    expect(hasPermission(Role.ADMIN, Permission.CORR_VIEW_ALL)).toBe(true);
  });

  it('المدير العام ونائبه يطلعان على كل المراسلات — الموظف لا', () => {
    expect(hasPermission(Role.GM, Permission.CORR_VIEW_ALL)).toBe(true);
    expect(hasPermission(Role.DEPUTY_GM, Permission.CORR_VIEW_ALL)).toBe(true);
    expect(hasPermission(Role.EMPLOYEE, Permission.CORR_VIEW_ALL)).toBe(false);
  });

  it('كل دور له صلاحية واحدة على الأقل والمصفوفة مكتملة للأدوار الخمسة', () => {
    const allRoles: Role[] = ['ADMIN', 'GM', 'DEPUTY_GM', 'DEPT_MANAGER', 'EMPLOYEE'];
    for (const role of allRoles) {
      expect(ROLE_PERMISSIONS[role].length).toBeGreaterThan(0);
    }
  });
});
