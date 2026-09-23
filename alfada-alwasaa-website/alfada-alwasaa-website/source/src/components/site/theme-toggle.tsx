"use client";

import * as React from "react";
import { Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { cn } from "@/lib/utils";

export function ThemeToggle({ className }: { className?: string }) {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <button
        type="button"
        aria-label="تبديل المظهر"
        className={cn(
          "flex h-9 w-9 items-center justify-center rounded-xl bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/15",
          className
        )}
      >
        <span className="h-4 w-4" />
      </button>
    );
  }

  const isDark = resolvedTheme === "dark";

  return (
    <button
      type="button"
      onClick={() => setTheme(isDark ? "light" : "dark")}
      aria-label={isDark ? "تفعيل الوضع الفاتح" : "تفعيل الوضع الداكن"}
      title={isDark ? "تفعيل الوضع الفاتح" : "تفعيل الوضع الداكن"}
      className={cn(
        "relative flex h-9 w-9 items-center justify-center rounded-xl transition-all duration-300",
        "bg-white/10 text-white ring-1 ring-white/15 hover:bg-white/20 hover:text-gold-light hover:ring-gold/40 active:scale-95",
        className
      )}
    >
      {isDark ? (
        <Sun className="h-4 w-4 text-gold transition-transform duration-300 rotate-0 hover:rotate-45" />
      ) : (
        <Moon className="h-4 w-4 text-gold-light transition-transform duration-300 rotate-0 hover:-rotate-12" />
      )}
    </button>
  );
}
