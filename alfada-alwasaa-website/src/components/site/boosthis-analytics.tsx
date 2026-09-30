"use client";

/**
 * قياس الأداء Boosthis — Web Vitals لكل صفحة من زوار حقيقيين
 *
 * يعمل في المتصفح فقط (حارس window يتخطى SSR). المفتاح يأتي من متغير
 * البناء NEXT_PUBLIC_BOOSTHIS_INVITE_KEY (ترويسة عامة بطبيعتها مثل مفاتيح
 * التحليلات)، وغيابه يبقي القياس محلياً بلا لوحة.
 * الهوية ثابتة لهذا التثبيت ولا تتغير — تغييرها يسجل جهازاً ثانياً في اللوحة.
 */
import { startWebVitals, enableTelemetry } from "@workspace/boosthis-runtime-web";

if (typeof window !== "undefined") {
  startWebVitals({ bubble: true });

  enableTelemetry({
    installId: "6c440a28-001e-4d42-a9f8-036966056978",
    // مفتاح مشروع Boosthis علني بطبيعته في كيت المتصفح (نطاق ship الرسمي،
    // يقابله سكربت الخدمة المضمّن في HTML) — متغير البناء أولًا والمفتاح
    // احتياطًا حتى لا ينشر الموقع بلا مفتاح إن لم يُضبط في لوحة الاستضافة
    inviteKey:
      process.env.NEXT_PUBLIC_BOOSTHIS_INVITE_KEY ??
      "bk_cb05a81d862fd8add87d24f10e2162e1c4faee29303feb540c37be603155c522",
    endpoint: "https://www.boosthis.com/api",
    appName: "alfada-alwasaa-website",
  });
}

export default function BoosthisAnalytics() {
  return null;
}
