"use client";

import { Award, HardHat, FileCheck2, ShieldCheck } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnCompliance() {
  return (
    <section className="py-14 bg-white dark:bg-navy-darker border-b border-navy/5 dark:border-white/5">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light ring-1 ring-gold/30">
              Institutional Compliance & Certifications
            </span>
            <h2 className="mt-2 text-2xl sm:text-3xl font-extrabold text-navy dark:text-white">
              Approved Engineering Standards & Trusted Credentials
            </h2>
            <p className="mt-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
              Upholding rigorous international benchmarks across safety, materials testing, and technical compliance.
            </p>
          </div>
        </Reveal>

        <div className="grid gap-4 sm:gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {EN_SITE_CONFIG.compliance.map((item, idx) => (
            <Reveal key={idx} index={idx}>
              <div className="h-full flex flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50/80 dark:bg-navy p-5 shadow-sm hover:border-gold/60 transition">
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 text-gold-light dark:text-gold">
                      {idx === 0 ? (
                        <Award className="h-5 w-5" />
                      ) : idx === 1 ? (
                        <HardHat className="h-5 w-5" />
                      ) : idx === 2 ? (
                        <FileCheck2 className="h-5 w-5" />
                      ) : (
                        <ShieldCheck className="h-5 w-5" />
                      )}
                    </span>
                    <span className="rounded-full bg-gold/10 px-2.5 py-0.5 text-[10px] font-bold text-navy dark:text-gold-light border border-gold/30">
                      {item.badge}
                    </span>
                  </div>
                  <h3 className="text-sm font-bold text-navy dark:text-white">{item.title}</h3>
                  <p className="mt-1 text-[11px] font-semibold text-gold dark:text-gold-light">{item.subtitle}</p>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">{item.desc}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnCompliance;
