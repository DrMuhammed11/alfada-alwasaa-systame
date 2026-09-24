"use client";

import { Gem } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnPosition() {
  return (
    <section id="position" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 text-center">
        <Reveal>
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
            {EN_SITE_CONFIG.position.kicker}
          </span>
          <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
            {EN_SITE_CONFIG.position.title}
          </h2>

          <div className="relative mx-auto my-8 flex w-fit flex-col items-center">
            <span className="flex h-20 w-20 items-center justify-center rounded-full bg-navy text-gold-light shadow-xl">
              <Gem className="h-10 w-10" />
            </span>
          </div>

          <p className="text-base sm:text-lg leading-relaxed text-slate-700 dark:text-slate-200">
            {EN_SITE_CONFIG.position.p1}
          </p>
          <p className="mt-4 text-base sm:text-lg leading-relaxed text-slate-700 dark:text-slate-200">
            {EN_SITE_CONFIG.position.p2}
          </p>
        </Reveal>
      </div>
    </section>
  );
}

export default EnPosition;
