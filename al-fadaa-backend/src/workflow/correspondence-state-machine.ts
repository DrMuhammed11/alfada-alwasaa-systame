import { BadRequestException } from '@nestjs/common';
import { CorrespondenceStatus } from '@prisma/client';

/**
 * إجراءات دورة حياة المراسلة
 */
export enum CorrespondenceAction {
  REVIEW = 'REVIEW',                 // دراسة المراسلة من قِبل المدير العام
  REFER = 'REFER',                   // إحالة المراسلة لنائب المدير أو مديري الأقسام
  START_DRAFT = 'START_DRAFT',       // بدء إعداد مسودة رد أو تكليف
  SUBMIT_REPLY = 'SUBMIT_REPLY',     // رفع مسودة الرد للاعتماد
  APPROVE_REPLY = 'APPROVE_REPLY',   // اعتماد مسودة الرد
  REJECT_REPLY = 'REJECT_REPLY',     // رفض الرد وإعادته للموظف لتعديله
  SEND_REPLY = 'SEND_REPLY',         // إرسال الرد النهائي المعتمد للعميل
  CLOSE = 'CLOSE',                   // إغلاق المراسلة
  ARCHIVE = 'ARCHIVE',               // أرشفة المراسلة
  REOPEN = 'REOPEN',                 // إعادة فتح المراسلة عند ورود تعقيب جديد من العميل
}

/**
 * التسميات العربية لحالات المراسلة
 */
export const CORRESPONDENCE_STATUS_LABELS: Record<CorrespondenceStatus, string> = {
  RECEIVED: 'مستلمة',
  UNDER_REVIEW: 'قيد الدراسة',
  REFERRED: 'محالة',
  IN_PROGRESS: 'جارٍ الإعداد',
  PENDING_APPROVAL: 'بانتظار الاعتماد',
  APPROVED: 'معتمدة',
  SENT: 'مُرسلة',
  CLOSED: 'مغلقة',
  ARCHIVED: 'مؤرشفة',
};

/**
 * التسميات العربية لإجراءات المراسلة
 */
export const CORRESPONDENCE_ACTION_LABELS: Record<CorrespondenceAction, string> = {
  REVIEW: 'دراسة المراسلة',
  REFER: 'إحالة المراسلة',
  START_DRAFT: 'إعداد رد',
  SUBMIT_REPLY: 'رفع الرد للاعتماد',
  APPROVE_REPLY: 'اعتماد الرد',
  REJECT_REPLY: 'رفض الرد وإعادته للمسودة',
  SEND_REPLY: 'إرسال الرد',
  CLOSE: 'إغلاق المراسلة',
  ARCHIVE: 'أرشفة المراسلة',
  REOPEN: 'إعادة فتح المراسلة',
};

/**
 * قاعدة الانتقال الفردية
 */
export interface TransitionRule {
  action: CorrespondenceAction;
  toStatus: CorrespondenceStatus;
  description: string;
}

/**
 * آلة الحالات المركزية للمراسلات — مصدر الحقيقة الوحيد لكافة الانتقالات
 * تضمن تطابق دورة الحياة المعتمدة:
 * مستلمة ← قيد الدراسة ← محالة ← جارٍ الإعداد ← بانتظار الاعتماد ← معتمدة ← مُرسلة ← مغلقة ← مؤرشفة
 * مع مسار الرفض (بانتظار الاعتماد ➔ جارٍ الإعداد) لإعادة المسودة لقيد التحرير.
 */
export const CORRESPONDENCE_TRANSITIONS: Record<CorrespondenceStatus, TransitionRule[]> = {
  // 1. مستلمة: وارد جديد من العميل
  RECEIVED: [
    { action: CorrespondenceAction.REVIEW, toStatus: CorrespondenceStatus.UNDER_REVIEW, description: 'بدء دراسة المراسلة من قِبل المدير العام' },
    { action: CorrespondenceAction.REFER, toStatus: CorrespondenceStatus.REFERRED, description: 'إحالة المراسلة إلى نائب المدير أو مديري الأقسام' },
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'بدء إعداد رد مباشر' },
    { action: CorrespondenceAction.SUBMIT_REPLY, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'رفع رد مباشر للاعتماد' },
    { action: CorrespondenceAction.CLOSE, toStatus: CorrespondenceStatus.CLOSED, description: 'إغلاق المراسلة دون الحاجة لرد' },
    { action: CorrespondenceAction.ARCHIVE, toStatus: CorrespondenceStatus.ARCHIVED, description: 'أرشفة المراسلة مباشرة' },
  ],

  // 2. قيد الدراسة: تحت نظر ومراجعة المدير العام
  UNDER_REVIEW: [
    { action: CorrespondenceAction.REFER, toStatus: CorrespondenceStatus.REFERRED, description: 'إحالة المراسلة بعد اكتمال دراسة المدير العام' },
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'بدء صياغة رد على المراسلة' },
    { action: CorrespondenceAction.SUBMIT_REPLY, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'رفع الرد للاعتماد' },
    { action: CorrespondenceAction.CLOSE, toStatus: CorrespondenceStatus.CLOSED, description: 'إغلاق المراسلة بعد الدراسة دون رد' },
    { action: CorrespondenceAction.ARCHIVE, toStatus: CorrespondenceStatus.ARCHIVED, description: 'أرشفة المراسلة بعد الدراسة' },
  ],

  // 3. محالة: أُحيلت لإدارة أو قسم أو موظف مختص
  REFERRED: [
    { action: CorrespondenceAction.REFER, toStatus: CorrespondenceStatus.REFERRED, description: 'إعادة إحالة أو إحالة داخل القسم إلى الموظف المختص' },
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'بدء إعداد مسودة الرد من قِبل المكلّف' },
    { action: CorrespondenceAction.SUBMIT_REPLY, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'رفع الرد المكتمل للاعتماد' },
    { action: CorrespondenceAction.CLOSE, toStatus: CorrespondenceStatus.CLOSED, description: 'إغلاق المراسلة المحالة' },
  ],

  // 4. جارٍ الإعداد: الموظف أو الإدارة تعمل على صياغة الرد وإنجاز المهام
  IN_PROGRESS: [
    { action: CorrespondenceAction.REFER, toStatus: CorrespondenceStatus.REFERRED, description: 'إعادة إحالة المعاملة أثناء الإعداد' },
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'متابعة صياغة الرد أو إضافة مسودة أخرى' },
    { action: CorrespondenceAction.SUBMIT_REPLY, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'رفع مسودة الرد للاعتماد من صاحب الصلاحية' },
  ],

  // 5. بانتظار الاعتماد: المسودة مرفوعة وتنتظر موافقة المدير المعني
  PENDING_APPROVAL: [
    { action: CorrespondenceAction.APPROVE_REPLY, toStatus: CorrespondenceStatus.APPROVED, description: 'اعتماد الرد من صاحب الصلاحية' },
    { action: CorrespondenceAction.REJECT_REPLY, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'مسار الرفض: رفض الرد مع ملاحظات وإعادته لقيد التحرير' },
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'إضافة أو تعديل مسودة رد أخرى بانتظار الاعتماد' },
  ],

  // 6. معتمدة: الرد معتمد رسميًا وجاهز للإرسال النهائي
  APPROVED: [
    { action: CorrespondenceAction.SEND_REPLY, toStatus: CorrespondenceStatus.SENT, description: 'الإرسال النهائي المعتمد للعميل عبر خادم البريد الرسمي' },
  ],

  // 7. مُرسلة: تم إرسال الرد الرسمي للعميل بنجاح
  SENT: [
    { action: CorrespondenceAction.START_DRAFT, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'بدء إعداد رد تعقيبي أو إضافي' },
    { action: CorrespondenceAction.SUBMIT_REPLY, toStatus: CorrespondenceStatus.PENDING_APPROVAL, description: 'رفع رد إضافي للاعتماد' },
    { action: CorrespondenceAction.CLOSE, toStatus: CorrespondenceStatus.CLOSED, description: 'إغلاق المراسلة بعد اكتمال المعالجة ونجاح الإرسال' },
    { action: CorrespondenceAction.ARCHIVE, toStatus: CorrespondenceStatus.ARCHIVED, description: 'أرشفة المراسلة بعد الإرسال' },
    { action: CorrespondenceAction.REOPEN, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'إعادة فتح المراسلة عند ورود تعقيب جديد من العميل' },
  ],

  // 8. مغلقة: تم إغلاق المراسلة بنجاح
  CLOSED: [
    { action: CorrespondenceAction.ARCHIVE, toStatus: CorrespondenceStatus.ARCHIVED, description: 'أرشفة المراسلة المغلقة' },
    { action: CorrespondenceAction.REOPEN, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'إعادة فتح المراسلة المغلقة عند ورود تعقيب جديد من العميل' },
  ],

  // 9. مؤرشفة: المعاملة في الأرشيف النهائي
  ARCHIVED: [
    { action: CorrespondenceAction.REOPEN, toStatus: CorrespondenceStatus.IN_PROGRESS, description: 'إعادة فتح المراسلة المؤرشفة عند استلام تعقيب جديد على نفس الخيط' },
  ],
};

/**
 * التحقق من إمكانية تنفيذ الإجراء على الحالة الحالية
 */
export function canTransition(
  current: CorrespondenceStatus,
  action: CorrespondenceAction,
): boolean {
  const rules = CORRESPONDENCE_TRANSITIONS[current];
  if (!rules) return false;
  return rules.some((r) => r.action === action);
}

/**
 * الحصول على الحالة المستهدفة الناتجة عن الإجراء (أو null إذا كان الانتقال غير مسموح)
 */
export function getNextStatus(
  current: CorrespondenceStatus,
  action: CorrespondenceAction,
): CorrespondenceStatus | null {
  const rules = CORRESPONDENCE_TRANSITIONS[current];
  if (!rules) return null;
  const match = rules.find((r) => r.action === action);
  return match ? match.toStatus : null;
}

/**
 * جلب كافة الحالات التي يُسمح منها بالقيام بإجراء محدد
 * (تُستبدل بها المصفوفات المتناثرة مثل closable و archivable و referable)
 */
export function getAllowedStatusesForAction(
  action: CorrespondenceAction,
): CorrespondenceStatus[] {
  const statuses: CorrespondenceStatus[] = [];
  for (const [status, rules] of Object.entries(CORRESPONDENCE_TRANSITIONS)) {
    if (rules.some((r) => r.action === action)) {
      statuses.push(status as CorrespondenceStatus);
    }
  }
  return statuses;
}

/**
 * جلب كافة الإجراءات المسموحة للحالة الحالية
 */
export function getAllowedActions(
  current: CorrespondenceStatus,
): CorrespondenceAction[] {
  const rules = CORRESPONDENCE_TRANSITIONS[current] ?? [];
  return rules.map((r) => r.action);
}

/**
 * تأكيد صحة الانتقال — ترمي BadRequestException برسالة عربية واضحة تذكر الحالة الحالية والانتقال المطلوب
 */
export function assertTransition(
  current: CorrespondenceStatus,
  action: CorrespondenceAction,
): CorrespondenceStatus {
  const nextStatus = getNextStatus(current, action);
  if (!nextStatus) {
    if (action === CorrespondenceAction.REFER) {
      throw new BadRequestException(`لا يمكن إحالة مراسلة في حالة «${current}»`);
    }
    const actionLabel = CORRESPONDENCE_ACTION_LABELS[action] ?? action;
    throw new BadRequestException(
      `لا يمكن ${actionLabel} على مراسلة في حالة «${current}»`,
    );
  }
  return nextStatus;
}
