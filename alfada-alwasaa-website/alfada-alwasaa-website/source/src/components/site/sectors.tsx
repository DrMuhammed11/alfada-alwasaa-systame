"use client";

import { useState } from "react";
import Image from "next/image";
import { 
  RadioTower, 
  Building2, 
  Flame, 
  Truck, 
  TrendingUp, 
  CheckCircle2, 
  ArrowLeft,
  Layers
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";

type Sector = {
  num: string;
  title: string;
  Icon: React.ElementType;
  services: string[];
  photos: { src: string; alt: string }[];
  accentColor?: string;
};

const SECTORS: Sector[] = [
  {
    num: "01",
    title: "الاتصالات والإنترنت",
    Icon: RadioTower,
    services: [
      "تقديم حلول داعمة للاتصال والتواصل التقني وفق متطلبات الأعمال الحديثة.",
    ],
    photos: [
      { src: "/profile/telecom_tower_sky.jpeg", alt: "أبراج اتصالات للمشروعات الميدانية" },
      { src: "/profile/telecom_antenna_city.jpeg", alt: "هوائيات اتصالات فوق إحدى المدن" },
    ],
  },
  {
    num: "02",
    title: "المقاولات العامة",
    Icon: Building2,
    services: [
      "إنشاء وصيانة الطرق والجسور.",
      "أعمال الحفريات وتسوية المواقع.",
      "التوريدات والتموينات الإنشائية.",
    ],
    photos: [
      { src: "/profile/construction_building.jpeg", alt: "أعمال إنشاءات ومقاولات عامة" },
      { src: "/profile/road_roller.jpeg", alt: "أعمال مدح وتسوية الطرق" },
    ],
  },
  {
    num: "03",
    title: "خدمات النفط",
    Icon: Flame,
    services: [
      "التوريدات النفطية المعتمدة.",
      "التموينات والمساندة التشغيلية.",
    ],
    photos: [
      { src: "/profile/oil_tanks_truck.jpeg", alt: "صهاريج توريدات نفطية" },
      { src: "/profile/oil_valve_flare.jpeg", alt: "محطات وتموينات نفطية" },
    ],
  },
  {
    num: "04",
    title: "الخدمات اللوجستية",
    Icon: Truck,
    services: [
      "الشحن والتفريغ متعدد الوسائط.",
      "التخليص الجمركي وإدارة سلاسل الإمداد.",
    ],
    photos: [
      { src: "/profile/port_ship.jpeg", alt: "شحن بحري في الموانئ" },
      { src: "/profile/container_truck.jpeg", alt: "نقل الحاويات برًا" },
    ],
  },
  {
    num: "05",
    title: "خدمات التسويق",
    Icon: TrendingUp,
    services: [
      "التسويق الإلكتروني وبناء الحضور الرقمي.",
      "الاستشارات التسويقية والترويج المتخصص.",
    ],
    photos: [
      { src: "/profile/marketing_laptop.jpeg", alt: "تحليلات الحملات التسويقية" },
      { src: "/profile/social_media.jpeg", alt: "منصات التواصل الاجتماعي" },
    ],
  },
];

export function Sectors() {
  const [activeFilter, setActiveFilter] = useState("all");

  const filteredSectors = activeFilter === "all" 
    ? SECTORS 
    : SECTORS.filter(s => s.num === activeFilter);

  return (
    <section id="sectors" className="relative overflow-hidden bg-mist py-24">
      {/* Background accents */}
      <div
        aria-hidden
        className="corner-ribbon start-0 top-0 bg-[linear-gradient(135deg,var(--color-navy)_0%,var(--color-navy)_38%,transparent_38.5%)] opacity-80"
      />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto">
          <SectionHeading center kicker="قطاعاتنا" title="حلول متكاملة ضمن منظومة واحدة" />
          <Reveal delay={0.1}>
            <p className="-mt-6 text-base sm:text-lg leading-8 text-slate-600">
              نعمل في قطاعات متعددة ومجالات واسعة من خلال خبرتنا وكوادرنا لتقديم حلول
              متكاملة ضمن منظومة واحدة، بما يختصر الوقت، ويرفع كفاءة التنفيذ، ويعزز جودة
              النتائج النهائية.
            </p>
          </Reveal>
        </div>

        {/* Category switcher pills */}
        <Reveal delay={0.15}>
          <div className="mt-10 flex flex-wrap items-center justify-center gap-2 sm:gap-3">
            <button
              type="button"
              onClick={() => setActiveFilter("all")}
              className={`rounded-full px-5 py-2.5 text-xs sm:text-sm font-bold transition-all duration-300 ${
                activeFilter === "all"
                  ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                  : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy"
              }`}
            >
              جميع القطاعات (5)
            </button>
            {SECTORS.map((s) => (
              <button
                key={s.num}
                type="button"
                onClick={() => setActiveFilter(s.num)}
                className={`flex items-center gap-2 rounded-full px-4 sm:px-5 py-2.5 text-xs sm:text-sm font-bold transition-all duration-300 ${
                  activeFilter === s.num
                    ? "bg-navy text-gold-light shadow-md ring-1 ring-gold/40 scale-105"
                    : "bg-white text-slate-700 hover:bg-slate-100 hover:text-navy"
                }`}
              >
                <s.Icon className="h-4 w-4 text-gold" />
                <span>{s.title}</span>
              </button>
            ))}
          </div>
        </Reveal>

        {/* Modern Showcase Cards Grid */}
        <div className="mt-12 grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {filteredSectors.map((sector, idx) => (
            <Reveal key={sector.num} delay={idx * 0.05}>
              <article className="group flex h-full flex-col overflow-hidden rounded-3xl border border-navy/10 bg-white shadow-[0_15px_40px_-20px_rgba(10,52,83,0.2)] transition-all duration-300 hover:-translate-y-1.5 hover:border-gold/50 hover:shadow-[0_25px_50px_-20px_rgba(10,52,83,0.35)]">
                {/* Visual Imagery with Dual-Photo Preview */}
                <div className="relative aspect-[16/10] w-full overflow-hidden bg-navy-darker">
                  <Image
                    src={sector.photos[0].src}
                    alt={sector.photos[0].alt}
                    fill
                    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 380px"
                    className="object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 via-navy-darker/20 to-transparent" />

                  {/* Top Badges */}
                  <div className="absolute top-4 inset-x-4 flex items-center justify-between">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-navy/90 text-gold-light shadow-md ring-1 ring-gold/30 backdrop-blur-md">
                      <sector.Icon className="h-5 w-5" />
                    </span>
                    <span className="rounded-full bg-gold px-3.5 py-1 text-xs font-black text-navy-darker shadow-md">
                      قطاع {sector.num}
                    </span>
                  </div>

                  {/* Secondary thumbnail inset */}
                  <div className="absolute bottom-3 end-3 h-12 w-16 overflow-hidden rounded-lg border-2 border-white/80 shadow-lg sm:h-14 sm:w-20">
                    <Image
                      src={sector.photos[1].src}
                      alt={sector.photos[1].alt}
                      fill
                      sizes="(max-width: 640px) 64px, 80px"
                      className="object-cover"
                    />
                  </div>

                  {/* Bottom Title overlay */}
                  <div className="absolute bottom-3 start-4">
                    <h3 className="text-xl font-black text-white drop-shadow-md">
                      {sector.title}
                    </h3>
                  </div>
                </div>

                {/* Content Body */}
                <div className="flex flex-1 flex-col justify-between p-6">
                  <div>
                    <span className="text-xs font-bold uppercase tracking-wider text-gold">
                      نطاق الخدمات والحلول:
                    </span>
                    <ul className="mt-3 space-y-2.5">
                      {sector.services.map((service, sIdx) => (
                        <li
                          key={sIdx}
                          className="flex items-start gap-2.5 text-sm leading-6 text-slate-700"
                        >
                          <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                          <span>{service}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Card Action Footer */}
                  <div className="mt-6 pt-4 border-t border-slate-100">
                    <a
                      href="#contact"
                      className="group/btn flex items-center justify-between rounded-xl bg-slate-50 px-4 py-2.5 text-xs font-bold text-navy transition-all duration-300 hover:bg-gold hover:text-navy-darker"
                    >
                      <span>طلب تسعير أو استشارة</span>
                      <ArrowLeft className="h-3.5 w-3.5 transition-transform duration-300 group-hover/btn:-translate-x-1" />
                    </a>
                  </div>
                </div>
              </article>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

