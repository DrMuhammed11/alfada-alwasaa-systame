"use client";

import { ShieldCheck, Award, FileCheck2, HardHat } from "lucide-react";
import { Reveal } from "./reveal";

const COMPLIANCE_ITEMS = [
  {
    title: "إدارة الجودة الشاملة ISO 9001",
    subtitle: "أنظمة تدقيق ومطابقة فنية مستمرة",
    desc: "تطبيق معايير الجودة العالمية في التخطيط، فحص المواد، وإجراءات التسليم الهندسي المرحلي لكافة المشروعات.",
    Icon: Award,
    badge: "ISO 9001:2015",
  },
  {
    title: "السلامة والصحة المهنية ISO 45001",
    subtitle: "ضوابط بيئية ووقائية صارمة بالميدان",
    desc: "امتثال كامل لإجراءات السلامة الميدانية وحماية الكوادر (HSE) في بيئات العمل الصعبة والمواقع الجبلية والوعرة.",
    Icon: HardHat,
    badge: "HSE / ISO 45001",
  },
  {
    title: "التراخيص الحكومية والسجلات الرسمية",
    subtitle: "اعتماد رسمي معترف به لدى الجهات السيادية",
    desc: "حيازة تراخيص المقاولات العامة، السجل التجاري المعتمد، تراخيص التخليص الجمركي وتوريدات قطاع الطاقة والاتصالات.",
    Icon: FileCheck2,
    badge: "تراخيص نظامية معتمدة",
  },
  {
    title: "مطابقة كود البناء والمواصفات القياسية",
    subtitle: "فحص مخبري وإشراف هندسي متواصل",
    desc: "تنفيذ الأعمال وفق كود الطرق والإنشاءات والاتصالات اليمني، مع فحوصات مخبرية موثقة قبل الاعتماد النهائي.",
    Icon: ShieldCheck,
    badge: "كود المواصفات القياسي",
  },
];

export function TrustBadges() {
  return (
    <section className="relative overflow-hidden bg-white dark:bg-navy-darker py-10 sm:py-14 border-t border-navy/10 dark:border-white/10 transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
          <Reveal>
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light ring-1 ring-gold/30">
              الامتثال والاعتمادات المؤسسية
            </span>
            <h2 className="mt-2 text-2xl sm:text-3xl font-extrabold text-navy dark:text-white">
              معايير هندسية معتمدة وثقة رصينة
            </h2>
            <p className="mt-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
              نلتزم بأعلى المقاييس الفنية والمهنية لضمان سلامة التنفيذ واستدامة المخرجات في كافة التعاقدات.
            </p>
          </Reveal>
        </div>

        <div className="grid gap-4 sm:gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {COMPLIANCE_ITEMS.map((item, idx) => (
            <Reveal key={item.title} index={idx}>
              <div className="group flex h-full flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50/80 dark:bg-navy p-5 shadow-sm transition hover:-translate-y-1 hover:border-gold/60 hover:shadow-md hover:bg-white dark:hover:bg-navy-deep">
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gold/15 text-gold-light dark:text-gold group-hover:bg-gold group-hover:text-navy-darker transition-colors duration-300">
                      <item.Icon className="h-5 w-5" strokeWidth={1.8} />
                    </span>
                    <span className="rounded-full bg-navy/5 dark:bg-white/10 px-2.5 py-1 font-mono text-[10px] font-bold text-navy dark:text-gold-light border border-navy/10 dark:border-white/10">
                      {item.badge}
                    </span>
                  </div>

                  <h3 className="text-sm sm:text-base font-bold text-navy dark:text-white group-hover:text-gold transition-colors">
                    {item.title}
                  </h3>
                  <p className="mt-1 text-[11px] font-semibold text-gold-light dark:text-gold">
                    {item.subtitle}
                  </p>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">
                    {item.desc}
                  </p>
                </div>

                <div className="mt-4 pt-3 border-t border-navy/5 dark:border-white/10 flex items-center gap-1.5 text-[11px] font-bold text-slate-500 dark:text-slate-400">
                  <ShieldCheck className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  <span>معتمد ومطبق ميدانياً</span>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
