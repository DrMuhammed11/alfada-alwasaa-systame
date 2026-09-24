"use client";

import { Handshake } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnConclusion() {
  return (
    <section id="conclusion" className="py-16 bg-slate-50 dark:bg-navy-darker/60 transition-colors duration-300">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 text-center">
        <Reveal>
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
            {EN_SITE_CONFIG.conclusion.kicker}
          </span>
          <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
            {EN_SITE_CONFIG.conclusion.title}
          </h2>

          <div className="relative mx-auto my-10 pt-4">
            <div
              aria-hidden
              className="pointer-events-none absolute inset-x-12 top-0 bottom-0 rounded-[2.5rem] bg-gradient-to-r from-gold/20 via-gold-light/10 to-transparent blur-2xl opacity-60"
            />
            <div className="relative rounded-[2.5rem] bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-8 sm:p-12 text-white shadow-2xl border border-white/15">
              <span className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-navy text-gold-light ring-2 ring-gold/40 shadow-xl">
                <Handshake className="h-10 w-10" strokeWidth={1.8} />
              </span>
              <p className="text-base sm:text-lg leading-relaxed text-white/95 max-w-3xl mx-auto">
                {EN_SITE_CONFIG.conclusion.text}
              </p>
              <div className="mt-8 flex items-center justify-center gap-3">
                <span className="h-0.5 w-10 bg-gradient-to-r from-transparent to-gold rounded-full" />
                <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
                <span className="h-0.5 w-10 bg-gradient-to-l from-transparent to-gold rounded-full" />
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default EnConclusion;
