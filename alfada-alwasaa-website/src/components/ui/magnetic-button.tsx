"use client";

import React, { useRef, useEffect } from "react";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

interface MagneticButtonProps {
  children: React.ReactNode;
  className?: string;
  maxOffset?: number; // default 6px
}

/**
 * زر بتأثير جاذبية مغناطيسية خفيف باتجاه مؤشر الفأرة على أجهزة سطح المكتب فقط
 * يُعطَّل تلقائياً على الشاشات اللمسية ومستخدمي prefers-reduced-motion
 * التنفيذ بمعالجة DOM مباشرة (بلا إعادة رندر ولا framer-motion): تتبع فوري أثناء الحركة
 * وعودة مرنة (spring-like) عبر انتقال CSS عند مغادرة المؤشر
 */
export function MagneticButton({
  children,
  className = "",
  maxOffset = 6,
}: MagneticButtonProps) {
  const ref = useRef<HTMLDivElement>(null);
  const reduce = useReducedMotion();

  useEffect(() => {
    const el = ref.current;
    if (!el || reduce || !window.matchMedia("(pointer: fine)").matches) return;

    const handleMouseMove = (e: MouseEvent) => {
      const rect = el.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;

      const distanceX = (e.clientX - centerX) * 0.18;
      const distanceY = (e.clientY - centerY) * 0.18;

      // Clamp to maxOffset (default <= 6px)
      const clampedX = Math.max(-maxOffset, Math.min(maxOffset, distanceX));
      const clampedY = Math.max(-maxOffset, Math.min(maxOffset, distanceY));

      el.style.transition = "transform 0.08s ease-out";
      el.style.transform = `translate(${clampedX}px, ${clampedY}px)`;
    };

    const handleMouseLeave = () => {
      el.style.transition = "transform 0.35s cubic-bezier(0.22, 1, 0.36, 1)";
      el.style.transform = "translate(0px, 0px)";
    };

    el.addEventListener("mousemove", handleMouseMove);
    el.addEventListener("mouseleave", handleMouseLeave);
    return () => {
      el.removeEventListener("mousemove", handleMouseMove);
      el.removeEventListener("mouseleave", handleMouseLeave);
    };
  }, [reduce, maxOffset]);

  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  );
}
