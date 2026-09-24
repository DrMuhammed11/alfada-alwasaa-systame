"use client";

import { HandHeart, Eye } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnVisionMission() {
  return (
    <section id="vision" className="py-16 bg-white dark:bg-navy-darker transition-colors duration-300">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-12">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
              Corporate Direction & Principles
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white sm:text-4xl">
              {EN_SITE_CONFIG.visionMission.title}
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Guiding execution standards, operational integrity, and long-term institutional value.
            </p>
          </div>
        </Reveal>

        <div className="grid gap-8 md:grid-cols-2 lg:gap-10">
          <Reveal index={0}>
            <div className="group relative h-full overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 sm:p-10 shadow-md hover:shadow-2xl hover:border-gold/50 transition-all duration-300 hover:-translate-y-1.5">
              <div className="flex items-center justify-between mb-6">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold/20 text-gold-dark dark:text-gold-light border border-gold/40 shadow-xs transition-transform duration-300 group-hover:scale-110">
                  <HandHeart className="h-7 w-7 text-gold" strokeWidth={1.8} />
                </div>
                <span className="font-mono text-xs font-black text-gold-dark dark:text-gold-light bg-gold/10 px-3 py-1 rounded-full border border-gold/25">
                  MISSION
                </span>
              </div>

              <span className="h-1.5 w-14 rounded-full bg-gradient-to-r from-gold to-gold-light block mb-4 transition-all duration-300 group-hover:w-24" />

              <h3 className="text-2xl font-bold text-navy dark:text-white">
                {EN_SITE_CONFIG.visionMission.mission.title}
              </h3>
              <p className="mt-4 text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {EN_SITE_CONFIG.visionMission.mission.text}
              </p>
            </div>
          </Reveal>

          <Reveal index={1}>
            <div className="group relative h-full overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 sm:p-10 shadow-md hover:shadow-2xl hover:border-gold/50 transition-all duration-300 hover:-translate-y-1.5">
              <div className="flex items-center justify-between mb-6">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold/20 text-gold-dark dark:text-gold-light border border-gold/40 shadow-xs transition-transform duration-300 group-hover:scale-110">
                  <Eye className="h-7 w-7 text-gold" strokeWidth={1.8} />
                </div>
                <span className="font-mono text-xs font-black text-gold-dark dark:text-gold-light bg-gold/10 px-3 py-1 rounded-full border border-gold/25">
                  VISION
                </span>
              </div>

              <span className="h-1.5 w-14 rounded-full bg-gradient-to-r from-gold to-gold-light block mb-4 transition-all duration-300 group-hover:w-24" />

              <h3 className="text-2xl font-bold text-navy dark:text-white">
                {EN_SITE_CONFIG.visionMission.vision.title}
              </h3>
              <p className="mt-4 text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {EN_SITE_CONFIG.visionMission.vision.text}
              </p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

export default EnVisionMission;
