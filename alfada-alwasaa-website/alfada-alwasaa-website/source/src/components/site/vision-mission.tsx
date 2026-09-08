import { Eye, HandHeart } from "lucide-react";
import { Reveal } from "./reveal";

export function VisionMission() {
  return (
    <section id="vision" className="relative overflow-hidden bg-white py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mb-16 text-center">
          <h2 className="gold-rule center inline-block pb-2 text-3xl font-extrabold text-navy sm:text-4xl lg:text-[2.75rem]">
            رؤيتنا ورسالتنا
          </h2>
        </Reveal>

        <div className="grid gap-16 md:grid-cols-2 md:gap-10 lg:gap-14">
          {/* رسالتنا */}
          <Reveal delay={0.1}>
            <div className="relative pt-16">
              <div className="group relative rounded-3xl border border-navy/10 bg-white p-8 pt-12 shadow-[0_20px_55px_-30px_rgba(10,52,83,0.3)] transition-all duration-500 hover:-translate-y-1 hover:shadow-[0_28px_70px_-30px_rgba(10,52,83,0.4)] sm:p-10 sm:pt-14">
                <div className="absolute -top-12 start-1/2 flex -translate-x-1/2 flex-col items-center">
                  {/* gold arc like the profile cards */}
                  <span
                    aria-hidden
                    className="absolute -top-7 h-16 w-40 rounded-t-full border-[3px] border-b-0 border-gold/80"
                  />
                  <span aria-hidden className="absolute -top-8.5 start-0 h-2.5 w-2.5 -translate-y-1/2 rounded-full bg-gold" />
                  <span aria-hidden className="absolute -top-8.5 end-0 h-2.5 w-2.5 -translate-y-1/2 rounded-full bg-gold" />
                  <span className="flex h-24 w-24 items-center justify-center rounded-full bg-white text-navy shadow-[0_12px_35px_-10px_rgba(10,52,83,0.35)] ring-1 ring-navy/10 transition-colors duration-500 group-hover:bg-navy group-hover:text-gold-light">
                    <HandHeart className="h-11 w-11" strokeWidth={1.6} />
                  </span>
                </div>

                <h3 className="mt-4 text-center text-3xl font-black text-navy">
                  رسالتنا
                </h3>
                <span aria-hidden className="mx-auto mt-3 block h-1 w-24 rounded-full bg-gold" />
                <p className="mt-6 text-justify text-[1.05rem] leading-9 text-slate-700">
                  نسعى إلى تقديم خدمات موثوقة ومتكاملة تركز على الجودة، والشفافية،
                  والانضباط، والاحترافية في التنفيذ، مع الالتزام الكامل بمتطلبات العميل،
                  وتحقيق أعلى مستويات الرضا والثقة.
                </p>
              </div>
            </div>
          </Reveal>

          {/* رؤيتنا */}
          <Reveal delay={0.22}>
            <div className="relative pt-16">
              <div className="group relative rounded-3xl border border-navy/10 bg-white p-8 pt-12 shadow-[0_20px_55px_-30px_rgba(10,52,83,0.3)] transition-all duration-500 hover:-translate-y-1 hover:shadow-[0_28px_70px_-30px_rgba(10,52,83,0.4)] sm:p-10 sm:pt-14">
                <div className="absolute -top-12 start-1/2 flex -translate-x-1/2 flex-col items-center">
                  <span
                    aria-hidden
                    className="absolute -top-7 h-16 w-40 rounded-t-full border-[3px] border-b-0 border-gold/80"
                  />
                  <span aria-hidden className="absolute -top-8.5 start-0 h-2.5 w-2.5 -translate-y-1/2 rounded-full bg-gold" />
                  <span aria-hidden className="absolute -top-8.5 end-0 h-2.5 w-2.5 -translate-y-1/2 rounded-full bg-gold" />
                  <span className="flex h-24 w-24 items-center justify-center rounded-full bg-white text-navy shadow-[0_12px_35px_-10px_rgba(10,52,83,0.35)] ring-1 ring-navy/10 transition-colors duration-500 group-hover:bg-navy group-hover:text-gold-light">
                    <Eye className="h-11 w-11" strokeWidth={1.6} />
                  </span>
                </div>

                <h3 className="mt-4 text-center text-3xl font-black text-navy">
                  رؤيتنا
                </h3>
                <span aria-hidden className="mx-auto mt-3 block h-1 w-24 rounded-full bg-gold" />
                <p className="mt-6 text-justify text-[1.05rem] leading-9 text-slate-700">
                  أن نكون من الشركات الرائدة في تقديم الخدمات المتكاملة في مجالات
                  المقاولات والاتصالات والخدمات المساندة، من خلال بناء علاقات استراتيجية
                  طويلة الأمد مع عملائنا، وتحقيق قيمة مضافة حقيقية في كل مشروع نتولاه.
                </p>
              </div>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
