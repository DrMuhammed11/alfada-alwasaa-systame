import { Handshake } from "lucide-react";
import { Reveal } from "./reveal";

export function Conclusion() {
  return (
    <section id="conclusion" className="relative overflow-hidden bg-mist pt-14 pb-6 sm:pt-16 sm:pb-8">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <Reveal className="mb-8 sm:mb-10 text-center">
          <h2 className="gold-rule center inline-block pb-2 text-3xl font-extrabold text-navy sm:text-4xl lg:text-[2.75rem]">
            خاتمة تعريفية
          </h2>
        </Reveal>

        <Reveal delay={0.12}>
          <div className="relative pt-8">
            {/* Navy card with the handshake emblem, echoing the profile closing page */}
            <div className="relative rounded-[2rem] bg-navy px-7 py-10 text-center shadow-[0_35px_90px_-35px_rgba(5,30,49,0.8)] sm:px-12 sm:py-12">
              <div className="absolute -top-12 start-1/2 -translate-x-1/2">
                <span className="flex h-24 w-24 items-center justify-center rounded-full border-[5px] border-mist bg-navy text-gold-light shadow-lg">
                  <Handshake className="h-11 w-11" strokeWidth={1.6} />
                </span>
              </div>

              {/* Exact closing text from the profile */}
              <p className="mt-6 text-justify leading-9 text-white/95 sm:text-[1.15rem] sm:leading-10">
                شركة الفضاء الواسع لخدمات الاتصالات والمقاولات ليست مجرد اسم في السوق، بل
                منصة عمل متكاملة تجمع بين القوة في التنفيذ، والرقّي في التعامل، والدقة في
                الأداء. وهي اليوم تضع بين يدي عملائها خبرة عملية، ورؤية واضحة، وقدرة
                حقيقية على تحويل المتطلبات إلى إنجازات ملموسة.
              </p>

              <span aria-hidden className="mx-auto mt-8 block h-1 w-28 rounded-full bg-gold" />
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
