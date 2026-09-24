"use client";

import { HandHeart, Eye } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnVisionMission() {
  return (
    <section id="vision" className="py-16 bg-white dark:bg-navy-darker">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-12">
            <h2 className="text-3xl font-extrabold text-navy dark:text-white sm:text-4xl">
              {EN_SITE_CONFIG.visionMission.title}
            </h2>
          </div>
        </Reveal>

        <div className="grid gap-8 md:grid-cols-2">
          <Reveal index={0}>
            <div className="h-full rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 shadow-md">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6 shadow-sm">
                <HandHeart className="h-7 w-7" />
              </div>
              <h3 className="text-2xl font-bold text-navy dark:text-white">
                {EN_SITE_CONFIG.visionMission.mission.title}
              </h3>
              <p className="mt-4 text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {EN_SITE_CONFIG.visionMission.mission.text}
              </p>
            </div>
          </Reveal>

          <Reveal index={1}>
            <div className="h-full rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 shadow-md">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6 shadow-sm">
                <Eye className="h-7 w-7" />
              </div>
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
