"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Globe, Check } from "lucide-react";
import { cn } from "@/lib/utils";

interface LanguageSwitcherProps {
  variant?: "pill" | "button" | "menu";
  className?: string;
}

export function LanguageSwitcher({
  variant = "pill",
  className,
}: LanguageSwitcherProps) {
  const pathname = usePathname() || "";
  const isEnglish = pathname.startsWith("/en");

  // التبديل بين النسخة العربية والإنجليزية
  const targetHref = isEnglish ? "/" : "/en";

  // 1. نمط القائمة المنسدلة للجوال (Mobile Drawer Full Block)
  if (variant === "menu") {
    return (
      <div className={cn("rounded-2xl border border-white/10 bg-white/5 p-3", className)}>
        <span className="block text-[11px] font-bold uppercase tracking-wider text-gold-light mb-2.5">
          {isEnglish ? "Language / اللغة" : "اللغة / Language"}
        </span>
        <div className="grid grid-cols-2 gap-2">
          <Link
            href="/"
            className={cn(
              "flex items-center justify-between rounded-xl px-3.5 py-2.5 text-xs font-bold transition",
              !isEnglish
                ? "bg-gold text-navy-darker font-black shadow-md"
                : "bg-white/10 text-white/80 hover:bg-white/20 hover:text-white"
            )}
          >
            <span className="flex items-center gap-1.5">
              <span>العربية</span>
            </span>
            {!isEnglish && <Check className="h-3.5 w-3.5 text-navy-darker stroke-[3]" />}
          </Link>

          <Link
            href="/en"
            className={cn(
              "flex items-center justify-between rounded-xl px-3.5 py-2.5 text-xs font-bold transition",
              isEnglish
                ? "bg-gold text-navy-darker font-black shadow-md"
                : "bg-white/10 text-white/80 hover:bg-white/20 hover:text-white"
            )}
          >
            <span className="flex items-center gap-1.5">
              <span>English</span>
            </span>
            {isEnglish && <Check className="h-3.5 w-3.5 text-navy-darker stroke-[3]" />}
          </Link>
        </div>
      </div>
    );
  }

  // 2. نمط الزر الانسيابي المدمج (Compact Action Button)
  if (variant === "button") {
    return (
      <Link
        href={targetHref}
        className={cn(
          "group inline-flex items-center gap-1.5 rounded-xl border border-white/15 bg-white/10 px-2.5 py-2 text-xs font-bold text-white shadow-sm backdrop-blur-md transition-all duration-300 hover:bg-gold hover:text-navy-darker hover:border-gold hover:shadow-[0_0_15px_rgba(198,149,74,0.4)]",
          className
        )}
        title={isEnglish ? "التبديل إلى النسخة العربية" : "Switch to English version"}
        aria-label={isEnglish ? "التبديل إلى النسخة العربية" : "Switch to English version"}
      >
        <Globe className="h-3.5 w-3.5 text-gold-light group-hover:text-navy-darker transition-colors duration-300" />
        <span className="font-extrabold">{isEnglish ? "العربية" : "EN"}</span>
      </Link>
    );
  }

  // 3. النمط الافتراضي المقسم الأنيق (Segmented Dual Pill)
  return (
    <div
      className={cn(
        "inline-flex items-center rounded-full border border-white/20 bg-navy-darker/60 p-0.5 backdrop-blur-md shadow-sm",
        className
      )}
      role="group"
      aria-label="Language selection"
    >
      <Link
        href="/"
        className={cn(
          "flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold transition-all duration-300",
          !isEnglish
            ? "bg-gold text-navy-darker shadow-sm font-black"
            : "text-white/80 hover:text-white hover:bg-white/10"
        )}
      >
        <span>العربية</span>
      </Link>

      <Link
        href="/en"
        className={cn(
          "flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold transition-all duration-300",
          isEnglish
            ? "bg-gold text-navy-darker shadow-sm font-black"
            : "text-white/80 hover:text-white hover:bg-white/10"
        )}
      >
        <Globe className={cn("h-3 w-3", isEnglish ? "text-navy-darker" : "text-gold-light")} />
        <span>English</span>
      </Link>
    </div>
  );
}
