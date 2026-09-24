import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { 
  Building2, 
  ShieldCheck, 
  Target, 
  Eye, 
  Award, 
  CheckCircle2, 
  ArrowLeft,
  ChevronLeft 
} from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { SiteHeader } from "@/components/site/header";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

export const metadata: Metadata = {
  title: "من نحن | شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة في اليمن",
  description: "تعرف على شركة الفضاء الواسع — تاريخنا، رؤيتنا، ورسالتنا في تقديم حلول متكاملة تجمع بين المقاولات العامة، الاتصالات، التوريدات، والخدمات اللوجستية باليمن.",
  keywords: [
    "من نحن الفضاء الواسع",
    "شركة الفضاء الواسع اليمن",
    "تاريخ شركة الفضاء الواسع",
    "رؤية ورسالة الفضاء الواسع",
    "شركة مقاولات واتصالات صنعاء"
  ],
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/about",
    languages: {
      ar: "https://www.alfadaalwasaa.com/about",
      en: "https://www.alfadaalwasaa.com/en/about",
    },
  },
  openGraph: {
    title: "من نحن | شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة",
    description: "كيان مهني متعدد الخدمات يقدم حلولاً متكاملة تجمع بين الخبرة التنفيذية والانضباط المؤسسي باليمن.",
    url: "https://www.alfadaalwasaa.com/about",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "شركة الفضاء الواسع" }],
    locale: "ar_YE",
    type: "website",
  },
};

export default function AboutPage() {
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
        name: "من نحن",
        item: "https://www.alfadaalwasaa.com/about",
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
        {/* Hero Section with Ambient Glow */}
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
                من نحن
              </span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <Building2 className="h-4 w-4 text-gold" />
                هوية مؤسسية رصينة وتاريخ مهني معتمد
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                {SITE_CONFIG.company.tagline} — كيان مهني متعدد الخدمات تأسس على رؤية واضحة تقوم على تقديم حلول متكاملة تجمع بين الخبرة التنفيذية، والانضباط المؤسسي، والجودة العالية.
              </p>
            </div>
          </div>
        </section>

        {/* Company Identity & 4 Operational Pillars */}
        <section className="py-16 sm:py-24 bg-white dark:bg-navy-darker/60 transition-colors duration-300">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-12 lg:grid-cols-12 lg:items-center">
              <div className="lg:col-span-7 space-y-6 text-base leading-8 text-slate-700 dark:text-slate-200">
                <span className="inline-block rounded-full bg-gold/15 px-3.5 py-1 text-xs font-black uppercase tracking-wider text-navy dark:text-gold-light ring-1 ring-gold/30">
                  مسيرتنا وهويتنا
                </span>
                <h2 className="text-2xl font-black text-navy dark:text-white sm:text-3xl leading-snug">
                  شريك موثوق لتطلعات المشاريع الكبرى والتنموية في اليمن
                </h2>
                <p>
                  منذ انطلاقتها، حرصت شركة الفضاء الواسع على أن تكون شريكاً موثوقاً للجهات الحكومية والخاصة التي تبحث عن أداء رصين، وتنفيذ دقيق، ونتائج تليق بتطلعات المشاريع الإستراتيجية.
                </p>
                <p>
                  نعمل كمنظومة عمل موحدة تدمج خبرات المقاولات العامة، البنية التحتية، توريدات الطاقة والمعدات، خدمات الاتصالات الحديثة، والخدمات اللوجستية في بوتقة واحدة، ما يوفر لعملائنا إدارة مركزية وسلاسة في الإنجاز وتوفيراً ملموساً في التكاليف والوقت.
                </p>
                
                {/* 4 Pillars Grid */}
                <div className="pt-4 grid gap-4 sm:grid-cols-2">
                  <div className="group rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-5 shadow-sm hover:shadow-md hover:border-gold/40 transition-all duration-300">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 dark:bg-gold/20 text-gold mb-3 group-hover:scale-110 transition-transform">
                      <ShieldCheck className="h-5 w-5" />
                    </div>
                    <h3 className="font-extrabold text-navy dark:text-white text-sm">انضباط مؤسسي</h3>
                    <p className="text-xs text-slate-600 dark:text-slate-300 mt-1.5 leading-relaxed">
                      التزام تعاقدي وميداني دقيق بكافة المواصفات الفنية والجداول الزمنية المحددة.
                    </p>
                  </div>

                  <div className="group rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-5 shadow-sm hover:shadow-md hover:border-gold/40 transition-all duration-300">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 dark:bg-gold/20 text-gold mb-3 group-hover:scale-110 transition-transform">
                      <Award className="h-5 w-5" />
                    </div>
                    <h3 className="font-extrabold text-navy dark:text-white text-sm">جودة واحتراف هندسي</h3>
                    <p className="text-xs text-slate-600 dark:text-slate-300 mt-1.5 leading-relaxed">
                      مخرجات هندسية متينة تواكب المواصفات والمقاييس المعتمدة في كبرى المشروعات.
                    </p>
                  </div>

                  <div className="group rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-5 shadow-sm hover:shadow-md hover:border-gold/40 transition-all duration-300">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 dark:bg-gold/20 text-gold mb-3 group-hover:scale-110 transition-transform">
                      <CheckCircle2 className="h-5 w-5" />
                    </div>
                    <h3 className="font-extrabold text-navy dark:text-white text-sm">السلامة المهنية والبيئية</h3>
                    <p className="text-xs text-slate-600 dark:text-slate-300 mt-1.5 leading-relaxed">
                      بروتوكولات أمان صارمة في مواقع العمل لحماية الأفراد والأصول والبيئة المحيطة.
                    </p>
                  </div>

                  <div className="group rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-5 shadow-sm hover:shadow-md hover:border-gold/40 transition-all duration-300">
                    <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 dark:bg-gold/20 text-gold mb-3 group-hover:scale-110 transition-transform">
                      <Building2 className="h-5 w-5" />
                    </div>
                    <h3 className="font-extrabold text-navy dark:text-white text-sm">جاهزية انتشار شاملة</h3>
                    <p className="text-xs text-slate-600 dark:text-slate-300 mt-1.5 leading-relaxed">
                      أسطول آليات ثقيلة وفرق استجابة ميدانية تغطي كافة محافظات الجمهورية اليمنية.
                    </p>
                  </div>
                </div>
              </div>

              {/* Company Building & Headquarters Showcase */}
              <div className="lg:col-span-5">
                <div className="relative aspect-[4/3] overflow-hidden rounded-3xl border-2 border-gold/30 dark:border-gold/40 shadow-2xl bg-navy-darker group">
                  <Image
                    src="/profile/site_hadramout_building.webp"
                    alt="مقر ومشاريع شركة الفضاء الواسع"
                    fill
                    sizes="(max-width: 1024px) 100vw, 450px"
                    className="object-cover group-hover:scale-105 transition-transform duration-700"
                    priority
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/90 via-navy-darker/20 to-transparent" />
                  <div className="absolute bottom-4 start-4 end-4 flex items-center justify-between gap-2 rounded-2xl bg-navy/85 backdrop-blur-md px-4 py-2.5 border border-white/10 text-white text-xs">
                    <span className="font-bold">المقر والمشاريع الميدانية</span>
                    <span className="font-mono text-[11px] text-gold-light">AL-FADA AL-WASAA</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Vision, Mission & Values (Luxury Corporate Cards) */}
        <section className="py-16 sm:py-24 bg-mist/60 dark:bg-navy-darker transition-colors duration-300">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-2xl mx-auto mb-12">
              <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light ring-1 ring-gold/30">
                الموجهات الإستراتيجية
              </span>
              <h2 className="mt-3 text-2xl font-black text-navy dark:text-white sm:text-3xl">
                الرؤية، الرسالة، والقيم الحاكمة
              </h2>
            </div>

            <div className="grid gap-8 md:grid-cols-2">
              {/* Vision Card */}
              <div className="group relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-8 sm:p-10 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300">
                <div
                  className="pointer-events-none absolute -top-16 -end-16 h-36 w-36 rounded-full bg-gold/10 blur-2xl group-hover:bg-gold/20 transition-colors"
                  aria-hidden="true"
                />
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-navy dark:bg-navy-darker text-gold border border-gold/30 mb-6 shadow-sm group-hover:scale-105 transition-transform">
                  <Eye className="h-7 w-7" />
                </div>
                <span className="inline-block rounded-full bg-gold/10 px-3 py-1 text-[11px] font-bold text-gold-light dark:text-gold mb-3 border border-gold/20 font-mono">
                  OUR VISION
                </span>
                <h3 className="text-xl font-black text-navy dark:text-white sm:text-2xl">
                  رؤيتنا المستقبلية
                </h3>
                <p className="mt-4 text-sm leading-8 text-slate-600 dark:text-slate-300">
                  أن نكون الكيان المهني الأكثر موثوقية وتميزاً في تقديم الحلول المتكاملة في اليمن، ونموذجاً يحتذى به في الانضباط المؤسسي والقدرة على مواكبة تحديات التنمية والمشاريع العملاقة.
                </p>
                <div className="mt-6 h-1 w-16 rounded-full bg-gradient-to-r from-gold to-gold/30" />
              </div>

              {/* Mission Card */}
              <div className="group relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-8 sm:p-10 shadow-sm hover:shadow-xl hover:border-gold/50 transition-all duration-300">
                <div
                  className="pointer-events-none absolute -top-16 -end-16 h-36 w-36 rounded-full bg-gold/10 blur-2xl group-hover:bg-gold/20 transition-colors"
                  aria-hidden="true"
                />
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6 shadow-sm group-hover:scale-105 transition-transform">
                  <Target className="h-7 w-7" />
                </div>
                <span className="inline-block rounded-full bg-gold/10 px-3 py-1 text-[11px] font-bold text-gold-light dark:text-gold mb-3 border border-gold/20 font-mono">
                  OUR MISSION
                </span>
                <h3 className="text-xl font-black text-navy dark:text-white sm:text-2xl">
                  رسالتنا وقيمنا
                </h3>
                <p className="mt-4 text-sm leading-8 text-slate-600 dark:text-slate-300">
                  تقديم خدمات إنشائية وتقنية ولوجستية بمعايير هندسية متقدمة، عبر فريق متخصص وأسطول متطور، مع الحفاظ على مبادئ الشفافية والمسؤولية المهنية وبناء علاقات استراتيجية مستدامة مع شركائنا.
                </p>
                <div className="mt-6 h-1 w-16 rounded-full bg-gradient-to-r from-gold to-gold/30" />
              </div>
            </div>
          </div>
        </section>

        {/* CTA Conversion Banner */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy via-navy-deep to-navy-darker py-20 text-white text-center">
          <div
            className="pointer-events-none absolute top-1/2 start-1/2 -translate-x-1/2 -translate-y-1/2 h-80 w-80 rounded-full bg-gold/15 blur-3xl"
            aria-hidden="true"
          />
          <div className="relative mx-auto max-w-4xl px-4 sm:px-6">
            <span className="inline-block rounded-full bg-gold/20 px-4 py-1.5 text-xs font-bold text-gold-light ring-1 ring-gold/40 mb-4">
              شراكة عملية ونتائج ملموسة
            </span>
            <h2 className="text-2xl font-black sm:text-4xl text-white">هل لديك مشروع قادم وتبحث عن شريك موثوق؟</h2>
            <p className="mt-4 text-sm sm:text-base text-white/80 max-w-2xl mx-auto leading-8">
              فريقنا الهندسي والاستشاري جاهز لمناقشة كافة التفاصيل الفنية وتقديم دراسة شاملة لاحتياجات مشروعك بأعلى كفاءة وسرعة استجابة.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              <Link
                href="/contact"
                className="rounded-full bg-gold px-8 py-3.5 text-sm font-black text-navy-darker hover:bg-gold-light transition shadow-lg hover:scale-105 active:scale-95"
              >
                تواصل معنا الآن
              </Link>
              <Link
                href="/#services"
                className="rounded-full border border-white/20 bg-white/10 px-8 py-3.5 text-sm font-bold text-white hover:bg-white/20 transition hover:scale-105 active:scale-95"
              >
                استعرض خدماتنا
              </Link>
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}