"use client";

import { Star, Quote } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnTestimonials() {
  return (
    <section className="py-16 bg-white dark:bg-navy-darker">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Client & Partner Testimonials
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Endorsements of Operational Trust
            </h2>
          </div>
        </Reveal>

        <div className="grid gap-6 md:grid-cols-3">
          {EN_SITE_CONFIG.testimonials.map((t, idx) => (
            <Reveal key={idx} index={idx}>
              <div className="h-full flex flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6 shadow-sm hover:border-gold/50 transition">
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-1 text-amber-400">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} className="h-4 w-4 fill-amber-400" />
                      ))}
                    </div>
                    <Quote className="h-5 w-5 text-gold-light" />
                  </div>
                  <p className="text-xs sm:text-sm leading-relaxed text-slate-700 dark:text-slate-200">
                    &ldquo;{t.quote}&rdquo;
                  </p>
                </div>
                <div className="mt-6 border-t border-slate-200 dark:border-white/10 pt-4">
                  <h4 className="text-sm font-bold text-navy dark:text-white">{t.name}</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{t.role}</p>
                  <span className="inline-block mt-1 text-[11px] font-bold text-gold">{t.sector}</span>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnTestimonials;
