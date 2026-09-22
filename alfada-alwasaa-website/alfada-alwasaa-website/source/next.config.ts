import type { NextConfig } from "next";
import withBundleAnalyzer from "@next/bundle-analyzer";

// يُفعَّل تحليل الحزمة فقط عند تشغيل: npm run analyze
const analyze = withBundleAnalyzer({
  enabled: process.env.ANALYZE === "true",
});

const nextConfig: NextConfig = {
  /**
   * التصدير الثابت الكامل (Static HTML/CSS/JS Export)
   * يولّد موقعاً ساكناً في مجلد out/ صالحاً للنشر المباشر على خوادم الويب وCDNs
   */
  output: "export",

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
};

export default analyze(nextConfig);
