"use client";

import { useEffect, useRef } from "react";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

/**
 * شريط تقدم القراءة (Reading Progress Bar)
 * شريط رفيع بتدرج ذهبي في أعلى الصفحة لمتابعة التقدم في القراءة
 * تنفيذ أصلي بـ rAF مباشر على الـ DOM (بديل useScroll/useTransform من framer-motion)
 * يُعطَّل عند تفضيل المستخدم لتقليل الحركة
 */
export function ReadingProgress() {
  const reduce = useReducedMotion();
  const barRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (reduce) return;
    let ticking = false;

    const update = () => {
      const el = barRef.current;
      if (el) {
        const max = document.documentElement.scrollHeight - window.innerHeight;
        const progress = max > 0 ? Math.min(window.scrollY / max, 1) : 0;
        el.style.transform = `scaleX(${progress})`;
        el.style.height = progress > 0.95 ? "3px" : "2px";
      }
      ticking = false;
    };

    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(update);
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll, { passive: true });
    update();
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
    };
  }, [reduce]);

  if (reduce) return null;

  return (
    <div
      ref={barRef}
      style={{ transform: "scaleX(0)", willChange: "transform" }}
      className="fixed inset-x-0 top-0 z-[999] h-[2px] origin-right bg-gradient-to-r from-gold-light via-gold to-amber-400 shadow-[0_0_8px_rgba(198,149,74,0.5)] pointer-events-none"
    />
  );
}
