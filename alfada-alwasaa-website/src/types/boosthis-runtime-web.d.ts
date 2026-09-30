/**
 * تصريحات أنواع حزمة قياس الأداء Boosthis للموقع.
 *
 * الحزمة الحقيقية تُشحن مصدر TypeScript مباشرة (node_modules/@workspace/
 * boosthis-runtime-web — وصلة junction إلى lib/boosthis-runtime-web غير
 * المعدَّلة) ويجمعها Next عبر transpilePackages وقت البناء.
 *
 * هذا التصريح الظلّي يحل مشكلة واحدة فقط: إعدادات tsconfig صارمة للموقع
 * تُخطئ في توقيعات الكيت نفسه (TS2352 في timerHealth.ts) — فنعلن الواجهة
 * العامة هنا ليُفحص كودنا عليها، ويبقى مصدر الكيت خارج برنامج الفحص.
 * المصدر الحقيقي للواجهة: lib/boosthis-runtime-web/src/index.ts
 */
declare module "@workspace/boosthis-runtime-web" {
  export interface StartWebVitalsOptions {
    /** الفقاعة العائمة — تظهر افتراضياً في كل البيئات؛ BOOSTHIS_BUBBLE=0 يخفيها */
    bubble?: boolean;
    [key: string]: unknown;
  }

  export interface BoosthisWebTelemetryOptions {
    /** هوية ثابتة لهذا التثبيت (UUID v4 يُولَّد مرة واحدة ولا يتغير) */
    installId?: string;
    endpoint?: string;
    /** اسم ودّي للموقع في لوحة Boosthis (بلا بيانات شخصية) */
    appName?: string;
    /** مفتاح المشروع bk_... من متغير البناء، غيابه يبقي القياس محلياً */
    inviteKey?: string;
    [key: string]: unknown;
  }

  export declare function startWebVitals(options?: StartWebVitalsOptions): void;
  export declare function enableTelemetry(opts: BoosthisWebTelemetryOptions): unknown;
  export declare function startSnapshotAutoUpload(): void;
  export declare function registerWebRoutes(routes: string[]): void;
  export declare function getUnreachableRoutes(): string[];
}
