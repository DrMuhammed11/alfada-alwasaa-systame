"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ReactNode } from "react";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

type RevealProps = {
  children: ReactNode;
  delay?: number;
  y?: number;
  className?: string;
  once?: boolean;
};

/**
 * غلاف انسيابي خفيف لحركات الظهور مع التمرير (Scroll-Reveal)
 * يعتمد حصرياً على opacity و transform لضمان المعالجة على كرت الشاشة (GPU)
 * ومضبوط لتسريع الحركة على أجهزة الجوال مع تثبيت العرض لمرة واحدة (once: true) لمنع إعادة التشغيل العكسي.
 */
export function Reveal({
  children,
  delay = 0,
  y = 14,
  className,
  once = true,
}: RevealProps) {
  const reduce = useReducedMotion();
  const isMobile = useIsMobile();

  return (
    <motion.div
      className={cn("transform-gpu", className)}
      style={{ willChange: "opacity, transform" }}
      initial={reduce ? false : { opacity: 0, y: isMobile ? Math.min(y, 10) : y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once, margin: "-15px" }}
      transition={{
        duration: isMobile ? 0.35 : 0.42,
        delay: Math.min(delay, 0.15),
        ease: [0.16, 1, 0.3, 1],
      }}
    >
      {children}
    </motion.div>
  );
}

