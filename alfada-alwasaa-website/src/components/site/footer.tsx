import Image from "next/image";
import { Reveal } from "./reveal";
import { SITE_CONFIG } from "@/config/site";
import { LanguageSwitcher } from "./language-switcher";

export function SiteFooter() {
  return (
    <footer className="relative mt-auto overflow-hidden bg-navy-darker text-white">
      {/* top gold seam */}
      <div aria-hidden className="h-1 w-full bg-gradient-to-l from-gold via-gold-light to-gold" />
      <div className="dot-grid absolute inset-0 opacity-20" aria-hidden />

      <div className="relative mx-auto max-w-7xl px-4 py-12 sm:px-6 sm:py-14 lg:px-8">
        <div className="flex flex-col items-center gap-5 sm:gap-6 text-center">
          {/* Complete, pristine Logo Lockup (Never cropped, perfectly harmonious) */}
          <Reveal>
            <div className="flex flex-col items-center text-center">
              <div className="relative h-20 w-20 sm:h-24 sm:w-24 drop-shadow-[0_4px_20px_rgba(198,149,74,0.35)]">
                <Image
                  src={SITE_CONFIG.assets.logoMark}
                  alt={SITE_CONFIG.company.fullName}
                  fill
                  sizes="(max-width: 640px) 80px, 96px"
                  className="object-contain"
                />
              </div>
              <div className="mt-3">
                <span className="block text-2xl sm:text-3xl font-black tracking-tight text-white">
                  الفضاء الواسع
                </span>
                <div className="mt-1 flex items-center justify-center gap-2.5">
                  <span className="h-[1px] w-6 sm:w-8 bg-gold/70 rounded-full" />
                  <span className="text-[10px] sm:text-[11px] font-bold tracking-[0.25em] text-gold-light">
                    AL-FADA AL-WASAA
                  </span>
                  <span className="h-[1px] w-6 sm:w-8 bg-gold/70 rounded-full" />
                </div>
              </div>
            </div>
          </Reveal>

          {/* Live Tagline (Scalable typography) */}
          <Reveal delay={0.06}>
            <p className="-mt-1 text-sm sm:text-base font-extrabold tracking-wide text-gold-light">
              الانضباط المؤسسي والريادة الميدانية في اليمن
            </p>
          </Reveal>

          {/* Pristine Complete Sector Icons */}
          <Reveal delay={0.1}>
            <div className="relative h-11 sm:h-12 w-full max-w-[260px]">
              <Image
                src={SITE_CONFIG.assets.sectorIconsStrip}
                alt="المقاولات العامة، الطرق والجسور، النفط، الاتصالات، التسويق"
                fill
                sizes="260px"
                className="object-contain drop-shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
              />
            </div>
          </Reveal>

          {/* Quick links */}
          <Reveal delay={0.14}>
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
              <a href="#faq" className="hover:text-gold-light transition">
                الأسئلة الشائعة
              </a>
              <a
                href="/profile/alfada-alwasaa-profile.pdf"
                download="alfada-alwasaa-profile.pdf"
                className="text-gold font-bold hover:text-gold-light transition underline"
              >
                تحميل البروفايل (PDF)
              </a>
              <LanguageSwitcher variant="pill" />
            </div>
          </Reveal>

          {/* Quick contact and address in footer */}
          <Reveal delay={0.18}>
            <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2.5 text-xs text-white/70">
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

          <Reveal delay={0.2}>
            <p className="max-w-xl text-xs sm:text-sm leading-7 text-white/60">
              {SITE_CONFIG.company.fullName} — {SITE_CONFIG.company.brief}
            </p>
          </Reveal>
        </div>

        <div className="mt-8 flex flex-col items-center justify-between gap-3 border-t border-white/10 pt-5 sm:flex-row">
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
