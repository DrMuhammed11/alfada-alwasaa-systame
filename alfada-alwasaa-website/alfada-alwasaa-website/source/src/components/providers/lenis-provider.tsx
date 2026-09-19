"use client";

import { useEffect, type ReactNode } from "react";
import Lenis from "lenis";

/**
 * مزود التمرير السلس الذكي (Lenis Smooth Scroll)
 * يضمن تجربة تصفح غاية في الانسيابية على أجهزة سطح المكتب والجوال
 * مع معالجة محسوبة على دورة التحديث البرمجية (requestAnimationFrame)
 */
export function LenisProvider({ children }: { children?: ReactNode }) {
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return;
    }

    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: "vertical",
      gestureOrientation: "vertical",
      smoothWheel: true,
      touchMultiplier: 1.5,
    });

    let rafId: number;
    function raf(time: number) {
      lenis.raf(time);
      rafId = requestAnimationFrame(raf);
    }
    rafId = requestAnimationFrame(raf);

    return () => {
      cancelAnimationFrame(rafId);
      lenis.destroy();
    };
  }, []);

  return <>{children}</>;
}
