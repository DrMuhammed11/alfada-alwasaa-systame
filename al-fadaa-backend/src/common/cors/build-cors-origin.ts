/**
 * بناء دالة التحقق من الأصل (Origin) لإعدادات CORS.
 *
 * - تقرأ القائمة من متغير البيئة CORS_ORIGIN (نطاقات مفصولة بفواصل).
 * - في بيئة الإنتاج: ترفض التشغيل إذا كانت القائمة فارغة أو تحتوي على *.
 * - في بيئة التطوير: تُضيف نطاقات localhost تلقائيًا.
 * - تسمح بالطلبات بدون رأس Origin (خادم-لخادم، Postman، إلخ).
 */

/** النطاقات المحلية المسموح بها تلقائيًا أثناء التطوير */
const DEV_LOCALHOST_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:3001',
  'http://localhost:5000',
  'http://localhost:5001',
  'http://localhost:5050',
];

/**
 * تحليل متغير CORS_ORIGIN إلى مصفوفة نطاقات نظيفة.
 * @param raw القيمة الخام من متغير البيئة
 */
export function parseCorsOrigins(raw: string | undefined): string[] {
  if (!raw || raw.trim() === '') return [];
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);
}

/**
 * التحقق من قائمة النطاقات في بيئة الإنتاج:
 * - يجب ألا تكون فارغة.
 * - يجب ألا تحتوي على * (wildcard).
 * يُلقي خطأ إذا فشل التحقق.
 */
export function validateProductionOrigins(origins: string[]): void {
  if (origins.length === 0) {
    throw new Error(
      'CORS_ORIGIN فارغ في بيئة الإنتاج — يجب تحديد النطاقات المسموح بها.',
    );
  }
  if (origins.includes('*')) {
    throw new Error(
      'CORS_ORIGIN يحتوي على * (wildcard) في بيئة الإنتاج — ممنوع. حدد النطاقات بدقة.',
    );
  }
}

/**
 * بناء قائمة النطاقات النهائية المسموح بها حسب البيئة.
 * @param rawEnv القيمة الخام لـ CORS_ORIGIN
 * @param isProduction هل البيئة إنتاجية؟
 */
export function buildAllowedOrigins(
  rawEnv: string | undefined,
  isProduction: boolean,
): string[] {
  const origins = parseCorsOrigins(rawEnv);

  if (isProduction) {
    validateProductionOrigins(origins);
    return origins;
  }

  // في التطوير: دمج النطاقات المُعطاة مع نطاقات localhost (بدون تكرار)
  const merged = new Set([...origins.filter((o) => o !== '*'), ...DEV_LOCALHOST_ORIGINS]);
  return Array.from(merged);
}

/**
 * بناء دالة origin المتوافقة مع حزمة cors.
 * تُستخدم كقيمة الخاصية `origin` في إعدادات enableCors.
 */
export function buildCorsOriginFunction(
  rawEnv: string | undefined,
  isProduction: boolean,
): (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => void {
  const allowed = buildAllowedOrigins(rawEnv, isProduction);

  return (
    origin: string | undefined,
    callback: (err: Error | null, allow?: boolean) => void,
  ) => {
    // السماح بالطلبات بدون Origin (خادم-لخادم، Postman، curl)
    if (!origin) {
      callback(null, true);
      return;
    }

    if (allowed.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`الأصل ${origin} غير مسموح به حسب سياسة CORS.`));
    }
  };
}
