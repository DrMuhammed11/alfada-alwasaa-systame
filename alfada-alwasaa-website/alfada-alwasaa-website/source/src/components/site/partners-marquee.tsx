"use client";

import { 
  RadioTower, 
  Flame, 
  Building2, 
  Ship, 
  Truck, 
  ShieldCheck, 
  Factory,
  Globe2 
} from "lucide-react";
import { Reveal } from "./reveal";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

const SECTOR_PARTNERS = [
  {
    name: "مشغلو شبكات الاتصالات والإنترنت",
    en: "Telecom & Internet Operators",
    Icon: RadioTower,
  },
  {
    name: "منشآت وتوريدات قطاع النفط والطاقة",
    en: "Oil & Energy Supply Sector",
    Icon: Flame,
  },
  {
    name: "مقاولو ومشاريع البنية التحتية والطرق",
    en: "Infrastructure & Road Contractors",
    Icon: Building2,
  },
  {
    name: "سلاسل الإمداد والتخليص المينائي",
    en: "Port Logistics & Supply Chains",
    Icon: Ship,
  },
  {
    name: "أساطيل النقل الثقيل متعدد الوسائط",
    en: "Heavy Multimodal Fleet Transport",
    Icon: Truck,
  },
  {
    name: "الشركات الصناعية ومستوردي المعدات",
    en: "Industrial & Heavy Equipment Importers",
    Icon: Factory,
  },
  {
    name: "المؤسسات التنموية والمشاريع الكبرى",
    en: "Development & Enterprise Projects",
    Icon: Globe2,
  },
  {
    name: "منظومات الجودة والسلامة المعتمدة",
    en: "Certified Quality & Safety Systems",
    Icon: ShieldCheck,
  },
];

export function PartnersMarquee() {
  const reduce = useReducedMotion();

  // تكرار القائمة مرتين للحصول على شريط لا نهائي مستمر
  const marqueeItems = [...SECTOR_PARTNERS, ...SECTOR_PARTNERS];

  return (
    <section className="relative overflow-hidden border-y border-navy/10 dark:border-white/10 bg-mist/60 dark:bg-navy-darker/40 py-8 transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mb-4 text-center">
        <Reveal>
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light ring-1 ring-gold/30">
            قطاعات الشراكة وشبكات الأعمال
          </span>
          <p className="mt-2 text-xs sm:text-sm font-semibold text-slate-600 dark:text-slate-300">
            نعمل جنباً إلى جنب مع كبرى القطاعات الحيوية في إدارة وتنفيذ المشروعات التنموية
          </p>
        </Reveal>
      </div>

      {/* Marquee Wrapper with soft lateral fades */}
      <div className="relative w-full overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_10%,black_90%,transparent)]">
        {/* CSS animation خالص — بديل motion.div من framer-motion
            كلاس marquee-track معرَّف في globals.css: translateX(0→-50%) 35s linear infinite
            يُعطَّل تلقائياً عند prefers-reduced-motion عبر globals.css */}
        <div className={`flex w-max gap-4 py-2${reduce ? "" : " marquee-track"}`}>
          {marqueeItems.map((item, idx) => (
            <div
              key={`${item.name}-${idx}`}
              className="flex items-center gap-3 rounded-2xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy px-5 py-3 shadow-sm transition hover:border-gold/60 hover:shadow-md shrink-0"
            >
              <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-gold/15 text-gold-light dark:text-gold">
                <item.Icon className="h-4 w-4" strokeWidth={2} />
              </span>
              <div className="text-right">
                <span className="block text-xs font-bold text-navy dark:text-white">
                  {item.name}
                </span>
                <span className="block text-[10px] font-medium text-slate-500 dark:text-slate-400">
                  {item.en}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
