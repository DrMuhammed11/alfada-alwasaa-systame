"use client";

import { motion, useScroll, useReducedMotion } from "framer-motion";

/**
 * شريط تقدم القراءة (Reading Progress Bar)
 * شريط رفيع (2px) بتدرج ذهبي في أعلى الصفحة لمتابعة التقدم في صفحات المقالات والخدمات
 * يُعطَّل في حال كان المستخدم يفضل تقليل الحركة
 */
export function ReadingProgress() {
  const { scrollYProgress } = useScroll();
  const reduce = useReducedMotion();

  if (reduce) return null;

  return (
    <motion.div
      style={{ scaleX: scrollYProgress }}
      className="fixed inset-x-0 top-0 z-[999] h-[2px] origin-right bg-gradient-to-r from-gold-light via-gold to-amber-500 shadow-sm pointer-events-none"
    />
  );
}
