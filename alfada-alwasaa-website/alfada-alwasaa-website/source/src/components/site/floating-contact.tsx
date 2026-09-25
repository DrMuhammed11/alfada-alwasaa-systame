"use client";

import { useState, useEffect } from "react";
import { MessageSquare, ArrowUp, Phone, X, Building2, UserCheck } from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { ThemeToggle } from "./theme-toggle";

export function FloatingContact() {
  const [showTopBtn, setShowTopBtn] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setShowTopBtn(window.scrollY > 400);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  return (
    <div className="fixed bottom-6 left-6 z-50 flex flex-col items-center gap-3">
      {/* Theme toggle — خارج الهيدر ضمن المجموعة العائمة */}
      <ThemeToggle className="h-11 w-11 rounded-full bg-navy/90 text-gold-light shadow-lg backdrop-blur-md ring-1 ring-white/20 transition-all hover:scale-110 hover:bg-gold hover:text-navy-darker hover:ring-gold/50 active:scale-95" />

      {/* Scroll to top button */}
      {showTopBtn && (
        <button
          type="button"
          onClick={scrollToTop}
          aria-label="العودة لأعلى الصفحة"
          className="fade-pop-enter flex h-11 w-11 items-center justify-center rounded-full bg-navy/90 text-white shadow-lg backdrop-blur-md ring-1 ring-white/20 transition-all hover:scale-110 hover:bg-gold hover:text-navy-darker active:scale-95"
        >
          <ArrowUp className="h-5 w-5" />
        </button>
      )}

      {/* Floating Speed-Dial Menu for Both Numbers */}
      {menuOpen && (
        <div className="fade-pop-enter mb-2 w-72 rounded-3xl border border-gold/30 bg-navy-deep/98 p-4 text-white shadow-[0_20px_50px_rgba(0,0,0,0.5)] backdrop-blur-xl">
          <div className="flex items-center justify-between border-b border-white/10 pb-3 mb-3">
            <span className="text-xs font-bold text-gold-light">اتصال سريع ومباشر</span>
            <button
              type="button"
              onClick={() => setMenuOpen(false)}
              aria-label="إغلاق قائمة الاتصال السريع"
              className="rounded-lg p-1 text-white/60 hover:bg-white/10 hover:text-white"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          <div className="space-y-3">
            {/* General Management */}
            <div className="rounded-2xl bg-white/5 p-3 ring-1 ring-white/10">
              <div className="flex items-center gap-2 mb-2">
                <Building2 className="h-4 w-4 text-gold" />
                <span className="text-xs font-bold text-white">{SITE_CONFIG.contacts.general.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <a
                  href={SITE_CONFIG.contacts.general.telHref}
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-gold/90 py-1.5 text-xs font-black text-navy-darker hover:bg-gold transition"
                >
                  <Phone className="h-3.5 w-3.5" />
                  <span>اتصال</span>
                </a>
                <a
                  href={SITE_CONFIG.contacts.general.waHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500 py-1.5 text-xs font-black text-white hover:bg-emerald-600 transition"
                >
                  <MessageSquare className="h-3.5 w-3.5" />
                  <span>واتساب</span>
                </a>
              </div>
            </div>

            {/* Deputy Director */}
            <div className="rounded-2xl bg-white/5 p-3 ring-1 ring-white/10">
              <div className="flex items-center gap-2 mb-2">
                <UserCheck className="h-4 w-4 text-gold" />
                <span className="text-xs font-bold text-white">{SITE_CONFIG.contacts.deputy.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <a
                  href={SITE_CONFIG.contacts.deputy.telHref}
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-gold/90 py-1.5 text-xs font-black text-navy-darker hover:bg-gold transition"
                >
                  <Phone className="h-3.5 w-3.5" />
                  <span>اتصال</span>
                </a>
                <a
                  href={SITE_CONFIG.contacts.deputy.waHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500 py-1.5 text-xs font-black text-white hover:bg-emerald-600 transition"
                >
                  <MessageSquare className="h-3.5 w-3.5" />
                  <span>واتساب</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Speed dial toggle button for numbers */}
      <button
        type="button"
        onClick={() => setMenuOpen((v) => !v)}
        aria-label="قائمة أرقام الإدارة والمسؤولين"
        className="flex h-9 w-9 items-center justify-center rounded-full bg-navy/90 text-gold-light shadow-md ring-1 ring-white/20 transition hover:bg-navy hover:text-white text-xs font-bold"
        title="أرقام الإدارة والمشاريع"
      >
        <Phone className="h-4 w-4" />
      </button>

      {/* Main One-Click WhatsApp Action Button */}
      <a
        href={SITE_CONFIG.contacts.general.waHref}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="محادثة واتساب فورية مباشرة مع الإدارة العامة"
        className="group relative flex h-14 w-14 items-center justify-center rounded-full bg-emerald-500 text-white shadow-[0_10px_25px_rgba(16,185,129,0.5)] transition hover:bg-emerald-600 hover:scale-105 active:scale-95"
      >
        <span className="absolute -inset-1 rounded-full bg-emerald-400/40 blur-sm animate-pulse" />
        <MessageSquare className="relative h-7 w-7" />

        {/* Tooltip hint on hover (desktop) */}
        <span className="pointer-events-none absolute right-full mr-3 hidden whitespace-nowrap rounded-xl bg-navy-darker px-3 py-1.5 text-xs font-bold text-white shadow-md ring-1 ring-white/10 md:group-hover:block">
          محادثة واتساب فورية (الإدارة العامة)
        </span>
      </a>
    </div>
  );
}
