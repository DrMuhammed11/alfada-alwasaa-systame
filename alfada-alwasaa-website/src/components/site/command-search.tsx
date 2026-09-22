"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Command } from "cmdk";
import { 
  Search, 
  Building2, 
  Route, 
  Shovel, 
  Package, 
  RadioTower, 
  MonitorSmartphone, 
  Ship, 
  FileText, 
  Phone, 
  MessageSquare, 
  HelpCircle,
  Briefcase,
  X
} from "lucide-react";
import { SITE_CONFIG } from "@/config/site";
import { BLOG_POSTS } from "@/config/blog-data";

interface CommandSearchProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const SERVICE_ICONS: Record<string, React.ElementType> = {
  contracting: Building2,
  roads: Route,
  excavation: Shovel,
  supplies: Package,
  telecom: RadioTower,
  marketing: MonitorSmartphone,
  shipping: Ship,
};

export function CommandSearch({ open, onOpenChange }: CommandSearchProps) {
  const router = useRouter();

  // الاستماع لاختصارات لوحة المفاتيح Ctrl+K أو ⌘K أو /
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if ((e.key === "k" && (e.metaKey || e.ctrlKey)) || (e.key === "/" && !open && document.activeElement?.tagName !== "INPUT" && document.activeElement?.tagName !== "TEXTAREA")) {
        e.preventDefault();
        onOpenChange(!open);
      }
    };

    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, [open, onOpenChange]);

  const handleSelect = (callback: () => void) => {
    onOpenChange(false);
    callback();
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-start justify-center pt-16 sm:pt-24 px-4 bg-navy-darker/70 backdrop-blur-md transition-all">
      {/* Background click to close */}
      <div 
        className="fixed inset-0 -z-10" 
        onClick={() => onOpenChange(false)} 
        aria-hidden="true" 
      />

      <div className="relative w-full max-w-2xl overflow-hidden rounded-3xl border border-gold/40 bg-navy-deep/98 text-white shadow-[0_25px_70px_rgba(0,0,0,0.7)] ring-1 ring-white/10">
        <Command
          dir="rtl"
          label="البحث السريع في موقع الفضاء الواسع"
          className="flex flex-col w-full"
        >
          {/* Header & Search Input */}
          <div className="flex items-center gap-3 border-b border-white/10 px-4 py-3 sm:px-5">
            <Search className="h-5 w-5 text-gold-light shrink-0" />
            <Command.Input
              autoFocus
              placeholder="ابحث عن الخدمات (طرق، اتصالات، عوازل، توريد)، المقالات، أو المشاريع..."
              className="w-full bg-transparent text-sm sm:text-base font-semibold text-white placeholder:text-white/50 focus:outline-none"
            />
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="rounded-lg p-1.5 text-white/50 hover:bg-white/10 hover:text-white transition"
              aria-label="إغلاق البحث"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Results List */}
          <Command.List className="max-h-[60vh] overflow-y-auto p-3 sm:p-4 space-y-4 text-sm scrollbar-thin">
            <Command.Empty className="py-12 text-center text-sm font-bold text-white/60">
              لم يتم العثور على أي نتائج مطابقة لكلمة البحث.
            </Command.Empty>

            {/* خدمات الشركة */}
            <Command.Group heading="منظومة الخدمات الرئيسية" className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                {SITE_CONFIG.servicesList.map((service) => {
                  const Icon = SERVICE_ICONS[service.slug] || Briefcase;
                  return (
                    <Command.Item
                      key={service.slug}
                      value={`${service.title} ${service.desc} ${service.slug}`}
                      onSelect={() =>
                        handleSelect(() => router.push(`/services/${service.slug}`))
                      }
                      className="flex cursor-pointer items-center justify-between rounded-2xl px-3.5 py-2.5 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-white/10 text-gold-light shrink-0">
                          <Icon className="h-4 w-4" />
                        </span>
                        <div>
                          <span className="font-bold text-xs sm:text-sm block">
                            {service.title}
                          </span>
                          <span className="text-[11px] opacity-75 line-clamp-1 block">
                            {service.desc}
                          </span>
                        </div>
                      </div>
                      <span className="font-mono text-xs font-black opacity-80">
                        #{service.num}
                      </span>
                    </Command.Item>
                  );
                })}
              </div>
            </Command.Group>

            {/* سابقة الأعمال والقطاعات */}
            <Command.Group heading="سابقة الأعمال والقطاعات" className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                <Command.Item
                  value="مشاريع شق وتعبيد الطرق وتسوية المسارات مقاولات"
                  onSelect={() => handleSelect(() => router.push("/#track"))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Route className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">مشاريع شق وتعبيد الطرق والجسور</span>
                </Command.Item>
                <Command.Item
                  value="تجهيز أبراج الاتصالات والصيانة الميدانية شبكات"
                  onSelect={() => handleSelect(() => router.push("/#track"))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <RadioTower className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">أبراج الاتصالات والطاقة الشمسية الميدانية</span>
                </Command.Item>
                <Command.Item
                  value="التخليص الجمركي وإدارة سلاسل الإفراج المينائي موانئ"
                  onSelect={() => handleSelect(() => router.push("/#track"))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Ship className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">التخليص الجمركي والشحن متعدد الوسائط</span>
                </Command.Item>
              </div>
            </Command.Group>

            {/* مقالات المدونة */}
            <Command.Group heading="المقالات والدراسات" className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                {Object.values(BLOG_POSTS).map((post) => (
                  <Command.Item
                    key={post.slug}
                    value={`${post.title} ${post.description}`}
                    onSelect={() =>
                      handleSelect(() => router.push(`/blog/${post.slug}`))
                    }
                    className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                  >
                    <FileText className="h-4 w-4 shrink-0 text-gold" />
                    <span className="text-xs sm:text-sm font-bold line-clamp-1">{post.title}</span>
                  </Command.Item>
                ))}
              </div>
            </Command.Group>

            {/* إجراءات سريعة وتواصل */}
            <Command.Group heading="إجراءات سريعة وتواصل" className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                <Command.Item
                  value="طلب استشارة أو تسعير نموذج التواصل تواصل معنا"
                  onSelect={() => handleSelect(() => router.push("/#contact"))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <MessageSquare className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">طلب استشارة أو تسعير مشروع</span>
                </Command.Item>
                <Command.Item
                  value="الأسئلة الشائعة إيضاحات ضمان الجودة"
                  onSelect={() => handleSelect(() => router.push("/#faq"))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <HelpCircle className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">الأسئلة الشائعة وإيضاحات التعاقد</span>
                </Command.Item>
                <Command.Item
                  value="اتصال الإدارة العامة هاتف مباشر"
                  onSelect={() =>
                    handleSelect(() => {
                      window.location.href = SITE_CONFIG.contacts.general.telHref;
                    })
                  }
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Phone className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">
                    اتصال هاتفي بالإدارة العامة ({SITE_CONFIG.contacts.general.display})
                  </span>
                </Command.Item>
              </div>
            </Command.Group>
          </Command.List>

          {/* Footer keyboard guidance */}
          <div className="flex items-center justify-between border-t border-white/10 px-4 py-2.5 text-[11px] text-white/50 bg-navy-darker/60">
            <div className="flex items-center gap-3">
              <span>التنقل: <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↑</kbd> <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↓</kbd></span>
              <span>الاختيار: <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↵ Enter</kbd></span>
            </div>
            <span>الإغلاق: <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">Esc</kbd></span>
          </div>
        </Command>
      </div>
    </div>
  );
}
