"use client";

import { useState, useEffect, useRef } from "react";
import { Award, Layers, Clock, ShieldCheck } from "lucide-react";
import { Reveal } from "./reveal";
import { SITE_CONFIG } from "@/config/site";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

const STAT_ICONS = [Layers, ShieldCheck, Award, Clock];

const STATS = SITE_CONFIG.stats.map((item, idx) => ({
  ...item,
  Icon: STAT_ICONS[idx],
  ...parseStat(item.num),
}));

/** دالة تفكيك الرقم واللاحقة لمعالجة الأرقام المركبة مثل 5+ و 24/7 */
function parseStat(raw: string) {
  const match = raw.match(/^(\d+)(.*)$/);
  if (!match) return { target: 0, suffix: raw };
  return {
    target: parseInt(match[1], 10),
    suffix: match[2] || "",
  };
}

/** مكوّن العدّاد الرقمي الانسيابي برصد مجال الرؤية ودعم tabular-nums */
function AnimatedCounter({ rawNum }: { rawNum: string }) {
  const reduce = useReducedMotion();
  const { target, suffix } = parseStat(rawNum);
  const containerRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const node = containerRef.current;
    if (!node || reduce) return;

    let animId: number;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        observer.disconnect();

        // أنيميشن عد مباشر على DOM دون إعادة رندر React لكل إطار — ينهي LCP سريعاً وخالياً من الـ reflow
        const duration = 250;
        let startTime: number | null = null;
        const easeOutCubic = (x: number): number => 1 - Math.pow(1 - x, 3);

        const step = (now: number) => {
          if (!startTime) startTime = now;
          const elapsed = now - startTime;
          const progress = Math.min(elapsed / duration, 1);
          const eased = easeOutCubic(progress);
          const currentVal = Math.round(eased * target);
          if (node) {
            node.textContent = `${currentVal}${suffix}`;
          }

          if (progress < 1) {
            animId = requestAnimationFrame(step);
          }
        };

        animId = requestAnimationFrame(step);
      },
      { threshold: 0.25 }
    );

    observer.observe(node);
    return () => {
      observer.disconnect();
      cancelAnimationFrame(animId);
    };
  }, [reduce, suffix, target]);

  return (
    <span ref={containerRef} className="tabular-nums">
      {target}
      {suffix}
    </span>
  );
}

export function Stats() {
  return (
    <section className="relative -mt-10 z-20 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <Reveal>
        <div className="shimmer-card rounded-3xl border border-gold/30 bg-gradient-to-br from-navy-deep via-navy to-navy-darker p-6 shadow-[0_25px_60px_-15px_rgba(5,30,49,0.7)] backdrop-blur-lg sm:p-10">
          <div className="grid grid-cols-2 gap-6 md:grid-cols-4 md:gap-8 divide-y-2 divide-white/10 md:divide-y-0 md:divide-x-2">
            {STATS.map((stat, idx) => (
              <div
                key={stat.label}
                aria-label={`${stat.target}${stat.suffix}`}
                className={`flex flex-col items-center text-center ${
                  idx > 1 ? "pt-6 md:pt-0" : ""
                }`}
              >
                <div className="mb-3 flex h-13 w-13 items-center justify-center rounded-2xl bg-gold/15 text-gold-light ring-1 ring-gold/30">
                  <stat.Icon className="h-6 w-6" strokeWidth={2} />
                </div>
                {/* لون صلب بدل bg-clip-text: يُرسم فوراً عند تبديل الخط ويُسرِّع LCP */}
                <span className="text-3xl font-black tracking-tight text-gold-light sm:text-4xl lg:text-5xl">
                  <AnimatedCounter rawNum={stat.num} />
                </span>
                <span className="mt-2 text-sm font-bold text-white/95 sm:text-base">
                  {stat.label}
                </span>
                <span className="mt-1 text-xs text-white/60">
                  {stat.sub}
                </span>
              </div>
            ))}
          </div>
        </div>
      </Reveal>
    </section>
  );
}
