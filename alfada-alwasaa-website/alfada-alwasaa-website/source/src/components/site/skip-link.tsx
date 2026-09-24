"use client";

import { usePathname } from "next/navigation";

/**
 * رابط تجاوز المحتوى للوصولية (Accessibility Skip Link)
 * يعرض التسمية بالعربية أو الإنجليزية حسب مسار الصفحة الحالية،
 * ويظهر عند التركيز بلوحة المفاتيح فقط
 */
export function SkipLink() {
  const pathname = usePathname() || "";
  const isEnglish = pathname.startsWith("/en");

  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:start-4 focus:z-[9999] focus:rounded-md focus:bg-gold focus:px-4 focus:py-2 focus:text-navy-dark focus:font-bold focus:shadow-lg focus:outline-none"
    >
      {isEnglish ? "Skip to main content" : "تجاوز إلى المحتوى الرئيسي"}
    </a>
  );
}
