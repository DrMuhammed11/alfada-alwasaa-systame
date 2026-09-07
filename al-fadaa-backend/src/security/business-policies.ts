import {
  CorrespondenceStatus,
  CorrespondenceType,
  ReplyStatus,
  Role,
} from '@prisma/client';
import {
  canTransition,
  CorrespondenceAction,
} from '../workflow/correspondence-state-machine';

/**
 * ════════════════════════════════════════════════════════════════════════════════
 * جدول قرار قواعد الأعمال والصلاحيات (Business Policies & Decision Matrix)
 * ════════════════════════════════════════════════════════════════════════════════
 * يطابق مصفوفة الأدوار الخمسة المعتمدة في النظام:
 *
 * ┌──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
 * │ الدور        │ إحالة        │ تكليف        │ اعتماد / رفض │ إرسال نهائي  │ إغلاق        │ أرشفة        │
 * ├──────────────┼──────────────┼──────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
 * │ ADMIN        │ ❌ غير متاح  │ ❌ غير متاح  │ ✅ إدارة عامة│ ✅ مسموح     │ ✅ مسموح     │ ✅ مسموح     │
 * │ GM           │ ✅ للنائب/المدراء│ ✅ لأي موظف │ ✅ مسموح     │ ✅ مسموح     │ ✅ مسموح     │ ✅ مسموح     │
 * │ DEPUTY_GM    │ ✅ للمدراء فقط│ ✅ لأي موظف │ ✅ مسموح     │ ✅ بالتوكيل  │ ✅ مسموح     │ ✅ مسموح     │
 * │ DEPT_MANAGER │ ✅ لموظفي قسمه│ ✅ لموظفي قسمه│ ✅ لقسمه/المحال│ ❌ غير مصرح │ ❌ غير مصرح  │ ❌ غير مصرح  │
 * │ EMPLOYEE     │ ❌ غير مصرح  │ ❌ غير مصرح  │ ❌ غير مصرح  │ ❌ غير مصرح  │ ❌ غير مصرح  │ ❌ غير مصرح  │
 * └──────────────┴──────────────┴──────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
 *
 * القواعد الجوهرية الإلزامية:
 * 1. منع الإحالة للنفس مطلقاً لكافة الأدوار.
 * 2. منع اعتماد أو رفض أي رد أعدّه المستخدم بنفسه (فصل الاختصاص).
 * 3. حصر نطاق مدير القسم في موظفي قسمه ومراسلاته فقط.
 * 4. حصر الإرسال النهائي وإغلاق وأرشفة المعاملات بالإدارة العليا.
 * ════════════════════════════════════════════════════════════════════════════════
 */

export interface PolicyResult {
  allowed: boolean;
  reason?: string;
}

export interface UserContext {
  id: string;
  role: Role | string;
  name?: string;
  email?: string;
  departmentId?: string | null;
  isActive?: boolean;
}

export interface CorrespondenceContext {
  id: string;
  status: CorrespondenceStatus;
  type?: CorrespondenceType;
  departmentId?: string | null;
  senderEmail?: string | null;
}

export interface ReplyContext {
  id: string;
  authorId: string;
  status: ReplyStatus;
  sentAt?: Date | null;
}

export interface ReferralContext {
  id?: string;
  fromUserId: string;
  toUserId: string;
}

export const ROLE_LABELS: Record<Role, string> = {
  GM: 'المدير العام',
  DEPUTY_GM: 'نائب المدير العام',
  DEPT_MANAGER: 'مدير قسم',
  EMPLOYEE: 'موظف',
  ADMIN: 'مدير النظام',
};

/**
 * 1. سياسة الإحالة (canRefer):
 *  - فحص توفر ونشاط المحال إليه
 *  - منع الإحالة للنفس
 *  - تطبيق مصفوفة التسلسل الإداري للإحالة
 *  - إلزام مدير القسم بموظفي قسمه فقط
 */
export function canRefer(
  user: UserContext,
  target: UserContext | null | undefined,
  corr?: CorrespondenceContext,
): PolicyResult {
  if (!target || target.isActive === false) {
    return { allowed: false, reason: 'المستخدم المحال إليه غير متوفر' };
  }

  if (target.id === user.id) {
    return { allowed: false, reason: 'لا يمكن إحالة المراسلة إلى نفسك' };
  }

  const allowedTargets: Role[] =
    user.role === Role.GM
      ? [Role.DEPUTY_GM, Role.DEPT_MANAGER]
      : user.role === Role.DEPUTY_GM
        ? [Role.DEPT_MANAGER]
        : user.role === Role.DEPT_MANAGER
          ? [Role.EMPLOYEE]
          : [];

  if (!allowedTargets.includes(target.role as Role)) {
    const allowedNames = allowedTargets.map((r) => ROLE_LABELS[r] ?? r).join(' / ');
    return {
      allowed: false,
      reason:
        allowedTargets.length > 0
          ? `بصفتك (${ROLE_LABELS[user.role as Role] ?? user.role})، الإحالة مسموحة فقط إلى: ${allowedNames}`
          : 'ليس لديك صلاحية إحالة المراسلات',
    };
  }

  if (user.role === Role.DEPT_MANAGER) {
    if (!user.departmentId || target.departmentId !== user.departmentId) {
      return {
        allowed: false,
        reason: 'بصفتك مدير قسم يمكنك الإحالة لموظفي قسمك فقط',
      };
    }
  }

  return { allowed: true };
}

/**
 * 2. سياسة التكليف (canAssignTask):
 *  - المراسلة ليست مغلقة أو مؤرشفة
 *  - فحص وجود ونشاط الموظف المكلف
 *  - صلاحية التكليف: GM, DEPUTY_GM, DEPT_MANAGER
 *  - مدير القسم يكلف موظفي قسمه فقط
 */
export function canAssignTask(
  user: UserContext,
  target: UserContext | null | undefined,
  corr?: CorrespondenceContext,
): PolicyResult {
  if (
    corr &&
    (corr.status === CorrespondenceStatus.CLOSED ||
      corr.status === CorrespondenceStatus.ARCHIVED)
  ) {
    return {
      allowed: false,
      reason: 'لا يمكن إنشاء تكليف على مراسلة مغلقة أو مؤرشفة',
    };
  }

  if (!target || target.isActive === false) {
    return { allowed: false, reason: 'الموظف المكلَّف غير متوفر أو غير نشط' };
  }

  if (user.role === Role.EMPLOYEE) {
    return { allowed: false, reason: 'ليس لديك صلاحية تكليف الموظفين' };
  }

  if (user.role === Role.DEPT_MANAGER) {
    if (target.role !== Role.EMPLOYEE) {
      return { allowed: false, reason: 'مدير القسم يكلّف موظفي قسمه فقط' };
    }
    if (!user.departmentId || target.departmentId !== user.departmentId) {
      return {
        allowed: false,
        reason: 'بصفتك مدير قسم يمكنك تكليف موظفي قسمك فقط',
      };
    }
  }

  return { allowed: true };
}

/**
 * 3. سياسة اعتماد الرد (canApproveReply):
 *  - الرد في حالة SUBMITTED
 *  - لا يجوز اعتماد رد صاغه المعتمد بنفسه
 *  - مدير القسم يعتمد لمراسلات قسمه أو المحالة إليه فقط
 */
export function canApproveReply(
  user: UserContext,
  reply: ReplyContext,
  corr: CorrespondenceContext,
  openReferrals?: ReferralContext[],
): PolicyResult {
  if (reply.status !== ReplyStatus.SUBMITTED) {
    return { allowed: false, reason: 'الرد غير مرفوع للاعتماد' };
  }

  if (reply.authorId === user.id) {
    return {
      allowed: false,
      reason: 'لا يمكنك اعتماد أو رفض رد أعددته بنفسك',
    };
  }

  if (user.role === Role.EMPLOYEE) {
    return { allowed: false, reason: 'ليس لديك صلاحية اعتماد الردود' };
  }

  if (user.role === Role.DEPT_MANAGER) {
    const inMyDept =
      !!user.departmentId && corr.departmentId === user.departmentId;
    const referredToMe = (openReferrals ?? []).some(
      (r) => r.toUserId === user.id,
    );
    if (!inMyDept && !referredToMe) {
      return {
        allowed: false,
        reason: 'يمكنك اعتماد ردود مراسلات قسمك أو المحالة إليك فقط',
      };
    }
  }

  return { allowed: true };
}

/**
 * 4. سياسة الإرسال النهائي للعميل (canSendReply):
 *  - محصورة بالإدارة العليا (GM, ADMIN, DEPUTY_GM)
 *  - الرد معتمد (أو حالة مباشرة للمدير العام)
 *  - لم يُرسل مسبقاً
 *  - مراسلة واردة ولها بريد إلكتروني
 */
export function canSendReply(
  user: UserContext,
  reply: ReplyContext,
  corr: CorrespondenceContext,
): PolicyResult {
  const isExecutive =
    user.role === Role.GM ||
    user.role === Role.ADMIN ||
    user.role === Role.DEPUTY_GM;

  if (!isExecutive) {
    return {
      allowed: false,
      reason: 'صلاحية الإرسال النهائي للعملاء محصورة بالإدارة العليا',
    };
  }

  if (
    reply.status !== ReplyStatus.APPROVED &&
    !(
      (user.role === Role.GM || user.role === Role.ADMIN) &&
      (reply.status === ReplyStatus.DRAFT ||
        reply.status === ReplyStatus.SUBMITTED)
    )
  ) {
    return { allowed: false, reason: 'لا يمكن إرسال رد غير معتمد' };
  }

  if (reply.sentAt) {
    return { allowed: false, reason: 'تم إرسال هذا الرد مسبقًا' };
  }

  if (corr.type && corr.type !== CorrespondenceType.INCOMING) {
    return {
      allowed: false,
      reason: 'الإرسال متاح للردود على المراسلات الواردة',
    };
  }

  if (!corr.senderEmail) {
    return {
      allowed: false,
      reason: 'لا يوجد بريد إلكتروني للمرسل — حدّث بيانات المراسلة أولًا',
    };
  }

  return { allowed: true };
}

/**
 * 5. سياسة إغلاق المراسلة (canCloseCorrespondence):
 *  - محصورة بالإدارة العليا
 *  - المراسلة في حالة قابلة للإغلاق وفق آلة الحالات
 */
export function canCloseCorrespondence(
  user: UserContext,
  corr: CorrespondenceContext,
): PolicyResult {
  const isExecutive =
    user.role === Role.GM ||
    user.role === Role.ADMIN ||
    user.role === Role.DEPUTY_GM;

  if (!isExecutive) {
    return {
      allowed: false,
      reason: 'إغلاق المراسلات محصور بالإدارة العليا',
    };
  }

  if (!canTransition(corr.status, CorrespondenceAction.CLOSE)) {
    return {
      allowed: false,
      reason: `لا يمكن إغلاق المراسلة — حالتها الحالية «${corr.status}»`,
    };
  }

  return { allowed: true };
}

/**
 * 6. سياسة أرشفة المراسلة (canArchiveCorrespondence):
 *  - محصورة بالإدارة العليا
 *  - المراسلة في حالة قابلة للأرشفة وفق آلة الحالات
 */
export function canArchiveCorrespondence(
  user: UserContext,
  corr: CorrespondenceContext,
): PolicyResult {
  const isExecutive =
    user.role === Role.GM ||
    user.role === Role.ADMIN ||
    user.role === Role.DEPUTY_GM;

  if (!isExecutive) {
    return {
      allowed: false,
      reason: 'أرشفة المراسلات محصورة بالإدارة العليا',
    };
  }

  if (!canTransition(corr.status, CorrespondenceAction.ARCHIVE)) {
    return {
      allowed: false,
      reason: `لا يمكن أرشفة المراسلة — حالتها الحالية «${corr.status}»`,
    };
  }

  return { allowed: true };
}
