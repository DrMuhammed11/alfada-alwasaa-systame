import type { Metadata } from "next";
import Link from "next/link";
import { Scale, ChevronLeft, CheckCircle2, ShieldAlert } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { SiteHeader } from "@/components/site/header";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

export const metadata: Metadata = {
  title: "الشروط والأحكام والضوابط التعاقدية | شركة الفضاء الواسع",
  description: "الشروط والأحكام المنظمة للتعاملات التجارية وعروض الأسعار والخدمات الهندسية والميدانية لشركة الفضاء الواسع.",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/terms",
    languages: {
      ar: "https://www.alfadaalwasaa.com/terms",
      en: "https://www.alfadaalwasaa.com/en/terms",
    },
  },
  openGraph: {
    title: "الشروط والأحكام | شركة الفضاء الواسع",
    description: "الضوابط والشروط الرسمية المعتمدة لتقديم الخدمات الهندسية والتعاقدات.",
    url: "https://www.alfadaalwasaa.com/terms",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "الشروط والأحكام - شركة الفضاء الواسع" }],
    locale: "ar_YE",
    type: "website",
  },
};

export default function TermsPage() {
  const breadcrumbSchema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "الرئيسية",
        item: "https://www.alfadaalwasaa.com",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "الشروط والأحكام",
        item: "https://www.alfadaalwasaa.com/terms",
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 dark:bg-navy-darker text-slate-900 dark:text-slate-100 transition-colors">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SiteHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-14 text-white sm:py-20">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">الشروط والأحكام</span>
            </nav>

            <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
              <Scale className="h-4 w-4 text-gold" />
              الضوابط والأطر التعاقدية
            </span>

            <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
              الشروط والأحكام الرسمية
            </h1>

            <p className="mt-4 text-sm sm:text-base leading-7 text-white/80 max-w-2xl">
              تحدد هذه الوثيقة القواعد والأحكام العامة المنظمة لاستخدام البوابة الإلكترونية وتقديم الطلبات والتعاملات التجارية مع شركة الفضاء الواسع.
            </p>

            <div className="mt-6 flex items-center gap-4 text-xs text-gold-soft/80 border-t border-white/10 pt-4">
              <span>الإصدار الرسمي: 2026</span>
              <span>•</span>
              <span>تنطبق على كافة المعاملات والمراسلات</span>
            </div>
          </div>
        </section>

        {/* Content Body */}
        <section className="py-12 sm:py-16 bg-white dark:bg-navy">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <div className="prose prose-slate dark:prose-invert max-w-none space-y-10 text-justify text-sm sm:text-base leading-8 text-slate-700 dark:text-slate-200">
              {/* Preamble */}
              <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy-darker/60 p-6 sm:p-8">
                <h2 className="text-xl font-bold text-navy dark:text-white mb-3">
                  1. التمهيد ونطاق التطبيق
                </h2>
                <p>
                  يخضع استخدام هذا الموقع وكافة التعاملات المنبثقة عنه لأحكام هذه الشروط. استخدامك للموقع أو إرسالك لطلب عرض سعر أو استشارة يُعد موافقة صريحة على الالتزام بهذه الضوابط والاشتراطات المهنية المعتمدة لدى {SITE_CONFIG.company.fullName}.
                </p>
              </div>

              {/* Quotations & Proposals */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  2. عروض الأسعار والتقديرات الفنية
                </h2>
                <ul className="space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>تُعد عروض الأسعار والدراسات الأولية المقدمة عبر الموقع أو البريد الإلكتروني استرشادية، ولا تصبح نهائية وملزمة إلا بعد توقيع العقد الرسمي وجداول الكميات المعتمدة بين الطرفين.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>تحتفظ الشركة بحق تعديل الأسعار بناءً على المسوحات الميدانية وتغير تكاليف المواد الخام أو أسعار الصرف الرسمية قبل التوقيع النهائي.</span>
                  </li>
                </ul>
              </div>

              {/* Intellectual Property */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  3. حقوق الملكية الفكرية والعلامة التجارية
                </h2>
                <p>
                  كافة المحتويات المنشورة على هذا الموقع (بما فيها الشعار الرسمي، الاسم التجاري، الصور الميدانية الحصرية، النصوص التعريفية، والمخططات) هي ملكية حصرية لشركة الفضاء الواسع ومحمية بموجب القوانين والأنظمة المعمول بها. يُحظر نسخ أو إعادة نشر أي جزء دون إذن كتابي مسبق.
                </p>
              </div>

              {/* Force Majeure */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  4. القوة القاهرة والظروف الطارئة
                </h2>
                <p>
                  لا تتحمل الشركة أي مسؤولية عن أي تأخير في الردود أو تنفيذ الأعمال الميدانية ناجم عن ظروف قاهرة خارجة عن السيطرة، بما في ذلك الكوارث الطبيعية، الاضطرابات الأمنية، إغلاق الموانئ أو الطرق، أو القرارات الحكومية الطارئة.
                </p>
              </div>

              {/* Governing Law */}
              <div className="rounded-3xl border border-gold/40 bg-gold/5 dark:bg-gold/10 p-6 sm:p-8">
                <h3 className="flex items-center gap-2 text-lg font-black text-navy dark:text-gold-light mb-2">
                  <ShieldAlert className="h-5 w-5 text-gold shrink-0" />
                  <span>5. القانون الواجب التطبيق والاختصاص القضائي</span>
                </h3>
                <p className="text-sm leading-7 text-slate-700 dark:text-slate-300">
                  تخضع هذه الشروط وكافة الاتفاقيات والعقود المبرمة مع شركة الفضاء الواسع للقوانين والأنظمة والتشريعات التجارية النافذة في الجمهورية اليمنية، ويكون الاختصاص القضائي في أي نزاع لمحاكم أمانة العاصمة صنعاء.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}
