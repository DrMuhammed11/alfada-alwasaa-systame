"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import {
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  Ship,
  TrendingUp,
  ArrowRight,
  MessageSquare,
  CheckCircle2,
  Sparkles,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SERVICES_DATA } from "@/config/services-data";
import { EN_SERVICES_DATA } from "@/config/en-services-data";
import { SITE_CONFIG } from "@/config/site";
import { Reveal } from "./reveal";

const SERVICE_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  contracting: Building2,
  roads: Route,
  excavation: Shovel,
  supplies: Package,
  telecom: RadioTower,
  shipping: Ship,
  marketing: TrendingUp,
};

export function EnServicesTabs() {
  const [activeTab, setActiveTab] = useState("contracting");

  const activeService =
    EN_SITE_CONFIG.servicesList.find((s) => s.slug === activeTab) ||
    EN_SITE_CONFIG.servicesList[0];

  const IconComponent = SERVICE_ICONS[activeService.slug] || Building2;
  const enDetail = EN_SERVICES_DATA[activeService.slug] || null;
  const serviceImage = SERVICES_DATA[activeService.slug]?.image || "/profile/hero_bg.webp";

  return (
    <section id="services" className="py-16 bg-white dark:bg-navy-darker transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
              Detailed Services Portfolio
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Integrated Technical, Engineering & Business Services
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Explore our key service areas, review execution specifications, or request a project quotation
            </p>
          </div>
        </Reveal>

        {/* Service Tabs Header */}
        <Reveal delay={0.05}>
          <div className="mb-10 overflow-x-auto scrollbar-none -mx-4 px-4 sm:mx-0 sm:px-0">
            <div className="mx-auto flex w-fit max-w-full items-center gap-2">
            {EN_SITE_CONFIG.servicesList.map((svc) => {
              const Icon = SERVICE_ICONS[svc.slug] || Building2;
              const isSelected = activeTab === svc.slug;
              return (
                <button
                  key={svc.slug}
                  onClick={() => setActiveTab(svc.slug)}
                  className={`inline-flex shrink-0 items-center gap-2 whitespace-nowrap rounded-2xl px-4 py-2.5 text-xs sm:text-sm font-bold transition-all duration-300 ${
                    isSelected
                      ? "bg-gold text-navy-darker shadow-lg shadow-gold/25 ring-1 ring-gold scale-[1.02] font-black z-10"
                      : "bg-slate-100 dark:bg-white/10 text-slate-700 dark:text-white/80 hover:bg-slate-200 dark:hover:bg-white/15"
                  }`}
                >
                  <Icon className={`h-4 w-4 ${isSelected ? "text-navy-darker" : "text-gold"}`} />
                  <span>{svc.title}</span>
                  <span
                    className={`hidden sm:inline-block rounded-md px-1.5 py-0.5 text-[10px] font-mono font-black ${
                      isSelected ? "bg-navy-darker/15 text-navy-darker" : "bg-navy/10 text-navy dark:bg-white/10 dark:text-gold-light"
                    }`}
                  >
                    #{svc.num}
                  </span>
                </button>
              );
            })}
            </div>
          </div>
        </Reveal>

        {/* Active Service Tab Detail with luxury dark gradient matching Arabic */}
        <div className="relative">
          <div
            key={activeService.slug}
            className="fade-pop-enter relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-6 sm:p-8 lg:p-10 text-white shadow-[0_25px_60px_-15px_rgba(5,30,49,0.7)]"
          >
            {/* Subtle background glow effect */}
            <div
              aria-hidden
              className="pointer-events-none absolute -end-24 -top-24 h-80 w-80 rounded-full bg-gold/15 blur-3xl"
            />
            <div aria-hidden className="dot-grid pointer-events-none absolute inset-0 opacity-10" />
            <span aria-hidden className="absolute -top-1.5 -start-1.5 h-8 w-8 rounded-tl-2xl border-t-2 border-s-2 border-gold" />
            <span aria-hidden className="absolute -bottom-1.5 -end-1.5 h-8 w-8 rounded-br-2xl border-b-2 border-e-2 border-gold" />

            <div className="grid items-center gap-8 lg:grid-cols-12 lg:gap-10">
              <div className="flex flex-col justify-between lg:col-span-7 space-y-4">
                <div>
                  <div className="flex items-center gap-3">
                    <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-gold-light ring-1 ring-gold/40 shadow-inner">
                      <IconComponent className="h-5 w-5" />
                    </span>
                    <span className="rounded-full bg-white/10 px-3 py-1 font-mono text-xs font-black text-gold-light ring-1 ring-white/15">
                      SERVICE #{activeService.num}
                    </span>
                    <span className="inline-flex items-center gap-1 text-xs font-bold text-gold-light">
                      <Sparkles className="h-3.5 w-3.5" />
                      <span>Certified Portfolio</span>
                    </span>
                  </div>

                  <h3 className="mt-4 text-2xl sm:text-3xl font-black text-white leading-tight">
                    {activeService.title}
                  </h3>
                  <p className="mt-2.5 text-base sm:text-lg leading-relaxed text-white/85">
                    {activeService.desc}
                  </p>

                  {enDetail?.subtitle && (
                    <p className="mt-2 text-sm leading-relaxed text-gold-soft/90">
                      {enDetail.subtitle}
                    </p>
                  )}

                  {/* Key Feature Bullets */}
                  {enDetail?.features && (
                    <div className="mt-5 border-t border-white/10 pt-4">
                      <span className="text-xs font-black uppercase tracking-wider text-gold-light">
                        Core Execution Specifications:
                      </span>
                      <div className="mt-3 grid gap-2 sm:grid-cols-2">
                        {enDetail.features.slice(0, 4).map((feat, fIdx) => (
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

                <div className="pt-4 flex flex-wrap items-center gap-3 border-t border-white/10">
                  <Link
                    href={`/en/services/${activeService.slug}`}
                    className="inline-flex items-center gap-2 rounded-2xl bg-gold px-5 py-2.5 text-xs sm:text-sm font-black text-navy-darker hover:bg-gold-light hover:scale-105 active:scale-95 transition-all shadow-md"
                  >
                    <span>Technical Details & Scope</span>
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                  <a
                    href="#contact"
                    className="inline-flex items-center gap-2 rounded-2xl bg-white/10 px-4 py-2.5 text-xs sm:text-sm font-bold text-white ring-1 ring-white/15 hover:bg-white/20 hover:text-gold-light transition"
                  >
                    <span>Request a Quote</span>
                  </a>
                  <a
                    href={`https://wa.me/${EN_SITE_CONFIG.contacts.general.waNumber}?text=${encodeURIComponent(
                      `Hello, I would like to inquire about ${activeService.title} services.`
                    )}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-2xl bg-emerald-500/20 px-4 py-2.5 text-xs sm:text-sm font-bold text-emerald-300 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                  >
                    <MessageSquare className="h-4 w-4" />
                    <span>WhatsApp</span>
                  </a>
                </div>
              </div>

              <div className="lg:col-span-5">
                <div className="group relative aspect-[16/11] max-h-[380px] w-full overflow-hidden rounded-2xl border-2 border-gold/30 shadow-2xl bg-navy-darker transition-all duration-400 ease-out hover:-translate-y-0.5 hover:border-gold/60">
                  <Image
                    src={serviceImage}
                    alt={activeService.title}
                    fill
                    loading="lazy"
                    sizes="(max-width: 1024px) 100vw, 40vw"
                    className="object-cover transition-transform duration-400 ease-out group-hover:scale-[1.03]"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 via-transparent to-transparent" />
                  <div className="absolute bottom-3 start-3 end-3 flex items-center justify-between rounded-xl bg-navy-darker/80 px-3 py-2 backdrop-blur-md border border-white/10">
                    <span className="text-[11px] font-bold text-gold-light">
                      {activeService.title}
                    </span>
                    <span className="text-[10px] text-white/80">
                      Standard Compliance
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Company Guarantee & Tagline Banner */}
        <Reveal delay={0.2} className="mt-8">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 rounded-2xl border border-navy/10 dark:border-white/10 bg-mist dark:bg-navy p-5 sm:p-6 text-slate-800 dark:text-white transition-colors">
            <div className="flex items-center gap-3">
              <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-navy dark:bg-navy-darker p-1 ring-1 ring-gold/40">
                <Image
                  src={SITE_CONFIG.assets.logoMark}
                  alt="Al-Fada Al-Wasaa"
                  fill
                  sizes="40px"
                  className="object-contain"
                />
              </div>
              <div>
                <p className="text-sm font-black text-navy dark:text-gold-light">
                  {EN_SITE_CONFIG.company.tagline}
                </p>
                <p className="text-xs text-slate-600 dark:text-white/70">
                  Every sector is delivered under rigorous engineering coordination and executive supervision.
                </p>
              </div>
            </div>
            <a
              href="#contact"
              className="shrink-0 rounded-full bg-navy dark:bg-gold px-5 py-2 text-xs font-bold text-white dark:text-navy-darker shadow-sm transition hover:scale-105"
            >
              Request a Project Study Now
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default EnServicesTabs;
