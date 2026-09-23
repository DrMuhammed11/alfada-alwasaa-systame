import Link from "next/link";
import Image from "next/image";
import { Home, Briefcase, Phone, MessageSquare, ArrowRight } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";

export const metadata = {
  title: "الصفحة غير موجودة (404) | شركة الفضاء الواسع",
  description: "عذراً، الصفحة التي تبحث عنها غير موجودة أو تم نقلها. تفضل بالعودة إلى الصفحة الرئيسية لشركة الفضاء الواسع.",
  robots: {
    index: false,
    follow: true,
  },
};

/**
 * صفحة الخطأ 404 المخصصة للهوية المؤسسية لشركة الفضاء الواسع
 * مصممة بتناغم ألوان الكحلي والذهبي مع أزرار تنقل واضحة وقنوات اتصال سريعة
 */
export default function NotFound() {
  return (
    <div className="relative min-h-screen flex flex-col justify-between bg-navy text-white overflow-hidden selection:bg-gold selection:text-navy-darker">
      {/* خلفية هندسية متناسقة */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-navy-deep/80 via-navy to-navy-darker pointer-events-none" />

      {/* الرأس: شعار الشركة */}
      <header className="relative z-10 mx-auto w-full max-w-7xl px-6 pt-10 sm:px-8">
        <Link
          href="/"
          className="inline-flex items-center gap-3 transition-opacity hover:opacity-90"
        >
          <div className="relative h-12 w-12 rounded-2xl bg-white/10 p-2 ring-1 ring-white/20 backdrop-blur-sm">
            <Image
              src={SITE_CONFIG.assets.logoMark}
              alt="شعار شركة الفضاء الواسع"
              fill
              sizes="48px"
              className="object-contain p-1"
            />
          </div>
          <div>
            <span className="block text-sm font-black text-white sm:text-base">
              {SITE_CONFIG.company.fullName}
            </span>
            <span className="block text-xs font-semibold text-gold-light">
              {SITE_CONFIG.company.tagline}
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
          الصفحة غير موجودة
        </h1>
        <p className="mx-auto mt-4 max-w-xl text-base leading-8 text-white/80 sm:text-lg">
          عذراً، الرابط الذي تبحث عنه غير متاح أو تم نقله أو قد تم تحديث هيكل الموقع. يسعدنا مساعدتك في الوصول إلى وجهتك المطلوبة.
        </p>

        {/* أزرار الإجراءات الرئيسية */}
        <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
          <Link
            href="/"
            className="inline-flex items-center gap-2 rounded-2xl bg-gold px-8 py-4 text-base font-extrabold text-navy-darker shadow-[0_15px_35px_-10px_rgba(198,149,74,0.5)] transition hover:bg-gold-light hover:shadow-[0_20px_40px_-10px_rgba(198,149,74,0.65)]"
          >
            <Home className="h-5 w-5" />
            <span>العودة للصفحة الرئيسية</span>
          </Link>

          <Link
            href="/#services"
            className="inline-flex items-center gap-2 rounded-2xl bg-white/10 px-8 py-4 text-base font-bold text-white ring-1 ring-white/20 backdrop-blur-sm transition hover:bg-white/20 hover:ring-gold/50"
          >
            <Briefcase className="h-5 w-5 text-gold-light" />
            <span>استعراض خدماتنا</span>
          </Link>
        </div>

        {/* بطاقة التواصل السريع والدعم */}
        <div className="mt-14 rounded-3xl bg-white/5 p-6 ring-1 ring-white/10 backdrop-blur-md sm:p-8">
          <h2 className="text-sm font-bold text-gold-light">
            هل تحتاج إلى مساعدة أو طلب استشارة مباشرة؟
          </h2>
          <p className="mt-2 text-xs leading-6 text-white/70">
            فريق خدمة العملاء متاح للرد على كافة الاستفسارات وتلبية متطلبات المشاريع.
          </p>

          <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
            <a
              href={SITE_CONFIG.contacts.general.telHref}
              className="inline-flex items-center gap-2 rounded-xl bg-white/10 px-5 py-2.5 text-xs font-bold text-white transition hover:bg-gold hover:text-navy-darker"
            >
              <Phone className="h-3.5 w-3.5 text-gold" />
              <span>اتصال مباشر: {SITE_CONFIG.contacts.general.display}</span>
            </a>

            <a
              href={SITE_CONFIG.contacts.general.waHref}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-500/20 px-5 py-2.5 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 transition hover:bg-emerald-500 hover:text-white"
            >
              <MessageSquare className="h-3.5 w-3.5" />
              <span>محادثة واتساب سريعة</span>
            </a>

            <Link
              href="/#contact"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-gold hover:text-gold-light transition underline-offset-4 hover:underline px-2 py-1"
            >
              <span>نموذج المراسلات والمتابعة</span>
              <ArrowRight className="h-3.5 w-3.5 rotate-180" />
            </Link>
          </div>
        </div>
      </main>

      {/* التذييل البسيط */}
      <footer className="relative z-10 mx-auto w-full max-w-7xl px-6 py-6 text-center text-xs text-white/50 sm:px-8">
        <p>
          © {new Date().getFullYear()} {SITE_CONFIG.company.fullName}. جميع الحقوق محفوظة.
        </p>
      </footer>
    </div>
  );
}
