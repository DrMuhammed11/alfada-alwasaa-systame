"use client";

/**
 * القالب الموحّد لصفحات الخدمات التفصيلية السبع — ثنائي اللغة (عربي/إنجليزي)
 * Shared bilingual template for all seven service detail pages.
 *
 * - لغة واحدة، قالب واحد: الرسم والنصوص والأيقونات الاتجاهية تُضبط عبر `locale`.
 * - أقسام الصفحة: هيرو بمؤشرات، نظرة عامة + بطاقة حقائق، نطاق الأعمال بأيقونات،
 *   منهجية العمل (5 مراحل)، معرض الميدان، المزايا، أسئلة شائعة (accordion)،
 *   خدمات مرتبطة، ودعوة ختامية للتواصل.
 * - دعم كامل للوضع الليلي وRTL/LTR عبر الخصائص المنطقية (start/end).
 * - الحركات: hero-fade-up (CSS خالص مرسَّر مرئياً) + Reveal (تحسين تدريجي
 *   mount-only) + shimmer — بلا أي opacity:0 في HTML الثابت.
 */

import Image from "next/image";
import Link from "next/link";
import {
  ArrowLeft,
  ArrowRight,
  BadgeCheck,
  Bolt,
  Blocks,
  BrickWall,
  Briefcase,
  Building,
  Building2,
  Cable,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  ClipboardCheck,
  Cog,
  DraftingCompass,
  FileCheck,
  FileText,
  FlaskConical,
  Fuel,
  Hammer,
  Handshake,
  HardHat,
  LandPlot,
  Landmark,
  Layers,
  LayoutGrid,
  MapPinned,
  MessageSquare,
  Milestone,
  Mountain,
  Network,
  Package,
  PaintRoller,
  PhoneCall,
  Plus,
  Printer,
  RadioTower,
  Route,
  Share2,
  ShieldCheck,
  Shovel,
  Signal,
  Ship,
  Sparkles,
  Sun,
  TrendingUp,
  Tractor,
  Truck,
  Warehouse,
  Waves,
  Wifi,
  Wrench,
  type LucideIcon,
} from "lucide-react";
import { toast } from "sonner";
import { EN_SERVICES_DATA } from "@/config/en-services-data";
import { SERVICES_DATA, type ServiceDetail, type ServiceIconName } from "@/config/services-data";
import { SITE_CONFIG } from "@/config/site";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { cn } from "@/lib/utils";
import { SiteHeader } from "./header";
import { SiteFooter } from "./footer";
import { FloatingContact } from "./floating-contact";
import { EnHeader } from "./en-header";
import { EnFooter } from "./en-footer";
import { EnFloatingContact } from "./en-floating-contact";
import { ReadingProgress } from "./reading-progress";
import { SectionHeading } from "./section-heading";
import { Reveal } from "./reveal";

/* ===== أيقونة كل خدمة (تُستعمل أيضاً في تبويبات الرئيسية) ===== */
export const SERVICE_SLUG_ICONS: Record<string, LucideIcon> = {
  contracting: Building2,
  roads: Route,
  excavation: Shovel,
  telecom: RadioTower,
  shipping: Ship,
  supplies: Package,
  marketing: TrendingUp,
};

/* ===== فك أسماء الأيقونات القادمة من البيانات إلى مكونات lucide ===== */
const FEATURE_ICONS: Record<ServiceIconName, LucideIcon> = {
  Building2,
  Blocks,
  HardHat,
  PaintRoller,
  Landmark,
  Hammer,
  ClipboardCheck,
  Route,
  Truck,
  LayoutGrid,
  Milestone,
  Waves,
  Wrench,
  Mountain,
  Shovel,
  Layers,
  LandPlot,
  FlaskConical,
  RadioTower,
  Cable,
  Signal,
  Sun,
  Wifi,
  Bolt,
  Ship,
  FileCheck,
  FileText,
  Warehouse,
  Network,
  BrickWall,
  Tractor,
  Cog,
  Fuel,
  Package,
  TrendingUp,
  MapPinned,
  Building,
  DraftingCompass,
  Briefcase,
  Handshake,
};

/* ===== قاموس النصوص ثنائي اللغة ===== */
const LABELS = {
  ar: {
    breadcrumbLabel: "مسار التنقل",
    home: "الرئيسية",
    servicesNav: "خدماتنا",
    badge: "خدمة معتمدة واحترافية",
    quote: "طلب دراسة أو تسعير",
    print: "طباعة المواصفات (PDF)",
    printTitle: "طباعة المواصفات الفنية أو الحفظ كـ PDF",
    share: "مشاركة",
    shareTitle: "مشاركة تفاصيل الخدمة",
    shareCopied: "تم نسخ رابط الخدمة إلى الحافظة بنجاح",
    specsChip: "تنفيذ مطابق للمواصفات",
    overviewKicker: "نظرة عامة",
    overviewTitle: (s: string) => `الريادة في تقديم ${s}`,
    factsTitle: "بطاقة الخدمة السريعة",
    featuresKicker: "نطاق الأعمال",
    featuresTitle: "القدرات التنفيذية المتخصصة",
    processKicker: "منهجية العمل",
    processTitle: "رحلة تنفيذ مشروعك خطوة بخطوة",
    galleryKicker: "معرض الميدان",
    galleryTitle: "المعدات والتنفيذ الميداني",
    galleryCaption: (n: number) => `تنفيذ ميداني ${String(n).padStart(2, "0")}`,
    whyKicker: "لماذا الفضاء الواسع؟",
    whyTitle: (s: string) => `مزايا الشراكة والتعاقد معنا في ${s}`,
    faqKicker: "الأسئلة الشائعة",
    faqTitle: (s: string) => `استفسارات متكررة حول ${s}`,
    relatedKicker: "منظومة متكاملة",
    relatedTitle: "استكشف خدماتنا وقطاعاتنا الأخرى",
    allServices: "جميع الخدمات",
    ctaTitle: "جاهزون لتنفيذ مشروعك القادم",
    ctaDesc: "فريقنا المتخصص جاهز لدراسة متطلباتك وتقديم حل متكامل بمعايير تنفيذية رصينة — تواصل معنا الآن وسيصلك الرد خلال ساعات العمل.",
    ctaWhatsapp: "تواصل عبر واتساب",
    ariaPhone: "اتصال هاتفي مباشر",
  },
  en: {
    breadcrumbLabel: "Breadcrumb",
    home: "Home",
    servicesNav: "Services",
    badge: "Certified & Professional Service",
    quote: "Request a Study or Quotation",
    print: "Print Specs (PDF)",
    printTitle: "Print technical specifications or save as PDF",
    share: "Share",
    shareTitle: "Share service details",
    shareCopied: "Service link copied to clipboard successfully",
    specsChip: "Specification-Compliant Execution",
    overviewKicker: "Overview",
    overviewTitle: (s: string) => `Leading the Field in ${s}`,
    factsTitle: "Service Quick Facts",
    featuresKicker: "Scope of Work",
    featuresTitle: "Specialized Execution Capabilities",
    processKicker: "How We Work",
    processTitle: "Your Project Journey, Step by Step",
    galleryKicker: "Field Gallery",
    galleryTitle: "Equipment & On-Site Execution",
    galleryCaption: (n: number) => `Field photo ${String(n).padStart(2, "0")}`,
    whyKicker: "Why Al-Fada Al-Wasaa?",
    whyTitle: (s: string) => `Advantages of Partnering with Us in ${s}`,
    faqKicker: "Frequently Asked Questions",
    faqTitle: (s: string) => `Common Questions About ${s}`,
    relatedKicker: "One Integrated Ecosystem",
    relatedTitle: "Explore Our Other Services & Sectors",
    allServices: "All Services",
    ctaTitle: "Ready to Deliver Your Next Project",
    ctaDesc: "Our specialized team is ready to study your requirements and deliver an integrated solution to rigorous execution standards — reach out now and you will hear back within working hours.",
    ctaWhatsapp: "Contact via WhatsApp",
    ariaPhone: "Direct phone call",
  },
} as const;

export function ServiceDetailView({
  service,
  locale,
}: {
  service: ServiceDetail;
  locale: "ar" | "en";
}) {
  const t = LABELS[locale];
  const isAr = locale === "ar";
  const config = isAr ? SITE_CONFIG : EN_SITE_CONFIG;
  const Chevron = isAr ? ChevronLeft : ChevronRight;
  const Arrow = isAr ? ArrowLeft : ArrowRight;
  const basePath = isAr ? "/services" : "/en/services";
  const homeHref = isAr ? "/" : "/en";

  const otherServices = Object.values(
    isAr ? SERVICES_DATA : EN_SERVICES_DATA
  ).filter((s) => s.slug !== service.slug);

  const handleShare = () => {
    if (typeof navigator !== "undefined" && navigator.share) {
      navigator
        .share({
          title: `${service.title} | ${config.company.shortName}`,
          text: service.subtitle,
          url: window.location.href,
        })
        .catch(() => {});
    } else if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(window.location.href);
      toast.success(t.shareCopied);
    }
  };

  const FeatureIcon = (name: ServiceIconName) => FEATURE_ICONS[name] ?? Sparkles;
  const featureCols =
    service.features.length > 6
      ? "sm:grid-cols-2 lg:grid-cols-4"
      : "sm:grid-cols-2 lg:grid-cols-3";

  return (
    <div className="flex min-h-screen flex-col bg-white text-slate-900 transition-colors dark:bg-navy-darker dark:text-slate-100">
      <ReadingProgress />
      {isAr ? <SiteHeader /> : <EnHeader />}

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* ============ الهيرو ============ */}
        <section className="relative overflow-hidden bg-navy-darker py-14 text-white sm:py-20">
          {/* توهجات ذهبية ونمط نقطي */}
          <div className="dot-grid pointer-events-none absolute inset-0 opacity-15" aria-hidden />
          <div
            aria-hidden
            className="pointer-events-none absolute -top-32 end-[-10%] h-96 w-96 rounded-full bg-gold/15 blur-3xl"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute bottom-[-40%] start-[-8%] h-[28rem] w-[28rem] rounded-full bg-navy/80 blur-3xl"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-navy-darker to-transparent"
          />

          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {/* مسار التنقل */}
            <nav
              className="hero-fade-up mb-6 flex items-center gap-2 text-xs font-semibold text-white/70"
              aria-label={t.breadcrumbLabel}
            >
              <Link href={homeHref} className="transition hover:text-gold">
                {t.home}
              </Link>
              <Chevron className="h-3 w-3 text-gold" aria-hidden />
              <Link href={`${homeHref}#services`} className="transition hover:text-gold">
                {t.servicesNav}
              </Link>
              <Chevron className="h-3 w-3 text-gold" aria-hidden />
              <span className="font-bold text-gold-light">{service.shortTitle}</span>
            </nav>

            <div className="grid gap-10 lg:grid-cols-12 lg:items-center lg:gap-12">
              {/* عمود المعلومات */}
              <div className="lg:col-span-7">
                <span
                  className="hero-fade-up inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm"
                  style={{ ["--hero-delay" as string]: "0.05s" }}
                >
                    <ShieldCheck className="h-4 w-4 text-gold" aria-hidden />
                    {t.badge}
                </span>

                <h1
                  className="hero-fade-up mt-4 text-3xl font-black leading-[1.25] text-white sm:text-4xl lg:text-[2.9rem]"
                  style={{ ["--hero-delay" as string]: "0.12s" }}
                >
                  {service.title}
                </h1>

                <p
                  className="hero-fade-up mt-4 max-w-2xl text-base leading-8 text-white/80 sm:text-lg sm:leading-9"
                  style={{ ["--hero-delay" as string]: "0.2s" }}
                >
                  {service.subtitle}
                </p>

                {/* أزرار الإجراءات المباشرة */}
                <div
                  className="hero-fade-up mt-7 flex flex-wrap items-center gap-3"
                  style={{ ["--hero-delay" as string]: "0.28s" }}
                >
                  <a
                    href={config.contacts.general.waHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-full bg-gold px-6 py-3 text-xs font-black text-navy-darker shadow-lg shadow-gold/25 transition-all duration-300 hover:scale-105 hover:bg-gold-light active:scale-95 sm:text-sm print:hidden"
                  >
                    <MessageSquare className="h-4 w-4" aria-hidden />
                    <span>{t.quote}</span>
                  </a>

                  <a
                    href={config.contacts.general.telHref}
                    aria-label={t.ariaPhone}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-xs font-bold text-white backdrop-blur-sm transition-all duration-300 hover:bg-white/20 hover:text-gold-light sm:text-sm print:hidden"
                  >
                    <PhoneCall className="h-4 w-4 text-gold-light" aria-hidden />
                    <span dir="ltr">{config.contacts.general.display}</span>
                  </a>

                  <button
                    type="button"
                    onClick={() => window.print()}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-3 text-xs font-bold text-white backdrop-blur-sm transition-all duration-300 hover:bg-white/20 hover:text-gold-light sm:text-sm print:hidden"
                    title={t.printTitle}
                  >
                    <Printer className="h-4 w-4 text-gold-light" aria-hidden />
                    <span>{t.print}</span>
                  </button>

                  <button
                    type="button"
                    onClick={handleShare}
                    className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-3 text-xs font-bold text-white backdrop-blur-sm transition-all duration-300 hover:bg-white/20 hover:text-gold-light sm:text-sm print:hidden"
                    title={t.shareTitle}
                  >
                    <Share2 className="h-4 w-4 text-gold-light" aria-hidden />
                    <span>{t.share}</span>
                  </button>
                </div>
              </div>

              {/* الصورة المميزة */}
              <div className="hero-fade-up lg:col-span-5" style={{ ["--hero-delay" as string]: "0.2s" }}>
                <div className="relative">
                  {/* إطار ذهبي مزخرف خلفي */}
                  <div
                    aria-hidden
                    className="absolute -inset-2 rounded-[2rem] border border-gold/25"
                  />
                  <div className="group relative aspect-[4/3] overflow-hidden rounded-[1.75rem] border-2 border-gold/40 bg-navy shadow-2xl shadow-black/40">
                    <Image
                      src={service.image}
                      alt={service.title}
                      fill
                      sizes="(max-width: 1024px) 100vw, 460px"
                      className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.04]"
                      priority
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/70 via-transparent to-navy-darker/10" />
                    {/* شريحة تعريفية عائمة */}
                    <div className="absolute inset-x-3 bottom-3 flex items-center gap-2 rounded-xl border border-white/10 bg-navy-darker/80 px-3 py-2 backdrop-blur-md">
                      <BadgeCheck className="h-4 w-4 shrink-0 text-gold-light" aria-hidden />
                      <span className="text-[11px] font-bold text-white/90 sm:text-xs">
                        {t.specsChip}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* شريط المؤشرات السريعة */}
            <div
              className="hero-fade-up mt-10 grid grid-cols-2 gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/10 backdrop-blur-sm lg:grid-cols-4"
              style={{ ["--hero-delay" as string]: "0.36s" }}
            >
              {service.highlights.map((item, idx) => (
                <div key={idx} className="bg-navy-darker/70 px-4 py-3.5 text-center sm:px-5">
                  <span className="block text-lg font-black text-gold-light sm:text-xl">
                    {item.value}
                  </span>
                  <span className="mt-0.5 block text-[11px] font-semibold leading-4 text-white/70">
                    {item.label}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ============ نظرة عامة + بطاقة الحقائق ============ */}
        <section className="py-16 transition-colors sm:py-20">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-10 lg:grid-cols-12 lg:gap-12">
              <div className="lg:col-span-7">
                <SectionHeading kicker={t.overviewKicker} title={t.overviewTitle(service.shortTitle)} />
                <div className="space-y-4 text-base leading-8 text-slate-700 dark:text-slate-300">
                  {service.overview.map((para, i) => (
                    <p key={i}>{para}</p>
                  ))}
                </div>
              </div>

              {/* بطاقة الحقائق السريعة */}
              <Reveal delay={0.1} className="lg:col-span-5">
                <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-6 text-white shadow-xl sm:p-7 dark:shadow-black/30">
                  <div
                    aria-hidden
                    className="pointer-events-none absolute -end-16 -top-16 h-48 w-48 rounded-full bg-gold/15 blur-3xl"
                  />
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-white/10 ring-1 ring-gold/40">
                      <Sparkles className="h-4 w-4 text-gold-light" aria-hidden />
                    </span>
                    <h3 className="text-base font-black text-white">{t.factsTitle}</h3>
                  </div>
                  <dl className="mt-5 space-y-0 divide-y divide-white/10">
                    {service.facts.map((fact, idx) => (
                      <div key={idx} className="flex items-start justify-between gap-4 py-3">
                        <dt className="shrink-0 text-xs font-extrabold text-gold-light">
                          {fact.label}
                        </dt>
                        <dd className="text-end text-[13px] font-semibold leading-6 text-white/90">
                          {fact.value}
                        </dd>
                      </div>
                    ))}
                  </dl>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        {/* ============ نطاق الأعمال ============ */}
        <section className="border-y border-slate-200/80 bg-mist py-16 transition-colors sm:py-20 dark:border-white/10 dark:bg-navy">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <SectionHeading center kicker={t.featuresKicker} title={t.featuresTitle} />
            <div className={cn("grid gap-5", featureCols)}>
              {service.features.map((feat, idx) => {
                const Icon = FeatureIcon(feat.icon);
                return (
                  <Reveal key={idx} index={idx}>
                    <div className="shimmer-card group h-full rounded-2xl border border-slate-200/90 bg-white p-6 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-gold/60 hover:shadow-md dark:border-white/10 dark:bg-navy-deep dark:hover:border-gold/50 dark:hover:bg-navy-deep/80">
                      <span className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-gold-soft text-navy transition-colors duration-300 group-hover:bg-gold group-hover:text-navy-darker dark:bg-gold/15 dark:text-gold-light dark:group-hover:bg-gold dark:group-hover:text-navy-darker">
                        <Icon className="h-5 w-5" strokeWidth={1.9} aria-hidden />
                      </span>
                      <h3 className="text-base font-extrabold text-navy dark:text-white">
                        {feat.title}
                      </h3>
                      <p className="mt-2 text-[13px] leading-6 text-slate-600 dark:text-slate-400">
                        {feat.desc}
                      </p>
                    </div>
                  </Reveal>
                );
              })}
            </div>
          </div>
        </section>

        {/* ============ منهجية العمل ============ */}
        <section className="py-16 transition-colors sm:py-20">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <SectionHeading center kicker={t.processKicker} title={t.processTitle} />

            <div className="relative">
              {/* الخط الرابط (سطح المكتب) */}
              <div
                aria-hidden
                className="absolute inset-x-16 top-7 hidden h-0.5 bg-gradient-to-r from-gold/10 via-gold/45 to-gold/10 lg:block"
              />
              <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-5 lg:gap-5">
                {service.process.map((step, idx) => (
                  <Reveal key={idx} index={idx}>
                    <div className="relative flex h-full flex-col items-center text-center">
                      <span className="relative z-10 flex h-14 w-14 items-center justify-center rounded-2xl bg-navy font-mono text-base font-black text-gold-light shadow-md ring-4 ring-white dark:bg-gold dark:text-navy-darker dark:ring-navy-darker">
                        {String(idx + 1).padStart(2, "0")}
                      </span>
                      <h3 className="mt-4 text-sm font-black text-navy dark:text-white">
                        {step.title}
                      </h3>
                      <p className="mt-2 text-xs leading-6 text-slate-600 dark:text-slate-400">
                        {step.desc}
                      </p>
                    </div>
                  </Reveal>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* ============ معرض الميدان ============ */}
        <section className="relative overflow-hidden bg-navy-darker py-16 text-white sm:py-20">
          <div className="dot-grid pointer-events-none absolute inset-0 opacity-10" aria-hidden />
          <div
            aria-hidden
            className="pointer-events-none absolute -top-24 start-1/3 h-72 w-72 rounded-full bg-gold/10 blur-3xl"
          />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <SectionHeading light center kicker={t.galleryKicker} title={t.galleryTitle} />
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {service.galleryImages.map((img, idx) => (
                <Reveal key={idx} index={idx}>
                  <div className="group relative aspect-[4/3] overflow-hidden rounded-2xl border border-white/15 bg-navy shadow-lg transition-colors duration-300 hover:border-gold/60">
                    <Image
                      src={img}
                      alt={`${service.title} — ${t.galleryCaption(idx + 1)}`}
                      fill
                      sizes="(max-width: 640px) 100vw, (max-width: 960px) 50vw, 33vw"
                      className="object-cover transition-transform duration-500 ease-out group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 via-transparent to-transparent" />
                    <div className="absolute bottom-3 start-3 flex items-center gap-1.5 rounded-lg border border-white/10 bg-navy-darker/80 px-2.5 py-1.5 backdrop-blur-md">
                      <BadgeCheck className="h-3.5 w-3.5 text-gold-light" aria-hidden />
                      <span className="text-[10px] font-bold text-white/90 sm:text-[11px]">
                        {t.galleryCaption(idx + 1)}
                      </span>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ============ مزايا الشراكة ============ */}
        <section className="py-16 transition-colors sm:py-20">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <Reveal>
              <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-7 text-white shadow-xl sm:p-10 lg:p-12">
                <div
                  aria-hidden
                  className="pointer-events-none absolute -end-20 -bottom-20 h-72 w-72 rounded-full bg-gold/12 blur-3xl"
                />
                <div className="dot-grid pointer-events-none absolute inset-0 opacity-10" aria-hidden />
                <div className="relative">
                  <div className="max-w-2xl">
                    <span className="inline-block rounded-full bg-gold/15 px-4 py-1.5 text-xs font-black tracking-wide text-gold-light ring-1 ring-gold/30">
                      {t.whyKicker}
                    </span>
                    <h2 className="mt-3 text-2xl font-black leading-snug text-white sm:text-3xl">
                      {t.whyTitle(service.shortTitle)}
                    </h2>
                  </div>

                  <div className="mt-8 grid gap-3.5 sm:grid-cols-2">
                    {service.advantages.map((adv, idx) => (
                      <div
                        key={idx}
                        className="flex items-start gap-3 rounded-xl border border-white/10 bg-white/5 p-4 transition-colors duration-300 hover:border-gold/40 hover:bg-white/10"
                      >
                        <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-gold-light" aria-hidden />
                        <span className="text-sm leading-7 text-white/90">{adv}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        {/* ============ الأسئلة الشائعة (Accordion بلا JS) ============ */}
        <section className="border-y border-slate-200/80 bg-mist py-16 transition-colors sm:py-20 dark:border-white/10 dark:bg-navy">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <SectionHeading center kicker={t.faqKicker} title={t.faqTitle(service.shortTitle)} />
            <div className="space-y-3.5">
              {service.faqs.map((faq, idx) => (
                <Reveal key={idx} index={idx}>
                  <details
                    open={idx === 0}
                    name="service-faq"
                    className="group rounded-2xl border border-slate-200 bg-white shadow-sm transition-colors open:border-gold/60 dark:border-white/10 dark:bg-navy-deep dark:open:border-gold/40"
                  >
                    <summary className="flex cursor-pointer list-none items-center gap-3 p-5 [&::-webkit-details-marker]:hidden">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gold-soft text-navy dark:bg-gold/15 dark:text-gold-light">
                        <Plus className="h-4 w-4 transition-transform duration-300 group-open:rotate-45" aria-hidden />
                      </span>
                      <h3 className="text-sm font-black leading-7 text-navy transition-colors group-hover:text-gold-dark dark:text-white dark:group-hover:text-gold-light sm:text-base">
                        {faq.q}
                      </h3>
                    </summary>
                    <div className="border-t border-slate-100 px-5 pb-5 pt-4 dark:border-white/10">
                      <p className="ps-11 text-sm leading-8 text-slate-600 dark:text-slate-400">
                        {faq.a}
                      </p>
                    </div>
                  </details>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* ============ خدمات مرتبطة ============ */}
        <section className="py-16 transition-colors sm:py-20">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
              <div>
                <span className="text-xs font-bold text-gold">{t.relatedKicker}</span>
                <h2 className="mt-1 text-2xl font-black text-navy dark:text-white sm:text-3xl">
                  {t.relatedTitle}
                </h2>
              </div>
              <Link
                href={`${homeHref}#services`}
                className="inline-flex w-fit items-center gap-1.5 text-xs font-bold text-navy transition hover:text-gold dark:text-gold-light dark:hover:text-gold"
              >
                <span>{t.allServices}</span>
                <Arrow className="h-4 w-4" aria-hidden />
              </Link>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {otherServices.map((other, idx) => {
                const OtherIcon = SERVICE_SLUG_ICONS[other.slug] ?? Building2;
                return (
                  <Reveal key={other.slug} index={idx}>
                    <Link
                      href={`${basePath}/${other.slug}`}
                      className="group flex h-full items-center justify-between gap-3 rounded-2xl border border-slate-200 bg-white p-4 transition-all duration-300 hover:-translate-y-0.5 hover:border-gold hover:shadow-sm dark:border-white/10 dark:bg-navy-deep dark:hover:border-gold/60"
                    >
                      <div className="flex items-center gap-3">
                        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-mist text-gold transition-colors duration-300 group-hover:bg-gold group-hover:text-navy-darker dark:bg-navy dark:text-gold-light dark:group-hover:bg-gold dark:group-hover:text-navy-darker">
                          <OtherIcon className="h-5 w-5" strokeWidth={1.9} aria-hidden />
                        </span>
                        <div>
                          <span className="block text-sm font-extrabold text-navy transition-colors group-hover:text-gold-dark dark:text-white dark:group-hover:text-gold-light">
                            {other.title}
                          </span>
                          <span className="line-clamp-1 text-xs text-slate-500 dark:text-slate-400">
                            {other.subtitle}
                          </span>
                        </div>
                      </div>
                      <Chevron className="h-4 w-4 shrink-0 text-slate-400 transition-colors group-hover:text-gold" aria-hidden />
                    </Link>
                  </Reveal>
                );
              })}
            </div>
          </div>
        </section>

        {/* ============ دعوة ختامية للتواصل ============ */}
        <section className="pb-16 sm:pb-20">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <Reveal>
              <div className="relative overflow-hidden rounded-3xl border border-gold/30 bg-gradient-to-br from-navy via-navy-deep to-navy-darker p-8 text-center text-white shadow-xl sm:p-12">
                <div
                  aria-hidden
                  className="pointer-events-none absolute -top-24 start-1/2 h-56 w-56 -translate-x-1/2 rounded-full bg-gold/20 blur-3xl rtl:translate-x-1/2"
                />
                <div className="dot-grid pointer-events-none absolute inset-0 opacity-10" aria-hidden />
                <div className="relative mx-auto max-w-2xl">
                  <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-gold text-navy-darker shadow-lg shadow-gold/30">
                    <PhoneCall className="h-5 w-5" aria-hidden />
                  </span>
                  <h2 className="mt-5 text-2xl font-black text-white sm:text-3xl">
                    {t.ctaTitle}
                  </h2>
                  <p className="mt-3 text-sm leading-8 text-white/80 sm:text-base">
                    {t.ctaDesc}
                  </p>
                  <div className="mt-7 flex flex-wrap items-center justify-center gap-3">
                    <a
                      href={config.contacts.general.waHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 rounded-full bg-gold px-6 py-3 text-xs font-black text-navy-darker shadow-lg shadow-gold/25 transition-all duration-300 hover:scale-105 hover:bg-gold-light active:scale-95 sm:text-sm print:hidden"
                    >
                      <MessageSquare className="h-4 w-4" aria-hidden />
                      <span>{t.ctaWhatsapp}</span>
                    </a>
                    <a
                      href={config.contacts.general.telHref}
                      aria-label={t.ariaPhone}
                      className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-5 py-3 text-xs font-bold text-white backdrop-blur-sm transition-all duration-300 hover:bg-white/20 hover:text-gold-light sm:text-sm print:hidden"
                    >
                      <PhoneCall className="h-4 w-4 text-gold-light" aria-hidden />
                      <span dir="ltr">{config.contacts.general.display}</span>
                    </a>
                  </div>
                  <p className="mt-5 text-[11px] font-semibold text-white/60">
                    {config.contacts.workingHours}
                  </p>
                </div>
              </div>
            </Reveal>
          </div>
        </section>
      </main>

      {isAr ? <SiteFooter /> : <EnFooter />}
      {isAr ? <FloatingContact /> : <EnFloatingContact />}
    </div>
  );
}
