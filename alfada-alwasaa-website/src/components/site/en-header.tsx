"use client";

/**
 * English Site Header — shared chrome for all English pages (/en, /en/about, /en/services/...)
 * Same unified sizing system as the Arabic header: every control is 40px tall,
 * a responsive type ladder for the nav (lg → 2xl), and active-section tracking.
 * Pure CSS mobile accordion using grid-rows technique (zero framer-motion).
 */

import { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import Image from "next/image";
import Link from "next/link";
import { Menu, Search, X } from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";
import { LanguageSwitcher } from "@/components/site/language-switcher";
import { cn } from "@/lib/utils";

// Search palette loads on first open only — keeps cmdk out of the critical path
const CommandSearch = dynamic(
  () => import("./command-search").then((m) => ({ default: m.CommandSearch })),
  { ssr: false }
);

const NAV_ITEMS = EN_SITE_CONFIG.navItems;

export function EnHeader() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [active, setActive] = useState<string>("");

  // Track the section currently in view to highlight its nav link (parity with AR header)
  useEffect(() => {
    let observer: IntersectionObserver | null = null;
    const hasIdle = typeof window !== "undefined" && "requestIdleCallback" in window;
    const idleId = hasIdle
      ? window.requestIdleCallback(() => setupObserver())
      : window.setTimeout(() => setupObserver(), 200);

    function setupObserver() {
      const entries = NAV_ITEMS.map((i) => i.href);
      const hashIds = entries
        .filter((h) => h.includes("#"))
        .map((h) => h.slice(h.indexOf("#") + 1));
      if (hashIds.length === 0) return;
      observer = new IntersectionObserver(
        (observed) => {
          for (const entry of observed) {
            if (entry.isIntersecting) setActive(`#${entry.target.id}`);
          }
        },
        { rootMargin: "-40% 0px -55% 0px" }
      );
      hashIds.forEach((id) => {
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

  const isNavItemActive = (href: string) => {
    if (!active) return false;
    if (href.includes("#")) return href.endsWith(active);
    return false;
  };

  return (
    <>
      <header className="fixed inset-x-0 top-0 z-50 bg-navy/95 backdrop-blur-md shadow-md border-b border-white/10 text-white">
        <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between gap-3 px-4 sm:px-6 lg:px-6 xl:px-8">
          {/* Brand — one line on every screen */}
          <Link
            href="/en"
            className="flex shrink-0 items-center gap-2 sm:gap-3"
            aria-label="Al-Fada Al-Wasaa Home"
          >
            <span className="relative h-9 w-9 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40 max-[359px]:h-8 max-[359px]:w-8 sm:h-12 sm:w-12">
              <Image
                src={SITE_CONFIG.assets.logoMark}
                alt="Al-Fada Al-Wasaa Logo"
                fill
                sizes="(max-width: 640px) 36px, 48px"
                className="object-contain p-1"
                priority
              />
            </span>
            <span className="leading-tight">
              <span className="block whitespace-nowrap text-base font-extrabold text-white max-[359px]:text-sm sm:text-lg tracking-tight">
                AL-FADA AL-WASAA
              </span>
              <span className="hidden text-[9.5px] font-semibold tracking-[0.24em] text-gold-light sm:block sm:text-[10.5px]">
                TELECOM & CONTRACTING
              </span>
            </span>
          </Link>

          {/* Desktop Nav */}
          <nav
            className="hidden min-w-0 items-center lg:flex"
            aria-label="Main Navigation"
          >
            {NAV_ITEMS.map((item) => {
              const isActive = isNavItemActive(item.href);
              return (
                <a
                  key={item.href}
                  href={item.href}
                  aria-current={isActive ? "page" : undefined}
                  className={cn(
                    "relative whitespace-nowrap rounded-full px-1.5 py-2 text-[11.5px] font-bold transition-colors duration-300 xl:px-3.5 xl:text-[14px] 2xl:text-[15px] 2xl:px-4",
                    isActive
                      ? "text-gold-light"
                      : "text-white/85 hover:text-white"
                  )}
                >
                  {item.label}
                  {isActive && (
                    <span className="absolute inset-x-3 -bottom-0.5 h-0.5 rounded-full bg-gold" />
                  )}
                </a>
              );
            })}
          </nav>

          {/* Desktop Actions — uniform 40px height */}
          <div className="hidden lg:flex shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              aria-label="Quick Search (Ctrl+K)"
              title="Quick Search (Ctrl+K)"
              className="flex h-10 items-center justify-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 text-[13px] font-semibold text-white/90 backdrop-blur-md transition hover:bg-white/20 hover:text-white xl:px-4"
            >
              <Search className="h-4 w-4 shrink-0 text-gold-light" />
              <span className="hidden xl:inline">Search...</span>
              <kbd className="hidden items-center rounded bg-white/10 px-1.5 py-0.5 text-[10px] font-mono text-gold-light xl:inline-flex">
                Ctrl+K
              </kbd>
            </button>

            <LanguageSwitcher variant="button" className="h-10 rounded-full" />

            <a
              href="/en/contact"
              className="flex h-10 whitespace-nowrap items-center rounded-full bg-gold px-4 text-[12px] font-black text-navy-darker shadow-[0_4px_14px_rgba(198,149,74,0.4)] transition hover:bg-gold-light hover:shadow-[0_6px_20px_rgba(198,149,74,0.6)] xl:px-6 xl:text-[13px]"
            >
              Request Quote
            </a>
          </div>

          {/* Mobile buttons — uniform 40px */}
          <div className="flex items-center gap-1.5 lg:hidden max-[359px]:gap-1">
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              aria-label="Quick Search"
              className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/20 max-[359px]:h-9 max-[359px]:w-9"
            >
              <Search className="h-4 w-4 text-gold-light" />
            </button>
            <LanguageSwitcher variant="button" className="h-10 rounded-full max-[359px]:h-9" />
            <button
              type="button"
              onClick={() => setMobileMenuOpen((v) => !v)}
              aria-expanded={mobileMenuOpen}
              className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/20 max-[359px]:h-9 max-[359px]:w-9"
              aria-label="Toggle Navigation"
            >
              {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>

        {/* Mobile dropdown — pure CSS accordion with grid-rows technique */}
        <div
          className={cn(
            "grid transition-all duration-300 ease-in-out lg:hidden",
            mobileMenuOpen
              ? "grid-rows-[1fr] opacity-100 visible"
              : "grid-rows-[0fr] opacity-0 invisible"
          )}
        >
          <div className="overflow-hidden">
            <nav
              className="border-t border-white/10 bg-navy-deep px-4 py-4"
              aria-label="Mobile Navigation"
            >
              <div className="space-y-2">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className="block rounded-lg px-3 py-2.5 text-sm font-semibold text-white/90 hover:bg-white/10"
                  >
                    {item.label}
                  </a>
                ))}
                <div className="pt-2">
                  <LanguageSwitcher variant="menu" />
                </div>
                <a
                  href="/en/contact"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block text-center rounded-xl bg-gold py-3 text-sm font-black text-navy-darker mt-3 shadow-md"
                >
                  Request Quote or Proposal
                </a>
                <div className="grid grid-cols-2 gap-2 pt-2">
                  <a
                    href={EN_SITE_CONFIG.contacts.general.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{EN_SITE_CONFIG.contacts.general.label}</span>
                    <span dir="ltr">{EN_SITE_CONFIG.contacts.general.display}</span>
                  </a>
                  <a
                    href={EN_SITE_CONFIG.contacts.deputy.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{EN_SITE_CONFIG.contacts.deputy.label}</span>
                    <span dir="ltr">{EN_SITE_CONFIG.contacts.deputy.display}</span>
                  </a>
                </div>
              </div>
            </nav>
          </div>
        </div>
      </header>

      {/* Command Search Palette — mounted only when open */}
      {searchOpen && (
        <CommandSearch open={searchOpen} onOpenChange={setSearchOpen} />
      )}
    </>
  );
}

export default EnHeader;
