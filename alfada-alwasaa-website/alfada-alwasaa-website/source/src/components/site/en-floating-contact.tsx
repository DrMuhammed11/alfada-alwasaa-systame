"use client";

/**
 * English Floating Speed-Dial Contact Widget — shared chrome for all English pages
 * Pure CSS transitions with fade-pop-enter (zero framer-motion).
 */

import { useState, useEffect } from "react";
import { ArrowUp, Building2, MessageSquare, Phone, X } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";

export function EnFloatingContact() {
  const [showTopBtn, setShowTopBtn] = useState(false);
  const [floatingMenuOpen, setFloatingMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setShowTopBtn(window.scrollY > 400);
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col items-center gap-3">
      {/* Scroll to top button */}
      {showTopBtn && (
        <button
          type="button"
          onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
          aria-label="Scroll to top"
          className="fade-pop-enter flex h-11 w-11 items-center justify-center rounded-full bg-navy/90 text-white shadow-lg backdrop-blur-md ring-1 ring-white/20 transition-all hover:scale-110 hover:bg-gold hover:text-navy-darker active:scale-95"
        >
          <ArrowUp className="h-5 w-5" />
        </button>
      )}

      {/* Speed-Dial Menu */}
      {floatingMenuOpen && (
        <div className="fade-pop-enter mb-2 w-72 rounded-3xl border border-gold/30 bg-navy-deep/98 p-4 text-white shadow-2xl backdrop-blur-xl">
          <div className="flex items-center justify-between border-b border-white/10 pb-3 mb-3">
            <span className="text-xs font-bold text-gold-light">Quick Contact Channels</span>
            <button
              type="button"
              onClick={() => setFloatingMenuOpen(false)}
              aria-label="Close speed dial"
              className="rounded-lg p-1 text-white/60 hover:bg-white/10 hover:text-white"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          <div className="space-y-3">
            {/* General Management */}
            <div className="rounded-2xl bg-white/5 p-3">
              <div className="flex items-center gap-2 mb-2">
                <Building2 className="h-4 w-4 text-gold-light" />
                <span className="text-xs font-bold text-white">General Management</span>
              </div>
              <div className="grid grid-cols-2 gap-1.5">
                <a
                  href={EN_SITE_CONFIG.contacts.general.telHref}
                  className="flex items-center justify-center gap-1 rounded-xl bg-white/10 py-1.5 text-[11px] font-bold hover:bg-gold hover:text-navy-darker transition"
                >
                  <Phone className="h-3 w-3" />
                  <span>Call</span>
                </a>
                <a
                  href={EN_SITE_CONFIG.contacts.general.waHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/20 py-1.5 text-[11px] font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                >
                  <MessageSquare className="h-3 w-3" />
                  <span>WhatsApp</span>
                </a>
              </div>
            </div>

            {/* Deputy Director */}
            <div className="rounded-2xl bg-white/5 p-3">
              <div className="flex items-center gap-2 mb-2">
                <Phone className="h-4 w-4 text-gold-light" />
                <span className="text-xs font-bold text-white">Deputy Director</span>
              </div>
              <div className="grid grid-cols-2 gap-1.5">
                <a
                  href={EN_SITE_CONFIG.contacts.deputy.telHref}
                  className="flex items-center justify-center gap-1 rounded-xl bg-white/10 py-1.5 text-[11px] font-bold hover:bg-gold hover:text-navy-darker transition"
                >
                  <Phone className="h-3 w-3" />
                  <span>Call</span>
                </a>
                <a
                  href={EN_SITE_CONFIG.contacts.deputy.waHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/20 py-1.5 text-[11px] font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                >
                  <MessageSquare className="h-3 w-3" />
                  <span>WhatsApp</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Speed-dial Toggle Button */}
      <button
        type="button"
        onClick={() => setFloatingMenuOpen((v) => !v)}
        aria-label="Direct Contact Channels"
        className="relative flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-tr from-emerald-600 to-emerald-500 text-white shadow-xl ring-2 ring-white/30 transition-transform duration-200 hover:scale-105 active:scale-95"
      >
        <span className="absolute -top-1 -right-1 flex h-4 w-4">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
          <span className="relative inline-flex h-4 w-4 rounded-full bg-emerald-400" />
        </span>
        <MessageSquare className="h-7 w-7" />
      </button>
    </div>
  );
}

export default EnFloatingContact;
