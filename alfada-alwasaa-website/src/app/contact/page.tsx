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
  description: "تواصل مع شركة الفضاء الواسع لخدمات الاتصالات والمقاولات بصنعاء. أرقام الهاتف، واتساب، البريد الرسمي، والعنوان المباشر جوار مصنع شملان. هاتف: +967776999942",
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
    <div className="flex min-h-screen flex-col bg-slate-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SiteHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Banner */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-20">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">تواصل معنا</span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <PhoneCall className="h-4 w-4 text-gold" />
                استجابة سريعة ومباشرة
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                تواصل مع شركة الفضاء الواسع
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg">
                يسعدنا دائماً استقبال استفساراتكم ومناقشة مشاريعكم القادمة في مجالات المقاولات العامة، الاتصالات، والتوريدات في صنعاء وعموم محافظات اليمن.
              </p>
            </div>
          </div>
        </section>

        {/* Contact Info Cards */}
        <section className="py-12 bg-white border-b border-slate-200">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {/* General management */}
              <div className="rounded-2xl border border-slate-200 bg-slate-50/70 p-6 shadow-sm hover:border-gold/50 transition">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-navy text-gold-light mb-4">
                  <PhoneCall className="h-5 w-5" />
                </div>
                <h3 className="font-extrabold text-navy text-sm">{SITE_CONFIG.contacts.general.label}</h3>
                <p className="text-xs text-slate-500 mt-1">{SITE_CONFIG.contacts.general.sublabel}</p>
                <a
                  href={SITE_CONFIG.contacts.general.telHref}
                  className="mt-3 block text-sm font-black text-navy hover:text-gold transition"
                  dir="ltr"
                >
                  {SITE_CONFIG.contacts.general.display}
                </a>
              </div>

              {/* Deputy manager */}
              <div className="rounded-2xl border border-slate-200 bg-slate-50/70 p-6 shadow-sm hover:border-gold/50 transition">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-navy text-gold-light mb-4">
                  <PhoneCall className="h-5 w-5" />
                </div>
                <h3 className="font-extrabold text-navy text-sm">{SITE_CONFIG.contacts.deputy.label}</h3>
                <p className="text-xs text-slate-500 mt-1">{SITE_CONFIG.contacts.deputy.sublabel}</p>
                <a
                  href={SITE_CONFIG.contacts.deputy.telHref}
                  className="mt-3 block text-sm font-black text-navy hover:text-gold transition"
                  dir="ltr"
                >
                  {SITE_CONFIG.contacts.deputy.display}
                </a>
              </div>

              {/* Email */}
              <div className="rounded-2xl border border-slate-200 bg-slate-50/70 p-6 shadow-sm hover:border-gold/50 transition">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-navy text-gold-light mb-4">
                  <Mail className="h-5 w-5" />
                </div>
                <h3 className="font-extrabold text-navy text-sm">البريد الإلكتروني</h3>
                <p className="text-xs text-slate-500 mt-1">للمراسلات والعقود الرسمية</p>
                <a
                  href={SITE_CONFIG.contacts.email.mailHref}
                  className="mt-3 block text-xs font-black text-navy hover:text-gold transition break-all"
                >
                  {SITE_CONFIG.contacts.email.address}
                </a>
              </div>

              {/* Location & Hours */}
              <div className="rounded-2xl border border-slate-200 bg-slate-50/70 p-6 shadow-sm hover:border-gold/50 transition">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gold text-navy-darker mb-4">
                  <MapPin className="h-5 w-5" />
                </div>
                <h3 className="font-extrabold text-navy text-sm">{SITE_CONFIG.contacts.location.label}</h3>
                <p className="text-xs text-slate-700 font-semibold mt-1">{SITE_CONFIG.contacts.location.fullAddress}</p>
                <p className="text-[11px] text-slate-500 mt-2 flex items-center gap-1">
                  <Clock className="h-3.5 w-3.5 text-gold shrink-0" />
                  <span>{SITE_CONFIG.contacts.workingHours}</span>
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Embedded Form */}
        <ContactSection />
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}