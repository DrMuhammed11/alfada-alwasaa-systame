"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ReactNode } from "react";

/**
 * انتقال الصفحات على مستوى التطبيق (Page Transitions)
 * انتقال خفيف جداً (opacity + 8px y) لمدة 200ms بدون أي وميض أبيض
 * مع تعطيل كامل للحركة تلقائياً عند تفعيل prefers-reduced-motion
 */
export default function Template({ children }: { children: ReactNode }) {
  const reduce = useReducedMotion();

  if (reduce) {
    return <>{children}</>;
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2, ease: [0.16, 1, 0.3, 1] }}
      className="flex min-h-screen flex-col w-full"
    >
      {children}
    </motion.div>
  );
}
