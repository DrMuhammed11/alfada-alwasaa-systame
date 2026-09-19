"use client";

import { useState } from "react";
import Image from "next/image";
import { 
  Quote, 
  Route, 
  ClipboardCheck, 
  RadioTower, 
  Package, 
  Truck, 
  CheckCircle2, 
  ShieldCheck, 
  ArrowLeft,
  Maximize2
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { TrackLightbox, type TrackItem } from "./track-lightbox";

const TRACK_CASE_STUDIES: TrackItem[] = [
  {
    id: "roads",
    title: "مشاريع شق وتعبيد الطرق وتسوية المسارات",
    tag: "مقاولات وأعمال مدنية",
    scope: "تنفيذ أعمال الحفريات الصخرية والردم والتسوية وفرش الطبقات الإسفلتية، مع تشييد العبّارات وتدعيم المنحدرات لضمان سلامة الطرق واستدامتها في التضاريس الوعرة.",
    metrics: [
      "مطابقة كود الطرق وأعلى المعايير والمواصفات الفنية",
      "أسطول معدات ثقيلة متكامل وكوادر هندسية ومساحية ميدانية",
    ],
    src: "/profile/track_roller.webp",
    alt: "أعمال شق وتسوية وسفلتة الطرق",
    Icon: Route,
  },
  {
    id: "customs",
    title: "التخليص الجمركي وإدارة سلاسل الإفراج المينائي",
    tag: "تخليص وتجارة دولية",
    scope: "إنهاء المعاملات الجمركية بكفاءة متقدمة للشحنات التجارية والمعدات الثقيلة عبر الموانئ والمنافذ، مع سرعة التدقيق والمطابقة النظامية لتفادي أي تأخير تشغيلي.",
    metrics: [
      "تسريع دورة الإفراج الجمركي وتقليص أوقات الانتظار",
      "امتثال قانوني كامل وسلامة موثقة لكافة الواردات",
    ],
    src: "/profile/track_ship.webp",
    alt: "عمليات التخليص الجمركي وتفريغ الحاويات",
    Icon: ClipboardCheck,
  },
  {
    id: "telecom",
    title: "تجهيز أبراج الاتصالات والصيانة الميدانية المستمرة",
    tag: "اتصالات وبنية شبكية",
    scope: "مسح وتشييد أبراج التغطية والهوائيات وربط خطوط المايكروويف، وتزويد المحطات بحلول الطاقة الهجينة والمولدات، مع توفير فرق طوارئ متخصصة للدعم الفني.",
    metrics: [
      "جاهزية تشغيلية واستجابة فنية طارئة على مدار 24/7",
      "استقرار التغطية وشبكات البث في أصعب المواقع والمحافظات",
    ],
    src: "/profile/track_tower.webp",
    alt: "أبراج وهوائيات شبكات الاتصالات",
    Icon: RadioTower,
  },
  {
    id: "supplies",
    title: "سلاسل التوريدات الصناعية والتموين المتخصص",
    tag: "توريدات وتموين عام",
    scope: "تأمين المواد والمعدات وقطع الغيار والمستلزمات التشغيلية للمشاريع الكبرى والجهات الحيوية، وفق آليات فحص جودة صارمة وجداول إمداد منتظمة تحمي خطط العمل.",
    metrics: [
      "فحص واعتماد مطابق لأعلى معايير الجودة المعتمدة",
      "التزام دقيق بالمواعيد وسلاسل إمداد مستدامة ومنضبطة",
    ],
    src: "/profile/track_forklift.webp",
    alt: "التوريدات والتموينات اللوجستية للمشاريع",
    Icon: Package,
  },
  {
    id: "logistics",
    title: "الخدمات اللوجستية والشحن البري التكاملي",
    tag: "لوجستيات وشحن متعدد الوسائط",
    scope: "إدارة أساطيل النقل الثقيل لشحن البضائع والمعدات الضخمة والحاويات، وتحديد المسارات الآمنة مع أنظمة التتبع الحي والمتابعة المستمرة لكافة الشحنات حتى وجهتها.",
    metrics: [
      "أسطول نقل حديث مجهز بتقنيات التتبع المباشر والسلامة",
      "تغطية جغرافية شاملة ومرونة عالية في نقل الحمولات الحساسة",
    ],
    src: "/profile/track_truck.webp",
    alt: "شحن ونقل المعدات والبضائع",
    Icon: Truck,
  },
];

export function TrackRecord() {
  const [selectedItem, setSelectedItem] = useState<TrackItem | null>(null);
  const [lightboxOpen, setLightboxOpen] = useState(false);

  const handleOpenLightbox = (item: TrackItem) => {
    setSelectedItem(item);
    setLightboxOpen(true);
  };

  return (
    <section id="track" className="relative overflow-hidden bg-mist dark:bg-navy-darker/60 py-12 sm:py-16 transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-start gap-10 lg:grid-cols-[0.9fr_1.1fr]">
          <SectionHeading kicker="سابقة الأعمال" title="سابقة تُعتمد" />
          <Reveal delay={0.1}>
            <div className="mb-2 flex items-start gap-3 rounded-2xl border border-gold/30 bg-white/70 dark:bg-navy/70 p-4 shadow-sm backdrop-blur-sm">
              <Quote className="mt-1 h-6 w-6 shrink-0 text-gold" strokeWidth={2} />
              <p className="text-lg font-extrabold text-navy dark:text-gold-light">
                شواهد على الثقة والإنجاز
              </p>
            </div>
            {/* Exact paragraph from the profile */}
            <p className="mt-4 text-justify text-[1.05rem] leading-9 text-slate-700 dark:text-slate-200">
              نفذت شركة الفضاء الواسع لخدمات الاتصالات والمقاولات عددًا من المشاريع
              المتنوعة التي شملت أعمال الطرق والحفريات، والتوريدات، والخدمات اللوجستية،
              والشحن، والتخليص الجمركي، إضافة إلى خدمات الاتصالات والدعم الفني، بما يعكس
              خبرتها المتعددة وقدرتها على تنفيذ الأعمال وفق أعلى معايير الجودة والالتزام.
            </p>
          </Reveal>
        </div>

        {/* Case Study Cards Grid — 5 documented fields in balanced layout */}
        <div className="mt-8 sm:mt-10 grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-2 lg:grid-cols-6">
          {TRACK_CASE_STUDIES.map((item, idx) => {
            const colSpanClass =
              idx < 3
                ? "lg:col-span-2"
                : "lg:col-span-3 md:col-span-1";

            return (
              <Reveal 
                key={item.id} 
                delay={idx * 0.08}
                className={`${colSpanClass} w-full`}
              >
                <article 
                  onClick={() => handleOpenLightbox(item)}
                  className="group flex h-full cursor-pointer flex-col justify-between overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy shadow-[0_12px_35px_-15px_rgba(10,52,83,0.12)] transition-all duration-500 hover:-translate-y-1.5 hover:border-gold/50 hover:shadow-[0_24px_55px_-15px_rgba(10,52,83,0.22)]"
                >
                  {/* Card Media Header with interactive hover zoom and Lightbox trigger */}
                  <div className="relative aspect-[16/10] w-full overflow-hidden bg-navy-darker">
                    <Image
                      src={item.src}
                      alt={item.alt}
                      fill
                      loading="lazy"
                      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                      className="object-cover transition-transform duration-700 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/85 via-navy-darker/20 to-transparent" />

                    {/* Top Floating Badge & Icon */}
                    <div className="absolute inset-x-4 top-4 flex items-center justify-between z-10">
                      <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-navy/90 text-gold-light shadow-md ring-1 ring-gold/30 backdrop-blur-md transition-colors duration-500 group-hover:bg-gold group-hover:text-navy-darker">
                        <item.Icon className="h-5 w-5" strokeWidth={1.8} />
                      </span>
                      <span className="rounded-full border border-gold/40 bg-navy-deep/85 px-3.5 py-1 text-xs font-bold text-gold-light shadow-md backdrop-blur-md">
                        {item.tag}
                      </span>
                    </div>

                    {/* Hover indicator: Lightbox prompt */}
                    <div className="absolute inset-0 flex items-center justify-center bg-navy-darker/50 opacity-0 backdrop-blur-xs transition-opacity duration-300 group-hover:opacity-100 z-10">
                      <span className="inline-flex items-center gap-2 rounded-full bg-gold px-4 py-2 text-xs font-black text-navy-darker shadow-lg transform translate-y-2 group-hover:translate-y-0 transition-transform duration-300">
                        <Maximize2 className="h-3.5 w-3.5" />
                        <span>عرض التفاصيل والصورة</span>
                      </span>
                    </div>

                    {/* Bottom overlay highlight title */}
                    <div className="absolute bottom-3 start-4 end-4 z-10">
                      <span className="text-[0.7rem] font-bold uppercase tracking-wider text-gold-light">
                        مجال الإنجاز {idx + 1}
                      </span>
                    </div>
                  </div>

                  {/* Card Body & Scope of Work */}
                  <div className="flex flex-1 flex-col justify-between p-6 sm:p-7">
                    <div>
                      <h3 className="text-lg sm:text-xl font-black text-navy dark:text-white transition-colors duration-300 group-hover:text-gold leading-snug">
                        {item.title}
                      </h3>
                      <p className="mt-3 text-sm leading-7 text-slate-600 dark:text-slate-300 text-justify">
                        {item.scope}
                      </p>
                    </div>

                    {/* Metrics / Quality Benchmarks */}
                    <div className="mt-6 border-t border-slate-100 dark:border-white/10 pt-5">
                      <span className="text-[0.72rem] font-black uppercase tracking-wider text-gold">
                        شواهد الجودة والمعايير:
                      </span>
                      <ul className="mt-2.5 space-y-2">
                        {item.metrics.map((metric, mIdx) => (
                          <li 
                            key={mIdx} 
                            className="flex items-start gap-2 text-xs leading-5 text-slate-700 dark:text-slate-200 font-semibold"
                          >
                            <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-gold" />
                            <span>{metric}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </article>
              </Reveal>
            );
          })}
        </div>

        {/* High-Trust Closing Banner */}
        <Reveal delay={0.15}>
          <div className="mt-10 sm:mt-12 flex flex-col sm:flex-row items-center justify-between gap-6 rounded-3xl border border-gold/30 bg-gradient-to-r from-navy to-navy-darker p-7 sm:p-9 text-white shadow-[0_20px_50px_-20px_rgba(10,52,83,0.5)]">
            <div className="text-center sm:text-start">
              <div className="flex items-center justify-center sm:justify-start gap-2 text-gold-light text-sm font-black mb-1">
                <ShieldCheck className="h-5 w-5 text-gold" />
                <span>شريكك .. لاستقبال أوسع</span>
              </div>
              <p className="text-base sm:text-lg font-bold text-white">
                جاهزون لتقديم حلول تنفيذية متكاملة تضمن نجاح مشروعكم القادم بأعلى معايير الدقة
              </p>
            </div>
            <a
              href="#contact"
              className="inline-flex shrink-0 items-center gap-2.5 rounded-2xl bg-gold px-6 py-3.5 text-sm font-black text-navy-darker shadow-lg transition-all duration-300 hover:bg-gold-light hover:scale-105 active:scale-95"
            >
              <span>طلب دراسة أو استشارة مشروع</span>
              <ArrowLeft className="h-4 w-4" />
            </a>
          </div>
        </Reveal>
      </div>

      {/* Lightbox Modal */}
      <TrackLightbox
        isOpen={lightboxOpen}
        onClose={() => setLightboxOpen(false)}
        item={selectedItem}
        items={TRACK_CASE_STUDIES}
        onSelect={(item) => setSelectedItem(item)}
      />
    </section>
  );
}
