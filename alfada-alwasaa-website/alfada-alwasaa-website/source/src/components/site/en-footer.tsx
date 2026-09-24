/**
 * English Site Footer — shared chrome for all English subpages
 * Extracted verbatim from the English homepage footer (src/app/en/page.tsx) for pixel parity,
 * with legal/blog links pointing to the dedicated English pages.
 */

import Image from "next/image";
import Link from "next/link";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";
import { LanguageSwitcher } from "@/components/site/language-switcher";

export function EnFooter() {
  return (
    <footer className="mt-auto border-t border-white/10 bg-navy-darker py-14 text-white">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4 pb-12 border-b border-white/10">
          {/* Col 1: Identity */}
          <div className="space-y-4">
            <div className="relative h-14 w-14">
              <Image
                src={SITE_CONFIG.assets.logoMark}
                alt="Al-Fada Al-Wasaa Mark"
                fill
                sizes="56px"
                className="object-contain"
              />
            </div>
            <h2 className="text-lg font-black text-white">{EN_SITE_CONFIG.company.fullName}</h2>
            <p className="text-xs text-gold-light leading-relaxed font-semibold">
              {EN_SITE_CONFIG.company.tagline}
            </p>
            <p className="text-xs text-white/70 leading-relaxed">
              A multi-service professional entity delivering enterprise engineering, civil works, telecom sites, and supply chains across Yemen.
            </p>
          </div>

          {/* Col 2: Navigation Links */}
          <div className="space-y-3">
            <h3 className="text-sm font-bold uppercase tracking-wider text-gold-light">Quick Navigation</h3>
            <ul className="space-y-2 text-xs text-white/80">
              {EN_SITE_CONFIG.navItems.map((item) => (
                <li key={item.href}>
                  <a href={item.href} className="hover:text-gold-light transition flex items-center gap-1.5">
                    <span className="h-1 w-1 rounded-full bg-gold" />
                    <span>{item.label}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Col 3: Legal & Language */}
          <div className="space-y-3">
            <h3 className="text-sm font-bold uppercase tracking-wider text-gold-light">Legal & Language</h3>
            <ul className="space-y-2 text-xs text-white/80">
              <li>
                <Link href="/en/privacy" className="hover:text-gold-light transition flex items-center gap-1.5">
                  <span className="h-1 w-1 rounded-full bg-gold" />
                  <span>Privacy Policy</span>
                </Link>
              </li>
              <li>
                <Link href="/en/terms" className="hover:text-gold-light transition flex items-center gap-1.5">
                  <span className="h-1 w-1 rounded-full bg-gold" />
                  <span>Terms of Service</span>
                </Link>
              </li>
              <li>
                <Link href="/en/blog" className="hover:text-gold-light transition flex items-center gap-1.5">
                  <span className="h-1 w-1 rounded-full bg-gold" />
                  <span>Corporate Blog & Insights</span>
                </Link>
              </li>
            </ul>
            <div className="pt-2">
              <LanguageSwitcher variant="pill" />
            </div>
          </div>

          {/* Col 4: Corporate Contacts */}
          <div className="space-y-3">
            <h3 className="text-sm font-bold uppercase tracking-wider text-gold-light">Corporate Directory</h3>
            <div className="space-y-2.5 text-xs text-white/80">
              <div>
                <span className="block text-[11px] text-white/60">General Management:</span>
                <a href={EN_SITE_CONFIG.contacts.general.telHref} className="font-bold text-gold-light font-mono">
                  {EN_SITE_CONFIG.contacts.general.display}
                </a>
              </div>
              <div>
                <span className="block text-[11px] text-white/60">Deputy General Manager:</span>
                <a href={EN_SITE_CONFIG.contacts.deputy.telHref} className="font-bold text-gold-light font-mono">
                  {EN_SITE_CONFIG.contacts.deputy.display}
                </a>
              </div>
              <div>
                <span className="block text-[11px] text-white/60">Official Email:</span>
                <a href={EN_SITE_CONFIG.contacts.email.mailHref} className="font-bold text-white font-mono">
                  {EN_SITE_CONFIG.contacts.email.address}
                </a>
              </div>
              <div>
                <span className="block text-[11px] text-white/60">Headquarters:</span>
                <span className="text-white/80">{EN_SITE_CONFIG.contacts.location.fullAddress}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-[11px] text-white/50">
          <p>
            &copy; {new Date().getFullYear()} {EN_SITE_CONFIG.company.fullName}. All rights reserved.
          </p>
          <p>
            Yemeni Commercial Registry & Sovereign Classifications Verified.
          </p>
        </div>
      </div>
    </footer>
  );
}
