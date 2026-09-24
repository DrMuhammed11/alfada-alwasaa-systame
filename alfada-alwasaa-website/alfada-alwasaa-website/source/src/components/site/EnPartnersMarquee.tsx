"use client";

import {
  RadioTower,
  Flame,
  Building2,
  Ship,
  Truck,
  Factory,
  Globe2,
  ShieldCheck,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

const PARTNER_ICONS = [
  RadioTower,
  Flame,
  Building2,
  Ship,
  Truck,
  Factory,
  Globe2,
  ShieldCheck,
];

export function EnPartnersMarquee() {
  const reduce = useReducedMotion();
  const marqueeItems = [
    ...EN_SITE_CONFIG.partnerCategories,
    ...EN_SITE_CONFIG.partnerCategories,
  ];

  return (
    <section className="py-12 bg-slate-50 dark:bg-navy-darker/40 border-b border-navy/5 dark:border-white/5 overflow-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mb-6 text-center">
        <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-gold-light">
          Ecosystem Network & Strategic Sectors
        </span>
      </div>
      <div className="relative w-full overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_10%,black_90%,transparent)]">
        <div className={`flex w-max gap-6 py-2${reduce ? "" : " marquee-track"}`}>
          {marqueeItems.map((name, idx) => {
            const IconComp = PARTNER_ICONS[idx % PARTNER_ICONS.length];
            return (
              <div
                key={idx}
                className="inline-flex items-center gap-2.5 rounded-full border border-navy/10 dark:border-white/10 bg-white dark:bg-navy px-5 py-2.5 shadow-sm text-xs font-bold text-navy dark:text-white shrink-0"
              >
                <IconComp className="h-4 w-4 text-gold" />
                <span>{name}</span>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export default EnPartnersMarquee;
