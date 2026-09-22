"use client";

import { motion, useScroll, useReducedMotion, useTransform } from "framer-motion";

/**
 * شريط تقدم القراءة (Reading Progress Bar)
 * شريط رفيع بتدرج ذهبي في أعلى الصفحة لمتابعة التقدم في القراءة
 * يُعطَّل عند تفضيل المستخدم لتقليل الحركة
 */
export function ReadingProgress() {
  const { scrollYProgress } = useScroll();
  const reduce = useReducedMotion();
  // تحويل التقدم إلى ارتفاع: يُضخَّم قليلاً عند الاكتمال
  const height = useTransform(scrollYProgress, [0.95, 1], [2, 3]);

  if (reduce) return null;

  return (
    <motion.div
      style={{
        scaleX: scrollYProgress,
        height,
        willChange: "transform",
      }}
      className="fixed inset-x-0 top-0 z-[999] origin-right bg-gradient-to-r from-gold-light via-gold to-amber-400 shadow-[0_0_8px_rgba(198,149,74,0.5)] pointer-events-none"
    />
  );
}
