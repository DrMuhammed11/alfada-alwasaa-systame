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
  ArrowRight, 
  Phone, 
  MessageSquare, 
  ShieldCheck, 
  Briefcase, 
  Award, 
  Clock, 
  Layers, 
  ChevronDown,
  Menu, 
  X, 
  Mail, 
  MapPin 
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";
import { ThemeToggle } from "@/components/site/theme-toggle";
import { LanguageSwitcher } from "@/components/site/language-switcher";

const SERVICE_ICONS = [
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  Ship,
  MonitorSmartphone,
];

export default function EnglishHomePage() {
  const [activeTab, setActiveTab] = useState("contracting");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [faqOpenIndex, setFaqOpenIndex] = useState<number | null>(0);

  const activeService =
    EN_SITE_CONFIG.servicesList.find((s) => s.slug === activeTab) ||
    EN_SITE_CONFIG.servicesList[0];

  return (
    <div className="flex min-h-screen flex-col bg-white dark:bg-navy-darker text-slate-900 dark:text-white transition-colors duration-300">
      
      {/* English Site Header */}
      <header className="fixed inset-x-0 top-0 z-50 bg-navy/95 backdrop-blur-md shadow-md border-b border-white/10 text-white">
        <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          {/* Brand */}
          <Link href="/en" className="flex items-center gap-3">
            <span className="relative h-11 w-11 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40">
              <Image
                src={SITE_CONFIG.assets.logoMark}
                alt="Al-Fada Al-Wasaa Logo"
                fill
                sizes="48px"
                className="object-contain p-1"
                priority
              />
            </span>
            <div className="leading-tight">
              <span className="block text-lg font-black tracking-tight text-white">
                AL-FADA AL-WASAA
              </span>
              <span className="block text-[10px] font-bold tracking-widest text-gold-light">
                TELECOM & CONTRACTING
              </span>
            </div>
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden lg:flex items-center gap-1" aria-label="Main Navigation">
            {EN_SITE_CONFIG.navItems.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="rounded-full px-3 py-1 text-xs xl:text-sm font-bold text-white/85 hover:text-gold-light transition"
              >
                {item.label}
              </a>
            ))}
          </nav>

          {/* Desktop Actions */}
          <div className="hidden lg:flex items-center gap-3">
            {/* Language Switcher */}
            <LanguageSwitcher variant="pill" />

            <ThemeToggle />

            <a
              href="#contact"
              className="rounded-full bg-gold px-5 py-2 text-xs font-black text-navy-darker shadow-md hover:bg-gold-light transition"
            >
              Request Quote
            </a>
          </div>

          {/* Mobile buttons */}
          <div className="flex items-center gap-2 lg:hidden">
            <LanguageSwitcher variant="button" />
            <ThemeToggle />
            <button
              type="button"
              onClick={() => setMobileMenuOpen((v) => !v)}
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white"
              aria-label="Toggle Navigation"
            >
              {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.nav
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              className="border-t border-white/10 bg-navy-deep px-4 py-4 lg:hidden"
            >
              <div className="space-y-2">
                {EN_SITE_CONFIG.navItems.map((item) => (
                  <a
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className="block rounded-lg px-3 py-2 text-sm font-semibold text-white/90 hover:bg-white/10"
                  >
                    {item.label}
                  </a>
                ))}
                <div className="pt-2">
                  <LanguageSwitcher variant="menu" />
                </div>
                <a
                  href="#contact"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block text-center rounded-xl bg-gold py-2.5 text-sm font-black text-navy-darker mt-3"
                >
                  Request Quote
                </a>
              </div>
            </motion.nav>
          )}
        </AnimatePresence>
      </header>

      {/* Hero Section */}
      <section id="home" className="relative flex items-center overflow-hidden bg-navy-darker pt-28 pb-16 sm:pb-20 text-white">
        <div className="absolute inset-0 -z-10">
          <Image
            src={SITE_CONFIG.assets.heroBg}
            alt="Al-Fada Al-Wasaa Operations"
            fill
            priority
            sizes="100vw"
            className="object-cover opacity-20"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-navy-darker/90 via-navy/85 to-navy-darker" />
        </div>

        <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 w-full">
          <div className="grid items-center gap-10 lg:grid-cols-[1.15fr_0.85fr] lg:gap-12">
            <div>
              {/* Trust Badge */}
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-navy-deep/80 px-4 py-1.5 text-xs font-bold text-gold-light shadow-md">
                <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
                <span>Multi-Service Enterprise Entity</span>
                <span className="text-white/40">|</span>
                <span>One Unified Ecosystem</span>
              </span>

              <h1 className="mt-5 text-3xl font-black text-white sm:text-5xl lg:text-6xl leading-tight">
                Al-Fada Al-Wasaa
                <span className="block mt-1 text-2xl sm:text-4xl font-extrabold bg-gradient-to-r from-gold via-gold-light to-white bg-clip-text text-transparent">
                  Telecom & General Contracting
                </span>
              </h1>

              <p className="mt-4 text-base sm:text-lg font-bold text-gold-light">
                {EN_SITE_CONFIG.company.tagline}
              </p>

              <p className="mt-5 text-sm sm:text-base leading-7 sm:leading-8 text-slate-200/90 max-w-2xl">
                {EN_SITE_CONFIG.company.brief} {EN_SITE_CONFIG.company.subBrief}
              </p>

              {/* 3 Pillars */}
              <div className="mt-6 grid grid-cols-3 gap-2.5 sm:gap-3 max-w-xl">
                {EN_SITE_CONFIG.pillars.map((pillar, idx) => {
                  const PillarIcon = [Briefcase, ShieldCheck, Award][idx];
                  return (
                    <div
                      key={pillar.title}
                      className="rounded-2xl border border-gold/30 bg-white/5 p-3 text-center backdrop-blur-sm"
                    >
                      <PillarIcon className="mx-auto h-5 w-5 text-gold-light" />
                      <h3 className="mt-1.5 text-xs font-bold text-white">{pillar.title}</h3>
                      <p className="mt-0.5 text-[10px] text-slate-300 hidden sm:block">{pillar.subtitle}</p>
                    </div>
                  );
                })}
              </div>

              {/* CTAs */}
              <div className="mt-8 flex flex-wrap items-center gap-3.5">
                <a
                  href="#contact"
                  className="inline-flex min-h-11 items-center gap-2 rounded-full bg-gold px-7 text-xs sm:text-sm font-black text-navy-darker shadow-lg hover:bg-gold-light transition"
                >
                  <span>Request Proposal / Consultation</span>
                  <ArrowRight className="h-4 w-4" />
                </a>

                <a
                  href="#services"
                  className="inline-flex min-h-11 items-center gap-2 rounded-full border border-white/20 bg-white/5 px-6 text-xs sm:text-sm font-bold text-white hover:border-gold/60 hover:text-gold-light transition"
                >
                  Explore Services
                </a>

                <a
                  href={SITE_CONFIG.contacts.general.telHref}
                  className="inline-flex min-h-11 items-center gap-2 rounded-full bg-white/10 px-5 text-xs sm:text-sm font-bold text-white/90 ring-1 ring-white/15"
                >
                  <Phone className="h-3.5 w-3.5 text-gold-light" />
                  <span>{SITE_CONFIG.contacts.general.display}</span>
                </a>
              </div>
            </div>

            {/* Logo and Brand Presentation Card */}
            <div className="flex justify-center">
              <div className="relative w-full max-w-md rounded-3xl border border-white/15 bg-gradient-to-b from-white/10 to-white/5 p-6 sm:p-8 shadow-2xl backdrop-blur-xl text-center">
                <div className="relative mx-auto h-28 w-28 drop-shadow-lg">
                  <Image
                    src={SITE_CONFIG.assets.logoMark}
                    alt="Al-Fada Al-Wasaa Mark"
                    fill
                    sizes="128px"
                    className="object-contain"
                  />
                </div>
                <h2 className="mt-4 text-2xl font-black text-white">
                  AL-FADA AL-WASAA
                </h2>
                <p className="mt-1 text-xs font-bold tracking-widest text-gold-light">
                  COMPANY PROFILE & SCOPE
                </p>

                <div className="mt-6 pt-5 border-t border-white/10">
                  <div className="relative h-12 w-full max-w-[280px] mx-auto">
                    <Image
                      src={SITE_CONFIG.assets.sectorIconsStrip}
                      alt="Operations Strip"
                      fill
                      sizes="280px"
                      className="object-contain"
                    />
                  </div>
                </div>

                <div className="mt-5 grid grid-cols-2 gap-2 pt-4 border-t border-white/10 text-center">
                  <div className="rounded-xl bg-navy-darker/60 py-2 px-3 border border-white/5">
                    <span className="block font-mono text-sm font-black text-gold">5+ Sectors</span>
                    <span className="block text-[10px] text-white/70">Unified ecosystem</span>
                  </div>
                  <div className="rounded-xl bg-navy-darker/60 py-2 px-3 border border-white/5">
                    <span className="block font-mono text-sm font-black text-gold">100% Quality</span>
                    <span className="block text-[10px] text-white/70">Standards compliance</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Counter Section */}
      <section className="relative -mt-8 z-20 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 w-full">
        <div className="rounded-3xl border border-gold/30 bg-gradient-to-br from-navy-deep via-navy to-navy-darker p-6 shadow-2xl backdrop-blur-lg sm:p-8">
          <div className="grid grid-cols-2 gap-6 md:grid-cols-4 md:gap-8 divide-y-2 divide-white/10 md:divide-y-0 md:divide-x-2 md:divide-white/10 text-center">
            {EN_SITE_CONFIG.stats.map((stat, idx) => {
              const Icon = [Layers, ShieldCheck, Award, Clock][idx];
              return (
                <div key={stat.label} className={`flex flex-col items-center ${idx > 1 ? "pt-6 md:pt-0" : ""}`}>
                  <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-gold/15 text-gold-light">
                    <Icon className="h-6 w-6" />
                  </div>
                  <span className="text-3xl font-black text-gold-light sm:text-4xl lg:text-5xl font-mono">
                    {stat.num}
                  </span>
                  <span className="mt-2 text-sm font-bold text-white">{stat.label}</span>
                  <span className="mt-1 text-xs text-white/60">{stat.sub}</span>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Sectors Section */}
      <section id="sectors" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Strategic Sectors
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Integrated Multi-Sector Execution
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Operating across strategic domains to accelerate project delivery, optimize execution efficiency, and maintain consistent enterprise quality.
            </p>
          </div>

          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {EN_SITE_CONFIG.sectors.map((sector) => (
              <article
                key={sector.num}
                className="group flex flex-col overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy shadow-md transition hover:-translate-y-1 hover:border-gold/50 hover:shadow-xl"
              >
                <div className="relative flex aspect-[16/10] w-full overflow-hidden bg-navy-darker">
                  <div className="relative w-1/2 overflow-hidden">
                    <Image
                      src={sector.photos[0].src}
                      alt={sector.photos[0].alt}
                      fill
                      loading="lazy"
                      sizes="(max-width: 768px) 50vw, 200px"
                      className="object-cover"
                    />
                  </div>
                  <div className="relative w-1/2 overflow-hidden">
                    <Image
                      src={sector.photos[1].src}
                      alt={sector.photos[1].alt}
                      fill
                      loading="lazy"
                      sizes="(max-width: 768px) 50vw, 200px"
                      className="object-cover"
                    />
                  </div>
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                  <div className="absolute bottom-3 start-4 z-10">
                    <h3 className="text-lg font-black text-white">{sector.title}</h3>
                  </div>
                  <div className="absolute top-3 end-4 z-10">
                    <span className="rounded-full bg-gold px-3 py-0.5 text-xs font-bold text-navy-darker">
                      Sector {sector.num}
                    </span>
                  </div>
                </div>

                <div className="flex flex-1 flex-col justify-between p-5">
                  <ul className="space-y-2">
                    {sector.services.map((srv, i) => (
                      <li key={i} className="flex items-start gap-2 text-xs sm:text-sm text-slate-700 dark:text-slate-200">
                        <CheckCircle2 className="h-4 w-4 text-gold shrink-0 mt-0.5" />
                        <span>{srv}</span>
                      </li>
                    ))}
                  </ul>

                  <a
                    href="#contact"
                    className="mt-6 flex items-center justify-between rounded-xl bg-slate-100 dark:bg-white/10 px-4 py-2.5 text-xs font-bold text-navy dark:text-white hover:bg-gold hover:text-navy-darker transition"
                  >
                    <span>Request Proposal</span>
                    <ArrowRight className="h-3.5 w-3.5" />
                  </a>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Services Section with Interactive Tabs */}
      <section id="services" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-8">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Service Capabilities
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Our Core Services Portfolio
            </h2>
          </div>

          {/* Service Tabs */}
          <div className="flex items-center gap-2 overflow-x-auto pb-3 mb-6 lg:grid lg:grid-cols-7 lg:gap-2">
            {EN_SITE_CONFIG.servicesList.map((service, idx) => {
              const isActive = activeTab === service.slug;
              const Icon = SERVICE_ICONS[idx] || Briefcase;
              return (
                <button
                  key={service.slug}
                  type="button"
                  onClick={() => setActiveTab(service.slug)}
                  className={`flex shrink-0 items-center justify-center gap-1.5 rounded-2xl px-3 py-2 text-xs font-bold transition lg:w-full ${
                    isActive
                      ? "bg-gold text-navy-darker shadow-md font-black"
                      : "bg-slate-100 dark:bg-navy text-slate-700 dark:text-white/80 hover:bg-slate-200 dark:hover:bg-navy-deep"
                  }`}
                >
                  <Icon className="h-4 w-4 shrink-0" />
                  <span className="truncate">{service.title}</span>
                </button>
              );
            })}
          </div>

          {/* Active Service Card */}
          <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-6 sm:p-10 text-white shadow-xl">
            <div className="grid items-center gap-8 lg:grid-cols-12">
              <div className="lg:col-span-7">
                <span className="rounded-full bg-white/10 px-3 py-1 font-mono text-xs font-bold text-gold-light">
                  Service #{activeService.num}
                </span>
                <h3 className="mt-4 text-2xl sm:text-3xl font-black text-white">
                  {activeService.title}
                </h3>
                <p className="mt-3 text-base leading-7 text-white/85">
                  {activeService.desc}
                </p>
                <div className="mt-6 flex flex-wrap gap-3">
                  <a
                    href="#contact"
                    className="inline-flex items-center gap-2 rounded-2xl bg-gold px-5 py-2.5 text-xs font-bold text-navy-darker hover:bg-gold-light transition"
                  >
                    <span>Request Engineering Scope / RFP</span>
                    <ArrowRight className="h-4 w-4" />
                  </a>
                  <a
                    href={SITE_CONFIG.contacts.general.waHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-2xl bg-white/10 px-4 py-2.5 text-xs font-bold text-white hover:bg-white/20 transition"
                  >
                    <MessageSquare className="h-3.5 w-3.5 text-gold-light" />
                    <span>WhatsApp Inquiry</span>
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

      {/* Track Record Section */}
      <section id="track" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Track Record
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Demonstrated Field Accomplishments
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Delivering cross-sector projects with unyielding adherence to civil engineering specifications, international logistics compliance, and operational reliability.
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {EN_SITE_CONFIG.trackRecord.map((tr) => (
              <div
                key={tr.id}
                className="overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy shadow-md hover:shadow-xl transition"
              >
                <div className="relative aspect-[16/10] bg-navy-darker">
                  <Image
                    src={tr.src}
                    alt={tr.title}
                    fill
                    loading="lazy"
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                  <span className="absolute top-3 start-3 rounded-full bg-navy/90 px-3 py-1 text-[11px] font-bold text-gold-light border border-gold/30">
                    {tr.tag}
                  </span>
                </div>
                <div className="p-5">
                  <h3 className="text-base font-bold text-navy dark:text-white">{tr.title}</h3>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">{tr.desc}</p>
                  <p className="mt-3 text-[11px] font-semibold text-gold dark:text-gold-light border-t border-slate-100 dark:border-white/10 pt-2">
                    {tr.metrics}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Why Us / Values Section */}
      <section id="why" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Core Principles
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Why Partner With Al-Fada Al-Wasaa?
            </h2>
          </div>

          <div className="grid gap-6 sm:grid-cols-3">
            {EN_SITE_CONFIG.values.map((val) => (
              <div
                key={val.title}
                className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6 shadow-sm hover:border-gold/50 transition"
              >
                <span className="h-2 w-10 rounded-full bg-gold block mb-4" />
                <h3 className="text-lg font-bold text-navy dark:text-white">{val.title}</h3>
                <p className="mt-2 text-xs leading-6 text-slate-600 dark:text-slate-300">{val.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* English FAQ Section */}
      <section id="faq" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Frequently Asked Questions
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Essential Inquiries & Procedures
            </h2>
          </div>

          <div className="space-y-3">
            {EN_SITE_CONFIG.faq.map((item, idx) => {
              const isOpen = faqOpenIndex === idx;
              return (
                <div
                  key={idx}
                  className="rounded-2xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy/80 overflow-hidden"
                >
                  <button
                    type="button"
                    onClick={() => setFaqOpenIndex(isOpen ? null : idx)}
                    className="flex w-full items-center justify-between p-4 sm:p-5 text-left font-bold text-navy dark:text-white"
                  >
                    <span className="text-sm sm:text-base">{item.question}</span>
                    <ChevronDown className={`h-4 w-4 text-gold transition ${isOpen ? "rotate-180" : ""}`} />
                  </button>
                  {isOpen && (
                    <div className="px-4 sm:px-5 pb-5 pt-2 text-xs sm:text-sm leading-6 text-slate-600 dark:text-slate-300 border-t border-navy/5 dark:border-white/10">
                      {item.answer}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* English Contact Section */}
      <section id="contact" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Direct Inquiries
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Connect With Executive Leadership
            </h2>
            <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">
              Submit tenders, technical queries, or procurement proposals directly to our corporate headquarters.
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-3 text-center">
            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6">
              <Phone className="h-6 w-6 text-gold mx-auto mb-3" />
              <h3 className="font-bold text-navy dark:text-white text-sm">General Management</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Direct inquiries & contracts</p>
              <a href={SITE_CONFIG.contacts.general.telHref} className="block font-bold text-gold mt-3 text-sm">
                {SITE_CONFIG.contacts.general.display}
              </a>
              <a
                href={SITE_CONFIG.contacts.general.waHref}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-3 inline-flex items-center gap-1.5 rounded-xl bg-emerald-500 px-4 py-1.5 text-xs font-bold text-white"
              >
                <MessageSquare className="h-3.5 w-3.5" />
                <span>WhatsApp</span>
              </a>
            </div>

            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6">
              <Mail className="h-6 w-6 text-gold mx-auto mb-3" />
              <h3 className="font-bold text-navy dark:text-white text-sm">Official Email</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Formal RFPs & Tenders</p>
              <a href={SITE_CONFIG.contacts.email.mailHref} className="block font-bold text-gold mt-3 text-sm">
                {SITE_CONFIG.contacts.email.address}
              </a>
            </div>

            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6">
              <MapPin className="h-6 w-6 text-gold mx-auto mb-3" />
              <h3 className="font-bold text-navy dark:text-white text-sm">Headquarters</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Sana&apos;a, Republic of Yemen</p>
              <span className="block font-bold text-navy dark:text-slate-200 mt-3 text-xs">
                {SITE_CONFIG.contacts.location.fullAddress}
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* English Site Footer */}
      <footer className="mt-auto border-t border-white/10 bg-navy-darker py-12 text-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 text-center">
          <div className="relative mx-auto h-16 w-16 mb-4">
            <Image
              src={SITE_CONFIG.assets.logoMark}
              alt="Al-Fada Al-Wasaa Mark"
              fill
              sizes="64px"
              className="object-contain"
            />
          </div>
          <h2 className="text-lg font-bold text-white">AL-FADA AL-WASAA COMPANY</h2>
          <p className="text-xs text-gold-light mt-1">{EN_SITE_CONFIG.company.tagline}</p>

          <div className="mt-6 flex flex-wrap justify-center gap-6 text-xs text-white/70">
            {EN_SITE_CONFIG.navItems.map((item) => (
              <a key={item.href} href={item.href} className="hover:text-gold-light transition">
                {item.label}
              </a>
            ))}
            <LanguageSwitcher variant="pill" />
          </div>

          <p className="mt-8 text-[11px] text-white/50 border-t border-white/10 pt-6">
            &copy; {new Date().getFullYear()} Al-Fada Al-Wasaa Company for Telecom Services & General Contracting. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
