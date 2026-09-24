import type { Metadata } from "next";
import Link from "next/link";
import { 
  PhoneCall, 
  Mail, 
  MapPin, 
  Clock, 
  MessageSquare, 
  ChevronLeft 
} from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { SiteHeader } from "@/components/site/header";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";
import { Contact as ContactSection } from "@/components/site/contact";

export const metadata: Metadata = {
  title: "تواصل معنا | شركة الفضاء الواسع في صنعاء واليمن",
  description: "تواصل مع شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة بصنعاء. أرقام الهاتف، واتساب، البريد الرسمي، والعنوان المباشر جوار مصنع شملان. هاتف: +967776999942",
  keywords: [
    "تواصل مع الفضاء الواسع",
    "رقم شركة الفضاء الواسع",
    "عنوان الفضاء الواسع صنعاء",
    "شركة مقاولات صنعاء شملان",
    "استشارة مقاولات اليمن"
  ],
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/contact",
    languages: {
      ar: "https://www.alfadaalwasaa.com/contact",
      en: "https://www.alfadaalwasaa.com/en/contact",
    },
  },
  openGraph: {
    title: "تواصل معنا | شركة الفضاء الواسع للمقاولات والاتصالات",
    description: "قنوات التواصل الرسمية والمباشرة مع إدارة شركة الفضاء الواسع في صنعاء.",
    url: "https://www.alfadaalwasaa.com/contact",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "تواصل معنا - الفضاء الواسع" }],
    locale: "ar_YE",
    type: "website",
  },
};

export default function ContactPage() {
  const breadcrumbSchema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "الرئيسية",
        item: "https://www.alfadaalwasaa.com",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "تواصل معنا",
        item: "https://www.alfadaalwasaa.com/contact",
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-white dark:bg-navy-darker text-slate-900 dark:text-white transition-colors duration-300">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SiteHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Banner with Ambient Glow */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-24">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          {/* Ambient Glowing Orb */}
          <div
            className="pointer-events-none absolute -top-24 -end-24 h-96 w-96 rounded-full bg-gold/15 blur-3xl"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute bottom-0 start-1/4 h-64 w-64 rounded-full bg-navy-light/20 blur-2xl"
            aria-hidden="true"
          />

          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="inline-flex items-center gap-1 rounded-full bg-white/10 px-3 py-1 hover:bg-white/20 hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="rounded-full bg-gold/20 px-3 py-1 text-gold-light font-bold ring-1 ring-gold/40">
                تواصل معنا
              </span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <PhoneCall className="h-4 w-4 text-gold" />
                قنوات اتصال رسمية ومباشرة 24/7
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                تواصل مع إدارة شركة الفضاء الواسع
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                يسعدنا دائماً استقبال استفساراتكم ومناقشة مشاريعكم القادمة في مجالات المقاولات العامة، الاتصالات، والتوريدات في صنعاء وعموم محافظات الجمهورية اليمنية.
              </p>
            </div>
          </div>
        </section>

        {/* 4 Luxury Contact Info Cards */}
        <section className="py-16 bg-mist/60 dark:bg-navy-darker/60 border-b border-navy/10 dark:border-white/10 transition-colors duration-300">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {/* General Management */}
              <div className="group rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300 flex flex-col justify-between">
                <div>
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-navy dark:bg-navy-darker text-gold border border-gold/30 mb-4 group-hover:scale-105 transition-transform shadow-xs">
                    <PhoneCall className="h-5 w-5" />
                  </div>
                  <span className="text-xs font-bold text-gold">{SITE_CONFIG.contacts.general.sublabel}</span>
                  <h3 className="font-black text-navy dark:text-white text-base mt-1">{SITE_CONFIG.contacts.general.label}</h3>
                  <a
                    href={SITE_CONFIG.contacts.general.telHref}
                    className="mt-3 block font-mono text-base font-black text-navy dark:text-gold-light hover:text-gold transition"
                    dir="ltr"
                  >
                    {SITE_CONFIG.contacts.general.display}
                  </a>
                </div>
                <div className="mt-5 pt-4 border-t border-slate-100 dark:border-white/10 grid grid-cols-2 gap-2">
                  <a
                    href={SITE_CONFIG.contacts.general.telHref}
                    className="flex items-center justify-center gap-1 rounded-xl bg-slate-100 dark:bg-white/10 py-2 text-xs font-bold text-navy dark:text-white hover:bg-gold hover:text-navy-darker transition"
                  >
                    اتصال
                  </a>
                  <a
                    href={`https://wa.me/${SITE_CONFIG.contacts.general.waNumber}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/15 dark:bg-emerald-500/20 py-2 text-xs font-bold text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                  >
                    واتساب
                  </a>
                </div>
              </div>

              {/* Deputy Director */}
              <div className="group rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300 flex flex-col justify-between">
                <div>
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-navy dark:bg-navy-darker text-gold border border-gold/30 mb-4 group-hover:scale-105 transition-transform shadow-xs">
                    <PhoneCall className="h-5 w-5" />
                  </div>
                  <span className="text-xs font-bold text-gold">{SITE_CONFIG.contacts.deputy.sublabel}</span>
                  <h3 className="font-black text-navy dark:text-white text-base mt-1">{SITE_CONFIG.contacts.deputy.label}</h3>
                  <a
                    href={SITE_CONFIG.contacts.deputy.telHref}
                    className="mt-3 block font-mono text-base font-black text-navy dark:text-gold-light hover:text-gold transition"
                    dir="ltr"
                  >
                    {SITE_CONFIG.contacts.deputy.display}
                  </a>
                </div>
                <div className="mt-5 pt-4 border-t border-slate-100 dark:border-white/10 grid grid-cols-2 gap-2">
                  <a
                    href={SITE_CONFIG.contacts.deputy.telHref}
                    className="flex items-center justify-center gap-1 rounded-xl bg-slate-100 dark:bg-white/10 py-2 text-xs font-bold text-navy dark:text-white hover:bg-gold hover:text-navy-darker transition"
                  >
                    اتصال
                  </a>
                  <a
                    href={`https://wa.me/${SITE_CONFIG.contacts.deputy.waNumber}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/15 dark:bg-emerald-500/20 py-2 text-xs font-bold text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                  >
                    واتساب
                  </a>
                </div>
              </div>

              {/* Official Email */}
              <div className="group rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300 flex flex-col justify-between">
                <div>
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-navy dark:bg-navy-darker text-gold border border-gold/30 mb-4 group-hover:scale-105 transition-transform shadow-xs">
                    <Mail className="h-5 w-5" />
                  </div>
                  <span className="text-xs font-bold text-gold">العقود والمراسلات</span>
                  <h3 className="font-black text-navy dark:text-white text-base mt-1">البريد الرسمي</h3>
                  <a
                    href={SITE_CONFIG.contacts.email.mailHref}
                    className="mt-3 block font-mono text-sm font-bold text-navy dark:text-gold-light hover:text-gold transition break-all"
                  >
                    {SITE_CONFIG.contacts.email.address}
                  </a>
                </div>
                <div className="mt-5 pt-4 border-t border-slate-100 dark:border-white/10">
                  <a
                    href={SITE_CONFIG.contacts.email.mailHref}
                    className="flex items-center justify-center gap-1.5 rounded-xl bg-slate-100 dark:bg-white/10 py-2 text-xs font-bold text-navy dark:text-white hover:bg-gold hover:text-navy-darker transition"
                  >
                    إرسال بريد إلكتروني
                  </a>
                </div>
              </div>

              {/* Location & Hours */}
              <div className="group rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300 flex flex-col justify-between">
                <div>
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-4 shadow-sm group-hover:scale-105 transition-transform">
                    <MapPin className="h-5 w-5" />
                  </div>
                  <span className="text-xs font-bold text-gold">المقر والنطاق</span>
                  <h3 className="font-black text-navy dark:text-white text-base mt-1">{SITE_CONFIG.contacts.location.label}</h3>
                  <p className="text-xs text-slate-700 dark:text-slate-200 font-semibold mt-2 leading-relaxed">
                    {SITE_CONFIG.contacts.location.fullAddress}
                  </p>
                </div>
                <div className="mt-5 pt-4 border-t border-slate-100 dark:border-white/10 text-[11px] text-slate-500 dark:text-slate-400 flex items-center gap-1.5">
                  <Clock className="h-3.5 w-3.5 text-gold shrink-0" />
                  <span>{SITE_CONFIG.contacts.workingHours} (طوارئ 24/7)</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Embedded Interactive Form & Tracking Hub */}
        <ContactSection />
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}