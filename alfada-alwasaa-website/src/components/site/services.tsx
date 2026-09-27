"use client";

/**
 * قسم الخدمات في الرئيسية — قائمة بطاقات انغماسية (Service Showcase Cards)
 * بطاقة أفقية كبيرة لكل خدمة: صورة بفاصل قطري + تدوير صورتين + شبكة مزايا + أزرار.
 * البيانات من SITE_CONFIG.servicesList و SERVICES_DATA — القالب مكوّن واحد للجميع.
 */

import Image from "next/image";
import { Sparkles } from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { ServiceShowcaseCard, type ShowcaseService } from "./service-showcase-card";
import { FEATURE_ICONS, SERVICE_SLUG_ICONS } from "./service-detail-view";
import { SITE_CONFIG } from "@/config/site";
import { SERVICES_DATA, type ServiceIconName } from "@/config/services-data";

const SERVICES: ShowcaseService[] = SITE_CONFIG.servicesList.map((service, i) => {
  const detail = SERVICES_DATA[service.slug];
  const firstImage = detail?.image ?? "";
  const secondImage = detail?.galleryImages?.[0] ?? firstImage;

  return {
    number: String(i + 1).padStart(2, "0"),
    slug: service.slug,
    kicker: detail?.shortTitle ?? service.title,
    icon: SERVICE_SLUG_ICONS[service.slug] ?? Sparkles,
    title: service.title,
    description: detail?.subtitle ?? service.desc,
    images: [
      { src: firstImage, alt: `${service.title} — أعمال تنفيذية ميدانية` },
      { src: secondImage, alt: `${service.title} — تجهيزات وتنفيذ في الموقع` },
    ].filter((img) => img.src),
    features: (detail?.features ?? [])
      .slice(0, 4)
      .map((f) => ({
        icon: FEATURE_ICONS[f.icon as ServiceIconName] ?? Sparkles,
        title: f.title,
        desc: f.desc,
        status: "معتمد",
      })),
    primaryAction: {
      label: "تفاصيل الخدمة والمواصفات",
      href: `/services/${service.slug}`,
    },
    secondaryAction: {
      label: "تواصل عبر واتساب",
      href: SITE_CONFIG.contacts.general.waHref,
    },
  };
});

export function Services() {
  return (
    <section
      id="services"
      className="relative overflow-hidden bg-white py-12 transition-colors duration-300 dark:bg-navy-darker sm:py-16"
    >
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          center
          kicker="قدراتنا التنفيذية"
          title="حلول تخصصية تلبي معايير المشاريع الحيوية"
        />

        <Reveal delay={0.05}>
          <p className="mx-auto -mt-6 max-w-3xl text-center text-base leading-8 text-slate-600 dark:text-slate-300 sm:text-lg">
            منظومة خدمات متكاملة تجمع الخبرة الهندسية والانضباط المؤسسي — كل خدمة بفريقها
            ومعداتها ومعايير تنفيذها المعتمدة.
          </p>
        </Reveal>

        <div className="mt-10 space-y-8 lg:space-y-10">
          {SERVICES.map((service, i) => (
            <Reveal key={service.slug} delay={Math.min(i * 0.05, 0.2)}>
              <ServiceShowcaseCard service={service} />
            </Reveal>
          ))}
        </div>

        {/* لافتة الضمان — خاتمة القسم */}
        <Reveal delay={0.2} className="mt-10">
          <div className="flex flex-col items-center justify-between gap-4 rounded-2xl border border-navy/10 bg-mist p-5 text-slate-800 transition-colors dark:border-white/10 dark:bg-navy dark:text-white sm:flex-row sm:p-6">
            <div className="flex items-center gap-3">
              <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-navy p-1 ring-1 ring-gold/40 dark:bg-navy-darker">
                <Image
                  src={SITE_CONFIG.assets.logoMark}
                  alt={SITE_CONFIG.company.shortName}
                  fill
                  sizes="40px"
                  className="object-contain"
                />
              </div>
              <div>
                <p className="text-sm font-black text-navy dark:text-gold-light">
                  {SITE_CONFIG.company.tagline}
                </p>
                <p className="text-xs text-slate-600 dark:text-white/70">
                  كافة القطاعات تُدار بتنسيق هندسي وإشراف تنفيذي صارم يضمن أعلى معايير الإنجاز.
                </p>
              </div>
            </div>

            <a
              href="#contact"
              className="shrink-0 rounded-full bg-navy px-5 py-2 text-xs font-bold text-white shadow-sm transition hover:scale-105 dark:bg-gold dark:text-navy-darker motion-reduce:hover:scale-100"
            >
              اطلب دراسة مشروعك الآن
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
