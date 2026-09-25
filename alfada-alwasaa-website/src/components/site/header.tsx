"use client";

import dynamic from "next/dynamic";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { Menu, Search } from "lucide-react";
import { cn } from "@/lib/utils";
import { SITE_CONFIG } from "@/config/site";
import { LanguageSwitcher } from "./language-switcher";

// لوحة البحث تُحمَّل فقط عند أول فتح — باقة cmdk خارج المسار الحرج
const CommandSearch = dynamic(
  () => import("./command-search").then((m) => ({ default: m.CommandSearch })),
  { ssr: false }
);

const NAV_ITEMS = SITE_CONFIG.navItems;

/* ===== سلّم مقاسات الهيدر الموحد — نظام واحد لكل الشاشات =====
   <360      : وضع الانهيار الطارئ (أزرار 36px، شعار 32px)
   360–959   : الجوال (أزرار 40px، شعار 36px، بلا سطر فرعي <sm)
   960–1279  : lg — سطح مكتب مضغوط (تنقل 12px، بحث أيقونة، أزرار 40px)
   1280–1535 : xl — المقاس القياسي (تنقل 14px، بحث بنص، أزرار 40px)
   ≥1536     : 2xl — تنقل 15px وفسحة أوسع
   كل عناصر التحكم بارتفاع موحد 40px وزوايا دائرية موحدة */

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
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // تتبع القسم الظاهر حالياً لإبراز رابطه (مؤجل إلى idle)
  useEffect(() => {
    let observer: IntersectionObserver | null = null;
    const hasIdle = typeof window !== "undefined" && "requestIdleCallback" in window;
    const idleId = hasIdle
      ? window.requestIdleCallback(() => setupObserver())
      : window.setTimeout(() => setupObserver(), 200);

    function setupObserver() {
      const ids = NAV_ITEMS.map((i) => i.href.slice(1));
      observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting) setActive(`#${entry.target.id}`);
          }
        },
        { rootMargin: "-40% 0px -55% 0px" }
      );
      ids.forEach((id) => {
        const el = document.getElementById(id);
        if (el) observer?.observe(el);
      });
    }

    return () => {
      if (hasIdle && typeof idleId === "number") {
        window.cancelIdleCallback(idleId as number);
      } else {
        window.clearTimeout(idleId as number);
      }
      observer?.disconnect();
    };
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

  // إغلاق قائمة الجوال بعد إتمام التنقل (hashchange)
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
      <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between gap-3 px-4 sm:px-6 lg:px-6 xl:px-8">
        {/* الشعار — سطر واحد دائماً */}
        <a
          href="#home"
          onClick={(e) => handleNavClick(e, "#home")}
          className="flex shrink-0 items-center gap-2 sm:gap-3"
          aria-label="الفضاء الواسع - الرئيسية"
        >
          <span className="relative h-9 w-9 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40 max-[359px]:h-8 max-[359px]:w-8 sm:h-12 sm:w-12">
            <Image
              src={SITE_CONFIG.assets.logoMark}
              alt="شعار شركة الفضاء الواسع"
              fill
              sizes="(max-width: 640px) 36px, 48px"
              className="object-contain p-1"
              priority
            />
          </span>
          <span className="leading-tight">
            <span className="block whitespace-nowrap text-base font-extrabold text-white max-[359px]:text-sm sm:text-xl">
              الفضاء الواسع
            </span>
            <span className="hidden text-[10px] font-semibold tracking-[0.28em] text-gold-light sm:block sm:text-[11px]">
              AL-FADA AL-WASAA
            </span>
          </span>
        </a>

        {/* تنقل سطح المكتب */}
        <nav
          className="hidden min-w-0 items-center lg:flex"
          aria-label="التنقل الرئيسي"
        >
          {NAV_ITEMS.map((item) => (
            <a
              key={item.href}
              href={item.href}
              onClick={(e) => handleNavClick(e, item.href)}
              aria-current={active === item.href ? "page" : undefined}
              className={cn(
                "relative whitespace-nowrap rounded-full px-1.5 py-2 text-[11.5px] font-bold transition-colors duration-300 xl:px-3.5 xl:text-[14px] 2xl:text-[15px] 2xl:px-4",
                active === item.href
                  ? "text-gold-light"
                  : "text-white/85 hover:text-white"
              )}
            >
              {item.label}
              {/* مؤشر الرابط النشط */}
              {active === item.href && (
                <span className="absolute inset-x-3 -bottom-0.5 h-0.5 rounded-full bg-gold" />
              )}
            </a>
          ))}
        </nav>

        {/* إجراءات سطح المكتب — ارتفاع موحد 40px */}
        <div className="hidden lg:flex shrink-0 items-center gap-2">
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            aria-label="البحث السريع (Ctrl+K)"
            title="البحث السريع (Ctrl+K)"
            className="flex h-10 items-center justify-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 text-[13px] font-semibold text-white/90 backdrop-blur-md transition hover:bg-white/20 hover:text-white xl:px-4"
          >
            <Search className="h-4 w-4 shrink-0 text-gold-light" />
            <span className="hidden xl:inline">بحث...</span>
            <kbd className="hidden items-center rounded bg-white/10 px-1.5 py-0.5 text-[10px] font-mono text-gold-light xl:inline-flex">
              Ctrl+K
            </kbd>
          </button>

          <LanguageSwitcher variant="button" className="h-10 rounded-full" />

          <a
            href="#contact"
            onClick={(e) => handleNavClick(e, "#contact")}
            className="flex h-10 whitespace-nowrap items-center rounded-full bg-gold px-4 text-[12px] font-black text-navy-darker shadow-[0_4px_14px_rgba(198,149,74,0.4)] transition hover:bg-gold-light hover:shadow-[0_6px_20px_rgba(198,149,74,0.6)] xl:px-6 xl:text-[13px]"
          >
            طلب استشارة
          </a>
        </div>

        {/* أزرار الجوال — 40px موحدة */}
        <div className="flex items-center gap-1.5 lg:hidden max-[359px]:gap-1">
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            aria-label="البحث السريع"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/20 max-[359px]:h-9 max-[359px]:w-9"
          >
            <Search className="h-4 w-4 text-gold-light" />
          </button>
          <LanguageSwitcher variant="button" className="h-10 rounded-full max-[359px]:h-9" />
          <button
            type="button"
            onClick={() => setOpen((v) => !v)}
            aria-expanded={open}
            aria-label="فتح قائمة التنقل"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/20 max-[359px]:h-9 max-[359px]:w-9"
          >
            <Menu className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* لوحة البحث — تُركَّب فقط عند الفتح */}
      {searchOpen && (
        <CommandSearch open={searchOpen} onOpenChange={setSearchOpen} />
      )}

      {/* قائمة الجوال — أكورديون CSS خالص بتقنية grid-rows،
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
