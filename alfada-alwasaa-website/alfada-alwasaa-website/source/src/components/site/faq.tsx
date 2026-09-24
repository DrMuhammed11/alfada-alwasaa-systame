"use client";

import { useState } from "react";
import { ChevronDown, HelpCircle, Sparkles } from "lucide-react";
import { SectionHeading } from "./section-heading";
import { Reveal } from "./reveal";

export const FAQ_ITEMS = [
  {
    question: "ما هي النطاقات الجغرافية ومناطق تغطية الشركة لتنفيذ المشاريع؟",
    answer:
      "تغطي شركة الفضاء الواسع كافة محافظات ومناطق الجمهورية اليمنية، مع جاهزية متخصصة لتنفيذ المشاريع المدنية وشبكات الاتصالات في التضاريس الجبلية والمواقع النائية، بالإضافة إلى إدارة العمليات اللوجستية والتخليص الجمركي عبر كافة الموانئ والمنافذ الحيوية.",
  },
  {
    question: "كيف تبدأ آلية التعاقد وطلب عروض الأسعار والدراسات الهندسية؟",
    answer:
      "تبدأ الإجراءات بتقديم العميل لمتطلبات المشروع أو جداول الكميات عبر نموذج الموقع أو التواصل المباشر مع الإدارة العامة. يقوم فريقنا الهندسي بدراسة المواصفات وإجراء المسوحات الميدانية اللازمة لتقديم عرض فني ومالي منضبط ومفصل خلال وقت قياسي.",
  },
  {
    question: "ما هي معايير الجودة والسلامة المتبعة أثناء تنفيذ الأعمال والمشاريع؟",
    answer:
      "نطبق معايير الجودة الهندسية والمواصفات القياسية المعتمدة لكل قطاع، مع الالتزام الصارم بضوابط السلامة والصحة المهنية والبيئية (HSE)، وضمان الرقابة والفحص المخبري المستمر لكافة المواد والمعدات المستخدمة حتى التسليم النهائي.",
  },
  {
    question: "ما هي الجاهزية التشغيلية والأسطول المتوفر لدى الشركة في أعمال الطرق والإنشاءات؟",
    answer:
      "تمتلك الشركة أسطولاً متكاملاً من المعدات والآليات الثقيلة (آليات التسوية، الحفارات، المداحل، والشاحنات)، مدعومة بكوادر مساحية واستشارية متمرسة لإنجاز مشاريع شق وسفلتة الطرق وتسوية المواقع الكبرى بأعلى كفاءة.",
  },
  {
    question: "كيف تُدار عمليات الشحن والتخليص الجمركي وسلاسل التوريد؟",
    answer:
      "ندير سلاسل التخليص الجمركي والشحن متعدد الوسائط عبر فريق متخصص في الموانئ والمنافذ لإنهاء المعاملات النظامية وتدقيق الوثائق دون تأخير، مع توفير أساطيل النقل المؤمنة لضمان وصول الشحنات والمعدات لمواقع العمل بأمان تام.",
  },
  {
    question: "هل تقدم الشركة خدمات الصيانة والدعم الفني الطارئ لأبراج الاتصالات؟",
    answer:
      "نعم، تخصص الشركة فرق عمل هندسية وميدانية بنظام الطوارئ على مدار الساعة (24/7) لأعمال الصيانة الوقائية والطارئة، تركيب وتوجيه المايكروويف، وتزويد المحطات بحلول الطاقة المتجددة والهجينة لضمان استقرار الشبكات.",
  },
];

export function Faq() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIndex((prev) => (prev === idx ? null : idx));
  };

  // Structured Data (JSON-LD) لمطابقة محركات البحث Google FAQ Schema
  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQ_ITEMS.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };

  return (
    <section id="faq" className="relative overflow-hidden bg-white dark:bg-navy-darker py-12 sm:py-16 transition-colors duration-300">
      {/* Schema Script for Google Rich Snippets */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />

      <div className="relative mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          center
          kicker="معلومات وإيضاحات"
          title="الأسئلة الشائعة"
        />

        <Reveal delay={0.08}>
          <p className="-mt-6 text-center text-sm sm:text-base leading-7 text-slate-600 dark:text-slate-300 mb-8 max-w-2xl mx-auto">
            إجابات واضحة ومباشرة حول منهجية عمل الشركة، معايير التنفيذ، وآليات التعاقد لخدمة شركائنا في مختلف القطاعات.
          </p>
        </Reveal>

        <div className="space-y-3.5">
          {FAQ_ITEMS.map((item, idx) => {
            const isOpen = openIndex === idx;
            return (
              <Reveal key={idx} index={idx}>
                <div
                  className={`rounded-2xl border transition-all duration-300 ${
                    isOpen
                      ? "border-gold/50 bg-mist/60 dark:bg-navy/80 shadow-md ring-1 ring-gold/20"
                      : "border-navy/10 dark:border-white/10 bg-white dark:bg-navy/40 hover:border-gold/30 hover:bg-slate-50 dark:hover:bg-navy/60"
                  }`}
                >
                  <button
                    type="button"
                    onClick={() => toggle(idx)}
                    aria-expanded={isOpen}
                    className="flex w-full items-center justify-between gap-4 p-4 sm:p-5 text-right font-extrabold text-navy dark:text-white"
                  >
                    <div className="flex items-center gap-3">
                      <span
                        className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-xl text-xs font-bold transition-colors ${
                          isOpen
                            ? "bg-gold text-navy-darker shadow-sm"
                            : "bg-navy/5 text-navy dark:bg-white/10 dark:text-gold-light"
                        }`}
                      >
                        <HelpCircle className="h-4 w-4" />
                      </span>
                      <span className="text-sm sm:text-base leading-snug">
                        {item.question}
                      </span>
                    </div>
                    <ChevronDown
                      className={`h-4 w-4 shrink-0 text-gold transition-transform duration-300 ${
                        isOpen ? "rotate-180" : ""
                      }`}
                    />
                  </button>

                  {/* أكورديون CSS خالص: تقنية grid-rows (بديل AnimatePresence) —
                      invisible تُبقي المحتوى خارج ترتيب التبويب عند الإغلاق */}
                  <div
                    className={`grid transition-all duration-300 ease-in-out ${
                      isOpen
                        ? "grid-rows-[1fr] opacity-100 visible"
                        : "grid-rows-[0fr] opacity-0 invisible"
                    }`}
                  >
                    <div className="overflow-hidden">
                      <div className="border-t border-navy/5 dark:border-white/10 px-4 sm:px-5 pb-5 pt-3 text-xs sm:text-sm leading-7 text-slate-600 dark:text-slate-300">
                        <p>{item.answer}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </Reveal>
            );
          })}
        </div>

        {/* CTA prompt below FAQ */}
        <Reveal delay={0.2} className="mt-8 text-center">
          <div className="inline-flex items-center gap-2 rounded-2xl border border-navy/10 dark:border-white/10 bg-mist dark:bg-navy/80 px-5 py-3 text-xs sm:text-sm text-slate-700 dark:text-slate-200">
            <Sparkles className="h-4 w-4 text-gold shrink-0" />
            <span>لديك استفسار آخر أو متطلبات خاصة بمشروعك؟</span>
            <a
              href="#contact"
              className="font-bold text-navy dark:text-gold-light underline hover:text-gold transition"
            >
              تواصل مع الفريق الهندسي مباشرة
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
