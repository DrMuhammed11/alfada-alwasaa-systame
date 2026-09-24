"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export function EnFaq() {
  const [faqOpenIndex, setFaqOpenIndex] = useState<number | null>(0);

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: EN_SITE_CONFIG.faq.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };

  return (
    <section id="faq" className="py-16 bg-white dark:bg-navy-darker">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Frequently Asked Questions
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Essential Procedures & Inquiries
            </h2>
          </div>
        </Reveal>

        <div className="space-y-3">
          {EN_SITE_CONFIG.faq.map((item, idx) => {
            const isOpen = faqOpenIndex === idx;
            return (
              <Reveal key={idx} index={idx}>
                <div className="rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy/80 overflow-hidden">
                  <button
                    type="button"
                    onClick={() => setFaqOpenIndex(isOpen ? null : idx)}
                    aria-expanded={isOpen}
                    className="flex w-full items-center justify-between p-4 sm:p-5 text-left font-bold text-navy dark:text-white"
                  >
                    <span className="text-sm sm:text-base">{item.question}</span>
                    <ChevronDown
                      className={`h-4 w-4 text-gold transition-transform duration-300 ${
                        isOpen ? "rotate-180" : ""
                      }`}
                    />
                  </button>
                  <div
                    className={`grid transition-all duration-300 ease-out ${
                      isOpen
                        ? "grid-rows-[1fr] opacity-100 visible"
                        : "grid-rows-[0fr] opacity-0 invisible"
                    }`}
                  >
                    <div className="overflow-hidden">
                      <div className="px-4 sm:px-5 pb-5 pt-2 text-xs sm:text-sm leading-6 text-slate-600 dark:text-slate-300 border-t border-navy/5 dark:border-white/10">
                        {item.answer}
                      </div>
                    </div>
                  </div>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export default EnFaq;
