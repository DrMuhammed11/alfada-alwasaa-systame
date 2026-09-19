import type { NextConfig } from "next";
import withBundleAnalyzer from "@next/bundle-analyzer";

// يُفعَّل تحليل الحزمة فقط عند تشغيل: npm run analyze
const analyze = withBundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
});

const nextConfig: NextConfig = {
  /**
   * الإبقاء على unoptimized: true ضروري لأن الموقع يُقدّم كثابت (Static Export عبر npx serve أو بيئات CDN الثابتة).
   * إزالة هذه الخاصية تجعل Next.js يوجّه طلبات الصور إلى نقطة نهاية ديناميكية (/_next/image)
   * غير متوفرة في بيئة التقديم الثابت المستقلة عن خادم Node.
   * وقد تم بالفعل تحسين وضغط كافة الصور المصدرية وتحويلها إلى WebP بجودة 82 وأبعاد مدروسة في Task 1.
   */
  images: { unoptimized: true },

  /**
   * تفعيل الوضع الصارم لـ React للكشف المبكر عن أي آثار جانبية محتملة وضمان توافقية React 19
   */
  reactStrictMode: true,

  /**
   * إخفاء مؤشرات التطوير العائمة في الواجهة
   */
  devIndicators: false,

  /**
   * ترويسات التخزين المؤقت الطويل (Cache-Control) للصور والأصول الثابتة
   */
  async headers() {
    return [
      {
        source: "/profile/:all*(svg|jpg|png|webp)",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=31536000, immutable",
          },
        ],
      },
      {
        source: "/projects/:all*(svg|jpg|png|webp)",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=31536000, immutable",
          },
        ],
      },
    ];
  },

  /**
   * التوجيه الدائم المباشر 301 من النطاق الجذري إلى https://www.alfadaalwasaa.com لمنع القفزة المزدوجة
   */
  async redirects() {
    return [
      {
        source: "/:path*",
        has: [{ type: "host", value: "alfadaalwasaa.com" }],
        destination: "https://www.alfadaalwasaa.com/:path*",
        permanent: true,
      },
    ];
  },
};

export default analyze(nextConfig);
