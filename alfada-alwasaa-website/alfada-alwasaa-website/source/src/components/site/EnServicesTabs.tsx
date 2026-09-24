"use client";

import { useState } from "react";
import Image from "next/image";
import {
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  Ship,
  MonitorSmartphone,
  ArrowRight,
  MessageSquare,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";
import { Reveal } from "./reveal";

const SERVICE_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  contracting: Building2,
  roads: Route,
  excavation: Shovel,
  supplies: Package,
  telecom: RadioTower,
  shipping: Ship,
  marketing: MonitorSmartphone,
};

export function EnServicesTabs() {
  const [activeTab, setActiveTab] = useState("contracting");

  const activeService =
    EN_SITE_CONFIG.servicesList.find((s) => s.slug === activeTab) ||
    EN_SITE_CONFIG.servicesList[0];

  return (
    <section id="services" className="py-16 bg-white dark:bg-navy-darker">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Detailed Services Portfolio
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Integrated Technical & Engineering Services
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Browse our key specialization areas, review execution specifications, or request direct tender proposals.
            </p>
          </div>
        </Reveal>

        {/* Service Tabs Header */}
        <Reveal delay={0.05}>
          <div className="flex flex-wrap justify-center gap-2 mb-10">
            {EN_SITE_CONFIG.servicesList.map((svc) => {
              const Icon = SERVICE_ICONS[svc.slug] || Building2;
              const isSelected = activeTab === svc.slug;
              return (
                <button
                  key={svc.slug}
                  onClick={() => setActiveTab(svc.slug)}
                  className={`inline-flex items-center gap-2 rounded-2xl px-4 py-2.5 text-xs sm:text-sm font-bold transition ${
                    isSelected
                      ? "bg-navy dark:bg-gold text-white dark:text-navy-darker shadow-md"
                      : "bg-slate-100 dark:bg-white/10 text-slate-600 dark:text-white/80 hover:bg-slate-200 dark:hover:bg-white/15"
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{svc.title}</span>
                </button>
              );
            })}
          </div>
        </Reveal>

        {/* Active Service Tab Detail with fade-pop-enter CSS animation */}
        <div
          key={activeService.slug}
          className="fade-pop-enter rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6 sm:p-10 shadow-lg"
        >
          <div className="grid gap-8 lg:grid-cols-12 items-center">
            <div className="lg:col-span-7 space-y-4">
              <span className="font-mono text-xs font-bold text-gold-light">SERVICE {activeService.num}</span>
              <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white">{activeService.title}</h3>
              <p className="text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {activeService.desc}
              </p>

              <div className="pt-4 flex flex-wrap items-center gap-3">
                <a
                  href="#contact"
                  className="inline-flex items-center gap-2 rounded-2xl bg-gold px-5 py-3 text-xs sm:text-sm font-black text-navy-darker hover:bg-gold-light transition shadow-md"
                >
                  <span>Request Quotation</span>
                  <ArrowRight className="h-4 w-4" />
                </a>
                <a
                  href={`https://wa.me/${EN_SITE_CONFIG.contacts.general.waNumber}?text=${encodeURIComponent(
                    `Hello, I would like to inquire about ${activeService.title} services.`
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-2xl bg-emerald-500/10 px-4 py-3 text-xs sm:text-sm font-bold text-emerald-700 dark:text-emerald-300 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                >
                  <MessageSquare className="h-4 w-4" />
                  <span>WhatsApp Technical Lead</span>
                </a>
              </div>
            </div>

            <div className="lg:col-span-5">
              <div className="relative aspect-[16/11] overflow-hidden rounded-2xl border border-gold/30 bg-navy-darker shadow-lg">
                <Image
                  src={SITE_CONFIG.assets.heroBg}
                  alt={activeService.title}
                  fill
                  sizes="(max-width: 1024px) 100vw, 40vw"
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

export default EnServicesTabs;
