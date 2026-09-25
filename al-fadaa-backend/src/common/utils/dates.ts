import { registerDecorator, ValidationOptions } from 'class-validator';

/**
 * أدوات معالجة حدود التواريخ في فلاتر الاستعلام.
 * العملاء يرسلون التواريخ أحيانًا بصيغة يوم فقط (YYYY-MM-DD) دون وقت،
 * لذا تُفسَّر هنا: «من» = بداية اليوم، و«إلى» = نهايته —
 * حتى لا يُستبعد اليوم الأخير من النتائج عند المقارنة بـ lte.
 */

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

/** تاريخ البداية — التاريخ بلا وقت يعني بداية اليوم (UTC) */
export function parseDateStart(value: string): Date {
  return new Date(DATE_ONLY.test(value) ? `${value}T00:00:00.000Z` : value);
}

/** تاريخ النهاية — التاريخ بلا وقت يعني نهاية اليوم (23:59:59.999) لا بدايته */
export function parseDateEnd(value: string): Date {
  return new Date(DATE_ONLY.test(value) ? `${value}T23:59:59.999Z` : value);
}

/**
 * التحقق من أن النص تاريخ حقيقي موجود في التقويم:
 * - يرفض التواريخ الجزئية («2026» أو «2026-09») التي يقبلها IsDateString
 *   وتفسَّر صمتاً على بداية السنة/الشهر فيقطع النتائج.
 * - يرفض التواريخ المزيفة («2026-02-30») التي يزيحها new Date صمتاً
 *   إلى اليوم التالي بدل رفضها.
 * القبول: YYYY-MM-DD أو ISO 8601 كاملًا (مع وقت ومنطقة زمنية اختيارية).
 */
export function isRealDateString(value: unknown): boolean {
  if (typeof value !== 'string') return false;
  const m = /^(\d{4})-(\d{2})-(\d{2})(?:[Tt\s].*)?$/.exec(value);
  if (!m) return false;
  const year = Number(m[1]);
  const month = Number(m[2]);
  const day = Number(m[3]);
  if (month < 1 || month > 12 || day < 1) return false;
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return day <= daysInMonth;
}

/** مُحقّق class-validator بديلًا صارمًا عن IsDateString */
export function IsRealDate(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isRealDate',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown) {
          return isRealDateString(value);
        },
        defaultMessage: () =>
          'صيغة التاريخ غير صالحة — استخدم YYYY-MM-DD أو ISO 8601 كاملًا بتاريخ موجود فعلًا في التقويم',
      },
    });
  };
}
