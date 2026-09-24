"use client";

import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnWhyUs() {
  return (
    <section id="why" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Core Principles
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Why Partner With Al-Fada Al-Wasaa?
            </h2>
          </div>
        </Reveal>

        <div className="grid gap-6 sm:grid-cols-3">
          {EN_SITE_CONFIG.values.map((val, idx) => (
            <Reveal key={val.title} index={idx}>
              <div className="h-full rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 shadow-sm hover:border-gold/50 transition">
                <span className="h-2 w-10 rounded-full bg-gold block mb-4" />
                <h3 className="text-lg font-bold text-navy dark:text-white">{val.title}</h3>
                <p className="mt-2 text-xs leading-6 text-slate-600 dark:text-slate-300">{val.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnWhyUs;
