import type { Metadata } from "next";
import Link from "next/link";
import { ShieldCheck, ChevronRight, Lock, FileText, CheckCircle2 } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { EnHeader } from "@/components/site/en-header";
import { EnFooter } from "@/components/site/en-footer";
import { EnFloatingContact } from "@/components/site/en-floating-contact";

export const metadata: Metadata = {
  title: "Privacy Policy & Data Confidentiality | Al-Fada Al-Wasaa",
  description: "Privacy policy and protection and confidentiality of commercial and engineering data for clients and partners of Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting.",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en/privacy",
    languages: {
      ar: "https://www.alfadaalwasaa.com/privacy",
      en: "https://www.alfadaalwasaa.com/en/privacy",
    },
  },
  openGraph: {
    title: "Privacy Policy & Data Confidentiality | Al-Fada Al-Wasaa",
    description: "Institutional commitment to the protection and confidentiality of client and project data.",
    url: "https://www.alfadaalwasaa.com/en/privacy",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "Privacy Policy - Al-Fada Al-Wasaa" }],
    locale: "en_US",
    type: "website",
  },
};

export default function EnPrivacyPolicyPage() {
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
        name: "Privacy Policy",
        item: "https://www.alfadaalwasaa.com/en/privacy",
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
              <span className="text-gold-light font-bold">Privacy Policy</span>
            </nav>

            <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
              <ShieldCheck className="h-4 w-4 text-gold" />
              Institutional Discipline & Confidentiality
            </span>

            <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
              Privacy Policy & Data Confidentiality
            </h1>

            <p className="mt-4 text-sm sm:text-base leading-7 text-white/80 max-w-2xl">
              Al-Fada Al-Wasaa commits to the highest standards of data protection and professional confidentiality for all information, engineering drawings, and commercial correspondence of our clients and partners.
            </p>

            <div className="mt-6 flex items-center gap-4 text-xs text-gold-soft/80 border-t border-white/10 pt-4">
              <span>Last updated: 2026</span>
              <span>•</span>
              <span>In force for all engagements</span>
            </div>
          </div>
        </section>

        {/* Content Body */}
        <section className="py-12 sm:py-16 bg-white dark:bg-navy">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <div className="prose prose-slate dark:prose-invert max-w-none space-y-10 text-justify text-sm sm:text-base leading-8 text-slate-700 dark:text-slate-200">
              {/* Introduction */}
              <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy-darker/60 p-6 sm:p-8">
                <h2 className="flex items-center gap-2.5 text-xl font-bold text-navy dark:text-white mb-3">
                  <Lock className="h-5 w-5 text-gold shrink-0" />
                  <span>1. Our General Commitment to Privacy Protection</span>
                </h2>
                <p>
                  {EN_SITE_CONFIG.company.fullName} recognizes the importance of privacy and absolute confidentiality of the technical and commercial information related to construction projects, telecom networks, supplies, and customs transactions. This document clearly defines how we handle data submitted through the official website or approved communication channels.
                </p>
              </div>

              {/* Data Collected */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  2. Data We Collect
                </h2>
                <p>
                  We collect only the data necessary for studying quotations, responding to inquiries, and documenting transactions in the central correspondence system:
                </p>
                <ul className="mt-4 space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>Identity & contact data:</strong> name, job title, organization or company name, phone number, and email address.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>Project & quotation details:</strong> bills of quantities (BOQ), drawings, and technical specifications submitted for pricing studies.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>Technical browsing data:</strong> IP address, browser type, language preferences, and cookies necessary to operate and secure the session.</span>
                  </li>
                </ul>
              </div>

              {/* Purpose of Use */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  3. How Data Is Used
                </h2>
                <p>
                  Received data is used exclusively for the following direct operational and contractual purposes:
                </p>
                <ul className="mt-4 space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>Preparing and delivering technical studies and competitive quotations.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>Documenting transactions and issuing reference numbers and tracking tokens for electronic follow-up.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>Coordinating field and logistics operations per the requirements of each execution sector.</span>
                  </li>
                </ul>
              </div>

              {/* Confidentiality & Non-Disclosure */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  4. Confidentiality of Drawings & Documents (Non-Disclosure)
                </h2>
                <p>
                  All engineering drawings, tender documents, supply schedules, and contracts are subject to a strict confidentiality protocol. No information is ever sold, rented, or shared with any third party for advertising or promotional purposes, and data access is limited strictly to the engineering and administrative staff concerned with the project.
                </p>
              </div>

              {/* Cookies */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  5. Cookies
                </h2>
                <p>
                  Our website uses essential cookies to enable vital functions such as saving the theme preference (light / dark), language preference (Arabic / English), and facilitating transaction tracking by storing the secure reference token locally on the user's device (LocalStorage). Users can manage these preferences through their browser at any time.
                </p>
              </div>

              {/* Contact for Privacy */}
              <div className="rounded-3xl border border-gold/40 bg-gold/5 dark:bg-gold/10 p-6 sm:p-8">
                <h3 className="flex items-center gap-2 text-lg font-black text-navy dark:text-gold-light mb-2">
                  <FileText className="h-5 w-5 text-gold shrink-0" />
                  <span>Contacting the Privacy & Data Protection Officer</span>
                </h3>
                <p className="text-sm leading-7 text-slate-700 dark:text-slate-300">
                  If you have any questions or requests related to your data or the confidentiality procedures in place, you can reach the Compliance & Documentation Department directly via the official email:{" "}
                  <a href={EN_SITE_CONFIG.contacts.email.mailHref} className="font-bold text-gold underline">
                    {EN_SITE_CONFIG.contacts.email.address}
                  </a>{" "}
                  or by phone at: <span dir="ltr" className="font-bold text-gold">{EN_SITE_CONFIG.contacts.general.display}</span>.
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
