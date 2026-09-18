"use client";

import Image from "next/image";
import Link from "next/link";
import { 
  CheckCircle2, 
  HelpCircle, 
  ArrowLeft, 
  PhoneCall, 
  MessageSquare,
  ShieldCheck,
  Building2,
  ChevronLeft
} from "lucide-react";
import { ServiceDetail, SERVICES_DATA } from "@/config/services-data";
import { SITE_CONFIG } from "@/config/site";
import { SiteHeader } from "./header";
import { SiteFooter } from "./footer";
import { FloatingContact } from "./floating-contact";

export function ServicePageView({ service }: { service: ServiceDetail }) {
  const otherServices = Object.values(SERVICES_DATA).filter(
    (s) => s.slug !== service.slug
  );

  // FAQ Schema for Google Rich Snippets
  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: service.faqs.map((faq) => ({
      "@type": "Question",
      name: faq.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.a,
      },
    })),
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <SiteHeader />

      <main className="flex-1 pt-[76px]">
        {/* Hero Banner */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-24">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {/* Breadcrumb */}
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <Link href="/#services" className="hover:text-gold transition">
                خدماتنا
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">{service.shortTitle}</span>
            </nav>

            <div className="grid gap-12 lg:grid-cols-12 lg:items-center">
              <div className="lg:col-span-7">
                <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                  <ShieldCheck className="h-4 w-4 text-gold" />
                  خدمة معتمدة واحترافية
                </span>

                <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                  {service.title}
                </h1>

                <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                  {service.subtitle}
                </p>

                {/* Direct Action Buttons */}
                <div className="mt-8 flex flex-wrap items-center gap-4">
                  <a
                    href={SITE_CONFIG.contacts.general.waHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2.5 rounded-full bg-gold px-7 py-3.5 text-sm font-black text-navy-darker shadow-lg transition-all duration-300 hover:bg-gold-light hover:scale-105 active:scale-95"
                  >
                    <MessageSquare className="h-4 w-4" />
                    <span>طلب دراسة أو تسعير</span>
                  </a>

                  <a
                    href={SITE_CONFIG.contacts.general.telHref}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-6 py-3.5 text-sm font-bold text-white backdrop-blur-sm transition-all hover:bg-white/20"
                  >
                    <PhoneCall className="h-4 w-4 text-gold-light" />
                    <span dir="ltr">{SITE_CONFIG.contacts.general.display}</span>
                  </a>
                </div>
              </div>

              {/* Featured Image */}
              <div className="lg:col-span-5">
                <div className="relative aspect-[4/3] overflow-hidden rounded-3xl border-2 border-gold/30 bg-navy-darker shadow-2xl">
                  <Image
                    src={service.image}
                    alt={service.title}
                    fill
                    sizes="(max-width: 1024px) 100vw, 450px"
                    className="object-cover"
                    priority
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/60 via-transparent to-transparent" />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Detailed Overview */}
        <section className="py-16 sm:py-20 bg-white">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl">
              <span className="text-xs font-extrabold uppercase tracking-wider text-gold">نظرة عامة</span>
              <h2 className="mt-2 text-2xl font-black text-navy sm:text-3xl">
                الريادة في تقديم {service.shortTitle}
              </h2>
              <div className="mt-6 space-y-4 text-base leading-8 text-slate-700">
                {service.overview.map((para, i) => (
                  <p key={i}>{para}</p>
                ))}
              </div>
            </div>

            {/* Scope of Work / Features */}
            <div className="mt-14">
              <h3 className="text-xl font-black text-navy sm:text-2xl mb-8">
                نطاق الأعمال والقدرات التنفيذية
              </h3>
              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                {service.features.map((feat, idx) => (
                  <div
                    key={idx}
                    className="rounded-2xl border border-slate-200/80 bg-slate-50/80 p-6 shadow-sm transition-all hover:-translate-y-1 hover:border-gold/50 hover:shadow-md hover:bg-white"
                  >
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-navy text-gold-light font-black text-sm mb-4">
                      0{idx + 1}
                    </span>
                    <h4 className="text-base font-extrabold text-navy">{feat.title}</h4>
                    <p className="mt-2 text-xs leading-6 text-slate-600">{feat.desc}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* Gallery Section */}
        {service.galleryImages && service.galleryImages.length > 0 && (
          <section className="py-16 bg-slate-100 border-y border-slate-200">
            <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
              <div className="text-center max-w-2xl mx-auto mb-10">
                <span className="text-xs font-bold text-gold">معرض الميدان</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                  المعدات والتنفيذ الميداني
                </h2>
              </div>

              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                {service.galleryImages.map((img, idx) => (
                  <div
                    key={idx}
                    className="group relative aspect-[4/3] overflow-hidden rounded-2xl border border-slate-300 bg-white shadow-sm"
                  >
                    <Image
                      src={img}
                      alt={`${service.title} - صورة ميدانية ${idx + 1}`}
                      fill
                      sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                      className="object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-navy-darker/20 transition-opacity duration-300 group-hover:opacity-0" />
                  </div>
                ))}
              </div>
            </div>
          </section>
        )}

        {/* Advantages */}
        <section className="py-16 sm:py-20 bg-white">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="rounded-3xl bg-gradient-to-br from-navy via-navy to-navy-darker p-8 sm:p-12 text-white shadow-xl">
              <div className="max-w-2xl">
                <span className="text-xs font-black tracking-wider text-gold-light">لماذا الفضاء الواسع؟</span>
                <h2 className="mt-2 text-2xl font-black text-white sm:text-3xl">
                  مزايا الشراكة والتعاقد معنا في {service.shortTitle}
                </h2>
              </div>

              <div className="mt-8 grid gap-4 sm:grid-cols-2">
                {service.advantages.map((adv, idx) => (
                  <div key={idx} className="flex items-start gap-3 rounded-xl bg-white/5 p-4 border border-white/10">
                    <CheckCircle2 className="h-5 w-5 shrink-0 text-gold-light mt-0.5" />
                    <span className="text-sm leading-7 text-white/90">{adv}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* FAQ Section */}
        <section className="py-16 sm:py-20 bg-slate-50">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-10">
              <span className="text-xs font-bold text-gold">الأسئلة الشائعة</span>
              <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                استفسارات متكررة حول {service.shortTitle}
              </h2>
            </div>

            <div className="space-y-4">
              {service.faqs.map((faq, idx) => (
                <div
                  key={idx}
                  className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
                >
                  <div className="flex items-start gap-3">
                    <HelpCircle className="h-5 w-5 shrink-0 text-gold mt-1" />
                    <div>
                      <h3 className="text-base font-black text-navy">{faq.q}</h3>
                      <p className="mt-3 text-sm leading-7 text-slate-600">{faq.a}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Explore Other Services */}
        <section className="py-16 bg-white border-t border-slate-200">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-8 gap-4">
              <div>
                <span className="text-xs font-bold text-gold">منظومة متكاملة</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                  استكشف خدماتنا وقطاعاتنا الأخرى
                </h2>
              </div>
              <Link
                href="/#services"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-navy hover:text-gold transition"
              >
                <span>جميع الخدمات</span>
                <ArrowLeft className="h-4 w-4" />
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {otherServices.slice(0, 6).map((other) => (
                <Link
                  key={other.slug}
                  href={`/services/${other.slug}`}
                  className="group flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50/70 p-4 transition-all hover:border-gold hover:bg-white hover:shadow-sm"
                >
                  <div className="flex items-center gap-3">
                    <Building2 className="h-5 w-5 text-gold group-hover:scale-110 transition-transform" />
                    <div>
                      <span className="block text-sm font-extrabold text-navy group-hover:text-gold-dark transition-colors">
                        {other.title}
                      </span>
                      <span className="text-xs text-slate-500 line-clamp-1">{other.subtitle}</span>
                    </div>
                  </div>
                  <ChevronLeft className="h-4 w-4 text-slate-400 group-hover:text-gold transition-colors" />
                </Link>
              ))}
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}