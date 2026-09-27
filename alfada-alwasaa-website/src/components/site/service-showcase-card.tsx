"use client";

/**
 * بطاقة خدمة انغماسية (Service Showcase Card) — قالب موحّد ثنائي الاتجاه
 * Shared immersive bilingual template for the homepage services section.
 *
 * - تكوين بصري موحّد: صورة كبيرة + فاصل قطري (~12°) + منطقة محتوى غنية
 *   (شبكة مزايا 2×2 + أزرار) — لا يبدو كصندوقين منفصلين.
 * - تدوير صورتين تلقائي (crossfade 700ms + Ken Burns خفيف) داخل حاوية ثابتة:
 *   GPU-friendly فقط (opacity/transform)، صفر layout shift.
 * - الاتجاه يُقرأ من usePathname (بدء بـ /en ⇒ LTR): انعكاس ترتيب الأعمدة،
 *   اتجاه القطري، اتجاه الأسهم والأسهم التنقلية — مكوّن واحد لكلتا اللغتين.
 * - الوصولية: prefers-reduced-motion يعطّل Ken Burns وحركات hover (fade فقط)،
 *   aria-labels، focus-visible، type="button".
 */

import { useCallback, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { WhatsAppIcon } from "./whatsapp-icon";

export interface ShowcaseImage {
  src: string;
  alt: string;
}

export interface ShowcaseFeature {
  icon: LucideIcon;
  title: string;
  desc: string;
  status?: string;
}

export interface ShowcaseAction {
  label: string;
  href: string;
}

export interface ShowcaseService {
  number: string;
  slug: string;
  kicker: string;
  icon: LucideIcon;
  title: string;
  description: string;
  images: ShowcaseImage[];
  features: ShowcaseFeature[];
  primaryAction: ShowcaseAction;
  secondaryAction: ShowcaseAction;
}

/** تدوير صورتين: تبديل تلقائي كل 5 ثوانٍ مع تنظيف المؤقت */
function useImageRotation(count: number, intervalMs = 5000) {
  const [active, setActive] = useState(0);

  useEffect(() => {
    if (count < 2) return;
    const id = setInterval(() => setActive((v) => (v + 1) % count), intervalMs);
    return () => clearInterval(id);
  }, [count, intervalMs]);

  const go = useCallback(
    (i: number) => setActive(((i % count) + count) % count),
    [count]
  );

  return { active, go };
}

export function ServiceShowcaseCard({ service }: { service: ShowcaseService }) {
  const isEn = usePathname()?.startsWith("/en") ?? false;
  const { active, go } = useImageRotation(service.images.length);
  const Icon = service.icon;
  const ForwardArrow = isEn ? ArrowRight : ArrowLeft;
  // RTL: السابق يشير يمينًا والتالي يسارًا — ويُعكس في LTR
  const PrevChevron = isEn ? ChevronLeft : ChevronRight;
  const NextChevron = isEn ? ChevronRight : ChevronLeft;
  const L = isEn
    ? { prev: "Previous image", next: "Next image", image: (n: number) => `Image ${n}` }
    : { prev: "الصورة السابقة", next: "الصورة التالية", image: (n: number) => `الصورة ${n}` };

  const hasMultiple = service.images.length > 1;

  return (
    <article className="group relative overflow-hidden rounded-[2rem] bg-gradient-to-br from-navy via-navy-deep to-navy-darker shadow-[0_25px_60px_rgba(5,30,49,0.30)] ring-1 ring-white/10 transition-transform duration-300 hover:-translate-y-1 motion-reduce:transition-none motion-reduce:hover:translate-y-0">
      {/* الرقم الزخرفي الكبير — زاوية أسفل النهاية، لا ينافس المحتوى */}
      <span
        aria-hidden
        className="pointer-events-none absolute -bottom-7 end-3 z-0 select-none text-[7rem] font-black leading-none text-white/5 sm:text-[10rem]"
      >
        {service.number}
      </span>

      <div className="relative z-10 grid lg:grid-cols-2">
        {/* ============ منطقة الصورة (تمتد نحو الفاصل القطري) ============ */}
        <div
          className={cn(
            "group/img relative p-4 sm:p-6 lg:p-0",
            isEn ? "lg:order-2" : "lg:order-1"
          )}
        >
          <div className="relative aspect-[16/10] w-full overflow-hidden rounded-2xl sm:aspect-[16/9] lg:aspect-auto lg:absolute lg:inset-0 lg:h-full lg:rounded-none">
            {/* طبقتا الصورة — crossfade 700ms + Ken Burns خفيف على الطبقة النشطة */}
            {service.images.map((img, i) => (
              <div
                key={i}
                aria-hidden={i !== active}
                className={cn(
                  "absolute inset-0 lg:-left-12 transition-opacity duration-700 ease-in-out",
                  isEn
                    ? "lg:[clip-path:polygon(96px_0,100%_0,100%_100%,0_100%)]"
                    : "lg:[clip-path:polygon(0_0,100%_0,100%_100%,96px_100%)]",
                  i === active
                    ? "opacity-100 animate-[showcase-kenburns_6s_ease-out_forwards] motion-reduce:animate-none"
                    : "opacity-0"
                )}
              >
                <Image
                  src={img.src}
                  alt={img.alt}
                  fill
                  sizes="(max-width: 1024px) 100vw, 640px"
                  priority={i === 0}
                  loading={i === 0 ? undefined : "lazy"}
                  className="object-cover transition-transform duration-500 ease-out group-hover/img:scale-[1.02] motion-reduce:transition-none motion-reduce:group-hover/img:scale-100"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/50 via-transparent to-transparent" />
              </div>
            ))}

            {/* أزرار السابق/التالي — سطح المكتب عند التمرير فقط */}
            {hasMultiple && (
              <>
                <button
                  type="button"
                  onClick={() => go(active - 1)}
                  aria-label={L.prev}
                  className="absolute start-3 top-1/2 z-10 hidden h-9 w-9 -translate-y-1/2 items-center justify-center rounded-full bg-navy-darker/70 text-white opacity-0 ring-1 ring-white/25 backdrop-blur-sm transition-all duration-300 hover:bg-gold hover:text-navy-darker focus-visible:opacity-100 focus-visible:ring-2 focus-visible:ring-gold lg:group-hover/img:opacity-100 lg:flex"
                >
                  <PrevChevron className="h-4 w-4" aria-hidden />
                </button>
                <button
                  type="button"
                  onClick={() => go(active + 1)}
                  aria-label={L.next}
                  className="absolute end-3 top-1/2 z-10 hidden h-9 w-9 -translate-y-1/2 items-center justify-center rounded-full bg-navy-darker/70 text-white opacity-0 ring-1 ring-white/25 backdrop-blur-sm transition-all duration-300 hover:bg-gold hover:text-navy-darker focus-visible:opacity-100 focus-visible:ring-2 focus-visible:ring-gold lg:group-hover/img:opacity-100 lg:flex"
                >
                  <NextChevron className="h-4 w-4" aria-hidden />
                </button>
              </>
            )}

            {/* مؤشر الحالة — متكامل مع الصورة، غير كاروسيلي */}
            {hasMultiple && (
              <div className="absolute inset-x-0 bottom-3 z-10 flex items-center justify-center gap-1.5">
                {service.images.map((_, i) => (
                  <button
                    key={i}
                    type="button"
                    onClick={() => go(i)}
                    aria-label={L.image(i + 1)}
                    className={cn(
                      "h-1.5 rounded-full transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold-light",
                      i === active
                        ? "w-5 bg-gold"
                        : "w-1.5 bg-white/60 hover:bg-white/90"
                    )}
                  />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* ============ منطقة المحتوى ============ */}
        <div
          className={cn(
            "relative flex flex-col p-6 sm:p-8 lg:p-10 lg:ps-20",
            isEn ? "lg:order-1" : "lg:order-2"
          )}
        >
          {/* TOP: الفئة + الأيقونة + الرقم */}
          <div className="flex items-center justify-between gap-3">
            <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-3.5 py-1.5 text-[11px] font-extrabold text-gold-light">
              <Icon
                className="h-3.5 w-3.5 transition-transform duration-300 group-hover:scale-110 motion-reduce:group-hover:scale-100"
                aria-hidden
              />
              {service.kicker}
            </span>
            <span className="text-xs font-black text-white/50">#{service.number}</span>
          </div>

          {/* MAIN: العنوان + الوصف */}
          <h3 className="mt-4 text-2xl font-black leading-snug text-white sm:text-3xl">
            {service.title}
          </h3>
          <p className="mt-3 text-sm leading-7 text-white/75 sm:text-[15px]">
            {service.description}
          </p>

          {/* DIVIDER */}
          <div className="my-5 border-t border-white/10" aria-hidden />

          {/* FEATURE GRID 2×2 */}
          <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2">
            {service.features.map((feat, i) => {
              const FeatureIcon = feat.icon;
              return (
                <div
                  key={i}
                  className="group/feat flex items-start gap-2.5 rounded-xl bg-white/5 p-3 ring-1 ring-white/10 transition-colors duration-300 hover:bg-white/10 motion-reduce:hover:bg-white/5"
                >
                  <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-gold/15 text-gold-light transition-transform duration-300 group-hover/feat:scale-110 motion-reduce:group-hover/feat:scale-100">
                    <FeatureIcon className="h-4 w-4" strokeWidth={1.9} aria-hidden />
                  </span>
                  <div className="min-w-0">
                    <div className="flex items-center gap-1.5">
                      <h4 className="text-xs font-bold text-white">{feat.title}</h4>
                      {feat.status && (
                        <CheckCircle2 className="h-3 w-3 shrink-0 text-gold" aria-hidden />
                      )}
                    </div>
                    <p className="mt-0.5 text-[11px] leading-5 text-white/70">{feat.desc}</p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* ACTIONS */}
          <div className="mt-auto flex flex-col gap-3 pt-7 sm:flex-row sm:items-center">
            <Link
              href={service.primaryAction.href}
              className="group/btn inline-flex items-center justify-center gap-2 rounded-full bg-gold px-5 py-2.5 text-xs font-black text-navy-darker shadow-lg shadow-gold/25 transition-all duration-300 hover:bg-gold-light hover:shadow-gold/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold-light focus-visible:ring-offset-2 focus-visible:ring-offset-navy-darker sm:justify-start"
            >
              <span>{service.primaryAction.label}</span>
              <ForwardArrow
                className="h-4 w-4 transition-transform duration-300 rtl:group-hover/btn:-translate-x-1 ltr:group-hover/btn:translate-x-1 motion-reduce:transition-none"
                aria-hidden
              />
            </Link>
            <a
              href={service.secondaryAction.href}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-white/10 px-5 py-2.5 text-xs font-bold text-white ring-1 ring-white/15 transition-colors duration-300 hover:bg-white/15 hover:text-gold-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold-light sm:justify-start"
            >
              <WhatsAppIcon className="h-4 w-4" aria-hidden />
              <span>{service.secondaryAction.label}</span>
            </a>
          </div>
        </div>
      </div>
    </article>
  );
}
