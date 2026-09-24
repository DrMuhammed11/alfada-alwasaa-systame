"use client";

import { useEffect, useState } from "react";

/**
 * رصد تفضيل تقليل الحركة (prefers-reduced-motion) كبديل خفيف عن hook في framer-motion
 * يعيد false في الـ SSR ويحدَّث بعد الـ mount، ويستجيب لتغيير التفضيل أثناء الجلسة
 */
export function useReducedMotion() {
  const [reduce, setReduce] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setReduce(mq.matches);
    update();
    mq.addEventListener("change", update);
    return () => mq.removeEventListener("change", update);
  }, []);

  return reduce;
}
