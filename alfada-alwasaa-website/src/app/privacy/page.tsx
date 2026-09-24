import type { Metadata } from "next";
import Link from "next/link";
import { ShieldCheck, ChevronLeft, Lock, FileText, CheckCircle2 } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { SiteHeader } from "@/components/site/header";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

export const metadata: Metadata = {
  title: "سياسة الخصوصية وسرية البيانات | شركة الفضاء الواسع",
  description: "سياسة الخصوصية وحماية وسرية البيانات التجارية والهندسية لعملاء وشركاء شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة.",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/privacy",
    languages: {
      ar: "https://www.alfadaalwasaa.com/privacy",
      en: "https://www.alfadaalwasaa.com/en/privacy",
    },
  },
  openGraph: {
    title: "سياسة الخصوصية وسرية البيانات | شركة الفضاء الواسع",
    description: "الالتزام المؤسسي بحماية وسرية بيانات العملاء والمشروعات.",
    url: "https://www.alfadaalwasaa.com/privacy",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "سياسة الخصوصية - شركة الفضاء الواسع" }],
    locale: "ar_YE",
    type: "website",
  },
};

export default function PrivacyPolicyPage() {
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
        name: "سياسة الخصوصية",
        item: "https://www.alfadaalwasaa.com/privacy",
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
              <span className="text-gold-light font-bold">سياسة الخصوصية</span>
            </nav>

            <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
              <ShieldCheck className="h-4 w-4 text-gold" />
              الانضباط والسرية المؤسسية
            </span>

            <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
              سياسة الخصوصية وسرية البيانات
            </h1>

            <p className="mt-4 text-sm sm:text-base leading-7 text-white/80 max-w-2xl">
              تلتزم شركة الفضاء الواسع بأعلى معايير حماية البيانات والسرية المهنية لكافة المعلومات والمخططات الهندسية والمراسلات التجارية لعملائنا وشركائنا.
            </p>

            <div className="mt-6 flex items-center gap-4 text-xs text-gold-soft/80 border-t border-white/10 pt-4">
              <span>تاريخ آخر تحديث: 2026</span>
              <span>•</span>
              <span>سارية المفعول لجميع التعاملات</span>
            </div>
          </div>
        </section>

        {/* Content Body */}
        <section className="py-12 sm:py-16 bg-white dark:bg-navy">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <div className="prose prose-slate dark:prose-invert max-w-none space-y-10 text-justify text-sm sm:text-base leading-8 text-slate-700 dark:text-slate-200">
              {/* Introduction */}
              <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy-darker/60 p-6 sm:p-8">
                <h2 className="flex items-center gap-2.5 text-xl font-bold text-navy dark:text-white mb-3">
                  <Lock className="h-5 w-5 text-gold shrink-0" />
                  <span>1. التزامنا العام بحماية الخصوصية</span>
                </h2>
                <p>
                  تدرك {SITE_CONFIG.company.fullName} أهمية الخصوصية والسرية المطلقة للمعلومات الفنية والتجارية المتعلقة بالمشروعات الإنشائية، شبكات الاتصالات، التوريدات، والمعاملات الجمركية. تحدد هذه الوثيقة بوضوح كيفية تعاملنا مع البيانات المدخلة عبر الموقع الرسمي أو قنوات التواصل المعتمدة.
                </p>
              </div>

              {/* Data Collected */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  2. البيانات التي نقوم بجمعها
                </h2>
                <p>
                  نقوم بجمع البيانات الضرورية فقط لغرض دراسة عروض الأسعار، الرد على الاستفسارات، وتوثيق المعاملات في نظام المراسلات المركزي:
                </p>
                <ul className="mt-4 space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>بيانات الهوية والتواصل:</strong> الاسم، المسمى الوظيفي، اسم الجهة أو الشركة، رقم الهاتف، والبريد الإلكتروني.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>تفاصيل المشروعات والعروض:</strong> جداول الكميات (BOQ)، المخططات، والمواصفات الفنية المرفوعة لدراسة الأسعار.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span><strong>البيانات التقنية للتصفح:</strong> عنوان الـ IP، نوع المتصفح، تفضيلات اللغة، وملفات تعريف الارتباط الضرورية لتشغيل وتأمين الجلسة.</span>
                  </li>
                </ul>
              </div>

              {/* Purpose of Use */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  3. أوجه استخدام البيانات
                </h2>
                <p>
                  تُستخدم البيانات المستلمة حصرياً للأغراض التشغيلية والتعاقدية المباشرة التالية:
                </p>
                <ul className="mt-4 space-y-2 list-none ps-0">
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>إعداد وتقديم الدراسات الفنية وعروض الأسعار التنافسية.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>توثيق المعاملات وإصدار أرقام مرجعية ورموز تتبع لمتابعة المعاملة إلكترونياً.</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-gold" />
                    <span>تنسيق العمليات الميدانية واللوجستية وفق متطلبات كل قطاع تنفيذي.</span>
                  </li>
                </ul>
              </div>

              {/* Confidentiality & Non-Disclosure */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  4. سرية المخططات والوثائق (Non-Disclosure)
                </h2>
                <p>
                  تخضع كافة المخططات الهندسية، وثائق المناقصات، جداول التوريدات، والعقود لبروتوكول سرية صارم. لا يتم بيع أو تأجير أو مشاركة أي معلومة مع أي طرف ثالث لأغراض دعائية أو ترويجية على الإطلاق، وتقتصر إتاحة البيانات على الكادر الهندسي والإداري المعني بالمشروع فقط.
                </p>
              </div>

              {/* Cookies */}
              <div>
                <h2 className="text-xl font-bold text-navy dark:text-white mb-4">
                  5. ملفات تعريف الارتباط (Cookies)
                </h2>
                <p>
                  يستخدم موقعنا ملفات تعريف الارتباط الأساسية لتمكين وظائف حيوية مثل حفظ تفضيل المظهر (فاتح / داكن)، تفضيل اللغة (عربي / إنجليزي)، وتسهيل تتبع المعاملات عبر حفظ الرمز المرجعي الآمن على جهاز المستخدم محلياً (LocalStorage). يمكن للمستخدم إدارة هذه التفضيلات عبر متصفحه في أي وقت.
                </p>
              </div>

              {/* Contact for Privacy */}
              <div className="rounded-3xl border border-gold/40 bg-gold/5 dark:bg-gold/10 p-6 sm:p-8">
                <h3 className="flex items-center gap-2 text-lg font-black text-navy dark:text-gold-light mb-2">
                  <FileText className="h-5 w-5 text-gold shrink-0" />
                  <span>التواصل مع مسؤول الخصوصية وحماية البيانات</span>
                </h3>
                <p className="text-sm leading-7 text-slate-700 dark:text-slate-300">
                  إذا كانت لديكم أي استفسارات أو طلبات تتعلق ببياناتكم أو إجراءات السرية المتبعة، يمكنكم التواصل المباشر مع إدارة الامتثال والتوثيق عبر البريد الرسمي:{" "}
                  <a href={SITE_CONFIG.contacts.email.mailHref} className="font-bold text-gold underline">
                    {SITE_CONFIG.contacts.email.address}
                  </a>{" "}
                  أو الاتصال المباشر على الهاتف: <span dir="ltr" className="font-bold text-gold">{SITE_CONFIG.contacts.general.display}</span>.
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
