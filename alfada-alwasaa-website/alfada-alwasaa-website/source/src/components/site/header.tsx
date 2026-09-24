"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { Menu, Search } from "lucide-react";
import { cn } from "@/lib/utils";
import { SITE_CONFIG } from "@/config/site";
import { ThemeToggle } from "./theme-toggle";
import { CommandSearch } from "./command-search";
import { LanguageSwitcher } from "./language-switcher";

const NAV_ITEMS = SITE_CONFIG.navItems;

export function SiteHeader() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState("#home");
  const [searchOpen, setSearchOpen] = useState(false);

  useEffect(() => {
    let ticking = false;
    const onScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          setScrolled(window.scrollY > 24);
          ticking = false;
        });
        ticking = true;
      }
    };
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

  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
    if (href.startsWith("#")) {
      const targetId = href.slice(1);
      const el = document.getElementById(targetId);
      if (el) {
        e.preventDefault();
        setOpen(false);
        setTimeout(() => {
          const headerOffset = 80;
          const elementPosition = el.getBoundingClientRect().top;
          const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
          window.scrollTo({
            top: Math.max(0, offsetPosition),
            behavior: "smooth",
          });
          window.history.pushState(null, "", href);
          setActive(href);
        }, 100);
      } else {
        setOpen(false);
        window.location.href = `/${href}`;
      }
    } else {
      setOpen(false);
    }
  };

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
        <a 
          href="#home" 
          onClick={(e) => handleNavClick(e, "#home")}
          className="flex items-center gap-3" 
          aria-label="الفضاء الواسع - الرئيسية"
        >
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
              onClick={(e) => handleNavClick(e, item.href)}
              aria-current={active === item.href ? "page" : undefined}
              className={cn(
                "relative rounded-full px-2 py-1 text-[11.5px] font-bold transition-colors duration-300 xl:px-3.5 xl:text-[13.5px] whitespace-nowrap",
                active === item.href
                  ? "text-gold-light"
                  : "text-white/85 hover:text-white"
              )}
            >
              {item.label}
              {/* مؤشر الرابط النشط — يظهر تحت الرابط الحالي */}
              {active === item.href && (
                <span className="absolute inset-x-3 -bottom-0.5 h-0.5 rounded-full bg-gold" />
              )}
            </a>
          ))}
        </nav>

        {/* Desktop CTA, Search, Language & Theme Toggle */}
        <div className="hidden items-center gap-2.5 lg:flex">
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            aria-label="البحث السريع (Ctrl+K)"
            className="flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold text-white/90 backdrop-blur-md transition hover:bg-white/20 hover:text-white"
          >
            <Search className="h-3.5 w-3.5 text-gold-light" />
            <span className="hidden xl:inline">بحث...</span>
            <kbd className="inline-flex items-center rounded bg-white/10 px-1.5 text-[10px] font-mono text-gold-light">
              Ctrl+K
            </kbd>
          </button>

          {/* زر تبديل اللغة بجانب أيقونة الوضع الليلي مباشرة */}
          <LanguageSwitcher variant="button" />

          {/* أيقونة الوضع الليلي */}
          <ThemeToggle />
          <a
            href="#contact"
            onClick={(e) => handleNavClick(e, "#contact")}
            className="rounded-full bg-gold px-5 py-2 text-xs font-extrabold text-navy-darker shadow-[0_4px_14px_rgba(198,149,74,0.4)] transition hover:bg-gold-light hover:shadow-[0_6px_20px_rgba(198,149,74,0.6)]"
          >
            طلب استشارة
          </a>
        </div>

        {/* Mobile: Search, Language, Theme Toggle, and Menu button */}
        <div className="flex items-center gap-2 lg:hidden">
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            aria-label="البحث السريع"
            className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/15"
          >
            <Search className="h-4 w-4 text-gold-light" />
          </button>
          <LanguageSwitcher variant="button" />
          <ThemeToggle />
          <button
            type="button"
            onClick={() => setOpen((v) => !v)}
            aria-expanded={open}
            aria-label="فتح قائمة التنقل"
            className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/15"
          >
            <Menu className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Command Search Palette */}
      <CommandSearch open={searchOpen} onOpenChange={setSearchOpen} />

      {/* Mobile dropdown — أكورديون CSS خالص بتقنية grid-rows (بديل AnimatePresence)،
          invisible عند الإغلاق تُبقي الروابط خارج ترتيب التبويب وشجرة الوصولية */}
      <div
        className={cn(
          "grid transition-all duration-300 ease-in-out lg:hidden",
          open
            ? "grid-rows-[1fr] opacity-100 visible"
            : "grid-rows-[0fr] opacity-0 invisible"
        )}
      >
        <div className="overflow-hidden">
          <nav
            className="border-t border-white/10 bg-navy-deep/98 backdrop-blur-md"
            aria-label="قائمة التنقل للجوال"
          >
            <ul className="space-y-1 px-4 py-4">
              {NAV_ITEMS.map((item) => (
                <li key={item.href}>
                  <a
                    href={item.href}
                    onClick={(e) => handleNavClick(e, item.href)}
                    aria-current={active === item.href ? "page" : undefined}
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
              <li className="pt-2">
                <LanguageSwitcher variant="menu" />
              </li>
              <li className="pt-2 space-y-2">
                <a
                  href="#contact"
                  onClick={(e) => handleNavClick(e, "#contact")}
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
          </nav>
        </div>
      </div>
    </header>
  );
}
