/**
 * تصريحات حزمة قياس الأداء Boosthis المُجمَّعة مسبقاً.
 * المصدر الحقيقي: lib/boosthis-runtime-node/src (كيت Boosthis غير مُعدَّل).
 * إعادة التوليد بعد تحديث الكيت:
 *   npx esbuild lib/boosthis-runtime-node/src/index.ts --bundle --platform=node --format=cjs --target=node20 --external:express --outfile=src/vendor/boosthis-kit.js
 */
export interface BoosthisAttachOptions {
  /** نوع الخادم حين لا يستطيع الكيت تمييزه وحده (مثل "hono") */
  serverKind?: string;
  /** تسمية المسار الذي لا يطابق أي مسار مسجل */
  fallbackName?: string;
  bubble?: boolean;
  projectKey?: string;
  [key: string]: unknown;
}

export interface BoosthisTelemetryOptions {
  /** هوية ثابتة لهذا التثبيت (UUID v4 يُولَّد مرة واحدة ولا يتغير) */
  installId?: string;
  endpoint?: string;
  /** اسم ودّي للخدمة في لوحة Boosthis (بلا بيانات شخصية، 60 حرفاً كحد أقصى) */
  appName?: string;
  /** مفتاح المشروع bk_... من بيئة التشغيل، غيابه يبقي القياس محلياً */
  inviteKey?: string;
  [key: string]: unknown;
}

export declare function attach(opts?: BoosthisAttachOptions): unknown;
export declare function enableTelemetry(opts: BoosthisTelemetryOptions): unknown;
