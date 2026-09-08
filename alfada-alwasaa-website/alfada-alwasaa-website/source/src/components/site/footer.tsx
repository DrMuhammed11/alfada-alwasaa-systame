import Image from "next/image";
import { Reveal } from "./reveal";
import { SITE_CONFIG } from "@/config/site";

export function SiteFooter() {
  return (
    <footer className="relative mt-auto overflow-hidden bg-navy-darker text-white">
      {/* top gold seam */}
      <div aria-hidden className="h-1 w-full bg-gradient-to-l from-gold via-gold-light to-gold" />
      <div className="dot-grid absolute inset-0 opacity-20" aria-hidden />

      <div className="relative mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center gap-8 text-center">
          {/* Logo lockup */}
          <Reveal>
            <div className="relative h-36 w-36 sm:h-44 sm:w-44">
              <Image
                src={SITE_CONFIG.assets.logoTransparent}
                alt={SITE_CONFIG.company.fullName}
                fill
                sizes="(max-width: 640px) 144px, 176px"
                className="object-contain"
              />
            </div>
          </Reveal>

          {/* Live Tagline (Scalable typography) */}
          <Reveal delay={0.08}>
            <p className="text-base sm:text-lg font-black tracking-wide text-gold-light">
              {SITE_CONFIG.company.tagline}
            </p>
          </Reveal>

          {/* Pristine Complete Sector Icons */}
          <Reveal delay={0.14}>
            <div className="relative h-13 sm:h-14 w-full max-w-[280px]">
              <Image
                src={SITE_CONFIG.assets.sectorIconsStrip}
                alt="المقاولات العامة، الطرق والجسور، النفط، الاتصالات، التسويق"
                fill
                sizes="280px"
                className="object-contain drop-shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
              />
            </div>
          </Reveal>

          {/* Quick links */}
          <Reveal delay={0.18}>
            <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 text-sm font-semibold text-white/80">
              {SITE_CONFIG.navItems.map((item) => (
                <a
                  key={item.href}
                  href={item.href}
                  className="hover:text-gold-light transition"
                >
                  {item.label}
                </a>
              ))}
            </div>
          </Reveal>

          {/* Quick contact and address in footer */}
          <Reveal delay={0.2}>
            <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-3 text-xs text-white/70">
              <span className="flex items-center gap-2">
                <span className="text-gold font-bold">العنوان:</span>
                <span>{SITE_CONFIG.contacts.location.fullAddress}</span>
              </span>
              <span className="hidden sm:inline text-white/20">|</span>
              <a
                href={SITE_CONFIG.contacts.general.telHref}
                className="flex items-center gap-2 hover:text-gold-light transition"
              >
                <span className="text-gold font-bold">{SITE_CONFIG.contacts.general.label}:</span>
                <span dir="ltr">{SITE_CONFIG.contacts.general.display}</span>
              </a>
              <span className="hidden sm:inline text-white/20">|</span>
              <a
                href={SITE_CONFIG.contacts.deputy.telHref}
                className="flex items-center gap-2 hover:text-gold-light transition"
              >
                <span className="text-gold font-bold">{SITE_CONFIG.contacts.deputy.label}:</span>
                <span dir="ltr">{SITE_CONFIG.contacts.deputy.display}</span>
              </a>
              <span className="hidden sm:inline text-white/20">|</span>
              <a
                href={SITE_CONFIG.contacts.email.mailHref}
                className="flex items-center gap-2 hover:text-gold-light transition"
              >
                <span className="text-gold font-bold">البريد:</span>
                <span>{SITE_CONFIG.contacts.email.address}</span>
              </a>
            </div>
          </Reveal>

          <Reveal delay={0.22}>
            <p className="max-w-xl text-sm leading-8 text-white/60">
              {SITE_CONFIG.company.fullName} — {SITE_CONFIG.company.brief}
            </p>
          </Reveal>
        </div>

        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-white/10 pt-7 sm:flex-row">
          <p className="text-xs font-semibold text-white/50">
            جميع الحقوق محفوظة © {new Date().getFullYear()} — {SITE_CONFIG.company.fullName}
          </p>
          <p className="text-[11px] font-bold tracking-[0.3em] text-gold-light/80">
            {SITE_CONFIG.company.enName}
          </p>
        </div>
      </div>
    </footer>
  );
}
