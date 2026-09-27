"use client";

/**
 * قائمة بطاقات الخدمات الأفقية (Service List Cards) — نظام موحّد ثنائي الاتجاه
 * Shared bilingual horizontal-card system for the homepage sectors section.
 *
 * - بطاقة أفقية كبيرة: صورة (35-42%) + محتوى رحب (58-65%) هرمية واضحة.
 * - تدوير صورتين تلقائي كل 5 ثوانٍ داخل حاوية ثابتة تماماً:
 *   crossfade ناعم + Ken Burns اختياري خفيف — GPU-friendly فقط (opacity/transform).
 * - رقم زخرفي كبير خلف المحتوى بمحاذاة ثابتة (أعلى النهاية).
 * - الاتجاه يُقرأ من usePathname (بدء بـ /en ⇒ LTR): انعكاس الأعمدة والأسهم
 *   ومحاذاة النص — مكوّن واحد لكلتا اللغتين.
 * - الوصولية: prefers-reduced-motion يعطّل Ken Burns وحركات hover،
 *   alt وصفي، aria-labels، focus states.
 */

import { useCallback, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowLeft, ArrowRight, type LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { WhatsAppIcon } from "./whatsapp-icon";

export interface ListCardImage {
  src: string;
  alt: string;
}

export interface ListCardAction {
  label: string;
  href: string;
}

export interface ServiceListItem {
  number: string;
  slug: string;
  category: string;
  icon: LucideIcon;
  title: string;
  description: string;
  images: ListCardImage[];
  primaryAction: ListCardAction;
  secondaryAction: ListCardAction;
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

export function ServiceListCard({ service }: { service: ServiceListItem }) {
  const isEn = usePathname()?.startsWith("/en") ?? false;
  const { active } = useImageRotation(service.images.length);
  const Icon = service.icon;
  const ForwardArrow = isEn ? ArrowRight : ArrowLeft;
  const hasMultiple = service.images.length > 1;

  return (
    <article className="group relative overflow-hidden rounded-3xl border border-slate-200/90 bg-white shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-gold/50 hover:shadow-md dark:border-white/10 dark:bg-navy-deep motion-reduce:transition-none motion-reduce:hover:translate-y-0">
      {/* الرقم الزخرفي الكبير — أعلى النهاية، خلف المحتوى تماماً */}
      <span
        aria-hidden
        className="pointer-events-none absolute -top-5 end-4 z-0 select-none text-[6rem] font-black leading-none text-navy/5 dark:text-white/5 sm:text-[8rem]"
      >
        {service.number}
      </span>

      <div className="relative z-10 grid lg:grid-cols-5">
        {/* ============ منطقة الصورة (35-42%) ============ */}
        <div
          className={cn(
            "relative p-4 sm:p-5 lg:p-5",
            isEn ? "lg:order-2 lg:col-span-2" : "lg:order-1 lg:col-span-2"
          )}
        >
          <div className="relative aspect-[4/3] w-full overflow-hidden rounded-2xl">
            {service.images.map((img, i) => (
              <div
                key={i}
                aria-hidden={i !== active}
                className={cn(
                  "absolute inset-0 transition-opacity duration-700 ease-in-out",
                  i === active
                    ? "opacity-100 animate-[showcase-kenburns_6s_ease-out_forwards] motion-reduce:animate-none"
                    : "opacity-0"
                )}
              >
                <Image
                  src={img.src}
                  alt={img.alt}
                  fill
                  sizes="(max-width: 1024px) 100vw, 480px"
                  priority={i === 0}
                  loading={i === 0 ? undefined : "lazy"}
                  className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.02] motion-reduce:transition-none motion-reduce:group-hover:scale-100"
                />
              </div>
            ))}

            {/* مؤشر خفي جداً — ليس تحكم كاروسيل */}
            {hasMultiple && (
              <div className="absolute bottom-2.5 inset-x-0 z-10 flex items-center justify-center gap-1.5">
                {service.images.map((_, i) => (
                  <span
                    key={i}
                    className={cn(
                      "h-1.5 rounded-full transition-all duration-300",
                      i === active ? "w-4 bg-gold" : "w-1.5 bg-white/70"
                    )}
                  />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* ============ منطقة المحتوى (58-65%) ============ */}
        <div
          className={cn(
            "relative flex flex-col p-5 sm:p-7 lg:py-7 lg:pe-10 lg:ps-2",
            isEn ? "lg:order-1 lg:col-span-3" : "lg:order-2 lg:col-span-3"
          )}
        >
          {/* الفئة */}
          <span className="inline-flex w-fit items-center gap-2 rounded-full bg-gold-soft px-3 py-1 text-[11px] font-extrabold text-navy dark:bg-gold/15 dark:text-gold-light">
            <Icon
              className="h-3.5 w-3.5 transition-transform duration-300 group-hover:scale-110 motion-reduce:group-hover:scale-100"
              aria-hidden
            />
            {service.category}
          </span>

          {/* العنوان + الوصف */}
          <h3 className="mt-3 text-xl font-black leading-snug text-navy dark:text-white sm:text-2xl">
            {service.title}
          </h3>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-600 dark:text-slate-300">
            {service.description}
          </p>

          {/* الأزرار — أسفل البطاقة دائماً */}
          <div className="mt-auto flex flex-col gap-3 pt-6 sm:flex-row sm:items-center">
            <Link
              href={service.primaryAction.href}
              className="group/btn inline-flex items-center justify-center gap-2 rounded-full bg-gold px-5 py-2.5 text-xs font-black text-navy-darker shadow-sm shadow-gold/25 transition-all duration-300 hover:bg-gold-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold focus-visible:ring-offset-2 sm:justify-start"
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
              className="inline-flex items-center justify-center gap-2 rounded-full border border-slate-200 bg-white px-5 py-2.5 text-xs font-bold text-navy transition-colors duration-300 hover:border-gold/60 hover:text-gold-dark focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold dark:border-white/15 dark:bg-transparent dark:text-white dark:hover:text-gold-light sm:justify-start"
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

/** القائمة العمودية من البطاقات الأفقية */
export function ServiceListSection({ services }: { services: ServiceListItem[] }) {
  return (
    <div className="space-y-6 lg:space-y-8">
      {services.map((service) => (
        <ServiceListCard key={service.slug} service={service} />
      ))}
    </div>
  );
}
