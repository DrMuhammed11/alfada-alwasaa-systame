"use client";

import Image from "next/image";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnTrackRecord() {
  return (
    <section id="track" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Demonstrated Accomplishments
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Field Execution Case Studies
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Delivering cross-sector projects with strict adherence to engineering codes, logistics compliance, and operational reliability.
            </p>
          </div>
        </Reveal>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {EN_SITE_CONFIG.trackRecord.map((tr, idx) => (
            <Reveal key={tr.id} index={idx}>
              <div className="h-full overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy shadow-md hover:shadow-xl transition">
                <div className="relative aspect-[16/10] bg-navy-darker">
                  <Image
                    src={tr.src}
                    alt={tr.title}
                    fill
                    loading="lazy"
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                  <span className="absolute top-3 start-3 rounded-full bg-navy/90 px-3 py-1 text-[11px] font-bold text-gold-light border border-gold/30">
                    {tr.tag}
                  </span>
                </div>
                <div className="p-5">
                  <h3 className="text-base font-bold text-navy dark:text-white">{tr.title}</h3>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">{tr.desc}</p>
                  <p className="mt-3 text-[11px] font-semibold text-navy dark:text-gold-light border-t border-slate-100 dark:border-white/10 pt-2">
                    {tr.metrics}
                  </p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnTrackRecord;
