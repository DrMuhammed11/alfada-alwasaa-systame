import { Gem, Quote } from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";

export function Position() {
  return (
    <section id="position" className="relative overflow-hidden bg-mist/60 dark:bg-navy-darker/60 py-16 sm:py-24 transition-colors duration-300">
      <div className="relative mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <SectionHeading center kicker="مكانتنا المؤسسية" title="مكانة راسخة وشراكة استراتيجية موثوقة" />

        <Reveal delay={0.1}>
          <div className="relative mt-10 overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-8 sm:p-12 lg:p-16 shadow-[0_20px_50px_-20px_rgba(10,52,83,0.15)] dark:shadow-[0_20px_50px_-20px_rgba(0,0,0,0.5)]">
            {/* Ambient gold glow orb in card corner */}
            <div
              className="pointer-events-none absolute -top-24 -start-24 h-64 w-64 rounded-full bg-gold/15 blur-3xl"
              aria-hidden="true"
            />
            <div
              className="pointer-events-none absolute -bottom-24 -end-24 h-64 w-64 rounded-full bg-gold/10 blur-3xl"
              aria-hidden="true"
            />

            {/* Emblem & Top badge */}
            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="mb-6 flex h-16 w-16 items-center justify-center rounded-2xl bg-gold/15 dark:bg-gold/20 text-gold border border-gold/30 shadow-sm">
                <Gem className="h-8 w-8" strokeWidth={1.8} />
              </div>

              <div className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-bold text-gold-light dark:text-gold mb-8">
                <Quote className="h-3.5 w-3.5 text-gold rotate-180" />
                <span>فلسفة الأداء والشراكة المستدامة</span>
              </div>
            </div>

            {/* Two balanced editorial columns */}
            <div className="relative z-10 grid gap-8 md:grid-cols-2 md:gap-12">
              <div className="space-y-4 text-slate-700 dark:text-slate-200">
                <h3 className="text-xl font-black text-navy dark:text-white leading-snug">
                  الشراكة الحقيقية تتجاوز مجرد تنفيذ المهام
                </h3>
                <p className="text-base leading-8 text-justify">
                  انطلقت الشركة من قناعة راسخة بأن الشركات الكبرى لا تبحث فقط عن منفذ خدمة، بل
                  عن شريك يعتمد عليه. ولذلك، نولي اهتمامًا بالغًا بالتفاصيل الفنية، وسلامة
                  الإجراءات، ودقة المتابعة، ووضوح التواصل في جميع مراحل العمل، بدءًا من التخطيط
                  وحتى التسليم النهائي.
                </p>
              </div>

              <div className="space-y-4 text-slate-700 dark:text-slate-200">
                <h3 className="text-xl font-black text-navy dark:text-white leading-snug">
                  التوازن المثالي بين الجدية والمرونة الميدانية
                </h3>
                <p className="text-base leading-8 text-justify">
                  ونحرص على أن تعكس جميع أعمالنا صورة مؤسسية راقية تجمع بين الجدية والمرونة،
                  وبين الجودة والسرعة، وبين الكفاءة الفنية والالتزام الكامل تجاه العميل. ومن هنا،
                  أصبحت الشركة خيارًا موثوقاً للجهات التي تتطلع إلى تنفيذ أعمالها عبر فريق يفهم
                  متطلبات السوق، ويجيد التعامل مع المشاريع ذات الطبيعة المتنوعة والمعقدة.
                </p>
              </div>
            </div>

            {/* Bottom accent line */}
            <div className="mt-10 pt-8 border-t border-slate-100 dark:border-white/10 flex flex-wrap items-center justify-between gap-4 text-xs font-semibold text-slate-500 dark:text-slate-400">
              <span className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-gold" />
                معايير هندسية معتمدة وموثقة
              </span>
              <span className="font-mono text-gold font-bold">AL-FADA AL-WASAA STANDARDS</span>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
