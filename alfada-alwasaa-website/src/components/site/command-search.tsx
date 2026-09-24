"use client";

import React, { useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
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
import { EN_SITE_CONFIG } from "@/config/en-site";
import { EN_BLOG_POSTS } from "@/config/en-blog-data";

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
  const pathname = usePathname() || "";
  const isEnglish = pathname.startsWith("/en");

  const t = isEnglish
    ? {
        dir: "ltr" as const,
        label: "Quick site search — Al-Fada Al-Wasaa",
        placeholder: "Search services (roads, telecom, supplies), articles, or projects...",
        close: "Close search",
        empty: "No matching results found.",
        groupServices: "Core Services",
        groupTrack: "Track Record & Sectors",
        groupBlog: "Articles & Studies",
        groupActions: "Quick Actions & Contact",
        track1: "Road Cutting, Paving & Corridor Grading Projects",
        track1Value: "road cutting paving grading corridors contracting",
        track2: "Telecom Towers & Off-Grid Solar Field Sites",
        track2Value: "telecom towers solar maintenance field networks",
        track3: "Customs Clearance & Multi-Modal Port Logistics",
        track3Value: "customs clearance port logistics release supply chain",
        action1: "Request a project consultation or quotation",
        action1Value: "request consultation quotation contact form",
        action2: "FAQ & Contracting Clarifications",
        action2Value: "faq questions clarifications quality assurance",
        action3: "Call General Management directly",
        nav: "Navigate:",
        select: "Select:",
        closeHint: "Close:",
      }
    : {
        dir: "rtl" as const,
        label: "البحث السريع في موقع الفضاء الواسع",
        placeholder: "ابحث عن الخدمات (طرق، اتصالات، عوازل، توريد)، المقالات، أو المشاريع...",
        close: "إغلاق البحث",
        empty: "لم يتم العثور على أي نتائج مطابقة لكلمة البحث.",
        groupServices: "منظومة الخدمات الرئيسية",
        groupTrack: "سابقة الأعمال والقطاعات",
        groupBlog: "المقالات والدراسات",
        groupActions: "إجراءات سريعة وتواصل",
        track1: "مشاريع شق وتعبيد الطرق والجسور",
        track1Value: "مشاريع شق وتعبيد الطرق وتسوية المسارات مقاولات",
        track2: "أبراج الاتصالات والطاقة الشمسية الميدانية",
        track2Value: "تجهيز أبراج الاتصالات والصيانة الميدانية شبكات",
        track3: "التخليص الجمركي والشحن متعدد الوسائط",
        track3Value: "التخليص الجمركي وإدارة سلاسل الإفراج المينائي موانئ",
        action1: "طلب استشارة أو تسعير مشروع",
        action1Value: "طلب استشارة أو تسعير نموذج التواصل تواصل معنا",
        action2: "الأسئلة الشائعة وإيضاحات التعاقد",
        action2Value: "الأسئلة الشائعة إيضاحات ضمان الجودة",
        action3: "اتصال هاتفي بالإدارة العامة",
        nav: "التنقل:",
        select: "الاختيار:",
        closeHint: "الإغلاق:",
      };

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

  const servicesList = isEnglish ? EN_SITE_CONFIG.servicesList : SITE_CONFIG.servicesList;
  const blogPosts = isEnglish ? Object.values(EN_BLOG_POSTS) : Object.values(BLOG_POSTS);
  const trackHref = isEnglish ? "/en#track" : "/#track";
  const contactHref = isEnglish ? "/en#contact" : "/#contact";
  const faqHref = isEnglish ? "/en#faq" : "/#faq";

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
          dir={t.dir}
          label={t.label}
          className="flex flex-col w-full"
        >
          {/* Header & Search Input */}
          <div className="flex items-center gap-3 border-b border-white/10 px-4 py-3 sm:px-5">
            <Search className="h-5 w-5 text-gold-light shrink-0" />
            <Command.Input
              autoFocus
              placeholder={t.placeholder}
              className="w-full bg-transparent text-sm sm:text-base font-semibold text-white placeholder:text-white/50 focus:outline-none"
            />
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="rounded-lg p-1.5 text-white/50 hover:bg-white/10 hover:text-white transition"
              aria-label={t.close}
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Results List */}
          <Command.List className="max-h-[60vh] overflow-y-auto p-3 sm:p-4 space-y-4 text-sm scrollbar-thin">
            <Command.Empty className="py-12 text-center text-sm font-bold text-white/60">
              {t.empty}
            </Command.Empty>

            {/* خدمات الشركة */}
            <Command.Group heading={t.groupServices} className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                {servicesList.map((service) => {
                  const Icon = SERVICE_ICONS[service.slug] || Briefcase;
                  return (
                    <Command.Item
                      key={service.slug}
                      value={`${service.title} ${service.desc} ${service.slug}`}
                      onSelect={() =>
                        handleSelect(() =>
                          router.push(isEnglish ? `/en/services/${service.slug}` : `/services/${service.slug}`)
                        )
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
            <Command.Group heading={t.groupTrack} className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                <Command.Item
                  value={t.track1Value}
                  onSelect={() => handleSelect(() => router.push(trackHref))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Route className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">{t.track1}</span>
                </Command.Item>
                <Command.Item
                  value={t.track2Value}
                  onSelect={() => handleSelect(() => router.push(trackHref))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <RadioTower className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">{t.track2}</span>
                </Command.Item>
                <Command.Item
                  value={t.track3Value}
                  onSelect={() => handleSelect(() => router.push(trackHref))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Ship className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">{t.track3}</span>
                </Command.Item>
              </div>
            </Command.Group>

            {/* مقالات المدونة */}
            <Command.Group heading={t.groupBlog} className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                {blogPosts.map((post) => (
                  <Command.Item
                    key={post.slug}
                    value={`${post.title} ${post.description}`}
                    onSelect={() =>
                      handleSelect(() =>
                        router.push(isEnglish ? `/en/blog/${post.slug}` : `/blog/${post.slug}`)
                      )
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
            <Command.Group heading={t.groupActions} className="text-xs font-bold text-gold-light px-2 mb-2">
              <div className="mt-2 space-y-1">
                <Command.Item
                  value={t.action1Value}
                  onSelect={() => handleSelect(() => router.push(contactHref))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <MessageSquare className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">{t.action1}</span>
                </Command.Item>
                <Command.Item
                  value={t.action2Value}
                  onSelect={() => handleSelect(() => router.push(faqHref))}
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <HelpCircle className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">{t.action2}</span>
                </Command.Item>
                <Command.Item
                  value={isEnglish ? "call general management phone direct" : "اتصال الإدارة العامة هاتف مباشر"}
                  onSelect={() =>
                    handleSelect(() => {
                      window.location.href = SITE_CONFIG.contacts.general.telHref;
                    })
                  }
                  className="flex cursor-pointer items-center gap-3 rounded-2xl px-3.5 py-2 text-white/90 hover:bg-gold/20 hover:text-white aria-selected:bg-gold aria-selected:text-navy-darker transition-colors"
                >
                  <Phone className="h-4 w-4 shrink-0 text-gold" />
                  <span className="text-xs sm:text-sm font-bold">
                    {t.action3} ({SITE_CONFIG.contacts.general.display})
                  </span>
                </Command.Item>
              </div>
            </Command.Group>
          </Command.List>

          {/* Footer keyboard guidance */}
          <div className="flex items-center justify-between border-t border-white/10 px-4 py-2.5 text-[11px] text-white/50 bg-navy-darker/60">
            <div className="flex items-center gap-3">
              <span>{t.nav} <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↑</kbd> <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↓</kbd></span>
              <span>{t.select} <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">↵ Enter</kbd></span>
            </div>
            <span>{t.closeHint} <kbd className="rounded bg-white/10 px-1.5 py-0.5 font-mono text-[10px] text-white">Esc</kbd></span>
          </div>
        </Command>
      </div>
    </div>
  );
}
