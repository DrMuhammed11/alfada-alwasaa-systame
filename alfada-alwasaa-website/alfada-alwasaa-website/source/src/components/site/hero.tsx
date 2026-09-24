"use client";

import Image from "next/image";
import type { CSSProperties } from "react";
import { motion, useReducedMotion, useScroll, useTransform } from "framer-motion";
import { ShieldCheck, Briefcase, Award, ArrowLeft, Phone, FileDown } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";

import { MagneticButton } from "@/components/ui/magnetic-button";

/**
 * تأخير الدخول المتدرج للعناصر (ثواني) — يُستخدم مع كلاس hero-fade-up
 * (أنيميشن CSS فقط في globals.css): الـ SSR يُرسِّر العناصر مرئية في HTML الثابت
 * بلا opacity:0 مضمّنة ولا انتظار للـ hydration، والدخول المتدرج يعمل عبر CSS فوراً
 */
const fadeUpDelay = (delay: number): CSSProperties =>
  ({ "--hero-delay": `${(delay * 0.35).toFixed(3)}s` }) as CSSProperties;

export function Hero() {
  const reduce = useReducedMotion();
  const { scrollY } = useScroll();
  const yParallax = useTransform(scrollY, [0, 800], [0, 800 * 0.12]);

  return (
    <section id="home" className="relative flex items-center overflow-hidden bg-navy-darker pt-24 pb-14 sm:pb-16 lg:pt-28 lg:pb-20">
      {/* Anchor for About to support both #home and #about smoothly */}
      <span id="about" className="absolute -top-24" />

      {/* Background artwork with elegant overlay and subtle parallax */}
      <motion.div
        style={{ y: reduce ? 0 : yParallax }}
        className="absolute -top-12 -bottom-12 inset-x-0"
      >
        <Image
          src={SITE_CONFIG.assets.heroBg}
          alt="أعمال ومشاريع شركة الفضاء الواسع"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-navy-darker/95 via-navy/90 to-navy-darker/98" />
        <div className="dot-grid absolute inset-0 opacity-25" />
      </motion.div>

      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Main 2-Column Responsive Layout: Unified Home & About */}
        <div className="grid items-center gap-10 lg:grid-cols-[1.15fr_0.85fr] lg:gap-12">

          {/* Column 1: Narrative, Identity, Pillars & CTAs */}
          <div className="text-right">
            {/* Trust badge */}
            <div className="hero-fade-up flex items-center" style={fadeUpDelay(0.05)}>
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-navy-deep/80 px-4 py-1.5 text-xs font-bold text-gold-light shadow-md backdrop-blur-md">
                <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
                <span>كيان مهني متعدد الخدمات</span>
                <span className="text-white/40">|</span>
                <span>شريككم الهندسي والتنفيذي المعتمد</span>
              </span>
            </div>

            {/* Main Headline */}
            <div className="hero-fade-up mt-4" style={fadeUpDelay(0.12)}>
              <h1 className="text-3xl font-black text-white sm:text-4xl lg:text-5xl leading-tight">
                شركة الفضاء الواسع
                <span className="block mt-1 text-2xl sm:text-3xl lg:text-4xl font-extrabold bg-gradient-to-l from-gold via-gold-light to-white bg-clip-text text-transparent">
                  لخدمات الاتصالات والمقاولات
                </span>
              </h1>

              {/* Responsive Slogan (Never cuts off) */}
              <div className="mt-3 flex items-center gap-3">
                <span className="h-0.5 w-8 rounded-full bg-gold hidden sm:block" />
                <p className="text-base sm:text-lg font-black tracking-wide text-gold-light">
                  كفاءة هندسية، دقة تنفيذية، وموثوقية في إدارة أضخم المشاريع
                </p>
              </div>
            </div>

            {/* Official Narrative text from Profile */}
            <p className="hero-fade-up mt-5 text-justify text-sm sm:text-base leading-7 sm:leading-8 text-slate-200/95 max-w-2xl" style={fadeUpDelay(0.2)}>
              كيان مهني متعدد الخدمات، تأسس على رؤية واضحة تقوم على تقديم حلول متكاملة
              تجمع بين الخبرة التنفيذية، والانضباط المؤسسي، والقدرة على الإنجاز بمعايير
              عالية من الجودة والاحتراف. ومنذ انطلاقتها، حرصت الشركة على أن تكون شريكًا
              موثوقًا للجهات التي تبحث عن أداء رصين، وتنفيذ دقيق، ونتائج تليق بتطلعات
              المشاريع الكبرى.
            </p>

            {/* The 3 Core Pillars in Compact Responsive Badges */}
            <div className="hero-fade-up mt-6 grid grid-cols-3 gap-2.5 sm:gap-3 max-w-xl" style={fadeUpDelay(0.28)}>
              {SITE_CONFIG.pillars.map((pillar, idx) => {
                const PillarIcon = [Briefcase, ShieldCheck, Award][idx];
                return (
                  <div
                    key={pillar.title}
                    className="rounded-2xl border border-gold/30 bg-white/5 p-3 text-center backdrop-blur-sm transition hover:border-gold hover:bg-white/10"
                  >
                    <PillarIcon className="mx-auto h-5 w-5 text-gold-light" />
                    <h3 className="mt-1.5 text-xs sm:text-sm font-black text-white">{pillar.title}</h3>
                    <p className="mt-0.5 text-[10px] text-slate-300 hidden sm:block">{pillar.subtitle}</p>
                  </div>
                );
              })}
            </div>

            {/* Quick Action Buttons */}
            <div className="hero-fade-up mt-8 flex flex-wrap items-center gap-3.5" style={fadeUpDelay(0.35)}>
              <MagneticButton>
                <a
                  href="#contact"
                  className="group inline-flex min-h-11 items-center gap-2 rounded-full bg-gold px-7 text-xs sm:text-sm font-black text-navy-darker shadow-[0_10px_25px_rgba(198,149,74,0.5)] transition-all duration-300 hover:-translate-y-0.5 hover:bg-gold-light hover:shadow-[0_15px_35px_rgba(198,149,74,0.65)]"
                >
                  <span>طلب استشارة أو تسعير</span>
                  <ArrowLeft className="h-4 w-4 transition-transform duration-300 group-hover:-translate-x-1" />
                </a>
              </MagneticButton>

              <a
                href="/profile/alfada-alwasaa-profile.pdf"
                download="alfada-alwasaa-profile.pdf"
                className="inline-flex min-h-11 items-center gap-2 rounded-full border border-gold/40 bg-gold/10 px-5 text-xs sm:text-sm font-bold text-gold-light backdrop-blur-sm transition hover:bg-gold hover:text-navy-darker shadow-sm"
              >
                <FileDown className="h-4 w-4" />
                <span>تحميل بروفايل الشركة (PDF)</span>
              </a>

              <a
                href="#sectors"
                className="inline-flex min-h-11 items-center gap-2 rounded-full border border-white/20 bg-white/5 px-5 text-xs sm:text-sm font-bold text-white backdrop-blur-sm transition hover:border-gold/60 hover:text-gold-light"
              >
                استكشف قطاعاتنا
              </a>

              <a
                href={SITE_CONFIG.contacts.general.telHref}
                className="inline-flex min-h-11 items-center gap-2 rounded-full bg-white/10 px-4 text-xs sm:text-sm font-bold text-white/90 ring-1 ring-white/15 transition hover:bg-white/15"
              >
                <Phone className="h-3.5 w-3.5 text-gold-light" />
                <span dir="ltr">{SITE_CONFIG.contacts.general.display}</span>
              </a>
            </div>
          </div>

          {/* Column 2: Visual Identity Card & Sector Preview */}
          <div className="hero-fade-up flex justify-center" style={fadeUpDelay(0.22)}>
            <div className="relative w-full max-w-md rounded-3xl border border-white/15 bg-gradient-to-b from-white/10 to-white/5 p-6 sm:p-8 shadow-[0_25px_60px_rgba(0,0,0,0.5)] backdrop-blur-xl">
              {/* Decorative gold corner accent */}
              <span className="absolute -top-2 -start-2 h-8 w-8 rounded-tl-2xl border-t-2 border-s-2 border-gold" />
              <span className="absolute -bottom-2 -end-2 h-8 w-8 rounded-br-2xl border-b-2 border-e-2 border-gold" />

              {/* Logo Presentation (Complete, Pristine, Never cropped) */}
              <div className="flex flex-col items-center text-center">
                <div className="relative h-24 w-24 sm:h-32 sm:w-32 drop-shadow-[0_15px_35px_rgba(0,0,0,0.6)]">
                  <Image
                    src={SITE_CONFIG.assets.logoMark}
                    alt="شعار شركة الفضاء الواسع"
                    fill
                    priority
                    sizes="(max-width: 640px) 96px, 128px"
                    className="object-contain"
                  />
                </div>
                <div className="mt-3">
                  <span className="block text-2xl sm:text-3xl font-black text-white">
                    الفضاء الواسع
                  </span>
                  <div className="mt-1 flex items-center justify-center gap-2.5">
                    <span className="h-[1.5px] w-6 sm:w-8 bg-gold rounded-full" />
                    <span className="text-[11px] sm:text-xs font-black tracking-[0.25em] text-gold-light">
                      AL-FADA AL-WASAA
                    </span>
                    <span className="h-[1.5px] w-6 sm:w-8 bg-gold rounded-full" />
                  </div>
                </div>
              </div>

              {/* Sector Icons Strip (Completely visible, pristine, never cuts off) */}
              <div className="mt-6 pt-5 border-t border-white/10 flex flex-col items-center">
                <span className="text-[11px] font-bold text-white/60 mb-2.5">
                  مجالات عمل الشركة الرئيسية
                </span>
                <div className="relative h-13 sm:h-14 w-full max-w-[320px] px-1">
                  <Image
                    src={SITE_CONFIG.assets.sectorIconsStrip}
                    alt="المقاولات، الطرق، النفط، الاتصالات، التسويق"
                    fill
                    priority
                    sizes="(max-width: 640px) 280px, 320px"
                    className="object-contain drop-shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
                  />
                </div>
              </div>

              {/* Quick Summary Badges */}
              <div className="mt-5 grid grid-cols-2 gap-2 pt-4 border-t border-white/10 text-center">
                <div className="rounded-xl bg-navy-darker/60 py-2 px-3 border border-white/5">
                  <span className="block font-mono text-sm font-black text-gold">5+ قطاعات</span>
                  <span className="block text-[10px] text-white/70">متكاملة في منظومة واحدة</span>
                </div>
                <div className="rounded-xl bg-navy-darker/60 py-2 px-3 border border-white/5">
                  <span className="block font-mono text-sm font-black text-gold">100% التزام</span>
                  <span className="block text-[10px] text-white/70">بالمواصفات والمعايير</span>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
