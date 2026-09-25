import { Eye, HandHeart } from "lucide-react";
import { Reveal } from "./reveal";

export function VisionMission() {
  return (
    <section id="vision" className="relative overflow-hidden bg-white dark:bg-navy-darker py-14 sm:py-20 transition-colors duration-300">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mb-12 sm:mb-16 text-center">
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
            الهوية والتوجه المؤسسي
          </span>
          <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white sm:text-4xl lg:text-[2.75rem]">
            رؤيتنا ورسالتنا
          </h2>
          <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300 max-w-2xl mx-auto">
            منظومة قيم ومبادئ تنفيذية توجه كافة عملياتنا لضمان استدامة الجودة وبناء شراكات وثيقة وموثوقة.
          </p>
        </Reveal>

        <div className="grid gap-8 md:grid-cols-2 lg:gap-10">
          {/* رسالتنا */}
          <Reveal delay={0.1}>
            <div className="group relative h-full overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 sm:p-10 shadow-md hover:shadow-2xl hover:border-gold/50 transition-all duration-300 hover:-translate-y-1.5">
              <div className="flex items-center justify-between mb-6">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold/20 text-gold-dark dark:text-gold-light border border-gold/40 shadow-xs transition-transform duration-300 group-hover:scale-110">
                  <HandHeart className="h-7 w-7 text-gold" strokeWidth={1.8} />
                </div>
                <span className="font-mono text-xs font-black text-gold-dark dark:text-gold-light bg-gold/10 px-3 py-1 rounded-full border border-gold/25">
                  MISSION
                </span>
              </div>

              <span className="h-1.5 w-14 rounded-full bg-gradient-to-r from-gold to-gold-light block mb-4 transition-all duration-300 group-hover:w-24" />

              <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white">
                رسالتنا
              </h3>
              <p className="mt-4 text-justify text-base sm:text-lg leading-8 sm:leading-9 text-slate-700 dark:text-slate-200">
                نسعى لتقديم خدمات موثوقة ومتكاملة ترتكز على الجودة، الشفافية، الانضباط،
                والسرعة في التنفيذ، مع الالتزام التام بمتطلبات عملائنا وتحقيق أعلى درجات
                الرضا والثقة.
              </p>
            </div>
          </Reveal>

          {/* رؤيتنا */}
          <Reveal delay={0.2}>
            <div className="group relative h-full overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 sm:p-10 shadow-md hover:shadow-2xl hover:border-gold/50 transition-all duration-300 hover:-translate-y-1.5">
              <div className="flex items-center justify-between mb-6">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold/20 text-gold-dark dark:text-gold-light border border-gold/40 shadow-xs transition-transform duration-300 group-hover:scale-110">
                  <Eye className="h-7 w-7 text-gold" strokeWidth={1.8} />
                </div>
                <span className="font-mono text-xs font-black text-gold-dark dark:text-gold-light bg-gold/10 px-3 py-1 rounded-full border border-gold/25">
                  VISION
                </span>
              </div>

              <span className="h-1.5 w-14 rounded-full bg-gradient-to-r from-gold to-gold-light block mb-4 transition-all duration-300 group-hover:w-24" />

              <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white">
                رؤيتنا
              </h3>
              <p className="mt-4 text-justify text-base sm:text-lg leading-8 sm:leading-9 text-slate-700 dark:text-slate-200">
                أن نكون الخيار الأول والنموذج الرائد محلياً وإقليمياً في مجالات المقاولات
                العامة، الاتصالات، والخدمات المساندة، من خلال بناء شراكات استراتيجية
                مستدامة مع عملائنا والمساهمة الفاعلة في تنمية المجتمع.
              </p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

export default VisionMission;
