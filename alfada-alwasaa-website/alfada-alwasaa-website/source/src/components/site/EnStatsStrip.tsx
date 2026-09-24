"use client";

import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnStatsStrip() {
  return (
    <section className="relative -mt-6 z-20 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <Reveal>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 shadow-xl">
          {EN_SITE_CONFIG.stats.map((st, i) => (
            <div
              key={i}
              className="text-center sm:text-left border-b sm:border-b-0 sm:border-r border-slate-100 dark:border-white/10 last:border-0 p-3"
            >
              <span className="block text-3xl sm:text-4xl font-black text-navy dark:text-gold tracking-tight">
                {st.num}
              </span>
              <h4 className="mt-1 text-sm font-bold text-slate-900 dark:text-white">
                {st.label}
              </h4>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                {st.sub}
              </p>
            </div>
          ))}
        </div>
      </Reveal>
    </section>
  );
}

export default EnStatsStrip;
