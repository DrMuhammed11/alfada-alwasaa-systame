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
    inviteKey: process.env.NEXT_PUBLIC_BOOSTHIS_INVITE_KEY,
    endpoint: "https://www.boosthis.com/api",
    appName: "alfada-alwasaa-website",
  });
}

export default function BoosthisAnalytics() {
  return null;
}
