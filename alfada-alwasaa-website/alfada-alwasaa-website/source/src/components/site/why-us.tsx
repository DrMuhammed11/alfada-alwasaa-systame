import { Reveal } from "./reveal";
import { SITE_CONFIG } from "@/config/site";

export function WhyUs() {

  return (
    <section id="why" className="relative overflow-hidden bg-white dark:bg-navy-darker py-12 sm:py-16 transition-colors duration-300">
      <div className="relative mx-auto grid max-w-6xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-[0.9fr_1.1fr] lg:gap-14 lg:px-8">
        {/* "لماذا نحن؟" visual echoing the profile page */}
        <Reveal>
          <div className="relative mx-auto flex aspect-square w-full max-w-md items-center justify-center rounded-[2.5rem] bg-mist dark:bg-navy border border-navy/10 dark:border-white/10 shadow-lg shadow-navy/5">
            <div
              aria-hidden
              className="absolute inset-5 rounded-[2rem] border-2 border-dashed border-gold/30 dark:border-gold/20"
            />
            <div className="relative flex h-56 w-56 items-center justify-center rounded-full border-[3px] border-navy dark:border-gold shadow-md sm:h-64 sm:w-64 bg-white/40 dark:bg-navy-darker/40 backdrop-blur-sm">
              <span aria-hidden className="absolute -top-1.5 right-1/2 h-3 w-3 translate-x-1/2 rounded-full bg-gold shadow-sm" />
              <span aria-hidden className="absolute -bottom-1.5 right-1/2 h-3 w-3 translate-x-1/2 rounded-full bg-gold shadow-sm" />
              <span aria-hidden className="absolute -end-1.5 top-1/2 h-3 w-3 -translate-y-1/2 rounded-full bg-gold shadow-sm" />
              <span
                aria-hidden
                className="absolute -bottom-6 -start-4 select-none text-[4.5rem] font-black leading-none text-gold/80 sm:-bottom-8 sm:-start-6 sm:text-[6rem]"
              >
                ؟
              </span>
              <span className="text-center text-3xl font-black text-navy dark:text-white sm:text-4xl">
                لماذا نحن؟
              </span>
            </div>
          </div>
        </Reveal>

        {/* Exact paragraph from the profile */}
        <div>
          <Reveal delay={0.1}>
            <span className="mb-3 inline-block rounded-full bg-gold/15 px-4 py-1.5 text-xs font-bold tracking-wide text-navy dark:text-gold-light border border-gold/30">
              قيمنا في العمل والريادة
            </span>
          </Reveal>
          <Reveal delay={0.16}>
            <p className="text-justify text-lg leading-9 text-slate-700 dark:text-slate-200 sm:text-[1.15rem] sm:leading-10">
              نحن نؤمن بأن التميز لا يُقاس بكم الخدمات فقط، بل بقدرة الشركة على تقديمها
              بجودة ثابتة وصورة مؤسسية تليق بالشركاء الكبار. نحن نعمل بعقلية النتائج،
              ونُدار بمنهجية واضحة، ونلتزم بأن يكون كل مشروع امتدادًا لسمعة الشركة وثقة
              عملائها.
            </p>
          </Reveal>

          <Reveal delay={0.24}>
            <div className="mt-6 sm:mt-8 grid gap-4 sm:grid-cols-3">
              {SITE_CONFIG.values.map((item, idx) => (
                <Reveal key={item.title} index={idx} delay={0.24}>
                  <div
                    className="group relative h-full rounded-2xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-5 shadow-sm transition-all duration-300 hover:-translate-y-1.5 hover:border-gold/60 hover:shadow-xl hover:bg-slate-50/50 dark:hover:bg-navy-deep"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <span className="inline-block h-2 w-8 rounded-full bg-gold transition-all duration-300 group-hover:w-14" />
                      <span className="font-mono text-[10px] font-black text-gold-dark dark:text-gold-light bg-gold/10 px-2 py-0.5 rounded-md">
                        0{idx + 1}
                      </span>
                    </div>
                    <h4 className="mt-2 text-base font-extrabold text-navy dark:text-white">
                      {item.title}
                    </h4>
                    <p className="mt-2 text-xs leading-6 text-slate-600 dark:text-slate-300">
                      {item.desc}
                    </p>
                  </div>
                </Reveal>
              ))}
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
