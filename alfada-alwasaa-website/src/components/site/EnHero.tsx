"use client";

import Image from "next/image";
import type { CSSProperties } from "react";
import { Briefcase, ShieldCheck, Award, MessageSquare } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";

const fadeUpDelay = (delay: number): CSSProperties =>
  ({ "--hero-delay": `${(delay * 0.35).toFixed(3)}s` }) as CSSProperties;

export function EnHero() {
  return (
    <section id="home" className="relative flex items-center overflow-hidden bg-navy-darker pt-28 pb-16 sm:pb-24 text-white">
      <div className="absolute inset-0 -z-10">
        <Image
          src={SITE_CONFIG.assets.heroBg}
          alt="Corporate Project Sites"
          fill
          priority
          sizes="100vw"
          className="object-cover opacity-20 filter brightness-75 contrast-125"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-navy-darker/90 via-navy-darker/60 to-navy-darker" />
      </div>

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-10 lg:grid-cols-12">
          <div className="lg:col-span-7">
            <span
              style={fadeUpDelay(0)}
              className="hero-fade-up inline-flex items-center gap-2 rounded-full border border-gold/40 bg-gold/10 px-4 py-1.5 text-xs font-bold text-gold-light"
            >
              <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
              <span>Multi-Sector Enterprise • Integrated Solutions</span>
            </span>

            <h1
              style={fadeUpDelay(1)}
              className="hero-fade-up mt-4 text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight leading-tight"
            >
              Al-Fada Al-Wasaa <br />
              <span className="bg-gradient-to-r from-gold via-gold-light to-white bg-clip-text text-transparent">
                Telecom & General Contracting
              </span>
            </h1>

            <p
              style={fadeUpDelay(2)}
              className="hero-fade-up mt-3 text-lg font-bold text-gold-light"
            >
              {EN_SITE_CONFIG.company.tagline}
            </p>

            <p
              style={fadeUpDelay(3)}
              className="hero-fade-up mt-4 text-sm sm:text-base leading-relaxed text-white/80 max-w-2xl"
            >
              {EN_SITE_CONFIG.company.brief}
            </p>
            <p
              style={fadeUpDelay(4)}
              className="hero-fade-up mt-2 text-xs sm:text-sm leading-relaxed text-white/70 max-w-2xl"
            >
              {EN_SITE_CONFIG.company.subBrief}
            </p>

            <div
              style={fadeUpDelay(5)}
              className="hero-fade-up mt-8 flex flex-wrap items-center gap-4"
            >
              <a
                href="#contact"
                className="rounded-full bg-gold px-7 py-3 text-sm font-black text-navy-darker shadow-lg hover:bg-gold-light hover:shadow-xl transition"
              >
                Request Consultation or Quote
              </a>
              <a
                href={EN_SITE_CONFIG.contacts.general.waHref}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-full border border-emerald-500/40 bg-emerald-500/20 px-6 py-3 text-sm font-bold text-emerald-300 hover:bg-emerald-500 hover:text-white transition"
              >
                <MessageSquare className="h-4 w-4" />
                <span>WhatsApp Management</span>
              </a>
            </div>
          </div>

          {/* Emblem Card */}
          <div
            style={fadeUpDelay(3)}
            className="hero-fade-up lg:col-span-5 flex justify-center"
          >
            <div className="relative w-full max-w-sm">
              <div
                aria-hidden
                className="pointer-events-none absolute -inset-1 rounded-3xl bg-gradient-to-r from-gold/25 via-gold-light/15 to-transparent blur-xl opacity-60"
              />
              <div className="relative rounded-3xl border border-white/20 bg-gradient-to-b from-white/[0.12] to-white/[0.04] p-6 backdrop-blur-2xl shadow-2xl">
                <span className="absolute -top-2 -start-2 h-8 w-8 rounded-tl-2xl border-t-2 border-s-2 border-gold" />
                <span className="absolute -bottom-2 -end-2 h-8 w-8 rounded-br-2xl border-b-2 border-e-2 border-gold" />

                {/* Free-floating emblem — transparent, no tile, blends with the card */}
                <div className="relative mx-auto h-40 w-40 sm:h-44 sm:w-44 drop-shadow-[0_15px_35px_rgba(0,0,0,0.6)]">
                  <Image
                    src={SITE_CONFIG.assets.logoMark}
                    alt="Al-Fada Al-Wasaa logo"
                    fill
                    sizes="(max-width: 640px) 160px, 176px"
                    className="object-contain"
                  />
                </div>
                <div className="mt-5 text-center">
                  <span className="block text-xl font-black text-white">
                    الفضاء الواسع
                  </span>
                  <h2 className="mt-1 text-[11px] font-extrabold tracking-[0.25em] text-gold-light">
                    AL-FADA AL-WASAA
                  </h2>
                  <p className="mt-1 text-xs text-gold-light font-medium">Telecom & General Contracting</p>
                </div>
                <div className="mt-5 grid grid-cols-3 gap-2 border-t border-white/10 pt-4 text-center">
                  <div className="rounded-xl bg-navy-darker/70 py-2 border border-gold/20 shadow-xs">
                    <span className="block text-xs font-black text-gold-light">10+ Years</span>
                    <span className="text-[10px] text-white/70">Field Practice</span>
                  </div>
                  <div className="rounded-xl bg-navy-darker/70 py-2 border border-gold/20 shadow-xs">
                    <span className="block text-xs font-black text-gold-light">65+ Projects</span>
                    <span className="text-[10px] text-white/70">Completed</span>
                  </div>
                  <div className="rounded-xl bg-navy-darker/70 py-2 border border-gold/20 shadow-xs">
                    <span className="block text-xs font-black text-gold-light">100%</span>
                    <span className="text-[10px] text-white/70">Compliance</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Pillars Strip */}
        <div
          style={fadeUpDelay(6)}
          className="hero-fade-up mt-12 grid gap-4 sm:grid-cols-3"
        >
          {EN_SITE_CONFIG.pillars.map((pillar, i) => (
            <div
              key={i}
              className="group flex items-center gap-4 rounded-2xl border border-gold/30 bg-white/[0.07] p-4 backdrop-blur-md hover:border-gold hover:bg-white/[0.12] hover:-translate-y-1 transition-all duration-300 shadow-sm hover:shadow-lg"
            >
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gold/20 text-gold-light font-black transition-transform duration-300 group-hover:scale-110">
                {i === 0 ? <Briefcase className="h-5 w-5" /> : i === 1 ? <ShieldCheck className="h-5 w-5" /> : <Award className="h-5 w-5" />}
              </div>
              <div>
                <h3 className="text-sm font-extrabold text-white">{pillar.title}</h3>
                <p className="text-xs text-gold-light">{pillar.subtitle}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default EnHero;
