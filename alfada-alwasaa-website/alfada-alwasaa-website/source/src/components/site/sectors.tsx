"use client";

import { useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { 
  RadioTower, 
  Building2, 
  Flame, 
  Truck, 
  TrendingUp, 
  CheckCircle2, 
  ArrowLeft
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";

export type Sector = {
  num: string;
  title: string;
  href: string;
  Icon: React.ElementType;
  services: string[];
  photos: { src: string; alt: string }[];
  accentColor?: string;
};


export interface SectorCmsItem {
  titleAr: string; titleEn: string; descAr?: string; descEn?: string;
  icon?: string; services?: string[]; photos?: { src: string; alt?: string }[]; order?: number;
}

const ICON_MAP: Record<string, React.ElementType> = {
  Antenna: RadioTower,
  Building2: Building2,
  Blocks: Flame,
  Ship: Truck,
  TrendingUp: TrendingUp,
};

const SECTOR_HREF: Record<string, string> = {
  "الاتصالات والإنترنت": "/services/telecom",
  "الاتصالات وتقنية المعلومات": "/services/telecom",
  "المقاولات العامة": "/services/contracting",
  "التوريدات العامة والتجهيزات": "/services/supplies",
  "الخدمات اللوجستية": "/services/shipping",
  "التسويق العقاري والفرص الاستثمارية": "/services/marketing",
};

const DEFAULT_PHOTOS = [
  { src: "/profile/site_telecom_tower.webp", alt: "عمليات ميدانية" },
  { src: "/profile/road_roller.webp", alt: "أعمال مواقع" },
];

/** تحويل قطاعات الـ CMS إلى صيغة العرض — الأيقونة والرابط والصور ببدائل آمنة */
export function mapCmsToSectors(items: SectorCmsItem[]): Sector[] {
  return items.map((s, i) => ({
    num: String(s.order ?? i + 1).padStart(2, "0"),
    title: s.titleAr,
    href: SECTOR_HREF[s.titleAr] ?? "/services",
    Icon: (s.icon && ICON_MAP[s.icon]) || Building2,
    services: s.services ?? (s.descAr ? [s.descAr] : []),
    photos:
      s.photos && s.photos.length > 0
        ? s.photos.map((ph) => ({ src: ph.src, alt: ph.alt ?? s.titleAr }))
        : DEFAULT_PHOTOS,
  }));
}

const SECTORS: Sector[] = [
  {
    num: "01",
    title: "الاتصالات والإنترنت",
    href: "/services/telecom",
    Icon: RadioTower,
    services: [
      "تقديم حلول داعمة للاتصال والتواصل التقني وفق متطلبات الأعمال الحديثة.",
    ],
    photos: [
      { src: "/profile/site_telecom_tower.webp", alt: "أبراج اتصالات وشبكات المايكروويف الميدانية" },
      { src: "/profile/site_solar_array.webp", alt: "منظومة الطاقة الشمسية لتشغيل محطات الاتصالات" },
    ],
  },
  {
    num: "02",
    title: "المقاولات العامة",
    href: "/services/contracting",
    Icon: Building2,
    services: [
      "إنشاء وصيانة الطرق والجسور.",
      "أعمال الحفريات وتسوية المواقع.",
      "التوريدات والتموينات الإنشائية.",
    ],
    photos: [
      { src: "/profile/site_mountain_station.webp", alt: "أعمال إنشاء المحطات والأبراج في المواقع الجبلية" },
      { src: "/profile/road_roller.webp", alt: "أعمال مدح وتسوية الطرق" },
    ],
  },
  {
    num: "03",
    title: "التوريدات العامة والتجهيزات",
    href: "/services/supplies",
    Icon: Flame,
    services: [
      "استيراد وتوريد المواد الإنشائية والكابلات.",
      "المعدات الثقيلة وقطع الغيار الأصلية والتموينات الميدانية.",
    ],
    photos: [
      { src: "/profile/track_forklift.webp", alt: "تجهيزات وتموينات ميدانية بالرافعات الشوكية" },
      { src: "/profile/track_truck.webp", alt: "شاحنات نقل المعدات والتوريدات" },
    ],
  },
  {
    num: "04",
    title: "الخدمات اللوجستية",
    href: "/services/shipping",
    Icon: Truck,
    services: [
      "الشحن والتفريغ متعدد الوسائط.",
      "التخليص الجمركي وإدارة سلاسل الإمداد.",
    ],
    photos: [
      { src: "/profile/port_ship.webp", alt: "شحن بحري في الموانئ" },
      { src: "/profile/container_truck.webp", alt: "نقل الحاويات برًا" },
    ],
  },
  {
    num: "05",
    title: "التسويق العقاري والفرص الاستثمارية",
    href: "/services/marketing",
    Icon: TrendingUp,
    services: [
      "دراسات الجدوى وتسويق الأراضي والمجمعات.",
      "التطوير العقاري وإدارة الأصول والاستشارات الاستثمارية.",
    ],
    photos: [
      { src: "/profile/site_hadramout_building.webp", alt: "مشاريع عقارية سكنية مطورة" },
      { src: "/profile/construction_building.webp", alt: "مواقع تطوير عقاري" },
    ],
  },
];

export function Sectors({ items }: { items?: SectorCmsItem[] }) {
  const [activeFilter, setActiveFilter] = useState("all");

  // الخادم يمرر بيانات الـCMS الخام، والتحويل يتم هنا داخل العميل (مسموح عبر الحد)
  // مع درع يضمن السقوط للبيانات الافتراضية عند أي شكل غير متوقع من الـCMS
  const sectors = useMemo(() => {
    try {
      return items && items.length > 0 ? mapCmsToSectors(items) : SECTORS;
    } catch {
      return SECTORS;
    }
  }, [items]);
  const filteredSectors = activeFilter === "all"
    ? sectors
    : sectors.filter(s => s.num === activeFilter);

  return (
    <section id="sectors" className="relative overflow-hidden bg-mist dark:bg-navy-darker/60 py-12 sm:py-16 transition-colors duration-300">
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto">
          <SectionHeading center kicker="قطاعات الأعمال" title="قطاعات استراتيجية تديرها كفاءات متخصصة" />
          <Reveal delay={0.1}>
            <p className="-mt-6 text-base sm:text-lg leading-8 text-slate-600 dark:text-slate-300">
              نعمل في قطاعات استراتيجية متعددة من خلال خبرتنا الميدانية وكوادرنا الهندسية المتخصصة، بما يختصر دورة الإنجاز، ويرفع كفاءة التنفيذ، ويعزز موثوقية النتائج النهائية للمشاريع الحيوية.
            </p>
          </Reveal>
        </div>

        {/* Category switcher pills */}
        <Reveal delay={0.15}>
          <div className="mt-10 overflow-x-auto scrollbar-none -mx-4 px-4 sm:mx-0 sm:px-0">
            <div className="mx-auto flex w-fit max-w-full items-center gap-2 sm:gap-2.5">
            <button
              type="button"
              onClick={() => setActiveFilter("all")}
              aria-pressed={activeFilter === "all"}
              className={`shrink-0 whitespace-nowrap rounded-full px-4 py-2 text-xs font-bold transition-all duration-300 ${
                activeFilter === "all"
                  ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                  : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
              }`}
            >
              جميع القطاعات ({sectors.length})
            </button>
            {sectors.map((s) => (
              <button
                key={s.num}
                type="button"
                onClick={() => setActiveFilter(s.num)}
                aria-pressed={activeFilter === s.num}
                className={`flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-3.5 py-2 text-xs font-bold transition-all duration-300 ${
                  activeFilter === s.num
                    ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                    : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy dark:bg-navy dark:text-white/80 dark:hover:bg-navy-deep dark:hover:text-white dark:ring-1 dark:ring-white/10"
                }`}
              >
                <s.Icon className="h-4 w-4 text-gold" />
                <span>{s.title}</span>
              </button>
            ))}
            </div>
          </div>
        </Reveal>

        {/* Modern Showcase Cards - Spacious horizontal layout matching English standard */}
        <div className="mt-8 sm:mt-10 space-y-8 sm:space-y-10">
          {filteredSectors.map((sector, idx) => (
            <Reveal key={sector.num} index={idx}>
              <div className="group/card relative overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 lg:p-10 shadow-md hover:shadow-xl hover:border-gold/40 transition-all duration-300">
                  <span aria-hidden className="pointer-events-none absolute -top-5 end-4 select-none font-mono text-[5.5rem] font-black leading-none text-navy/[0.04] dark:text-white/[0.04]">{sector.num}</span>
                <div className="relative z-10 grid gap-8 lg:grid-cols-12 items-center">
                  {/* Content Column (6 cols) */}
                  <div className="lg:col-span-7 space-y-5">
                    <div className="flex items-center gap-3">
                      <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gold/15 dark:bg-gold/20 text-navy dark:text-gold-light border border-gold/30 shadow-xs">
                        <sector.Icon className="h-5 w-5 text-gold" />
                      </span>
                      <span className="inline-block rounded-full bg-gold/10 px-3.5 py-1 text-xs font-black text-navy dark:text-gold-light border border-gold/30 font-mono">
                        القطاع {sector.num}
                      </span>
                    </div>

                    <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white leading-tight">
                      {sector.title}
                    </h3>

                    <div className="pt-1">
                      <span className="text-xs font-bold uppercase tracking-wider text-gold">
                        نطاق الخدمات والحلول:
                      </span>
                      <ul className="mt-3 space-y-2.5">
                        {sector.services.map((service, sIdx) => (
                          <li
                            key={sIdx}
                            className="flex items-start gap-2.5 text-sm sm:text-base leading-relaxed text-slate-700 dark:text-slate-200"
                          >
                            <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                            <span>{service}</span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    <div className="pt-3 flex flex-wrap items-center gap-3">
                      <Link
                        href={sector.href}
                        className="inline-flex items-center gap-2 rounded-xl bg-gold px-5 py-2.5 text-xs sm:text-sm font-black text-navy-darker hover:bg-gold-light transition-all shadow-sm hover:scale-[1.02] active:scale-98"
                      >
                        <span>استعراض خدمات القطاع</span>
                        <ArrowLeft className="h-4 w-4" />
                      </Link>
                      <a
                        href="#contact"
                        className="inline-flex items-center gap-2 rounded-xl border border-gold/40 px-4 py-2.5 text-xs sm:text-sm font-bold text-navy dark:text-gold-light hover:bg-gold hover:text-navy-darker hover:border-gold transition-colors"
                      >
                        <span>طلب دراسة أو تسعير</span>
                      </a>
                    </div>
                  </div>

                  {/* Media / Photos Column (6 cols) */}
                  <div className="lg:col-span-5">
                    <div className="grid grid-cols-2 items-start gap-3 sm:gap-4 lg:gap-5">
                      {sector.photos.map((ph, pIdx) => (
                        <div
                          key={pIdx}
                          className={`group/photo relative aspect-[4/3] overflow-hidden rounded-2xl bg-navy-darker shadow-sm ring-1 ring-navy/10 dark:ring-white/10 ${pIdx === 1 ? "lg:mt-10" : ""}`}
                        >
                          <Image
                            src={ph.src}
                            alt={ph.alt}
                            fill
                            loading="lazy"
                            decoding="async"
                            sizes="(max-width: 1024px) 50vw, 20vw"
                            className="object-cover transition-transform duration-500 group-hover/photo:scale-105"
                          />
                          <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/70 via-transparent to-transparent opacity-0 transition-opacity duration-300 group-hover/photo:opacity-100" />
                          <span className="absolute bottom-2.5 start-2.5 end-2.5 text-[11px] font-bold text-white opacity-0 transition-opacity duration-300 group-hover/photo:opacity-100 line-clamp-1 drop-shadow-md">
                            {ph.alt}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

