"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Menu } from "lucide-react";
import { cn } from "@/lib/utils";
import { SITE_CONFIG } from "@/config/site";

const NAV_ITEMS = SITE_CONFIG.navItems;

export function SiteHeader() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState("#home");

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Track the section currently in view to highlight its nav link.
  useEffect(() => {
    const ids = NAV_ITEMS.map((i) => i.href.slice(1));
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) setActive(`#${entry.target.id}`);
        }
      },
      { rootMargin: "-40% 0px -55% 0px" }
    );
    ids.forEach((id) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, []);

  // Close the mobile menu after navigation completes (hashchange)
  useEffect(() => {
    const onHashChange = () => setOpen(false);
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  return (
    <header
      className={cn(
        "fixed inset-x-0 top-0 z-50 transition-all duration-300",
        scrolled
          ? "bg-navy shadow-[0_10px_30px_-10px_rgba(5,30,49,0.7)] backdrop-blur-md"
          : "bg-gradient-to-b from-navy-darker/80 to-navy/0"
      )}
    >
      <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand */}
        <a href="#home" className="flex items-center gap-3" aria-label="الفضاء الواسع - الرئيسية">
          <span className="relative h-11 w-11 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40 sm:h-12 sm:w-12">
            <Image
              src={SITE_CONFIG.assets.logoMark}
              alt="شعار شركة الفضاء الواسع"
              fill
              sizes="(max-width: 640px) 44px, 48px"
              className="object-contain p-1"
              priority
            />
          </span>
          <span className="leading-tight">
            <span className="block text-lg font-extrabold text-white sm:text-xl">
              الفضاء الواسع
            </span>
            <span className="block text-[10px] font-semibold tracking-[0.28em] text-gold-light sm:text-[11px]">
              AL-FADA AL-WASAA
            </span>
          </span>
        </a>

        {/* Desktop nav */}
        <nav className="hidden items-center gap-1 lg:flex" aria-label="التنقل الرئيسي">
          {NAV_ITEMS.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className={cn(
                "relative rounded-full px-2.5 py-1.5 text-[12px] font-bold transition-colors duration-300 xl:px-3.5 xl:text-[13.5px]",
                active === item.href
                  ? "text-gold-light"
                  : "text-white/85 hover:text-white"
              )}
            >
              {item.label}
              <span
                className={cn(
                  "absolute inset-x-3 -bottom-0.5 h-0.5 rounded-full bg-gold transition-all duration-300",
                  active === item.href ? "opacity-100" : "opacity-0"
                )}
              />
            </a>
          ))}
        </nav>

        {/* Desktop CTA */}
        <div className="hidden items-center gap-3 lg:flex">
          <a
            href="#contact"
            className="rounded-full bg-gold px-5 py-2 text-xs font-extrabold text-navy-darker shadow-[0_4px_14px_rgba(198,149,74,0.4)] transition hover:bg-gold-light hover:shadow-[0_6px_20px_rgba(198,149,74,0.6)]"
          >
            طلب استشارة
          </a>
        </div>

        {/* Mobile menu button */}
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-expanded={open}
          aria-label="فتح قائمة التنقل"
          className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/15 lg:hidden"
        >
          <Menu className="h-5 w-5" />
        </button>
      </div>

      {/* Mobile dropdown */}
      <AnimatePresence>
        {open && (
          <motion.nav
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.3, ease: "easeInOut" }}
            className="overflow-hidden border-t border-white/10 bg-navy-deep/98 backdrop-blur-md lg:hidden"
            aria-label="قائمة التنقل للجوال"
          >
            <ul className="space-y-1 px-4 py-4">
              {NAV_ITEMS.map((item) => (
                <li key={item.href}>
                  <a
                    href={item.href}
                    onClick={() => setOpen(false)}
                    className={cn(
                      "block rounded-lg px-4 py-3 text-sm font-semibold transition",
                      active === item.href
                        ? "bg-gold/15 text-gold-light"
                        : "text-white/85 hover:bg-white/10"
                    )}
                  >
                    {item.label}
                  </a>
                </li>
              ))}
              <li className="pt-2 space-y-2">
                <a
                  href="#contact"
                  onClick={() => setOpen(false)}
                  className="flex items-center justify-center rounded-xl bg-gold py-3 text-sm font-black text-navy-darker shadow-md"
                >
                  طلب عرض سعر أو استشارة
                </a>
                <div className="grid grid-cols-2 gap-2 pt-1">
                  <a
                    href={SITE_CONFIG.contacts.general.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{SITE_CONFIG.contacts.general.label}</span>
                    <span dir="ltr">{SITE_CONFIG.contacts.general.display}</span>
                  </a>
                  <a
                    href={SITE_CONFIG.contacts.deputy.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{SITE_CONFIG.contacts.deputy.label}</span>
                    <span dir="ltr">{SITE_CONFIG.contacts.deputy.display}</span>
                  </a>
                </div>
              </li>
            </ul>
          </motion.nav>
        )}
      </AnimatePresence>
    </header>
  );
}
