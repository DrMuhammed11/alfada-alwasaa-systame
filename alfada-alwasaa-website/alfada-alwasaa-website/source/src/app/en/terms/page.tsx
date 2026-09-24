import type { Metadata } from "next";
import Link from "next/link";
import { Scale, ChevronRight, CheckCircle2, ShieldAlert } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { EnHeader } from "@/components/site/en-header";
import { EnFooter } from "@/components/site/en-footer";
import { EnFloatingContact } from "@/components/site/en-floating-contact";

export const metadata: Metadata = {
  title: "Terms & Conditions and Contractual Controls | Al-Fada Al-Wasaa",
  description: "The terms and conditions governing commercial dealings, quotations, and the engineering and field services of Al-Fada Al-Wasaa.",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en/terms",
    languages: {
      ar: "https://www.alfadaalwasaa.com/terms",
      en: "https://www.alfadaalwasaa.com/en/terms",
    },
  },
  openGraph: {
    title: "Terms & Conditions | Al-Fada Al-Wasaa",
    description: "The official approved controls and terms for delivering engineering services and engagements.",
    url: "https://www.alfadaalwasaa.com/en/terms",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "Terms & Conditions - Al-Fada Al-Wasaa" }],
    locale: "en_US",
    type: "website",
  },
};

export default function EnTermsPage() {
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
        name: "Terms & Conditions",
        item: "https://www.alfadaalwasaa.com/en/terms",
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 dark:bg-navy-darker text-slate-900 dark:text-slate-100 transition-colors">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <EnHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-14 text-white sm:py-20">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="Breadcrumb">
              <Link href="/en" className="hover:text-gold transition">
                Home
              </Link>
              <ChevronRight className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">Terms & Conditions</span>
            </nav>

            <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
              <Scale className="h-4 w-4 text-gold" />
              Controls & Contractual Frameworks
            </span>

            <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
              Official Terms & Conditions
            </h1>

            <p className="mt-4 text-sm sm:text-base leading-7 text-white/80 max-w-2xl">
              This document defines the general rules and terms governing the use of the electronic portal and the submission of requests and commercial dealings with Al-Fada Al-Wasaa.
            </p>

            <div className="mt-6 flex items-center gap-4 text-xs text-gold-soft/80 border-t border-white/10 pt-4">
              <span>Official edition: 2026</span>
              <span>•</span>
              <span>Applies to all transactions and correspondence</span>
            </div>
          </div>
        </section>

        {/* Content Body */}
        <section className="py-12 sm:py-16 bg-white dark:bg-navy">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <div className="prose prose-slate dark:prose-invert max-w-none space-y-10 text-justify text-sm sm:text-base leading-8 text-slate-700 dark:text-slate-200">
              {/* Preamble */}
              <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy-darker/60 p-6 sm:p-8">
                <h2 className="text-xl font-bold text-navy dark:text-white mb-3">
                  1. Preamble & Scope of Application
                </h2>
                <p>
                  Use of this website and all dealings arising from it are subject to these terms. Your use of the website or submission of a quotation request or consultation constitutes explicit consent to abide by these controls and the professional requirements approved by {EN_SITE_CONFIG.company.fullName}.
                </p>
              </div>

              {/* Quotations & Proposals */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  2. Quotations & Technical Estimates
                </h2>
                <ul className="space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>Quotations and preliminary studies submitted through the website or email are indicative only, and become final and binding only after signing the formal contract and the approved bills of quantities between both parties.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>The company reserves the right to adjust prices based on field surveys and changes in raw material costs or official exchange rates before final signature.</span>
                  </li>
                </ul>
              </div>

              {/* Intellectual Property */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  3. Intellectual Property & Trademark Rights
                </h2>
                <p>
                  All content published on this website (including the official logo, trade name, exclusive field photographs, descriptive texts, and drawings) is the exclusive property of Al-Fada Al-Wasaa and is protected under the applicable laws and regulations. Copying or republishing any part without prior written permission is prohibited.
                </p>
              </div>

              {/* Force Majeure */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  4. Force Majeure & Emergency Conditions
                </h2>
                <p>
                  The company bears no liability for any delay in responses or field works caused by circumstances beyond its control, including natural disasters, security disturbances, port or road closures, or emergency government decisions.
                </p>
              </div>

              {/* Governing Law */}
              <div className="rounded-3xl border border-gold/40 bg-gold/5 dark:bg-gold/10 p-6 sm:p-8">
                <h3 className="flex items-center gap-2 text-lg font-black text-navy dark:text-gold-light mb-2">
                  <ShieldAlert className="h-5 w-5 text-gold shrink-0" />
                  <span>5. Governing Law & Jurisdiction</span>
                </h3>
                <p className="text-sm leading-7 text-slate-700 dark:text-slate-300">
                  These terms and all agreements and contracts concluded with Al-Fada Al-Wasaa are governed by the commercial laws, regulations, and legislation in force in the Republic of Yemen, and the courts of the capital secretariat, Sana'a, shall have jurisdiction over any dispute.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <EnFooter />
      <EnFloatingContact />
    </div>
  );
}
