import type { NextConfig } from "next";
import withBundleAnalyzer from "@next/bundle-analyzer";

// يُفعَّل تحليل الحزمة فقط عند تشغيل: npm run analyze
const analyze = withBundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
});

/**
 * رؤوس الأمان — ممكنة الآن بعد التحول من التصدير الثابت إلى SSR
 * (كانت استحالة بنيوية تحت output: "export")
 */
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "SAMEORIGIN" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), interest-cohort=()",
  },
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
  {
    // CSP انطلاقية: تقيّد المصادر وتُبقي سكربت GA وtheme-provider الداخليين
    // (تتطور لاحقًا إلى nonces صارمة عند الحاجة)
    key: "Content-Security-Policy",
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://www.googletagmanager.com",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob:",
      "font-src 'self' data:",
      "connect-src 'self' https://www.google-analytics.com https://region1.google-analytics.com",
      "frame-ancestors 'self'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join("; "),
  },
];

const nextConfig: NextConfig = {
  /**
   * SSR/ISR — بدل التصدير الثابت:
   * - يمكن قراءة الترويسات في الجذر (lang/dir بنيوي)
   * - الصور تُحسَّن عبر /_next/image تلقائيًا
   * - رؤوس الأمان أعلاه ممكنة
   * - المحتوى يُجلب من /site-content/* مع revalidate بدل التجميد وقت البناء
   */
  reactStrictMode: true,
  devIndicators: false,

  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default analyze(nextConfig);
