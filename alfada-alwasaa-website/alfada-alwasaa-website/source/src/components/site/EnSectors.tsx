"use client";

/**
 * English Strategic Sectors — showcase cards with a centered filter strip
 * (mirrors the Arabic sectors.tsx: pills fit on one line when there is room,
 * scroll as a single strip when tight — they never orphan-wrap).
 */

import { useState } from "react";
import Image from "next/image";
import { CheckCircle2, ArrowRight } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";
import { cn } from "@/lib/utils";

export interface EnSectorCmsItem {
  titleEn: string; descEn?: string; services?: string[];
  photos?: { src: string; alt?: string }[]; order?: number;
}

const FALLBACK_PHOTOS = [
  { src: "/profile/site_telecom_tower.webp", alt: "Field operations" },
  { src: "/profile/road_roller.webp", alt: "Site works" },
];

export function EnSectors({ items }: { items?: EnSectorCmsItem[] }) {
  const [activeFilter, setActiveFilter] = useState("all");
  const sectors =
    items && items.length > 0
      ? items.map((s, i) => ({
          num: String(s.order ?? i + 1).padStart(2, "0"),
          title: s.titleEn,
          services: s.services ?? (s.descEn ? [s.descEn] : []),
          photos: s.photos && s.photos.length > 0 ? s.photos : FALLBACK_PHOTOS,
        }))
      : EN_SITE_CONFIG.sectors;
  const filteredSectors =
    activeFilter === "all"
      ? sectors
      : sectors.filter((s) => s.num === activeFilter);

  return (
    <section id="sectors" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Core Strategic Sectors
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Five Pillars of Operational Mastery
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Deploying interconnected capabilities that combine engineering proficiency, heavy equipment fleets, and nationwide logistics readiness.
            </p>
          </div>
        </Reveal>

        {/* Filter strip — centered when it fits, a single scrollable line when tight */}
        <Reveal delay={0.1}>
          <div className="mb-10 overflow-x-auto scrollbar-none -mx-4 px-4 sm:mx-0 sm:px-0">
            <div className="mx-auto flex w-fit max-w-full items-center gap-2 sm:gap-2.5">
              <button
                type="button"
                onClick={() => setActiveFilter("all")}
                aria-pressed={activeFilter === "all"}
                className={cn(
                  "shrink-0 whitespace-nowrap rounded-full px-4 py-2 text-xs font-bold transition-all duration-300",
                  activeFilter === "all"
                    ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                    : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
                )}
              >
                All Sectors ({sectors.length})
              </button>
              {sectors.map((s) => (
                <button
                  key={s.num}
                  type="button"
                  onClick={() => setActiveFilter(s.num)}
                  aria-pressed={activeFilter === s.num}
                  className={cn(
                    "shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-3.5 py-2 text-xs font-bold transition-all duration-300",
                    activeFilter === s.num
                      ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                      : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
                  )}
                >
                  <span>{s.title}</span>
                </button>
              ))}
            </div>
          </div>
        </Reveal>

        <div className="space-y-12">
          {filteredSectors.map((sec, idx) => (
            <Reveal key={sec.num} index={idx}>
              <div className="overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 shadow-md hover:shadow-xl transition">
                <div className="grid gap-8 lg:grid-cols-12 items-center">
                  <div className="lg:col-span-7 space-y-4">
                    <span className="inline-block rounded-full bg-gold/10 px-3 py-1 text-xs font-extrabold text-gold-light border border-gold/30 font-mono">
                      Sector {sec.num}
                    </span>
                    <h3 className="text-2xl font-black text-navy dark:text-white">{sec.title}</h3>
                    <ul className="space-y-2 pt-2">
                      {sec.services.map((item, sIdx) => (
                        <li key={sIdx} className="flex items-start gap-2.5 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
                          <CheckCircle2 className="h-4 w-4 text-gold shrink-0 mt-0.5" />
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                    <div className="pt-4 flex items-center gap-3">
                      <a
                        href="#contact"
                        className="inline-flex items-center gap-1.5 rounded-xl bg-gold px-4 py-2 text-xs font-bold text-navy-darker hover:bg-gold-light transition"
                      >
                        <span>Inquire About Sector</span>
                        <ArrowRight className="h-3.5 w-3.5" />
                      </a>
                    </div>
                  </div>

                  <div className="lg:col-span-5">
                    <div className="grid grid-cols-2 items-start gap-3 lg:gap-5">
                      {sec.photos.map((ph, pIdx) => (
                        <div key={pIdx} className={`relative aspect-[4/3] overflow-hidden rounded-2xl bg-navy-darker ${pIdx === 1 ? "lg:mt-10" : ""}`}>
                          <Image
                            src={ph.src}
                            alt={ph.alt}
                            fill
                            loading="lazy"
                            sizes="(max-width: 1024px) 50vw, 20vw"
                            className="object-cover hover:scale-105 transition duration-500"
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnSectors;
