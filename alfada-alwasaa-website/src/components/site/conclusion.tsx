import { Handshake } from "lucide-react";
import { Reveal } from "./reveal";

export function Conclusion() {
  return (
    <section id="conclusion" className="relative overflow-hidden bg-mist dark:bg-navy-darker/60 py-12 sm:py-16 transition-colors duration-300">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mb-8 sm:mb-10 text-center">
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
            شريككم الاستراتيجي
          </span>
          <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white sm:text-4xl lg:text-[2.75rem]">
            خاتمة وتطلعات
          </h2>
        </Reveal>

        <Reveal delay={0.12}>
          <div className="relative pt-10">
            {/* Ambient glow behind card */}
            <div
              aria-hidden
              className="pointer-events-none absolute inset-x-12 top-6 bottom-0 rounded-[2.5rem] bg-gradient-to-r from-gold/20 via-gold-light/10 to-transparent blur-2xl opacity-60"
            />
            {/* Navy card with the handshake emblem */}
            <div className="relative rounded-[2.5rem] bg-gradient-to-br from-navy via-navy-deep to-navy-darker px-7 py-10 text-center shadow-[0_35px_90px_-35px_rgba(5,30,49,0.8)] sm:px-12 sm:py-14 border border-white/15">
              <div className="absolute -top-12 start-1/2 -translate-x-1/2">
                <span className="flex h-24 w-24 items-center justify-center rounded-full border-[5px] border-mist dark:border-navy-darker bg-navy text-gold-light shadow-xl ring-2 ring-gold/40">
                  <Handshake className="h-11 w-11" strokeWidth={1.8} />
                </span>
              </div>

              {/* Exact closing text from the profile */}
              <p className="mt-6 text-justify sm:text-center leading-9 text-white/95 sm:text-[1.15rem] sm:leading-10 max-w-3xl mx-auto">
                إن شركة الفضاء الواسع ليست مجرد اسم في سوق المقاولات والاتصالات، بل هي
                منصة متكاملة للعمل الجاد، والسلوك المهني الرفيع، والإنجاز الموثوق. اليوم،
                نضع خبراتنا وإمكاناتنا في خدمة عملائنا، مستعدين للمضي معهم نحو آفاق
                أوسع وأهداف أكبر.
              </p>

              <div className="mt-8 flex items-center justify-center gap-3">
                <span className="h-0.5 w-10 bg-gradient-to-r from-transparent to-gold rounded-full" />
                <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
                <span className="h-0.5 w-10 bg-gradient-to-l from-transparent to-gold rounded-full" />
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default Conclusion;
