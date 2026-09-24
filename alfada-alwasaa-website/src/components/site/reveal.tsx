"use client";

import { useEffect, useRef } from "react";
import type { ReactNode } from "react";
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
 * تحسين تدريجي صحيح: الـ SSR يُرسِّر العنصر مرئياً دائماً (للزواحف ومستخدمي no-JS)،
 * وبعد الـ mount فقط تُخفى العناصر خارج نافذة العرض (كلاس reveal-hidden)
 * ثم يكشفها IntersectionObserver بانتقال CSS 0.6s ease (كلاس reveal-visible).
 * يعتمد حصرياً على opacity و transform لضمان المعالجة على كرت الشاشة (GPU).
 */
export function Reveal({
  children,
  delay = 0,
  index,
  y = 14,
  className,
  once = true,
}: RevealProps) {
  const ref = useRef<HTMLDivElement>(null);

  // stagger: 0.08s بين كل عنصر، محدود بـ 0.32s حداً أقصى لمنع تأخر واضح
  const staggerDelay = index !== undefined ? Math.min(index * 0.08, 0.32) : 0;
  const totalDelay = Math.min(delay + staggerDelay, 0.4);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    // احترام تفضيل تقليل الحركة: العنصر يبقى مرئياً كما رُسِّم في الـ SSR
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    // العنصر داخل نافذة العرض أصلاً: يبقى مرئياً بلا إخفاء ولا مراقبة
    if (node.getBoundingClientRect().top <= window.innerHeight) return;

    node.style.setProperty("--reveal-y", `${y}px`);
    node.style.setProperty("--reveal-delay", `${totalDelay}s`);
    node.classList.add("reveal-hidden");

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          node.classList.remove("reveal-hidden");
          node.classList.add("reveal-visible");
          if (once) observer.disconnect();
        } else if (!once) {
          node.classList.remove("reveal-visible");
          node.classList.add("reveal-hidden");
        }
      },
      { rootMargin: "-80px" }
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [once, totalDelay, y]);

  return (
    <div ref={ref} className={cn("transform-gpu", className)}>
      {children}
    </div>
  );
}
