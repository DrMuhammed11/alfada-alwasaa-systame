"use client";

import { Handshake } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnConclusion() {
  return (
    <section id="conclusion" className="py-12 bg-slate-50 dark:bg-navy-darker/60">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 text-center">
        <Reveal>
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
            {EN_SITE_CONFIG.conclusion.kicker}
          </span>
          <h2 className="mt-2 text-2xl sm:text-3xl font-extrabold text-navy dark:text-white">
            {EN_SITE_CONFIG.conclusion.title}
          </h2>

          <div className="relative mx-auto my-8 rounded-3xl bg-navy p-8 sm:p-10 text-white shadow-xl border border-white/10">
            <span className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-navy-darker text-gold-light border-2 border-gold/40 shadow-md">
              <Handshake className="h-10 w-10" />
            </span>
            <p className="text-base sm:text-lg leading-relaxed text-white/90">
              {EN_SITE_CONFIG.conclusion.text}
            </p>
            <span className="mx-auto mt-6 block h-1 w-24 rounded-full bg-gold" />
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default EnConclusion;
