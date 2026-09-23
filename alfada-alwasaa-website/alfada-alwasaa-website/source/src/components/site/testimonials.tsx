"use client";

import { Quote, Star } from "lucide-react";
import { SectionHeading } from "./section-heading";
import { Reveal } from "./reveal";

const TESTIMONIALS = [
  {
    quote:
      "تميزت شركة الفضاء الواسع بالانضباط الهندسي الصارم في تسوية المسارات الجبلية والالتزام الدقيق بمواصفات كود الطرق وفحوصات الدمك المخبرية لطبقات الأساس في الموعد التعاقدي المحدد.",
    name: "م. عبدالسلام القاضي",
    role: "استشاري إشراف مشروعات بنية تحتية وطرق",
    sector: "قطاع الإنشاءات والطرق",
  },
  {
    quote:
      "سلاسة التخليص الجمركي للشحنات وسرعة تسيير القوافل والشحن من الموانئ إلى مواقع العمل مباشرة وفّرت على مشاريعنا الصناعية وقتاً حرجاً وتكاليف تخزين إضافية كانت تؤرق سلاسل الإمداد.",
    name: "أ. عادل الحمادي",
    role: "مدير سلاسل الإمداد والخدمات اللوجستية",
    sector: "قطاع التوريدات والموانئ",
  },
  {
    quote:
      "استجابة فرق الطوارئ الميدانية على مدار 24/7 وتركيب أنظمة الطاقة الشمسية الهجينة للأبراج في أصعب التضاريس شكّلت ركيزة أساسية لاستقرار بث وتغطية الشبكة دون أي انقطاع تشغيلي.",
    name: "م. طارق الصعفاني",
    role: "مدير تشغيل وصيانة شبكات الاتصالات",
    sector: "قطاع الاتصالات والإنترنت",
  },
];

export function Testimonials() {
  return (
    <section className="relative overflow-hidden bg-mist/60 dark:bg-navy-darker/40 py-12 sm:py-16 transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          center
          kicker="شواهد الثقة"
          title="آراء شركاء المشروعات والجهات المستفيدة"
        />

        <div className="mt-8 grid gap-6 md:grid-cols-3">
          {TESTIMONIALS.map((item, idx) => (
            <Reveal key={item.name} index={idx}>
              <div className="flex h-full flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-7 shadow-[0_10px_30px_-15px_rgba(10,52,83,0.15)] transition hover:-translate-y-1 hover:border-gold/60 hover:shadow-lg">
                <div>
                  {/* Star Rating and Quote mark */}
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-1 text-amber-400">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} className="h-4 w-4 fill-amber-400" />
                      ))}
                    </div>
                    <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-gold/15 text-gold-light dark:text-gold">
                      <Quote className="h-4 w-4" />
                    </span>
                  </div>

                  <p className="text-xs sm:text-sm leading-6 sm:leading-7 text-slate-700 dark:text-slate-200 text-justify">
                    &ldquo;{item.quote}&rdquo;
                  </p>
                </div>

                <div className="mt-6 pt-4 border-t border-slate-100 dark:border-white/10">
                  <span className="block text-sm font-bold text-navy dark:text-white">
                    {item.name}
                  </span>
                  <span className="block text-xs font-semibold text-gold-light dark:text-gold mt-0.5">
                    {item.role}
                  </span>
                  <span className="block text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                    {item.sector}
                  </span>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
