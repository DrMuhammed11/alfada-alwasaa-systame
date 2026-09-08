import Image from "next/image";
import {
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  MonitorSmartphone,
  Ship,
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { SITE_CONFIG } from "@/config/site";

const SERVICES = [
  {
    num: "01",
    title: "المقاولات العامة",
    desc: "تنفيذ الأعمال الإنشائية والميدانية وفق معايير هندسية وإدارية دقيقة.",
    Icon: Building2,
  },
  {
    num: "02",
    title: "الطرق والجسور",
    desc: "إنشاء وصيانة البنية التحتية الحيوية بكفاءة عالية.",
    Icon: Route,
  },
  {
    num: "03",
    title: "أعمال الحفريات",
    desc: "تجهيز المواقع وأعمال الحفر والردم والتسوية باحترافية.",
    Icon: Shovel,
  },
  {
    num: "04",
    title: "التوريدات والتموينات",
    desc: "توفير الاحتياجات التشغيلية والميدانية بسرعة وموثوقية.",
    Icon: Package,
  },
  {
    num: "05",
    title: "خدمات الاتصال",
    desc: "تقديم حلول داعمة للاتصال والتواصل التقني وفق متطلبات الأعمال الحديثة.",
    Icon: RadioTower,
  },
  {
    num: "06",
    title: "التسويق الإلكتروني",
    desc: "بناء حضور رقمي فعال يدعم وصول العلامات التجارية إلى جمهورها المستهدف.",
    Icon: MonitorSmartphone,
  },
  {
    num: "07",
    title: "الشحن والتخليص الجمركي",
    desc: "إدارة سلسلة الحركة اللوجستية وتسهيل الإجراءات بكفاءة.",
    Icon: Ship,
  },
];

export function Services() {
  return (
    <section id="services" className="relative overflow-hidden bg-white py-24">
      <div
        aria-hidden
        className="corner-ribbon end-0 top-0 bg-[linear-gradient(-135deg,var(--color-navy)_0%,var(--color-navy)_38%,transparent_38.5%)]"
      />
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading center kicker="منظومة عمل واحدة" title="خدماتنا" />

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {SERVICES.map((service, idx) => (
            <Reveal key={service.num} delay={idx * 0.04}>
              <article className="group relative flex h-full flex-col justify-between overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-navy via-navy to-navy-darker p-7 shadow-[0_15px_40px_-20px_rgba(5,30,49,0.7)] transition-all duration-300 hover:-translate-y-1.5 hover:border-gold/60 hover:shadow-[0_25px_60px_-15px_rgba(198,149,74,0.3)] sm:p-8">
                {/* Glow accent */}
                <div 
                  aria-hidden
                  className="pointer-events-none absolute -end-12 -top-12 h-32 w-32 rounded-full bg-gold/10 blur-2xl transition-all duration-300 group-hover:bg-gold/25 group-hover:scale-125"
                />

                <div>
                  <div className="relative flex items-center justify-between gap-4">
                    <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/10 text-gold-light ring-1 ring-gold/40 transition-all duration-300 group-hover:bg-gold group-hover:text-navy-darker group-hover:scale-105">
                      <service.Icon className="h-7 w-7" strokeWidth={1.8} />
                    </span>
                    <span className="rounded-full bg-white/5 px-3 py-1 font-mono text-sm font-black text-gold-light ring-1 ring-white/10">
                      #{service.num}
                    </span>
                  </div>

                  <h3 className="relative mt-6 text-xl font-black text-white sm:text-[1.3rem]">
                    {service.title}
                  </h3>
                  <p className="relative mt-3 text-sm leading-7 text-white/75">
                    {service.desc}
                  </p>
                </div>

                <div className="relative mt-6 pt-4 border-t border-white/10 flex items-center justify-between">
                  <span className="text-xs font-semibold text-gold-light/80">منظومة معتمدة</span>
                  <a 
                    href="#contact" 
                    className="text-xs font-bold text-white/80 hover:text-gold transition flex items-center gap-1"
                  >
                    <span>طلب الخدمة</span>
                    <span>←</span>
                  </a>
                </div>
              </article>
            </Reveal>
          ))}

          {/* Filler card that carries the company motto (literal from the profile) */}
          <Reveal delay={0.42}>
            <div className="flex h-full min-h-[220px] flex-col items-center justify-center gap-3 overflow-hidden rounded-3xl border-2 border-dashed border-gold/50 bg-navy-darker p-8 text-center">
              <div className="relative h-12 w-12 rounded-xl bg-white/5 p-1 ring-1 ring-gold/40">
                <Image
                  src={SITE_CONFIG.assets.logoMark}
                  alt={SITE_CONFIG.company.shortName}
                  fill
                  sizes="48px"
                  className="object-contain"
                />
              </div>
              <p className="text-base font-black text-gold-light">
                {SITE_CONFIG.company.tagline}
              </p>
              <p className="text-xs font-semibold text-white/70">
                منظومة واحدة تجمع كل ما يحتاجه مشروعك
              </p>
              <a
                href="#contact"
                className="mt-2 inline-flex items-center gap-2 rounded-full bg-gold px-6 py-2.5 text-xs font-black text-navy-darker shadow-md transition hover:bg-gold-light"
              >
                اطلب خدمتك الآن
              </a>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
