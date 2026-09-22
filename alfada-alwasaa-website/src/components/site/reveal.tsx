"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ReactNode } from "react";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

type RevealProps = {
  children: ReactNode;
  delay?: number;
  /** رقم ترتيب البطاقة — يُحسب منه تأخير stagger تلقائياً (0.08s × index) */
  index?: number;
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
  index,
  y = 14,
  className,
  once = true,
}: RevealProps) {
  const reduce = useReducedMotion();
  const isMobile = useIsMobile();

  // stagger: 0.08s بين كل عنصر، محدود بـ 0.32s حداً أقصى لمنع تأخر واضح
  const staggerDelay = index !== undefined ? Math.min(index * 0.08, 0.32) : 0;
  const totalDelay = Math.min(delay + staggerDelay, 0.4);

  return (
    <motion.div
      className={cn("transform-gpu", className)}
      style={{ willChange: "opacity, transform" }}
      initial={reduce ? false : { opacity: 0, y: isMobile ? Math.min(y, 10) : y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once, margin: "-15px" }}
      transition={{
        duration: isMobile ? 0.35 : 0.42,
        delay: reduce ? 0 : totalDelay,
        ease: [0.16, 1, 0.3, 1],
      }}
    >
      {children}
    </motion.div>
  );
}

