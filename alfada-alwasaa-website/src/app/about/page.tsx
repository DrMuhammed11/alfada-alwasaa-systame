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
import { Stats } from "@/components/site/stats";

export const metadata: Metadata = {
  title: "من نحن | شركة الفضاء الواسع لخدمات الاتصالات والمقاولات في اليمن",
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
    title: "من نحن | شركة الفضاء الواسع لخدمات الاتصالات والمقاولات",
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
    <div className="flex min-h-screen flex-col bg-slate-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SiteHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-24">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">من نحن</span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <Building2 className="h-4 w-4 text-gold" />
                هوية رصينة وتاريخ مهني
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                شركة الفضاء الواسع لخدمات الاتصالات والمقاولات
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg sm:leading-9">
                {SITE_CONFIG.company.tagline} — كيان مهني متعدد الخدمات تأسس على رؤية واضحة تقوم على تقديم حلول متكاملة تجمع بين الخبرة التنفيذية، والانضباط المؤسسي، والجودة العالية.
              </p>
            </div>
          </div>
        </section>

        {/* Story & About content */}
        <section className="py-16 sm:py-20 bg-white">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-12 lg:grid-cols-12 lg:items-center">
              <div className="lg:col-span-7 space-y-6 text-base leading-8 text-slate-700">
                <span className="text-xs font-black uppercase tracking-wider text-gold">مسيرتنا وهويتنا</span>
                <h2 className="text-2xl font-black text-navy sm:text-3xl">
                  شريك موثوق لتطلعات المشاريع الكبرى في اليمن
                </h2>
                <p>
                  منذ انطلاقتها، حرصت شركة الفضاء الواسع على أن تكون شريكاً موثوقاً للجهات الحكومية والخاصة التي تبحث عن أداء رصين، وتنفيذ دقيق، ونتائج تليق بتطلعات المشاريع الإستراتيجية.
                </p>
                <p>
                  نعمل كمنظومة عمل موحدة تدمج خبرات المقاولات العامة، البنية التحتية، توريدات الطاقة والمعدات، خدمات الاتصالات الحديثة، والخدمات اللوجستية في بوتقة واحدة، ما يوفر لعملائنا إدارة مركزية وسلاسة في الإنجاز وتوفيراً ملموساً في التكاليف والوقت.
                </p>
                
                <div className="pt-4 grid gap-4 sm:grid-cols-2">
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <ShieldCheck className="h-6 w-6 text-gold mb-2" />
                    <h3 className="font-extrabold text-navy text-sm">انضباط مؤسسي</h3>
                    <p className="text-xs text-slate-600 mt-1">التزام تعاقدي وميداني دقيق بكافة المواصفات والمواعيد.</p>
                  </div>
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    <Award className="h-6 w-6 text-gold mb-2" />
                    <h3 className="font-extrabold text-navy text-sm">جودة واحتراف</h3>
                    <p className="text-xs text-slate-600 mt-1">مخرجات هندسية متينة تواكب كبرى الشركات الإقليمية.</p>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-5">
                <div className="relative aspect-[4/3] overflow-hidden rounded-3xl border-2 border-gold/30 shadow-xl bg-navy-darker">
                  <Image
                    src="/profile/site_hadramout_building.webp"
                    alt="مقر ومشاريع شركة الفضاء الواسع"
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

        {/* Stats */}
        <Stats />

        {/* Vision & Mission */}
        <section className="py-16 sm:py-20 bg-slate-50">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-8 md:grid-cols-2">
              <div className="rounded-3xl border border-slate-200 bg-white p-8 sm:p-10 shadow-sm">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-navy text-gold-light mb-6">
                  <Eye className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-black text-navy sm:text-2xl">رؤيتنا المستقبلية</h3>
                <p className="mt-4 text-sm leading-8 text-slate-600">
                  أن نكون الكيان المهني الأكثر موثوقية وتميزاً في تقديم الحلول المتكاملة في اليمن، ونموذجاً يحتذى به في الانضباط المؤسسي والقدرة على مواكبة تحديات التنمية والمشاريع العملاقة.
                </p>
              </div>

              <div className="rounded-3xl border border-slate-200 bg-white p-8 sm:p-10 shadow-sm">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6">
                  <Target className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-black text-navy sm:text-2xl">رسالتنا وقيمنا</h3>
                <p className="mt-4 text-sm leading-8 text-slate-600">
                  تقديم خدمات إنشائية وتقنية ولوجستية بمعايير هندسية متقدمة، عبر فريق متخصص وأسطول متطور، مع الحفاظ على مبادئ الشفافية والمسؤولية المهنية وبناء علاقات استراتيجية مستدامة مع شركائنا.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="py-16 bg-navy text-white text-center">
          <div className="mx-auto max-w-4xl px-4">
            <h2 className="text-2xl font-black sm:text-3xl">هل لديك مشروع قادم وتبحث عن شريك موثوق؟</h2>
            <p className="mt-3 text-sm text-white/80 max-w-2xl mx-auto leading-7">
              فريقنا الهندسي والاستشاري جاهز لمناقشة كافة التفاصيل الفنية وتقديم دراسة شاملة لاحتياجات مشروعك.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              <Link
                href="/contact"
                className="rounded-full bg-gold px-8 py-3 text-sm font-black text-navy-darker hover:bg-gold-light transition shadow-lg"
              >
                تواصل معنا الآن
              </Link>
              <Link
                href="/#services"
                className="rounded-full border border-white/20 bg-white/10 px-8 py-3 text-sm font-bold text-white hover:bg-white/20 transition"
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