"use client";

/**
 * قطاعات الأعمال في الرئيسية — قائمة بطاقات أفقية (Service List Cards)
 * كل قطاع بطاقة أفقية كبيرة: صورتان متناوبان + محتوى هرمي + أزرار.
 * البيانات من الـCMS (تمرير خام من page.tsx) مع سقوط آمن للبيانات الافتراضية.
 */

import { useMemo } from "react";
import {
  Building2,
  Flame,
  RadioTower,
  TrendingUp,
  Truck,
  type LucideIcon,
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import {
  ServiceListSection,
  type ServiceListItem,
} from "./service-list-card";
import { SITE_CONFIG } from "@/config/site";

export type Sector = {
  num: string;
  title: string;
  href: string;
  Icon: LucideIcon;
  services: string[];
  photos: { src: string; alt: string }[];
  accentColor?: string;
};


export interface SectorCmsItem {
  titleAr: string; titleEn: string; descAr?: string; descEn?: string;
  icon?: string; services?: string[]; photos?: { src: string; alt?: string }[]; order?: number;
}

const ICON_MAP: Record<string, LucideIcon> = {
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

/** صور افتراضية مميزة لكل قطاع — تُستخدم حين يأتي قطاع الـCMS بلا صور خاصة
 *  (مطابقة بالعنوان، ثم مسبح مرتَّب بالفهرس لمنع تكرار الصور بين القطاعات) */
const SECTOR_PHOTOS: Record<string, { src: string; alt: string }[]> = {
  "الاتصالات والإنترنت": [
    { src: "/profile/site_telecom_tower.webp", alt: "أبراج اتصالات وشبكات المايكروويف الميدانية" },
    { src: "/profile/site_solar_array.webp", alt: "منظومة الطاقة الشمسية لتشغيل محطات الاتصالات" },
  ],
  "الاتصالات وتقنية المعلومات": [
    { src: "/profile/site_telecom_tower.webp", alt: "أبراج اتصالات وشبكات المايكروويف الميدانية" },
    { src: "/profile/site_solar_array.webp", alt: "منظومة الطاقة الشمسية لتشغيل محطات الاتصالات" },
  ],
  "المقاولات العامة": [
    { src: "/profile/site_mountain_station.webp", alt: "أعمال إنشاء المحطات والأبراج في المواقع الجبلية" },
    { src: "/profile/road_roller.webp", alt: "أعمال مدح وتسوية الطرق" },
  ],
  "التوريدات العامة والتجهيزات": [
    { src: "/profile/track_forklift.webp", alt: "تجهيزات وتموينات ميدانية بالرافعات الشوكية" },
    { src: "/profile/track_truck.webp", alt: "شاحنات نقل المعدات والتوريدات" },
  ],
  "الخدمات اللوجستية": [
    { src: "/profile/port_ship.webp", alt: "شحن بحري في الموانئ" },
    { src: "/profile/container_truck.webp", alt: "نقل الحاويات برًا" },
  ],
  "التسويق العقاري والفرص الاستثمارية": [
    { src: "/profile/site_hadramout_building.webp", alt: "مشاريع عقارية سكنية مطورة" },
    { src: "/profile/construction_building.webp", alt: "مواقع تطوير عقاري" },
  ],
};

const SECTOR_PHOTOS_ORDERED = [
  SECTOR_PHOTOS["الاتصالات وتقنية المعلومات"],
  SECTOR_PHOTOS["المقاولات العامة"],
  SECTOR_PHOTOS["التوريدات العامة والتجهيزات"],
  SECTOR_PHOTOS["الخدمات اللوجستية"],
  SECTOR_PHOTOS["التسويق العقاري والفرص الاستثمارية"],
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
        : SECTOR_PHOTOS[s.titleAr] ??
          SECTOR_PHOTOS_ORDERED[i % SECTOR_PHOTOS_ORDERED.length],
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
  // الخادم يمرر بيانات الـCMS الخام، والتحويل يتم هنا داخل العميل (مسموح عبر الحد)
  // مع درع يضمن السقوط للبيانات الافتراضية عند أي شكل غير متوقع من الـCMS
  const sectors = useMemo(() => {
    try {
      return items && items.length > 0 ? mapCmsToSectors(items) : SECTORS;
    } catch {
      return SECTORS;
    }
  }, [items]);

  const listItems: ServiceListItem[] = sectors.map((sec) => ({
    number: sec.num,
    slug: sec.href,
    category: "قطاع أعمال استراتيجي",
    icon: sec.Icon,
    title: sec.title,
    description: sec.services[0] ?? "",
    images: sec.photos.slice(0, 2).map((ph) => ({
      src: ph.src,
      alt: ph.alt || sec.title,
    })),
    primaryAction: { label: "استكشاف القطاع", href: sec.href },
    secondaryAction: {
      label: "تواصل عبر واتساب",
      href: SITE_CONFIG.contacts.general.waHref,
    },
  }));

  return (
    <section
      id="sectors"
      className="relative overflow-hidden bg-mist py-12 transition-colors duration-300 dark:bg-navy-darker/60 sm:py-16"
    >
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          center
          kicker="قطاعات الأعمال"
          title="قطاعات استراتيجية تديرها كفاءات متخصصة"
        />
        <Reveal delay={0.1}>
          <p className="mx-auto -mt-6 max-w-3xl text-center text-base leading-8 text-slate-600 dark:text-slate-300 sm:text-lg">
            نعمل في قطاعات استراتيجية متعددة من خلال خبرتنا الميدانية وكوادرنا الهندسية
            المتخصصة، بما يختصر دورة الإنجاز، ويرفع كفاءة التنفيذ، ويعزز موثوقية النتائج
            النهائية للمشاريع الحيوية.
          </p>
        </Reveal>

        <div className="mt-10">
          <ServiceListSection services={listItems} />
        </div>
      </div>
    </section>
  );
}
