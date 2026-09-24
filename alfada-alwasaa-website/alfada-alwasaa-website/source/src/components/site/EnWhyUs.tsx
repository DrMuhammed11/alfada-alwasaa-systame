"use client";

import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnWhyUs() {
  return (
    <section id="why" className="py-16 bg-slate-50 dark:bg-navy-darker/60 transition-colors duration-300">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-12">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
              Core Execution Principles
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white sm:text-4xl">
              Why Partner With Al-Fada Al-Wasaa?
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Delivering consistent engineering quality and institutional reliability across every major engagement.
            </p>
          </div>
        </Reveal>

        <div className="grid gap-6 sm:grid-cols-3">
          {EN_SITE_CONFIG.values.map((val, idx) => (
            <Reveal key={val.title} index={idx}>
              <div className="group relative h-full rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-sm hover:shadow-2xl hover:border-gold/50 hover:-translate-y-1.5 transition-all duration-300">
                <div className="flex items-center justify-between mb-4">
                  <span className="inline-block h-2 w-10 rounded-full bg-gold transition-all duration-300 group-hover:w-16" />
                  <span className="font-mono text-xs font-black text-gold-dark dark:text-gold-light bg-gold/10 px-2.5 py-0.5 rounded-md">
                    0{idx + 1}
                  </span>
                </div>
                <h3 className="text-lg font-bold text-navy dark:text-white">{val.title}</h3>
                <p className="mt-2.5 text-xs sm:text-sm leading-6 text-slate-600 dark:text-slate-300">{val.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnWhyUs;
