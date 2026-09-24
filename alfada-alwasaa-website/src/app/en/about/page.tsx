import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  Building2,
  ShieldCheck,
  Target,
  Eye,
  Award,
  ChevronRight
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { EnHeader } from "@/components/site/en-header";
import { EnFooter } from "@/components/site/en-footer";
import { EnFloatingContact } from "@/components/site/en-floating-contact";

export const metadata: Metadata = {
  title: "About Us | Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting in Yemen",
  description: "Learn about Al-Fada Al-Wasaa — our history, vision, and mission in delivering integrated solutions spanning general contracting, telecom, supplies, and logistics services across Yemen.",
  keywords: [
    "about Al-Fada Al-Wasaa",
    "Al-Fada Al-Wasaa Yemen",
    "Al-Fada Al-Wasaa company history",
    "Al-Fada Al-Wasaa vision and mission",
    "contracting and telecom company Sana'a"
  ],
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en/about",
    languages: {
      ar: "https://www.alfadaalwasaa.com/about",
      en: "https://www.alfadaalwasaa.com/en/about",
    },
  },
  openGraph: {
    title: "About Us | Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting",
    description: "A multi-service professional entity delivering integrated solutions that unite executive experience and institutional discipline across Yemen.",
    url: "https://www.alfadaalwasaa.com/en/about",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "Al-Fada Al-Wasaa" }],
    locale: "en_US",
    type: "website",
  },
};

export default function EnAboutPage() {
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
        name: "About Us",
        item: "https://www.alfadaalwasaa.com/en/about",
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <EnHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-24">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="Breadcrumb">
              <Link href="/en" className="hover:text-gold transition">
                Home
              </Link>
              <ChevronRight className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">About Us</span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <Building2 className="h-4 w-4 text-gold" />
                A Distinguished Identity & Professional History
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                Al-Fada Al-Wasaa Company for Telecommunications Services & General Contracting
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                {EN_SITE_CONFIG.company.tagline} — a multi-service professional entity founded on a clear vision of delivering integrated solutions that unite executive experience, institutional discipline, and the highest quality.
              </p>
            </div>
          </div>
        </section>

        {/* Story & About content */}
        <section className="py-16 sm:py-20 bg-white">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-12 lg:grid-cols-12 lg:items-center">
              <div className="lg:col-span-7 space-y-6 text-base leading-8 text-slate-700">
                <span className="text-xs font-black uppercase tracking-wider text-gold">OUR JOURNEY & IDENTITY</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl">
                  A Trusted Partner for the Aspirations of Major Projects in Yemen
                </h2>
                <p>
                  Since its inception, Al-Fada Al-Wasaa has been committed to being a reliable partner for government and private organizations seeking solid performance, meticulous execution, and outcomes befitting strategic mega projects.
                </p>
                <p>
                  We operate as one unified work system that integrates expertise in general contracting, infrastructure, energy and equipment supplies, modern telecom services, and logistics services into a single ecosystem — providing our clients with centralized management, smooth delivery, and tangible savings in cost and time.
                </p>

                <div className="pt-4 grid gap-4 sm:grid-cols-2">
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <ShieldCheck className="h-6 w-6 text-gold mb-2" />
                    <h3 className="font-extrabold text-navy text-sm">Institutional Discipline</h3>
                    <p className="text-xs text-slate-600 mt-1">Precise contractual and field commitment to every specification and deadline.</p>
                  </div>
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <Award className="h-6 w-6 text-gold mb-2" />
                    <h3 className="font-extrabold text-navy text-sm">Quality & Professionalism</h3>
                    <p className="text-xs text-slate-600 mt-1">Solid engineering output that keeps pace with the region's leading firms.</p>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-5">
                <div className="relative aspect-[4/3] overflow-hidden rounded-3xl border-2 border-gold/30 shadow-xl bg-navy-darker">
                  <Image
                    src="/profile/site_hadramout_building.webp"
                    alt="Al-Fada Al-Wasaa headquarters and projects"
                    fill
                    sizes="(max-width: 1024px) 100vw, 450px"
                    className="object-cover"
                    priority
                  />
                </div>
              </div>
            </div>
          </div>
        </section>


        {/* Vision & Mission */}
        <section className="py-16 sm:py-20 bg-slate-50">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-8 md:grid-cols-2">
              <div className="rounded-3xl border border-slate-200 bg-white p-8 sm:p-10 shadow-sm">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-navy text-gold-light mb-6">
                  <Eye className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-black text-navy sm:text-2xl">Our Vision</h3>
                <p className="mt-4 text-sm leading-8 text-slate-600">
                  To be the most trusted and distinguished professional entity delivering integrated solutions in Yemen, and a model of institutional discipline with the capacity to meet the challenges of development and mega projects.
                </p>
              </div>

              <div className="rounded-3xl border border-slate-200 bg-white p-8 sm:p-10 shadow-sm">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6">
                  <Target className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-black text-navy sm:text-2xl">Our Mission & Values</h3>
                <p className="mt-4 text-sm leading-8 text-slate-600">
                  Delivering construction, technical, and logistics services to advanced engineering standards through a specialized team and a modern fleet, while upholding transparency, professional responsibility, and building sustainable strategic relationships with our partners.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="py-16 bg-navy text-white text-center">
          <div className="mx-auto max-w-4xl px-4">
            <h2 className="text-2xl font-black sm:text-3xl">Have an upcoming project and looking for a trusted partner?</h2>
            <p className="mt-3 text-sm text-white/80 max-w-2xl mx-auto leading-7">
              Our engineering and consulting team is ready to discuss all technical details and deliver a comprehensive study of your project's needs.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              <Link
                href="/en/contact"
                className="rounded-full bg-gold px-8 py-3 text-sm font-black text-navy-darker hover:bg-gold-light transition shadow-lg"
              >
                Contact Us Now
              </Link>
              <Link
                href="/en#services"
                className="rounded-full border border-white/20 bg-white/10 px-8 py-3 text-sm font-bold text-white hover:bg-white/20 transition"
              >
                Explore Our Services
              </Link>
            </div>
          </div>
        </section>
      </main>

      <EnFooter />
      <EnFloatingContact />
    </div>
  );
}
