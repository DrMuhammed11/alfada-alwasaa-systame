"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Cookie, X, Check } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export function CookieConsent() {
  const [visible, setVisible] = useState(false);
  const pathname = usePathname() || "";
  const isEnglish = pathname.startsWith("/en");

  const t = isEnglish
    ? {
        ariaLabel: "Cookie and privacy notice",
        title: "Cookies & Privacy",
        body: "We use essential cookies to store your preferences (theme, language, and transaction-tracking security) for a smooth, protected browsing experience.",
        accept: "Accept & Agree",
        privacy: "Privacy Policy",
        close: "Close cookie notice",
      }
    : {
        ariaLabel: "إشعار ملفات تعريف الارتباط والخصوصية",
        title: "ملفات تعريف الارتباط والخصوصية",
        body: "نستخدم ملفات الارتباط الأساسية لحفظ تفضيلاتك (المظهر، اللغة، وأمان تتبع المعاملات) لضمان تجربة تصفح سلسة ومحمية.",
        accept: "موافق واعتماد",
        privacy: "سياسة الخصوصية",
        close: "إغلاق إشعار الكوكيز",
      };

  useEffect(() => {
    try {
      const consent = localStorage.getItem("cookieConsent");
      if (!consent) {
        // تأخير خفيف بعد تحميل الصفحة لعدم إزعاج المستخدم فوراً
        const timer = setTimeout(() => setVisible(true), 1500);
        return () => clearTimeout(timer);
      }
    } catch {
      // تجاهل إذا كانت الـ LocalStorage غير متاحة
    }
  }, []);

  const handleAccept = () => {
    try {
      localStorage.setItem("cookieConsent", "accepted");
    } catch {}
    setVisible(false);
  };

  const handleDismiss = () => {
    try {
      localStorage.setItem("cookieConsent", "dismissed");
    } catch {}
    setVisible(false);
  };

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 20, scale: 0.95 }}
          transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
          role="dialog"
          aria-live="polite"
          aria-label={t.ariaLabel}
          dir={isEnglish ? "ltr" : "rtl"}
          className="fixed bottom-5 end-5 z-50 max-w-sm rounded-3xl border border-gold/30 bg-navy-darker/95 p-5 text-white shadow-[0_20px_50px_rgba(5,30,49,0.7)] backdrop-blur-xl"
        >
          <div className="flex items-start gap-3.5">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-gold/15 text-gold-light ring-1 ring-gold/40">
              <Cookie className="h-5 w-5" />
            </span>
            <div className="flex-1">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-black uppercase tracking-wider text-gold-light">
                  {t.title}
                </h4>
                <button
                  type="button"
                  onClick={handleDismiss}
                  aria-label={t.close}
                  className="rounded-lg p-1 text-white/50 hover:bg-white/10 hover:text-white transition"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
              <p className="mt-2 text-xs leading-5 text-white/80">
                {t.body}
              </p>
              <div className="mt-4 flex items-center gap-2.5">
                <button
                  type="button"
                  onClick={handleAccept}
                  className="inline-flex items-center gap-1.5 rounded-xl bg-gold px-4 py-2 text-xs font-black text-navy-darker shadow-md hover:bg-gold-light transition"
                >
                  <Check className="h-3.5 w-3.5 stroke-[3]" />
                  <span>{t.accept}</span>
                </button>
                <Link
                  href={isEnglish ? "/en/privacy" : "/privacy"}
                  className="text-xs font-bold text-white/70 hover:text-gold-light transition underline underline-offset-4"
                >
                  {t.privacy}
                </Link>
              </div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
