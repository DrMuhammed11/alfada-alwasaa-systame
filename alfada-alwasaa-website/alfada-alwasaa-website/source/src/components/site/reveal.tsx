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

/* ===== قياس مجمّع: طابور واحد + rAF واحد لكل دفعة mount =====
   كل نسخ Reveal تضيف عقدها للطابور فقط، وrAF مشترك واحد يقرأ
   getBoundingClientRect لكل العقد في نفس الإطار (reflow واحد بدل N)
   ثم يسجّل العقد تحت الطية لدى مراقب IntersectionObserver مشترك واحد */

type QueuedNode = {
  node: HTMLDivElement;
  y: number;
  delay: number;
  once: boolean;
};

const queue = new Map<HTMLDivElement, QueuedNode>();
let rafScheduled = false;

const prefersReduced = () =>
  typeof window !== "undefined" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/* ===== مراقب مشترك واحد لكل نسخ Reveal في الصفحة ===== */
const targets = new Map<Element, { once: boolean }>();
let sharedObserver: IntersectionObserver | null = null;

function getObserver(): IntersectionObserver {
  if (sharedObserver) return sharedObserver;
  sharedObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        const handle = targets.get(entry.target);
        if (!handle) continue;
        const node = entry.target as HTMLElement;
        if (entry.isIntersecting) {
          node.classList.remove("reveal-hidden");
          node.classList.add("reveal-visible");
          if (handle.once) {
            targets.delete(entry.target);
            sharedObserver?.unobserve(entry.target);
          }
        } else if (!handle.once) {
          node.classList.remove("reveal-visible");
          node.classList.add("reveal-hidden");
        }
      }
    },
    { rootMargin: "-80px" }
  );
  return sharedObserver;
}

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

    if (prefersReduced()) return;

    queue.set(node, { node, y, delay: totalDelay, once });

    if (!rafScheduled) {
      rafScheduled = true;
      requestAnimationFrame(() => {
        rafScheduled = false;
        if (prefersReduced()) {
          queue.clear();
          return;
        }

        const batch = Array.from(queue.values());
        queue.clear();

        const vh = window.innerHeight;

        // 1. دفعة القراءة المجمّعة بالكامل (فصل تام بين القراءة والكتابة لمنع عاصفة reflow)
        const toHide: QueuedNode[] = [];
        for (let i = 0; i < batch.length; i++) {
          const item = batch[i];
          if (item.node.getBoundingClientRect().top > vh) {
            toHide.push(item);
          }
        }

        // 2. دفعة الكتابة المجمّعة وتفعيل المراقبة دفعة واحدة
        const observer = getObserver();
        for (let i = 0; i < toHide.length; i++) {
          const item = toHide[i];
          if (item.y !== 14) {
            item.node.style.setProperty("--reveal-y", `${item.y}px`);
          }
          if (item.delay > 0) {
            item.node.style.setProperty("--reveal-delay", `${item.delay}s`);
          }
          item.node.classList.add("reveal-hidden");
          targets.set(item.node, { once: item.once });
          observer.observe(item.node);
        }
      });
    }

    return () => {
      queue.delete(node);
      if (targets.has(node)) {
        targets.delete(node);
        sharedObserver?.unobserve(node);
      }
    };
  }, [once, totalDelay, y]);

  return (
    <div ref={ref} className={cn("transform-gpu", className)}>
      {children}
    </div>
  );
}
