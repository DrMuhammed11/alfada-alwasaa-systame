"use client";

import { useEffect } from "react";

/**
 * مزامنة لغة واتجاه مستند <html> للنسخة الإنجليزية
 * الـ layout الجذري عربي ثابت (lang="ar" dir="rtl") لا يمكن تغييره لكل صفحة
 * في التصدير الثابت، لذا يضبط هذا المكوّن الخصائص على مستوى المستند لصفحات /en
 */
export function LangSync({ lang, dir }: { lang: string; dir: string }) {
  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = dir;
  }, [lang, dir]);

  return null;
}
