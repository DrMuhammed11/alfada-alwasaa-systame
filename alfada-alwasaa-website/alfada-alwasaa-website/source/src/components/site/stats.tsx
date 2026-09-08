"use client";

import { motion } from "framer-motion";
import { Award, Layers, Clock, ShieldCheck } from "lucide-react";
import { Reveal } from "./reveal";

const STATS = [
  {
    num: "5+",
    label: "قطاعات أعمال استراتيجية",
    sub: "تغطية شاملة ومترابطة",
    Icon: Layers,
  },
  {
    num: "7+",
    label: "منظومات خدمية متكاملة",
    sub: "من التخطيط للتسليم",
    Icon: ShieldCheck,
  },
  {
    num: "100%",
    label: "التزام بالمعايير والمواصفات",
    sub: "انضباط وجودة تنفيذية",
    Icon: Award,
  },
  {
    num: "24/7",
    label: "جاهزية واستجابة مستمرة",
    sub: "متابعة وإشراف ميداني",
    Icon: Clock,
  },
];

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
                    {stat.num}
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

