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
    // تعطيل التمرير السلس على أجهزة اللمس (الهواتف والأجهزة اللوحية)
    if (window.matchMedia("(pointer: coarse)").matches) {
      return;
    }

    // تأخير التهيئة إلى وقت خمول المتصفح: لا تزاحم مع hydration وتحليل الباقات الأولى
    const requestIdle: (cb: () => void) => number =
      typeof window.requestIdleCallback === "function"
        ? (cb) => window.requestIdleCallback(cb)
        : (cb) => window.setTimeout(cb, 300);
    const cancelIdle: (id: number) => void =
      typeof window.cancelIdleCallback === "function"
        ? (id) => window.cancelIdleCallback(id)
        : (id) => window.clearTimeout(id);

    let lenis: Lenis | null = null;
    let rafId = 0;
    let idleId: number | undefined;

    idleId = requestIdle(() => {
      lenis = new Lenis({
        duration: 1.1,
        // easing انسيابي يمنح شعور "الطوافية" مع توقف سلس
        easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
        lerp: 0.085,
        orientation: "vertical",
        gestureOrientation: "vertical",
        smoothWheel: true,
        wheelMultiplier: 0.9,
        touchMultiplier: 1.5,
      });

      function raf(time: number) {
        lenis?.raf(time);
        rafId = requestAnimationFrame(raf);
      }
      rafId = requestAnimationFrame(raf);
    });

    return () => {
      if (idleId !== undefined) cancelIdle(idleId);
      cancelAnimationFrame(rafId);
      lenis?.destroy();
    };
  }, []);

  return <>{children}</>;
}
