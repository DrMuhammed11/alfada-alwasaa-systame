import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /**
   * الإبقاء على الصور بدون تحسين ديناميكي (unoptimized) في هذه المرحلة
   * لضمان التوافقية الكاملة وسلاسة النشر الثابت، وسيتم ترقيتها في مرحلة تحسين الأداء.
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

export default nextConfig;
