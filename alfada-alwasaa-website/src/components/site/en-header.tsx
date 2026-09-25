"use client";

/**
 * English Site Header — shared chrome for all English pages (/en, /en/about, /en/services/...)
 * Pure CSS mobile accordion using grid-rows technique (zero framer-motion).
 */

import { useState } from "react";
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

export function EnHeader() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);

  return (
    <>
      <header className="fixed inset-x-0 top-0 z-50 bg-navy/95 backdrop-blur-md shadow-md border-b border-white/10 text-white">
        <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          {/* Brand — compact on mobile: smaller mark, subtitle hidden under sm */}
          <Link href="/en" className="flex items-center gap-2 sm:gap-3" aria-label="Al-Fada Al-Wasaa Home">
            <span className="relative h-9 w-9 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40 sm:h-12 sm:w-12">
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
              <span className="block whitespace-nowrap text-[15px] font-extrabold text-white sm:text-lg tracking-tight">
                AL-FADA AL-WASAA
              </span>
              <span className="hidden text-[9.5px] font-semibold tracking-[0.24em] text-gold-light sm:block sm:text-[10.5px]">
                TELECOM & CONTRACTING
              </span>
            </span>
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden lg:flex items-center gap-1" aria-label="Main Navigation">
            {EN_SITE_CONFIG.navItems.map((item) => (
              <a
                key={item.href}
                href={item.href}
                className="rounded-full px-3 py-1 text-xs xl:text-sm font-bold text-white/85 hover:text-gold-light transition"
              >
                {item.label}
              </a>
            ))}
          </nav>

          {/* Desktop Actions */}
          <div className="hidden lg:flex items-center gap-2.5">
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              aria-label="Quick Search (Ctrl+K)"
              className="flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold text-white/90 backdrop-blur-md transition hover:bg-white/20 hover:text-white"
            >
              <Search className="h-3.5 w-3.5 text-gold-light" />
              <span className="hidden xl:inline">Search...</span>
              <kbd className="inline-flex items-center rounded bg-white/10 px-1.5 text-[10px] font-mono text-gold-light">
                Ctrl+K
              </kbd>
            </button>

            {/* Language Switcher Button next to Request Quote */}
            <LanguageSwitcher variant="button" />

            <a
              href="/en/contact"
              className="rounded-full bg-gold px-5 py-2 text-xs font-black text-navy-darker shadow-md hover:bg-gold-light transition"
            >
              Request Quote
            </a>
          </div>

          {/* Mobile buttons */}
          <div className="flex items-center gap-1.5 lg:hidden">
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              aria-label="Quick Search"
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white"
            >
              <Search className="h-4 w-4 text-gold-light" />
            </button>
            <LanguageSwitcher variant="button" className="h-10" />
            <button
              type="button"
              onClick={() => setMobileMenuOpen((v) => !v)}
              aria-expanded={mobileMenuOpen}
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white"
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
                {EN_SITE_CONFIG.navItems.map((item) => (
                  <a
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className="block rounded-lg px-3 py-2 text-sm font-semibold text-white/90 hover:bg-white/10"
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
                  className="block text-center rounded-xl bg-gold py-2.5 text-sm font-black text-navy-darker mt-3 shadow-md"
                >
                  Request Quote or Proposal
                </a>
                <div className="grid grid-cols-2 gap-2 pt-2">
                  <a
                    href={EN_SITE_CONFIG.contacts.general.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{EN_SITE_CONFIG.contacts.general.label}</span>
                    <span>{EN_SITE_CONFIG.contacts.general.display}</span>
                  </a>
                  <a
                    href={EN_SITE_CONFIG.contacts.deputy.telHref}
                    className="flex flex-col items-center justify-center rounded-xl bg-white/10 py-2 text-[11px] font-bold text-white/90 ring-1 ring-white/15"
                  >
                    <span className="text-[10px] text-gold-light">{EN_SITE_CONFIG.contacts.deputy.label}</span>
                    <span>{EN_SITE_CONFIG.contacts.deputy.display}</span>
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
