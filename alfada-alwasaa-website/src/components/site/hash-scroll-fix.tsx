"use client";

import { useEffect } from "react";

/**
 * إصلاح التنقل إلى الأقسام عبر الصفحات (مثل /#services أو /en#contact):
 * عند فتح رابط يحمل هاشاً أو التنقل إليه بين الصفحات، قد يصل المستخدم قبل
 * اكتمال تخطيط الصفحة (صور lazy وأقسام ديناميكية) فيتوقف التمرير في مكان
 * غير دقيق — نعيد التمرير السلس إلى القسم بعد الاستقرار، ونستمع لتغير الهاش.
 */
export function HashScrollFix() {
  useEffect(() => {
    let raf = 0;
    const timers: ReturnType<typeof setTimeout>[] = [];

    const scrollToHash = () => {
      const hash = window.location.hash;
      if (!hash || hash === "#") return;
      const el = document.getElementById(decodeURIComponent(hash.slice(1)));
      if (el) {
        el.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    };

    // محاولات متدرجة بعد كل تنقل: الصفحة قد تُكمّل تحميل الصور وتغيّر الارتفاعات
    const scheduleScrolls = () => {
      cancelAnimationFrame(raf);
      timers.forEach(clearTimeout);
      timers.length = 0;
      raf = requestAnimationFrame(scrollToHash);
      [120, 400, 900].forEach((ms) => timers.push(setTimeout(scrollToHash, ms)));
    };

    scheduleScrolls();
    window.addEventListener("hashchange", scheduleScrolls);
    return () => {
      cancelAnimationFrame(raf);
      timers.forEach(clearTimeout);
      window.removeEventListener("hashchange", scheduleScrolls);
    };
  }, []);

  return null;
}
