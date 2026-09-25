"use client";

import { useState } from "react";
import { ChevronDown, HelpCircle, Sparkles } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { Reveal } from "./reveal";

export interface EnFaqEntry { readonly question: string; readonly answer: string }

export function EnFaq({ items = EN_SITE_CONFIG.faq as unknown as EnFaqEntry[] }: { items?: EnFaqEntry[] }) {
  const [faqOpenIndex, setFaqOpenIndex] = useState<number | null>(0);

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  };

  return (
    <section id="faq" className="py-16 bg-white dark:bg-navy-darker transition-colors duration-300">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <Reveal>
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light border border-gold/30">
              Frequently Asked Questions
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white sm:text-4xl">
              Essential Procedures & Inquiries
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Clear, direct answers regarding execution methodology, quality compliance, and contracting procedures.
            </p>
          </div>
        </Reveal>

        <div className="space-y-3.5">
          {items.map((item, idx) => {
            const isOpen = faqOpenIndex === idx;
            return (
              <Reveal key={idx} index={idx}>
                <div
                  className={`rounded-2xl border transition-all duration-300 ${
                    isOpen
                      ? "border-gold/50 bg-slate-50/80 dark:bg-navy/80 shadow-md ring-1 ring-gold/20"
                      : "border-navy/10 dark:border-white/10 bg-white dark:bg-navy/40 hover:border-gold/30 hover:bg-slate-50 dark:hover:bg-navy/60"
                  }`}
                >
                  <button
                    type="button"
                    onClick={() => setFaqOpenIndex(isOpen ? null : idx)}
                    aria-expanded={isOpen}
                    className="flex w-full items-center justify-between gap-4 p-4 sm:p-5 text-left font-bold text-navy dark:text-white"
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
                      <span className="text-sm sm:text-base leading-snug">{item.question}</span>
                    </div>
                    <ChevronDown
                      className={`h-4 w-4 shrink-0 text-gold transition-transform duration-300 ${
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
                      <div className="px-4 sm:px-5 pb-5 pt-2 text-xs sm:text-sm leading-relaxed text-slate-600 dark:text-slate-300 border-t border-navy/5 dark:border-white/10">
                        {item.answer}
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
          <div className="inline-flex items-center gap-2 rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy/80 px-5 py-3 text-xs sm:text-sm text-slate-700 dark:text-slate-200">
            <Sparkles className="h-4 w-4 text-gold shrink-0" />
            <span>Have custom inquiries or specific project requirements?</span>
            <a
              href="#contact"
              className="font-bold text-navy dark:text-gold-light underline hover:text-gold transition"
            >
              Direct Project Consultation
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

export default EnFaq;
