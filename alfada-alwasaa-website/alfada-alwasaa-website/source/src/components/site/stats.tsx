"use client";

import { useState, useEffect, useRef } from "react";
import { useReducedMotion } from "framer-motion";
import { Award, Layers, Clock, ShieldCheck } from "lucide-react";
import { Reveal } from "./reveal";
import { SITE_CONFIG } from "@/config/site";

const STAT_ICONS = [Layers, ShieldCheck, Award, Clock];

const STATS = SITE_CONFIG.stats.map((item, idx) => ({
  ...item,
  Icon: STAT_ICONS[idx],
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
  const [count, setCount] = useState(reduce ? target : 0);
  const containerRef = useRef<HTMLSpanElement>(null);
  const [hasStarted, setHasStarted] = useState(false);

  useEffect(() => {
    if (reduce) {
      setCount(target);
      return;
    }

    const node = containerRef.current;
    if (!node) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setHasStarted(true);
          observer.disconnect();
        }
      },
      { threshold: 0.25 }
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [reduce, target]);

  useEffect(() => {
    if (!hasStarted || reduce) return;

    const duration = 1200; // 1.2s animation duration
    let startTime: number | null = null;
    let animId: number;

    const easeOutCubic = (x: number): number => 1 - Math.pow(1 - x, 3);

    const step = (now: number) => {
      if (!startTime) startTime = now;
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = easeOutCubic(progress);
      setCount(Math.round(eased * target));

      if (progress < 1) {
        animId = requestAnimationFrame(step);
      }
    };

    animId = requestAnimationFrame(step);
    return () => cancelAnimationFrame(animId);
  }, [hasStarted, reduce, target]);

  return (
    <span ref={containerRef} className="tabular-nums">
      {count}
      {suffix}
    </span>
  );
}

export function Stats() {
  return (
    <section className="relative -mt-10 z-20 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <Reveal>
        <div className="rounded-3xl border border-gold/30 bg-gradient-to-br from-navy-deep via-navy to-navy-darker p-6 shadow-[0_25px_60px_-15px_rgba(5,30,49,0.7)] backdrop-blur-lg sm:p-10">
          <div className="grid grid-cols-2 gap-6 md:grid-cols-4 md:gap-8 divide-y-2 divide-white/10 md:divide-y-0 md:divide-x-2 md:divide-x-reverse">
            {STATS.map((stat, idx) => (
              <div
                key={stat.label}
                className={`flex flex-col items-center text-center ${
                  idx > 1 ? "pt-6 md:pt-0" : ""
                } ${idx % 2 === 1 && idx === 1 ? "pt-0" : ""}`}
              >
                <div className="mb-3 flex h-13 w-13 items-center justify-center rounded-2xl bg-gold/15 text-gold-light ring-1 ring-gold/30">
                  <stat.Icon className="h-6 w-6" strokeWidth={2} />
                </div>
                <span className="text-3xl font-black tracking-tight text-white sm:text-4xl lg:text-5xl">
                  <span className="bg-gradient-to-l from-gold-light via-gold to-white bg-clip-text text-transparent">
                    <AnimatedCounter rawNum={stat.num} />
                  </span>
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

