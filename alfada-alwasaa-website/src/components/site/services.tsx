"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import {
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  MonitorSmartphone,
  Ship,
  CheckCircle2,
  ArrowLeft,
  Sparkles,
  ExternalLink,
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { SITE_CONFIG } from "@/config/site";
import { SERVICES_DATA } from "@/config/services-data";
import { cn } from "@/lib/utils";

const SERVICE_ICONS = [
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  MonitorSmartphone,
  Ship,
];

const SERVICES = SITE_CONFIG.servicesList.map((service, idx) => ({
  ...service,
  Icon: SERVICE_ICONS[idx],
  detail: SERVICES_DATA[service.slug] || null,
}));

export function Services() {
  const [activeSlug, setActiveSlug] = useState(SERVICES[0].slug);
  const activeService = SERVICES.find((s) => s.slug === activeSlug) || SERVICES[0];

  return (
    <section id="services" className="relative overflow-hidden bg-white dark:bg-navy-darker py-12 sm:py-16 transition-colors duration-300">
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading center kicker="منظومة عمل واحدة" title="خدماتنا" />

        {/* Tab Selector Header - Fully visible 7-grid on desktop, smooth start-aligned scroll on mobile */}
        <Reveal delay={0.05} className="mb-6 sm:mb-8">
          <div className="relative w-full">
            <div className="flex items-center gap-2 overflow-x-auto pb-3 pt-1 scrollbar-none justify-start lg:grid lg:grid-cols-7 lg:gap-2 lg:overflow-visible">
              {SERVICES.map((service) => {
                const isActive = activeSlug === service.slug;
                const Icon = service.Icon;
                return (
                  <button
                    key={service.slug}
                    type="button"
                    onClick={() => setActiveSlug(service.slug)}
                    className={cn(
                      "group relative flex shrink-0 items-center justify-center gap-1.5 rounded-2xl px-3.5 py-2.5 text-xs font-bold transition-all duration-300 lg:w-full lg:px-1.5 lg:py-2.5 lg:text-[11.5px] xl:text-xs xl:px-2",
                      isActive
                        ? "bg-gold text-navy-darker shadow-lg shadow-gold/25 ring-1 ring-gold scale-[1.02] z-10 font-black"
                        : "bg-mist text-slate-700 hover:bg-slate-200/80 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
                    )}
                  >
                    <Icon
                      className={cn(
                        "h-4 w-4 shrink-0 transition-transform duration-300 group-hover:scale-110",
                        isActive ? "text-navy-darker" : "text-gold"
                      )}
                    />
                    <span className="truncate">{service.title}</span>
                    <span
                      className={cn(
                        "hidden xl:inline-block rounded-md px-1.5 py-0.5 text-[10px] font-black font-mono shrink-0",
                        isActive
                          ? "bg-navy-darker/15 text-navy-darker"
                          : "bg-navy/10 text-navy dark:bg-white/10 dark:text-gold-light"
                      )}
                    >
                      #{service.num}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        </Reveal>

        {/* Active Tab Content Display with Framer Motion AnimatePresence */}
        <div className="relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeService.slug}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
              className="relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-6 sm:p-8 lg:p-10 text-white shadow-[0_25px_60px_-15px_rgba(5,30,49,0.7)]"
            >
              {/* Subtle background glow effect */}
              <div
                aria-hidden
                className="pointer-events-none absolute -end-24 -top-24 h-80 w-80 rounded-full bg-gold/15 blur-3xl"
              />

              <div className="grid items-center gap-8 lg:grid-cols-12 lg:gap-10">
                {/* Information Column (7 cols) */}
                <div className="flex flex-col justify-between lg:col-span-7">
                  <div>
                    {/* Badge & Number */}
                    <div className="flex items-center gap-3">
                      <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-gold-light ring-1 ring-gold/40 shadow-inner">
                        <activeService.Icon className="h-5 w-5" strokeWidth={1.8} />
                      </span>
                      <span className="rounded-full bg-white/10 px-3 py-1 font-mono text-xs font-black text-gold-light ring-1 ring-white/15">
                        الخدمة رقم #{activeService.num}
                      </span>
                      <span className="inline-flex items-center gap-1 text-xs font-bold text-gold-light">
                        <Sparkles className="h-3.5 w-3.5" />
                        <span>منظومة معتمدة</span>
                      </span>
                    </div>

                    {/* Title & Short Description */}
                    <h3 className="mt-4 text-2xl sm:text-3xl font-black text-white leading-tight">
                      {activeService.title}
                    </h3>
                    <p className="mt-2.5 text-base sm:text-lg leading-8 text-white/85">
                      {activeService.desc}
                    </p>

                    {/* Subtitle / Context from Detailed Data */}
                    {activeService.detail?.subtitle && (
                      <p className="mt-2 text-sm leading-7 text-gold-soft/90">
                        {activeService.detail.subtitle}
                      </p>
                    )}

                    {/* Key Feature Bullets */}
                    {activeService.detail?.features && (
                      <div className="mt-5 border-t border-white/10 pt-4">
                        <span className="text-xs font-black uppercase tracking-wider text-gold-light">
                          أبرز ركائز التنفيذ المعتمدة:
                        </span>
                        <div className="mt-3 grid gap-2 sm:grid-cols-2">
                          {activeService.detail.features.slice(0, 4).map((feat, fIdx) => (
                            <div
                              key={fIdx}
                              className="flex items-start gap-2 rounded-xl bg-white/5 p-2.5 ring-1 ring-white/10"
                            >
                              <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-gold" />
                              <div>
                                <span className="block text-xs font-bold text-white">
                                  {feat.title}
                                </span>
                                <span className="block text-[11px] leading-4 text-white/70">
                                  {feat.desc}
                                </span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Actions & Links */}
                  <div className="mt-7 flex flex-wrap items-center gap-3 pt-4 border-t border-white/10">
                    <Link
                      href={`/services/${activeService.slug}`}
                      className="inline-flex items-center gap-2 rounded-2xl bg-gold px-5 py-2.5 text-xs sm:text-sm font-black text-navy-darker shadow-lg transition-all duration-300 hover:bg-gold-light hover:scale-105 active:scale-95"
                    >
                      <span>تفاصيل الخدمة والمواصفات الفنية</span>
                      <ArrowLeft className="h-4 w-4" />
                    </Link>

                    <a
                      href="#contact"
                      className="inline-flex items-center gap-2 rounded-2xl bg-white/10 px-4 py-2.5 text-xs sm:text-sm font-bold text-white ring-1 ring-white/15 transition-all duration-300 hover:bg-white/20 hover:text-gold-light"
                    >
                      <span>طلب عرض سعر مباشر</span>
                      <ExternalLink className="h-3.5 w-3.5" />
                    </a>
                  </div>
                </div>

                {/* Media Image Column (5 cols) */}
                <div className="relative lg:col-span-5">
                  <div className="group relative aspect-[16/11] max-h-[380px] w-full overflow-hidden rounded-2xl border-2 border-gold/30 shadow-2xl bg-navy-darker transition-all duration-400 ease-out hover:-translate-y-0.5 hover:border-gold/60">
                    {activeService.detail?.image ? (
                      <Image
                        src={activeService.detail.image}
                        alt={activeService.title}
                        fill
                        loading="lazy"
                        sizes="(max-width: 1024px) 100vw, 40vw"
                        className="object-cover transition-transform duration-400 ease-out group-hover:scale-[1.03]"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center bg-navy-deep">
                        <activeService.Icon className="h-16 w-16 text-gold/40" />
                      </div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/70 via-transparent to-transparent" />

                    <div className="absolute bottom-3 start-3 end-3 flex items-center justify-between rounded-xl bg-navy-darker/80 px-3 py-2 backdrop-blur-md border border-white/10">
                      <span className="text-[11px] font-bold text-gold-light">
                        {activeService.title}
                      </span>
                      <span className="text-[10px] text-white/80">
                        تنفيذ احترافي مطابق للمواصفات
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Company Guarantee & Tagline Banner */}
        <Reveal delay={0.2} className="mt-8">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 rounded-2xl border border-navy/10 dark:border-white/10 bg-mist dark:bg-navy p-5 sm:p-6 text-slate-800 dark:text-white transition-colors">
            <div className="flex items-center gap-3">
              <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-navy dark:bg-navy-darker p-1 ring-1 ring-gold/40">
                <Image
                  src={SITE_CONFIG.assets.logoMark}
                  alt={SITE_CONFIG.company.shortName}
                  fill
                  sizes="40px"
                  className="object-contain"
                />
              </div>
              <div>
                <p className="text-sm font-black text-navy dark:text-gold-light">
                  {SITE_CONFIG.company.tagline}
                </p>
                <p className="text-xs text-slate-600 dark:text-white/70">
                  كافة القطاعات تُدار بتنسيق هندسي وإشراف تنفيذي صارم يضمن أعلى معايير الإنجاز.
                </p>
              </div>
            </div>

            <a
              href="#contact"
              className="shrink-0 rounded-full bg-navy dark:bg-gold px-5 py-2 text-xs font-bold text-white dark:text-navy-darker shadow-sm transition hover:scale-105"
            >
              اطلب دراسة مشروعك الآن
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
