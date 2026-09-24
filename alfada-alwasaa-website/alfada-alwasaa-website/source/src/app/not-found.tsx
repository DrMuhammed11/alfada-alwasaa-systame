"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Home, Briefcase, Phone, MessageSquare, ArrowRight } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { EN_SITE_CONFIG } from "@/config/en-site";

/** الحقول المشتركة المستخدمة من إعدادات الموقع باللغتين */
interface SiteConfigLike {
  company: { fullName: string; tagline: string };
  contacts: { general: { display: string; telHref: string; waHref: string } };
}

/** نصوص الواجهة بنفس أسلوب مكوّن الكوكيز — نسخة لكل لغة */
interface NotFoundTexts {
  logoAlt: string;
  heading: string;
  description: string;
  backHome: string;
  exploreServices: string;
  helpTitle: string;
  helpBody: string;
  callLabel: string;
  whatsapp: string;
  contactForm: string;
  rights: string;
}

const T_AR: NotFoundTexts = {
  logoAlt: "شعار شركة الفضاء الواسع",
  heading: "الصفحة غير موجودة",
  description:
    "عذراً، الرابط الذي تبحث عنه غير متاح أو تم نقله أو قد تم تحديث هيكل الموقع. يسعدنا مساعدتك في الوصول إلى وجهتك المطلوبة.",
  backHome: "العودة للصفحة الرئيسية",
  exploreServices: "استعراض خدماتنا",
  helpTitle: "هل تحتاج إلى مساعدة أو طلب استشارة مباشرة؟",
  helpBody:
    "فريق خدمة العملاء متاح للرد على كافة الاستفسارات وتلبية متطلبات المشاريع.",
  callLabel: "اتصال مباشر",
  whatsapp: "محادثة واتساب سريعة",
  contactForm: "نموذج المراسلات والمتابعة",
  rights: "جميع الحقوق محفوظة.",
};

const T_EN: NotFoundTexts = {
  logoAlt: "Al-Fada Al-Wasaa logo",
  heading: "Page Not Found",
  description:
    "Sorry, the link you are looking for is unavailable, has been moved, or the site structure has been updated. We are glad to help you reach your destination.",
  backHome: "Back to Homepage",
  exploreServices: "Explore Our Services",
  helpTitle: "Need help or a direct consultation?",
  helpBody:
    "Our customer service team is available to answer all inquiries and meet project requirements.",
  callLabel: "Direct call",
  whatsapp: "Quick WhatsApp chat",
  contactForm: "Inquiry & tracking form",
  rights: "All rights reserved.",
};

function renderVariant(
  t: NotFoundTexts,
  config: SiteConfigLike,
  hrefs: { home: string; services: string; contact: string },
  dir: "rtl" | "ltr",
  lang: string,
  hidden: boolean
) {
  return (
    <div
      dir={dir}
      lang={lang}
      className={`relative min-h-screen flex flex-col justify-between bg-navy text-white overflow-hidden selection:bg-gold selection:text-navy-darker${
        hidden ? " hidden" : ""
      }`}
    >
      {/* خلفية هندسية متناسقة */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-navy-deep/80 via-navy to-navy-darker pointer-events-none" />

      {/* الرأس: شعار الشركة */}
      <header className="relative z-10 mx-auto w-full max-w-7xl px-6 pt-10 sm:px-8">
        <Link
          href={hrefs.home}
          className="inline-flex items-center gap-3 transition-opacity hover:opacity-90"
        >
          <div className="relative h-12 w-12 rounded-2xl bg-white/10 p-2 ring-1 ring-white/20 backdrop-blur-sm">
            <Image
              src={SITE_CONFIG.assets.logoMark}
              alt={t.logoAlt}
              fill
              sizes="48px"
              className="object-contain p-1"
            />
          </div>
          <div>
            <span className="block text-sm font-black text-white sm:text-base">
              {config.company.fullName}
            </span>
            <span className="block text-xs font-semibold text-gold-light">
              {config.company.tagline}
            </span>
          </div>
        </Link>
      </header>

      {/* المحتوى الرئيسي */}
      <main className="relative z-10 mx-auto my-auto w-full max-w-3xl px-6 py-16 text-center sm:px-8">
        {/* الرقم البارز 404 */}
        <div className="inline-block">
          <span className="font-mono text-8xl font-black tracking-tight text-transparent bg-clip-text bg-gradient-to-b from-gold-light via-gold to-gold-dark sm:text-9xl drop-shadow-sm">
            404
          </span>
        </div>

        {/* العناوين والرسائل التوضيحية */}
        <h1 className="mt-6 text-3xl font-black text-white sm:text-4xl">
          {t.heading}
        </h1>
        <p className="mx-auto mt-4 max-w-xl text-base leading-8 text-white/80 sm:text-lg">
          {t.description}
        </p>

        {/* أزرار الإجراءات الرئيسية */}
        <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
          <Link
            href={hrefs.home}
            className="inline-flex items-center gap-2 rounded-2xl bg-gold px-8 py-4 text-base font-extrabold text-navy-darker shadow-[0_15px_35px_-10px_rgba(198,149,74,0.5)] transition hover:bg-gold-light hover:shadow-[0_20px_40px_-10px_rgba(198,149,74,0.65)]"
          >
            <Home className="h-5 w-5" />
            <span>{t.backHome}</span>
          </Link>

          <Link
            href={hrefs.services}
            className="inline-flex items-center gap-2 rounded-2xl bg-white/10 px-8 py-4 text-base font-bold text-white ring-1 ring-white/20 backdrop-blur-sm transition hover:bg-white/20 hover:ring-gold/50"
          >
            <Briefcase className="h-5 w-5 text-gold-light" />
            <span>{t.exploreServices}</span>
          </Link>
        </div>

        {/* بطاقة التواصل السريع والدعم */}
        <div className="mt-14 rounded-3xl bg-white/5 p-6 ring-1 ring-white/10 backdrop-blur-md sm:p-8">
          <h2 className="text-sm font-bold text-gold-light">{t.helpTitle}</h2>
          <p className="mt-2 text-xs leading-6 text-white/70">{t.helpBody}</p>

          <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
            <a
              href={config.contacts.general.telHref}
              className="inline-flex items-center gap-2 rounded-xl bg-white/10 px-5 py-2.5 text-xs font-bold text-white transition hover:bg-gold hover:text-navy-darker"
            >
              <Phone className="h-3.5 w-3.5 text-gold" />
              <span>
                {t.callLabel}: {config.contacts.general.display}
              </span>
            </a>

            <a
              href={config.contacts.general.waHref}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-500/20 px-5 py-2.5 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 transition hover:bg-emerald-500 hover:text-white"
            >
              <MessageSquare className="h-3.5 w-3.5" />
              <span>{t.whatsapp}</span>
            </a>

            <Link
              href={hrefs.contact}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-gold hover:text-gold-light transition underline-offset-4 hover:underline px-2 py-1"
            >
              <span>{t.contactForm}</span>
              <ArrowRight className="h-3.5 w-3.5 rotate-180" />
            </Link>
          </div>
        </div>
      </main>

      {/* التذييل البسيط */}
      <footer className="relative z-10 mx-auto w-full max-w-7xl px-6 py-6 text-center text-xs text-white/50 sm:px-8">
        <p>
          © {new Date().getFullYear()} {config.company.fullName}. {t.rights}
        </p>
      </footer>
    </div>
  );
}

/**
 * صفحة الخطأ 404 المخصصة للهوية المؤسسية لشركة الفضاء الواسع — ثنائية اللغة
 * في static export يُخدم ملف 404.html واحداً لأي مسار خاطئ، لذلك تُبنى النسختان
 * معاً (العربية هي الافتراضية في SSR لأن المسار غير معروف وقت البناء) ويُبدَّل
 * بينهما بعد التحميل حسب المسار الفعلي للمتصفح.
 */
export default function NotFound() {
  const pathname = usePathname() || "";
  const [mounted, setMounted] = useState(false);
  const [isEnglish, setIsEnglish] = useState(false);

  useEffect(() => {
    setMounted(true);
    // المسار من الـ router قد لا يعكس عنوان URL الفعلي عند خدمة 404.html
    // لمسار خاطئ في static export، لذا نعتمد أيضاً على window.location.pathname
    setIsEnglish(
      pathname.startsWith("/en") ||
        window.location.pathname.startsWith("/en")
    );
  }, [pathname]);

  useEffect(() => {
    const title = isEnglish
      ? "Page Not Found (404) | Al-Fada Al-Wasaa"
      : "الصفحة غير موجودة (404) | شركة الفضاء الواسع";
    document.title = title;
    // Next يعيد فرض عنوان الـ layout الجذري بعد التفعيل (في مهام لاحقة متأخرة)
    // فيكتب فوق العنوان المخصص؛ مراقبة <title> تعيد فرض عنوان صفحة الخطأ فوراً
    // بعد أي كتابة خارجية، وتتقارب دون حلقة لأن الكتابة تحدث فقط عند الاختلاف
    const observer = new MutationObserver(() => {
      if (document.title !== title) document.title = title;
    });
    observer.observe(document.head, {
      subtree: true,
      childList: true,
      characterData: true,
    });
    return () => observer.disconnect();
  }, [isEnglish]);

  const showEnglish = mounted && isEnglish;

  return (
    <>
      {renderVariant(
        T_AR,
        SITE_CONFIG,
        { home: "/", services: "/#services", contact: "/#contact" },
        "rtl",
        "ar",
        showEnglish
      )}
      {renderVariant(
        T_EN,
        EN_SITE_CONFIG,
        { home: "/en", services: "/en#services", contact: "/en#contact" },
        "ltr",
        "en",
        !showEnglish
      )}
    </>
  );
}
