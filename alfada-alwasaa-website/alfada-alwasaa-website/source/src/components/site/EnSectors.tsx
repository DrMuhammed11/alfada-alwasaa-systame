"use client";

import Image from "next/image";
import { CheckCircle2, ArrowRight } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export interface EnSectorCmsItem {
  titleEn: string; descEn?: string; services?: string[];
  photos?: { src: string; alt?: string }[]; order?: number;
}

const FALLBACK_PHOTOS = [
  { src: "/profile/site_telecom_tower.webp", alt: "Field operations" },
  { src: "/profile/road_roller.webp", alt: "Site works" },
];

export function EnSectors({ items }: { items?: EnSectorCmsItem[] }) {
  const sectors =
    items && items.length > 0
      ? items.map((s, i) => ({
          num: String(s.order ?? i + 1).padStart(2, "0"),
          title: s.titleEn,
          services: s.services ?? (s.descEn ? [s.descEn] : []),
          photos: s.photos && s.photos.length > 0 ? s.photos : FALLBACK_PHOTOS,
        }))
      : EN_SITE_CONFIG.sectors;
  return (
    <section id="sectors" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-3xl mx-auto mb-12">
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

        <div className="space-y-12">
          {sectors.map((sec, idx) => (
            <Reveal key={sec.num} index={idx}>
              <div className="overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 shadow-md hover:shadow-xl transition">
                <div className="grid gap-8 lg:grid-cols-12 items-center">
                  <div className="lg:col-span-6 space-y-4">
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

                  <div className="lg:col-span-6">
                    <div className="grid grid-cols-2 gap-3">
                      {sec.photos.map((ph, pIdx) => (
                        <div key={pIdx} className="relative aspect-[4/3] overflow-hidden rounded-2xl bg-navy-darker">
                          <Image
                            src={ph.src}
                            alt={ph.alt}
                            fill
                            loading="lazy"
                            sizes="(max-width: 1024px) 50vw, 25vw"
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
