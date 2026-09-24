"use client";

/**
 * سنة حقوق النشر تُحسب وقت التشغيل بدل التخبيز وقت البناء
 * الـ SSR يعرض سنة البناء في HTML الثابت (جيدة للزواحف)، وsuppressHydrationWarning
 * يمنع تحذير الانحراف إذا تغيّرت السنة بين البناء والزيارة (حول رأس السنة) مع تصحيحها تلقائياً
 */
export function CopyrightYear() {
  return <span suppressHydrationWarning>{new Date().getFullYear()}</span>;
}
