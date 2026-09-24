"use client";

/**
 * English Service Detail Page View — full English counterpart of service-page-view.tsx
 * Same layout, sections, schemas and interactions, translated for /en/services/*.
 */

import Image from "next/image";
import Link from "next/link";
import {
  CheckCircle2,
  HelpCircle,
  ArrowRight,
  PhoneCall,
  MessageSquare,
  ShieldCheck,
  Building2,
  ChevronRight,
  Printer,
  Share2
} from "lucide-react";
import { toast } from "sonner";
import { EN_SERVICES_DATA, type ServiceDetail as EnServiceDetail } from "@/config/en-services-data";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { EnHeader } from "./en-header";
import { EnFooter } from "./en-footer";
import { EnFloatingContact } from "./en-floating-contact";
import { ReadingProgress } from "./reading-progress";

export function EnServicePageView({ service }: { service: EnServiceDetail }) {
  const otherServices = Object.values(EN_SERVICES_DATA).filter(
    (s) => s.slug !== service.slug
  );

  const handleShare = () => {
    if (typeof navigator !== "undefined" && navigator.share) {
      navigator.share({
        title: `${service.title} | Al-Fada Al-Wasaa`,
        text: service.subtitle,
        url: window.location.href,
      }).catch(() => {});
    } else if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(window.location.href);
      toast.success("Service link copied to clipboard successfully");
    }
  };

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

  // BreadcrumbList Schema
  const breadcrumbSchema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: "https://www.alfadaalwasaa.com/en",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Services & Sectors",
        item: "https://www.alfadaalwasaa.com/en#services",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: service.title,
        item: `https://www.alfadaalwasaa.com/en/services/${service.slug}`,
      },
    ],
  };

  // Service Schema
  const serviceSchema = {
    "@context": "https://schema.org",
    "@type": "Service",
    name: service.title,
    description: service.subtitle,
    provider: {
      "@type": "Organization",
      name: EN_SITE_CONFIG.company.fullName,
      url: "https://www.alfadaalwasaa.com/en",
    },
    areaServed: {
      "@type": "Country",
      name: "Yemen",
    },
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 dark:bg-navy-darker text-slate-900 dark:text-slate-100 transition-colors">
      <ReadingProgress />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(serviceSchema) }}
      />
      <EnHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Banner */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-24">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {/* Breadcrumb */}
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="Breadcrumb">
              <Link href="/en" className="hover:text-gold transition">
                Home
              </Link>
              <ChevronRight className="h-3 w-3 text-gold" />
              <Link href="/en#services" className="hover:text-gold transition">
                Services
              </Link>
              <ChevronRight className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">{service.shortTitle}</span>
            </nav>

            <div className="grid gap-12 lg:grid-cols-12 lg:items-center">
              <div className="lg:col-span-7">
                <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                  <ShieldCheck className="h-4 w-4 text-gold" />
                  Certified & Professional Service
                </span>

                <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                  {service.title}
                </h1>

                <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                  {service.subtitle}
                </p>

                {/* Direct Action Buttons */}
                <div className="mt-8 flex flex-wrap items-center gap-3">
                  <a
                    href={EN_SITE_CONFIG.contacts.general.waHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-full bg-gold px-6 py-3 text-xs sm:text-sm font-black text-navy-darker shadow-lg transition-all duration-300 hover:bg-gold-light hover:scale-105 active:scale-95 print:hidden"
                  >
                    <MessageSquare className="h-4 w-4" />
                    <span>Request a Study or Quotation</span>
                  </a>

                  <a
                    href={EN_SITE_CONFIG.contacts.general.telHref}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-xs sm:text-sm font-bold text-white backdrop-blur-sm transition-all hover:bg-white/20 print:hidden"
                  >
                    <PhoneCall className="h-4 w-4 text-gold-light" />
                    <span dir="ltr">{EN_SITE_CONFIG.contacts.general.display}</span>
                  </a>

                  <button
                    type="button"
                    onClick={() => window.print()}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-3 text-xs sm:text-sm font-bold text-white backdrop-blur-sm transition-all hover:bg-white/20 hover:text-gold-light print:hidden"
                    title="Print technical specifications or save as PDF"
                  >
                    <Printer className="h-4 w-4 text-gold-light" />
                    <span>Print Specs (PDF)</span>
                  </button>

                  <button
                    type="button"
                    onClick={handleShare}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-3 text-xs sm:text-sm font-bold text-white backdrop-blur-sm transition-all hover:bg-white/20 hover:text-gold-light print:hidden"
                    title="Share service details"
                  >
                    <Share2 className="h-4 w-4 text-gold-light" />
                    <span>Share</span>
                  </button>
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
              <span className="text-xs font-extrabold uppercase tracking-wider text-gold">Overview</span>
              <h2 className="mt-2 text-2xl font-black text-navy sm:text-3xl">
                Leading the Field in {service.shortTitle}
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
                Scope of Work & Execution Capabilities
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
                <span className="text-xs font-bold text-gold">Field Gallery</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                  Equipment & On-Site Execution
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
                      alt={`${service.title} - field photo ${idx + 1}`}
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
                <span className="text-xs font-black tracking-wider text-gold-light">Why Al-Fada Al-Wasaa?</span>
                <h2 className="mt-2 text-2xl font-black text-white sm:text-3xl">
                  Advantages of Partnering with Us in {service.shortTitle}
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
              <span className="text-xs font-bold text-gold">Frequently Asked Questions</span>
              <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                Common Questions About {service.shortTitle}
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
                <span className="text-xs font-bold text-gold">One Integrated Ecosystem</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl mt-1">
                  Explore Our Other Services & Sectors
                </h2>
              </div>
              <Link
                href="/en#services"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-navy hover:text-gold transition"
              >
                <span>All Services</span>
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {otherServices.slice(0, 6).map((other) => (
                <Link
                  key={other.slug}
                  href={`/en/services/${other.slug}`}
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
                  <ChevronRight className="h-4 w-4 text-slate-400 group-hover:text-gold transition-colors" />
                </Link>
              ))}
            </div>
          </div>
        </section>
      </main>

      <EnFooter />
      <EnFloatingContact />
    </div>
  );
}
