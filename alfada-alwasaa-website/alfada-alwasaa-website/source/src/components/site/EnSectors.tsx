"use client";

/**
 * English Strategic Sectors — premium showcase with a centered filter strip
 * (pills fit on one line when there is room, scroll as a single strip when
 * tight — they never orphan-wrap), sector icons, ghost numbering, and
 * staggered photography with hover captions. Mirrors the Arabic sectors.tsx.
 */

import { useState } from "react";
import Image from "next/image";
import {
  CheckCircle2,
  ArrowRight,
  RadioTower,
  Building2,
  Package,
  Truck,
  TrendingUp,
  type LucideIcon,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { cn } from "@/lib/utils";

export interface EnSectorCmsItem {
  titleEn: string; descEn?: string; services?: string[];
  photos?: { src: string; alt?: string }[]; order?: number;
}

const FALLBACK_PHOTOS = [
  { src: "/profile/site_telecom_tower.webp", alt: "Field operations" },
  { src: "/profile/road_roller.webp", alt: "Site works" },
];

const SECTOR_ICONS: Record<string, LucideIcon> = {
  "01": RadioTower,
  "02": Building2,
  "03": Package,
  "04": Truck,
  "05": TrendingUp,
};

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
    <section id="sectors" className="relative overflow-hidden py-16 bg-slate-50 dark:bg-navy-darker/60 transition-colors duration-300">
      <div
        aria-hidden
        className="pointer-events-none absolute -top-24 start-1/4 h-72 w-72 rounded-full bg-gold/5 blur-3xl"
      />
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto">
          <SectionHeading center kicker="Core Strategic Sectors" title="Five Strategic Sectors" />
          <Reveal delay={0.1}>
            <p className="-mt-6 text-sm sm:text-base leading-7 text-slate-600 dark:text-slate-300">
              Delivering integrated solutions that combine engineering expertise, heavy equipment, and nationwide logistics capabilities.
            </p>
          </Reveal>
        </div>

        {/* Filter strip — centered when it fits, a single scrollable line when tight */}
        <Reveal delay={0.15}>
          <div className="mt-10 overflow-x-auto scrollbar-none -mx-4 px-4 sm:mx-0 sm:px-0">
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
              {sectors.map((s) => {
                const Icon = SECTOR_ICONS[s.num];
                return (
                  <button
                    key={s.num}
                    type="button"
                    onClick={() => setActiveFilter(s.num)}
                    aria-pressed={activeFilter === s.num}
                    className={cn(
                      "flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-3.5 py-2 text-xs font-bold transition-all duration-300",
                      activeFilter === s.num
                        ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                        : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
                    )}
                  >
                    {Icon && <Icon className="h-3.5 w-3.5 text-gold" />}
                    <span>{s.title}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </Reveal>

        <div className="mt-10 space-y-8 sm:space-y-10">
          {filteredSectors.map((sec, idx) => {
            const Icon = SECTOR_ICONS[sec.num] || Building2;
            return (
              <Reveal key={sec.num} index={idx}>
                <div className="group/card relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 lg:p-10 shadow-md hover:shadow-xl hover:border-gold/40 transition-all duration-300">
                  {/* Ghost sector number */}
                  <span
                    aria-hidden
                    className="pointer-events-none absolute -top-5 end-4 select-none font-mono text-[5.5rem] font-black leading-none text-navy/[0.04] dark:text-white/[0.04]"
                  >
                    {sec.num}
                  </span>

                  <div className="relative grid gap-8 lg:grid-cols-12 items-center">
                    <div className="lg:col-span-7 space-y-4">
                      <div className="flex items-center gap-3">
                        <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gold/15 dark:bg-gold/20 border border-gold/30 shadow-xs">
                          <Icon className="h-5 w-5 text-gold" />
                        </span>
                        <span className="inline-block rounded-full bg-gold/10 px-3.5 py-1 text-xs font-black text-navy dark:text-gold-light border border-gold/30 font-mono">
                          Sector {sec.num}
                        </span>
                      </div>

                      <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white leading-tight">
                        {sec.title}
                      </h3>

                      <ul className="space-y-2 pt-1">
                        {sec.services.map((item, sIdx) => (
                          <li key={sIdx} className="flex items-start gap-2.5 text-sm text-slate-600 dark:text-slate-300">
                            <CheckCircle2 className="h-4 w-4 shrink-0 text-gold mt-0.5" />
                            <span>{item}</span>
                          </li>
                        ))}
                      </ul>

                      <div className="pt-3 flex items-center gap-3">
                        <a
                          href="#contact"
                          className="inline-flex items-center gap-2 rounded-xl bg-gold px-5 py-2.5 text-xs font-black text-navy-darker hover:bg-gold-light hover:scale-[1.02] transition-all shadow-sm"
                        >
                          <span>Inquire About This Sector</span>
                          <ArrowRight className="h-3.5 w-3.5" />
                        </a>
                      </div>
                    </div>

                    <div className="lg:col-span-5">
                      <div className="grid grid-cols-2 items-start gap-3 sm:gap-4 lg:gap-5">
                        {sec.photos.map((ph, pIdx) => (
                          <div
                            key={pIdx}
                            className={`group/photo relative aspect-[4/3] overflow-hidden rounded-2xl bg-navy-darker shadow-sm ring-1 ring-navy/10 dark:ring-white/10 ${pIdx === 1 ? "lg:mt-10" : ""}`}
                          >
                            <Image
                              src={ph.src}
                              alt={ph.alt}
                              fill
                              loading="lazy"
                              decoding="async"
                              sizes="(max-width: 1024px) 50vw, 20vw"
                              className="object-cover transition-transform duration-500 group-hover/photo:scale-105"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/70 via-transparent to-transparent opacity-0 transition-opacity duration-300 group-hover/photo:opacity-100" />
                            <span className="absolute bottom-2.5 start-2.5 end-2.5 text-[10px] font-bold text-white opacity-0 transition-opacity duration-300 group-hover/photo:opacity-100 line-clamp-1 drop-shadow-md">
                              {ph.alt}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export default EnSectors;
