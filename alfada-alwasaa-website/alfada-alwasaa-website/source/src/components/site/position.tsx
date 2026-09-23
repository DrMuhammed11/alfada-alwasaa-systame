import { Gem } from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";

export function Position() {
  return (
    <section id="position" className="relative overflow-hidden bg-mist dark:bg-navy-darker/60 py-12 sm:py-16 transition-colors duration-300">
      <div className="mx-auto max-w-4xl px-4 text-center sm:px-6">
        <SectionHeading center kicker="مكانتنا" title="مكانة راسخة" />

        {/* Diamond emblem echoing the profile page */}
        <Reveal delay={0.1}>
          <div className="relative mx-auto mb-8 flex w-fit flex-col items-center">
            {/* gold arc */}
            <span
              aria-hidden
              className="absolute -top-9 h-24 w-56 rounded-t-full border-[3px] border-b-0 border-gold/70"
            />
            <span aria-hidden className="absolute -top-11 start-0 h-2.5 w-2.5 rounded-full bg-gold" />
            <span aria-hidden className="absolute -top-11 end-0 h-2.5 w-2.5 rounded-full bg-gold" />
            <span className="flex h-24 w-24 items-center justify-center rounded-full bg-navy text-gold-light shadow-[0_15px_40px_-12px_rgba(10,52,83,0.5)]">
              <Gem className="h-11 w-11" strokeWidth={1.6} />
            </span>
          </div>
        </Reveal>

        {/* Exact paragraphs from the profile */}
        <Reveal delay={0.16}>
          <p className="text-justify text-lg leading-9 text-slate-700 dark:text-slate-200 sm:text-[1.15rem] sm:leading-10">
            انطلقت الشركة من قناعة راسخة بأن الشركات الكبرى لا تبحث فقط عن منفذ خدمة، بل
            عن شريك يعتمد عليه. ولذلك، نولي اهتمامًا بالغًا بالتفاصيل الفنية، وسلامة
            الإجراءات، ودقة المتابعة، ووضوح التواصل في جميع مراحل العمل، بدءًا من التخطيط
            وحتى التسليم النهائي.
          </p>
        </Reveal>
        <Reveal delay={0.24}>
          <p className="mt-6 text-justify text-lg leading-9 text-slate-700 dark:text-slate-200 sm:text-[1.15rem] sm:leading-10">
            ونحرص على أن تعكس جميع أعمالنا صورة مؤسسية راقية تجمع بين الجدية والمرونة،
            وبين الجودة والسرعة، وبين الكفاءة الفنية والالتزام الكامل تجاه العميل. ومن هنا،
            أصبحت الشركة خيارًا مناسبًا للجهات التي تتطلع إلى تنفيذ أعمالها عبر فريق يفهم
            متطلبات السوق، ويجيد التعامل مع المشاريع ذات الطبيعة المتنوعة والمعقدة.
          </p>
        </Reveal>
      </div>
    </section>
  );
}
