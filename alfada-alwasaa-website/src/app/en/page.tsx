"use client";

import { useState, useEffect, useSyncExternalStore } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import {
  Building2,
  Route,
  Shovel,
  Package,
  RadioTower,
  Ship,
  MonitorSmartphone,
  Flame,
  Truck,
  Factory,
  Globe2,
  ShieldCheck,
  Award,
  HardHat,
  FileCheck2,
  Gem,
  HandHeart,
  Eye,
  Handshake,
  Star,
  Quote,
  ChevronDown,
  Phone,
  Mail,
  MapPin,
  Clock,
  Send,
  Search,
  Copy,
  Check,
  CheckCircle2,
  AlertCircle,
  Loader2,
  MessageSquare,
  ArrowRight,
  Menu,
  X,
  ArrowUp,
  Download,
  Share2,
  Briefcase,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { SITE_CONFIG } from "@/config/site";
import { ThemeToggle } from "@/components/site/theme-toggle";
import { LanguageSwitcher } from "@/components/site/language-switcher";
import { CommandSearch } from "@/components/site/command-search";
import { submitInquiry, trackInquiry, type TrackingResult } from "@/lib/api";

const enInquirySchema = z.object({
  name: z
    .string()
    .trim()
    .min(2, { message: "Please enter your name (at least 2 characters)" })
    .max(100, { message: "Name is too long (maximum 100 characters)" }),
  phone: z
    .string()
    .trim()
    .min(8, { message: "Please enter a valid phone number (at least 8 digits)" })
    .max(20, { message: "Phone number is too long" })
    .regex(/^[+0-9][0-9\s-]{7,19}$/, {
      message: "Please enter a valid phone number (e.g. +967... or 776999942)",
    }),
  email: z
    .string()
    .trim()
    .email({ message: "Please enter a valid email address (e.g. name@domain.com)" })
    .optional()
    .or(z.literal("")),
  service: z
    .string()
    .trim()
    .min(1, { message: "Please select a required service sector" }),
  message: z
    .string()
    .trim()
    .max(1500, { message: "Message text must not exceed 1500 characters" })
    .optional()
    .or(z.literal("")),
});

type EnInquiryFormValues = z.infer<typeof enInquirySchema>;

const SERVICE_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  contracting: Building2,
  roads: Route,
  excavation: Shovel,
  supplies: Package,
  telecom: RadioTower,
  shipping: Ship,
  marketing: MonitorSmartphone,
};

const PARTNER_ICONS = [
  RadioTower,
  Flame,
  Building2,
  Ship,
  Truck,
  Factory,
  Globe2,
  ShieldCheck,
];

function getTimelineStep(status: string): number {
  const upper = status?.toUpperCase() || "";
  if (["APPROVED", "SENT", "CLOSED", "ARCHIVED"].includes(upper)) return 4;
  if (["IN_PROGRESS", "PENDING_APPROVAL"].includes(upper)) return 3;
  if (["REFERRED", "UNDER_REVIEW"].includes(upper)) return 2;
  return 1;
}

function getStatusBadge(status: string) {
  const upper = status?.toUpperCase() || "";
  if (upper === "RECEIVED" || upper === "UNDER_REVIEW") {
    return {
      label: "Technical Review in Progress",
      badgeClass: "bg-amber-50 text-amber-800 ring-1 ring-amber-300",
      dotClass: "bg-amber-500",
    };
  }
  if (upper === "REFERRED" || upper === "IN_PROGRESS") {
    return {
      label: "Active Processing & Study",
      badgeClass: "bg-sky-50 text-sky-800 ring-1 ring-sky-300",
      dotClass: "bg-sky-500",
    };
  }
  if (["APPROVED", "SENT", "CLOSED", "ARCHIVED"].includes(upper)) {
    return {
      label: "Completed & Formally Handled",
      badgeClass: "bg-emerald-50 text-emerald-800 ring-1 ring-emerald-300",
      dotClass: "bg-emerald-500",
    };
  }
  if (upper === "CANCELLED" || upper === "REJECTED") {
    return {
      label: "Closed or Ineligible",
      badgeClass: "bg-rose-50 text-rose-800 ring-1 ring-rose-300",
      dotClass: "bg-rose-500",
    };
  }
  return {
    label: "Under Follow-up",
    badgeClass: "bg-slate-100 text-slate-800 ring-1 ring-slate-300",
    dotClass: "bg-slate-500",
  };
}

function subscribeToStorage(callback: () => void) {
  window.addEventListener("storage", callback);
  return () => window.removeEventListener("storage", callback);
}

function getStoredRef(): string | null {
  try {
    return localStorage.getItem("lastInquiryRef");
  } catch {
    return null;
  }
}

export default function EnglishHomePage() {
  const [activeTab, setActiveTab] = useState("contracting");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [faqOpenIndex, setFaqOpenIndex] = useState<number | null>(0);
  const [showTopBtn, setShowTopBtn] = useState(false);
  const [floatingMenuOpen, setFloatingMenuOpen] = useState(false);

  // Contact form & inquiry tracking state
  const [contactTab, setContactTab] = useState<"form" | "track">("form");
  const [submitted, setSubmitted] = useState(false);
  const [generatedRef, setGeneratedRef] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const storedRef = useSyncExternalStore(subscribeToStorage, getStoredRef, () => null);
  const [submittedRef, setSubmittedRef] = useState<string | null>(null);
  const savedRefNumber = submittedRef || storedRef;

  const [trackInput, setTrackInput] = useState("");
  const [trackTokenInput, setTrackTokenInput] = useState("");
  const [isTracking, setIsTracking] = useState(false);
  const [trackingResult, setTrackingResult] = useState<TrackingResult | null>(null);
  const [trackErrorMessage, setTrackErrorMessage] = useState<string | null>(null);

  const [selectedService, setSelectedService] = useState<string>(EN_SITE_CONFIG.sectorOptions[0]);

  useEffect(() => {
    const handleScroll = () => setShowTopBtn(window.scrollY > 400);
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<EnInquiryFormValues>({
    resolver: zodResolver(enInquirySchema),
    mode: "onTouched",
    defaultValues: {
      name: "",
      phone: "",
      email: "",
      service: EN_SITE_CONFIG.sectorOptions[0],
      message: "",
    },
  });

  const onSubmit = async (values: EnInquiryFormValues) => {
    setSubmitError(null);
    try {
      const res = await submitInquiry({
        name: values.name,
        phone: values.phone,
        email: values.email || undefined,
        service: values.service,
        message: values.message || undefined,
      });

      if (res.success && res.refNumber) {
        setGeneratedRef(res.refNumber);
        setSubmittedRef(res.refNumber);
        if (res.trackingToken) {
          try {
            localStorage.setItem("lastTrackingToken", res.trackingToken);
          } catch {}
        }
        try {
          localStorage.setItem("lastInquiryRef", res.refNumber);
        } catch {}
        setSubmitted(true);
        reset();
        toast.success("Your proposal request has been successfully submitted!", {
          description: `Reference Number: ${res.refNumber}`,
          duration: 10000,
        });
      } else {
        throw new Error(res.message || "Failed to submit request");
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "A connection error occurred. Please try again or reach out via WhatsApp.";
      setSubmitError(msg);
      toast.error("Failed to submit request", { description: msg });
    }
  };

  const handleTrackSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanRef = trackInput.trim().toUpperCase();
    const cleanToken = trackTokenInput.trim();

    if (!cleanRef) {
      setTrackErrorMessage("Please enter a valid reference number");
      return;
    }

    setIsTracking(true);
    setTrackErrorMessage(null);
    setTrackingResult(null);

    try {
      const res = await trackInquiry(cleanRef, cleanToken || undefined);
      if (res.success && res.data) {
        setTrackingResult(res.data);
      } else {
        setTrackErrorMessage(res.error || "No matching inquiry found. Please verify the reference number and security token.");
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to retrieve status. Please try again.";
      setTrackErrorMessage(msg);
    } finally {
      setIsTracking(false);
    }
  };

  const handleQuickTrack = (ref: string) => {
    setTrackInput(ref);
    let token = trackTokenInput;
    try {
      const saved = localStorage.getItem("lastTrackingToken");
      if (saved) {
        token = saved;
        setTrackTokenInput(saved);
      }
    } catch {}
    handleTrackSubmit({ preventDefault: () => {} } as React.FormEvent);
  };

  const activeService =
    EN_SITE_CONFIG.servicesList.find((s) => s.slug === activeTab) ||
    EN_SITE_CONFIG.servicesList[0];

  const whatsappMessage = encodeURIComponent(
    `Hello, I would like to inquire about Al-Fada Al-Wasaa Company regarding: ${selectedService || "General Services"}`
  );

  return (
    <div className="flex min-h-screen flex-col bg-white dark:bg-navy-darker text-slate-900 dark:text-white transition-colors duration-300 font-sans" dir="ltr">
      
      {/* English Site Header */}
      <header className="fixed inset-x-0 top-0 z-50 bg-navy/95 backdrop-blur-md shadow-md border-b border-white/10 text-white">
        <div className="mx-auto flex h-[76px] max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          {/* Brand */}
          <Link href="/en" className="flex items-center gap-3" aria-label="Al-Fada Al-Wasaa Home">
            <span className="relative h-11 w-11 overflow-hidden rounded-xl bg-white/5 ring-1 ring-gold/40 sm:h-12 sm:w-12">
              <Image
                src={SITE_CONFIG.assets.logoMark}
                alt="Al-Fada Al-Wasaa Logo"
                fill
                sizes="(max-width: 640px) 44px, 48px"
                className="object-contain p-1"
                priority
              />
            </span>
            <span className="leading-tight">
              <span className="block text-base font-extrabold text-white sm:text-lg tracking-tight">
                AL-FADA AL-WASAA
              </span>
              <span className="block text-[9.5px] font-semibold tracking-[0.24em] text-gold-light sm:text-[10.5px]">
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

            {/* Language Switcher Button next to Theme Toggle */}
            <LanguageSwitcher variant="button" />

            <ThemeToggle />

            <a
              href="#contact"
              className="rounded-full bg-gold px-5 py-2 text-xs font-black text-navy-darker shadow-md hover:bg-gold-light transition"
            >
              Request Quote
            </a>
          </div>

          {/* Mobile buttons */}
          <div className="flex items-center gap-2 lg:hidden">
            <button
              type="button"
              onClick={() => setSearchOpen(true)}
              aria-label="Quick Search"
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white"
            >
              <Search className="h-4 w-4 text-gold-light" />
            </button>
            <LanguageSwitcher variant="button" />
            <ThemeToggle />
            <button
              type="button"
              onClick={() => setMobileMenuOpen((v) => !v)}
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 text-white"
              aria-label="Toggle Navigation"
            >
              {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.nav
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              className="border-t border-white/10 bg-navy-deep px-4 py-4 lg:hidden"
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
                  href="#contact"
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
            </motion.nav>
          )}
        </AnimatePresence>
      </header>

      {/* Command Search Palette */}
      <CommandSearch open={searchOpen} onOpenChange={setSearchOpen} />

      {/* Hero Section */}
      <section id="home" className="relative flex items-center overflow-hidden bg-navy-darker pt-28 pb-16 sm:pb-24 text-white">
        <div className="absolute inset-0 -z-10">
          <Image
            src={SITE_CONFIG.assets.heroBg}
            alt="Corporate Project Sites"
            fill
            priority
            sizes="100vw"
            className="object-cover opacity-20 filter brightness-75 contrast-125"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-navy-darker/90 via-navy-darker/60 to-navy-darker" />
        </div>

        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid items-center gap-10 lg:grid-cols-12">
            <div className="lg:col-span-7">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-gold/10 px-4 py-1.5 text-xs font-bold text-gold-light">
                <span className="h-2 w-2 rounded-full bg-gold animate-pulse" />
                <span>Multi-Sector Enterprise • Integrated Solutions</span>
              </span>

              <h1 className="mt-4 text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight leading-tight">
                Al-Fada Al-Wasaa <br />
                <span className="text-gold">Telecom & Contracting</span>
              </h1>

              <p className="mt-3 text-lg font-bold text-gold-light">
                {EN_SITE_CONFIG.company.tagline}
              </p>

              <p className="mt-4 text-sm sm:text-base leading-relaxed text-white/80 max-w-2xl">
                {EN_SITE_CONFIG.company.brief}
              </p>
              <p className="mt-2 text-xs sm:text-sm leading-relaxed text-white/70 max-w-2xl">
                {EN_SITE_CONFIG.company.subBrief}
              </p>

              <div className="mt-8 flex flex-wrap items-center gap-4">
                <a
                  href="#contact"
                  className="rounded-full bg-gold px-7 py-3 text-sm font-black text-navy-darker shadow-lg hover:bg-gold-light hover:shadow-xl transition"
                >
                  Request Consultation or Quote
                </a>
                <a
                  href={EN_SITE_CONFIG.contacts.general.waHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-full border border-emerald-500/40 bg-emerald-500/20 px-6 py-3 text-sm font-bold text-emerald-300 hover:bg-emerald-500 hover:text-white transition"
                >
                  <MessageSquare className="h-4 w-4" />
                  <span>WhatsApp Management</span>
                </a>
              </div>
            </div>

            {/* Emblem Card */}
            <div className="lg:col-span-5 flex justify-center">
              <div className="relative w-full max-w-sm rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl shadow-2xl">
                <div className="relative mx-auto aspect-square w-48 overflow-hidden rounded-2xl bg-navy-darker/60 p-4 border border-gold/30">
                  <Image
                    src={SITE_CONFIG.assets.logoTransparent}
                    alt="Al-Fada Al-Wasaa"
                    fill
                    sizes="(max-width: 640px) 192px, 240px"
                    className="object-contain p-2"
                  />
                </div>
                <div className="mt-6 text-center">
                  <h3 className="text-lg font-extrabold text-white">AL-FADA AL-WASAA</h3>
                  <p className="text-xs text-gold-light">Telecom & Contracting Corporate Entity</p>
                </div>
                <div className="mt-4 grid grid-cols-3 gap-2 border-t border-white/10 pt-4 text-center">
                  <div>
                    <span className="block text-xs font-bold text-white">10+ Years</span>
                    <span className="text-[10px] text-white/60">Field Practice</span>
                  </div>
                  <div>
                    <span className="block text-xs font-bold text-white">65+ Sites</span>
                    <span className="text-[10px] text-white/60">Completed</span>
                  </div>
                  <div>
                    <span className="block text-xs font-bold text-white">100%</span>
                    <span className="text-[10px] text-white/60">Compliance</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Pillars Strip */}
          <div className="mt-12 grid gap-4 sm:grid-cols-3">
            {EN_SITE_CONFIG.pillars.map((pillar, i) => (
              <div
                key={i}
                className="flex items-center gap-4 rounded-2xl border border-white/10 bg-white/5 p-4 backdrop-blur-md hover:border-gold/50 transition"
              >
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gold text-navy-darker font-black">
                  {i === 0 ? <Briefcase className="h-5 w-5" /> : i === 1 ? <ShieldCheck className="h-5 w-5" /> : <Award className="h-5 w-5" />}
                </div>
                <div>
                  <h4 className="text-sm font-extrabold text-white">{pillar.title}</h4>
                  <p className="text-xs text-gold-light">{pillar.subtitle}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Operational Indicators & Statistics (Matching Arabic exactly) */}
      <section className="relative -mt-6 z-20 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 shadow-xl">
          {EN_SITE_CONFIG.stats.map((st, i) => (
            <div key={i} className="text-center sm:text-left border-b sm:border-b-0 sm:border-r border-slate-100 dark:border-white/10 last:border-0 p-3">
              <span className="block text-3xl sm:text-4xl font-black text-navy dark:text-gold tracking-tight">
                {st.num}
              </span>
              <h4 className="mt-1 text-sm font-bold text-slate-900 dark:text-white">
                {st.label}
              </h4>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                {st.sub}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Partners Marquee Strip */}
      <section className="py-12 bg-slate-50 dark:bg-navy-darker/40 border-b border-navy/5 dark:border-white/5 overflow-hidden">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mb-6 text-center">
          <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-gold-light">
            Ecosystem Network & Strategic Sectors
          </span>
        </div>
        <div className="flex gap-6 animate-marquee whitespace-nowrap overflow-x-auto py-2 px-4 no-scrollbar">
          {EN_SITE_CONFIG.partnerCategories.map((name, idx) => {
            const IconComp = PARTNER_ICONS[idx % PARTNER_ICONS.length];
            return (
              <div
                key={idx}
                className="inline-flex items-center gap-2.5 rounded-full border border-navy/10 dark:border-white/10 bg-white dark:bg-navy px-5 py-2.5 shadow-sm text-xs font-bold text-navy dark:text-white shrink-0"
              >
                <IconComp className="h-4 w-4 text-gold" />
                <span>{name}</span>
              </div>
            );
          })}
        </div>
      </section>

      {/* Institutional Compliance & Quality Badges */}
      <section className="py-14 bg-white dark:bg-navy-darker border-b border-navy/5 dark:border-white/5">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light ring-1 ring-gold/30">
              Institutional Compliance & Certifications
            </span>
            <h2 className="mt-2 text-2xl sm:text-3xl font-extrabold text-navy dark:text-white">
              Approved Engineering Standards & Trusted Credentials
            </h2>
            <p className="mt-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
              Upholding rigorous international benchmarks across safety, materials testing, and technical compliance.
            </p>
          </div>

          <div className="grid gap-4 sm:gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {EN_SITE_CONFIG.compliance.map((item, idx) => (
              <div
                key={idx}
                className="flex flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50/80 dark:bg-navy p-5 shadow-sm hover:border-gold/60 transition"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gold/15 text-gold-light dark:text-gold">
                      {idx === 0 ? <Award className="h-5 w-5" /> : idx === 1 ? <HardHat className="h-5 w-5" /> : idx === 2 ? <FileCheck2 className="h-5 w-5" /> : <ShieldCheck className="h-5 w-5" />}
                    </span>
                    <span className="rounded-full bg-gold/10 px-2.5 py-0.5 text-[10px] font-bold text-navy dark:text-gold-light border border-gold/30">
                      {item.badge}
                    </span>
                  </div>
                  <h3 className="text-sm font-bold text-navy dark:text-white">{item.title}</h3>
                  <p className="mt-1 text-[11px] font-semibold text-gold dark:text-gold-light">{item.subtitle}</p>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Strategic Sectors Section */}
      <section id="sectors" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Core Strategic Sectors
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Five Pillars of Operational Mastery
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Deploying interconnected capabilities that combine engineering proficiency, heavy equipment fleets, and nationwide logistics readiness.
            </p>
          </div>

          <div className="space-y-12">
            {EN_SITE_CONFIG.sectors.map((sec) => (
              <div
                key={sec.num}
                className="overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 sm:p-8 shadow-md hover:shadow-xl transition"
              >
                <div className="grid gap-8 lg:grid-cols-12 items-center">
                  <div className="lg:col-span-6 space-y-4">
                    <span className="inline-block rounded-full bg-gold/10 px-3 py-1 text-xs font-extrabold text-gold-light border border-gold/30 font-mono">
                      Sector {sec.num}
                    </span>
                    <h3 className="text-2xl font-black text-navy dark:text-white">{sec.title}</h3>
                    <ul className="space-y-2 pt-2">
                      {sec.services.map((item, idx) => (
                        <li key={idx} className="flex items-start gap-2.5 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
                          <CheckCircle2 className="h-4 w-4 text-gold shrink-0 mt-0.5" />
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                    <div className="pt-4 flex items-center gap-3">
                      <a
                        href="#contact"
                        className="inline-flex items-center gap-1.5 rounded-xl bg-gold px-4 py-2 text-xs font-bold text-navy-darker hover:bg-gold-light transition"
                      >
                        <span>Inquire About Sector</span>
                        <ArrowRight className="h-3.5 w-3.5" />
                      </a>
                    </div>
                  </div>

                  <div className="lg:col-span-6">
                    <div className="grid grid-cols-2 gap-3">
                      {sec.photos.map((ph, idx) => (
                        <div key={idx} className="relative aspect-[4/3] overflow-hidden rounded-2xl bg-navy-darker">
                          <Image
                            src={ph.src}
                            alt={ph.alt}
                            fill
                            loading="lazy"
                            sizes="(max-width: 1024px) 50vw, 25vw"
                            className="object-cover hover:scale-105 transition duration-500"
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Comprehensive Detailed Services Section */}
      <section id="services" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Detailed Services Portfolio
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Integrated Technical & Engineering Services
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Browse our key specialization areas, review execution specifications, or request direct tender proposals.
            </p>
          </div>

          {/* Service Tabs Header */}
          <div className="flex flex-wrap justify-center gap-2 mb-10">
            {EN_SITE_CONFIG.servicesList.map((svc) => {
              const Icon = SERVICE_ICONS[svc.slug] || Building2;
              const isSelected = activeTab === svc.slug;
              return (
                <button
                  key={svc.slug}
                  onClick={() => setActiveTab(svc.slug)}
                  className={`inline-flex items-center gap-2 rounded-2xl px-4 py-2.5 text-xs sm:text-sm font-bold transition ${
                    isSelected
                      ? "bg-navy dark:bg-gold text-white dark:text-navy-darker shadow-md"
                      : "bg-slate-100 dark:bg-white/10 text-slate-600 dark:text-white/80 hover:bg-slate-200 dark:hover:bg-white/15"
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{svc.title}</span>
                </button>
              );
            })}
          </div>

          {/* Active Service Tab Detail */}
          <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6 sm:p-10 shadow-lg">
            <div className="grid gap-8 lg:grid-cols-12 items-center">
              <div className="lg:col-span-7 space-y-4">
                <span className="font-mono text-xs font-bold text-gold-light">SERVICE {activeService.num}</span>
                <h3 className="text-2xl sm:text-3xl font-black text-navy dark:text-white">{activeService.title}</h3>
                <p className="text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                  {activeService.desc}
                </p>

                <div className="pt-4 flex flex-wrap items-center gap-3">
                  <a
                    href="#contact"
                    className="inline-flex items-center gap-2 rounded-2xl bg-gold px-5 py-3 text-xs sm:text-sm font-black text-navy-darker hover:bg-gold-light transition shadow-md"
                  >
                    <span>Request Quotation</span>
                    <ArrowRight className="h-4 w-4" />
                  </a>
                  <a
                    href={`https://wa.me/${EN_SITE_CONFIG.contacts.general.waNumber}?text=${encodeURIComponent(`Hello, I would like to inquire about ${activeService.title} services.`)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-2xl bg-emerald-500/10 px-4 py-3 text-xs sm:text-sm font-bold text-emerald-700 dark:text-emerald-300 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                  >
                    <MessageSquare className="h-4 w-4" />
                    <span>WhatsApp Technical Lead</span>
                  </a>
                </div>
              </div>

              <div className="lg:col-span-5">
                <div className="relative aspect-[16/11] overflow-hidden rounded-2xl border border-gold/30 bg-navy-darker shadow-lg">
                  <Image
                    src={SITE_CONFIG.assets.heroBg}
                    alt={activeService.title}
                    fill
                    sizes="(max-width: 1024px) 100vw, 40vw"
                    className="object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Strategic Market Position (from Profile) */}
      <section id="position" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 text-center">
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
            {EN_SITE_CONFIG.position.kicker}
          </span>
          <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
            {EN_SITE_CONFIG.position.title}
          </h2>

          <div className="relative mx-auto my-8 flex w-fit flex-col items-center">
            <span className="flex h-20 w-20 items-center justify-center rounded-full bg-navy text-gold-light shadow-xl">
              <Gem className="h-10 w-10" />
            </span>
          </div>

          <p className="text-base sm:text-lg leading-relaxed text-slate-700 dark:text-slate-200">
            {EN_SITE_CONFIG.position.p1}
          </p>
          <p className="mt-4 text-base sm:text-lg leading-relaxed text-slate-700 dark:text-slate-200">
            {EN_SITE_CONFIG.position.p2}
          </p>
        </div>
      </section>

      {/* Vision & Mission (from Profile) */}
      <section id="vision" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <h2 className="text-3xl font-extrabold text-navy dark:text-white sm:text-4xl">
              {EN_SITE_CONFIG.visionMission.title}
            </h2>
          </div>

          <div className="grid gap-8 md:grid-cols-2">
            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 shadow-md">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6 shadow-sm">
                <HandHeart className="h-7 w-7" />
              </div>
              <h3 className="text-2xl font-bold text-navy dark:text-white">
                {EN_SITE_CONFIG.visionMission.mission.title}
              </h3>
              <p className="mt-4 text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {EN_SITE_CONFIG.visionMission.mission.text}
              </p>
            </div>

            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-8 shadow-md">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gold text-navy-darker mb-6 shadow-sm">
                <Eye className="h-7 w-7" />
              </div>
              <h3 className="text-2xl font-bold text-navy dark:text-white">
                {EN_SITE_CONFIG.visionMission.vision.title}
              </h3>
              <p className="mt-4 text-sm sm:text-base leading-relaxed text-slate-600 dark:text-slate-300">
                {EN_SITE_CONFIG.visionMission.vision.text}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Track Record Section */}
      <section id="track" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Demonstrated Accomplishments
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Field Execution Case Studies
            </h2>
            <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300">
              Delivering cross-sector projects with strict adherence to engineering codes, logistics compliance, and operational reliability.
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {EN_SITE_CONFIG.trackRecord.map((tr) => (
              <div
                key={tr.id}
                className="overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy shadow-md hover:shadow-xl transition"
              >
                <div className="relative aspect-[16/10] bg-navy-darker">
                  <Image
                    src={tr.src}
                    alt={tr.title}
                    fill
                    loading="lazy"
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                  <span className="absolute top-3 start-3 rounded-full bg-navy/90 px-3 py-1 text-[11px] font-bold text-gold-light border border-gold/30">
                    {tr.tag}
                  </span>
                </div>
                <div className="p-5">
                  <h3 className="text-base font-bold text-navy dark:text-white">{tr.title}</h3>
                  <p className="mt-2 text-xs leading-5 text-slate-600 dark:text-slate-300">{tr.desc}</p>
                  <p className="mt-3 text-[11px] font-semibold text-gold dark:text-gold-light border-t border-slate-100 dark:border-white/10 pt-2">
                    {tr.metrics}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Client Testimonials Section */}
      <section className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Client & Partner Testimonials
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Endorsements of Operational Trust
            </h2>
          </div>

          <div className="grid gap-6 md:grid-cols-3">
            {EN_SITE_CONFIG.testimonials.map((t, idx) => (
              <div
                key={idx}
                className="flex flex-col justify-between rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy p-6 shadow-sm hover:border-gold/50 transition"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-1 text-amber-400">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} className="h-4 w-4 fill-amber-400" />
                      ))}
                    </div>
                    <Quote className="h-5 w-5 text-gold-light" />
                  </div>
                  <p className="text-xs sm:text-sm leading-relaxed text-slate-700 dark:text-slate-200">
                    &ldquo;{t.quote}&rdquo;
                  </p>
                </div>
                <div className="mt-6 border-t border-slate-200 dark:border-white/10 pt-4">
                  <h4 className="text-sm font-bold text-navy dark:text-white">{t.name}</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{t.role}</p>
                  <span className="inline-block mt-1 text-[11px] font-bold text-gold">{t.sector}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Why Us / Core Principles Section */}
      <section id="why" className="py-16 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Core Principles
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Why Partner With Al-Fada Al-Wasaa?
            </h2>
          </div>

          <div className="grid gap-6 sm:grid-cols-3">
            {EN_SITE_CONFIG.values.map((val) => (
              <div
                key={val.title}
                className="rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-6 shadow-sm hover:border-gold/50 transition"
              >
                <span className="h-2 w-10 rounded-full bg-gold block mb-4" />
                <h3 className="text-lg font-bold text-navy dark:text-white">{val.title}</h3>
                <p className="mt-2 text-xs leading-6 text-slate-600 dark:text-slate-300">{val.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* English FAQ Section */}
      <section id="faq" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Frequently Asked Questions
            </span>
            <h2 className="mt-3 text-3xl font-extrabold text-navy dark:text-white">
              Essential Procedures & Inquiries
            </h2>
          </div>

          <div className="space-y-3">
            {EN_SITE_CONFIG.faq.map((item, idx) => {
              const isOpen = faqOpenIndex === idx;
              return (
                <div
                  key={idx}
                  className="rounded-2xl border border-navy/10 dark:border-white/10 bg-slate-50 dark:bg-navy/80 overflow-hidden"
                >
                  <button
                    type="button"
                    onClick={() => setFaqOpenIndex(isOpen ? null : idx)}
                    className="flex w-full items-center justify-between p-4 sm:p-5 text-left font-bold text-navy dark:text-white"
                  >
                    <span className="text-sm sm:text-base">{item.question}</span>
                    <ChevronDown className={`h-4 w-4 text-gold transition ${isOpen ? "rotate-180" : ""}`} />
                  </button>
                  {isOpen && (
                    <div className="px-4 sm:px-5 pb-5 pt-2 text-xs sm:text-sm leading-6 text-slate-600 dark:text-slate-300 border-t border-navy/5 dark:border-white/10">
                      {item.answer}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Corporate Epilogue / Conclusion Section */}
      <section id="conclusion" className="py-12 bg-slate-50 dark:bg-navy-darker/60">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 text-center">
          <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
            {EN_SITE_CONFIG.conclusion.kicker}
          </span>
          <h2 className="mt-2 text-2xl sm:text-3xl font-extrabold text-navy dark:text-white">
            {EN_SITE_CONFIG.conclusion.title}
          </h2>

          <div className="relative mx-auto my-8 rounded-3xl bg-navy p-8 sm:p-10 text-white shadow-xl border border-white/10">
            <span className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-navy-darker text-gold-light border-2 border-gold/40 shadow-md">
              <Handshake className="h-10 w-10" />
            </span>
            <p className="text-base sm:text-lg leading-relaxed text-white/90">
              {EN_SITE_CONFIG.conclusion.text}
            </p>
            <span className="mx-auto mt-6 block h-1 w-24 rounded-full bg-gold" />
          </div>
        </div>
      </section>

      {/* Comprehensive English Contact & Inquiry Tracking Section */}
      <section id="contact" className="py-16 bg-white dark:bg-navy-darker">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <span className="inline-block rounded-full bg-gold/15 px-4 py-1 text-xs font-bold text-navy dark:text-gold-light">
              Connect With Us
            </span>
            <h2 className="mt-3 text-3xl sm:text-4xl font-extrabold text-navy dark:text-white">
              Executive Communication & Inquiries
            </h2>
            <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">
              Our leadership and engineering teams are ready to discuss project scopes and formulate structured commercial proposals.
            </p>
          </div>

          <div className="grid gap-8 lg:grid-cols-[1.1fr_1.3fr] items-start">
            {/* Left Column: Direct Corporate Channels (Matching Arabic exactly) */}
            <div className="space-y-6">
              <div className="rounded-3xl bg-navy p-8 text-white shadow-xl border border-white/10 sm:p-10">
                <div className="inline-flex items-center gap-2 rounded-full bg-gold/20 px-4 py-1.5 text-xs font-bold text-gold-light ring-1 ring-gold/30">
                  <Building2 className="h-4 w-4" />
                  <span>{EN_SITE_CONFIG.company.fullName}</span>
                </div>

                <h3 className="mt-6 text-2xl font-black text-white">
                  Direct Executive Channels
                </h3>
                <p className="mt-2 text-xs sm:text-sm text-white/75">
                  Reach our management directly for commercial discussions, tenders, or partnerships.
                </p>

                <div className="mt-8 space-y-4">
                  {/* General Management Card */}
                  <div className="rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 hover:bg-white/10 transition">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold text-navy-darker font-bold">
                        <Building2 className="h-5 w-5" />
                      </span>
                      <div>
                        <span className="block text-xs font-bold text-gold-light">
                          {EN_SITE_CONFIG.contacts.general.label} / {EN_SITE_CONFIG.contacts.general.sublabel}
                        </span>
                        <span className="block text-base font-black text-white font-mono">
                          {EN_SITE_CONFIG.contacts.general.display}
                        </span>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/10">
                      <a
                        href={EN_SITE_CONFIG.contacts.general.telHref}
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-white/10 py-2 text-xs font-bold text-white hover:bg-gold hover:text-navy-darker transition"
                      >
                        <Phone className="h-3.5 w-3.5" />
                        <span>Direct Call</span>
                      </a>
                      <a
                        href={EN_SITE_CONFIG.contacts.general.waHref}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500/20 py-2 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                      >
                        <MessageSquare className="h-3.5 w-3.5" />
                        <span>WhatsApp</span>
                      </a>
                    </div>
                  </div>

                  {/* Deputy General Manager Card */}
                  <div className="rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 hover:bg-white/10 transition">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold text-navy-darker font-bold">
                        <Phone className="h-5 w-5" />
                      </span>
                      <div>
                        <span className="block text-xs font-bold text-gold-light">
                          {EN_SITE_CONFIG.contacts.deputy.label} / {EN_SITE_CONFIG.contacts.deputy.sublabel}
                        </span>
                        <span className="block text-base font-black text-white font-mono">
                          {EN_SITE_CONFIG.contacts.deputy.display}
                        </span>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/10">
                      <a
                        href={EN_SITE_CONFIG.contacts.deputy.telHref}
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-white/10 py-2 text-xs font-bold text-white hover:bg-gold hover:text-navy-darker transition"
                      >
                        <Phone className="h-3.5 w-3.5" />
                        <span>Call Deputy</span>
                      </a>
                      <a
                        href={EN_SITE_CONFIG.contacts.deputy.waHref}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500/20 py-2 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                      >
                        <MessageSquare className="h-3.5 w-3.5" />
                        <span>WhatsApp</span>
                      </a>
                    </div>
                  </div>

                  {/* Email Card */}
                  <a
                    href={EN_SITE_CONFIG.contacts.email.mailHref}
                    className="flex items-center gap-4 rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 hover:bg-white/10 transition"
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold/20 text-gold-light ring-1 ring-gold/40">
                      <Mail className="h-5 w-5" />
                    </span>
                    <div>
                      <span className="block text-xs text-white/60">{EN_SITE_CONFIG.contacts.email.label}</span>
                      <span className="block text-sm font-bold text-white font-mono">
                        {EN_SITE_CONFIG.contacts.email.address}
                      </span>
                    </div>
                  </a>

                  {/* Headquarters & Coverage Card */}
                  <div className="flex items-center gap-4 rounded-2xl bg-white/5 p-4 ring-1 ring-white/10">
                    <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gold/20 text-gold-light ring-1 ring-gold/40">
                      <MapPin className="h-6 w-6" />
                    </span>
                    <div>
                      <span className="block text-xs text-white/60">{EN_SITE_CONFIG.contacts.location.label}</span>
                      <span className="block text-sm font-bold text-white">
                        {EN_SITE_CONFIG.contacts.location.fullAddress}
                      </span>
                      <span className="block text-[11px] text-gold-light mt-0.5">
                        {EN_SITE_CONFIG.contacts.location.coverage}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="mt-8 flex items-center gap-3 border-t border-white/10 pt-6 text-xs text-white/70">
                  <Clock className="h-4 w-4 text-gold shrink-0" />
                  <span>{EN_SITE_CONFIG.contacts.workingHours}</span>
                </div>
              </div>
            </div>

            {/* Right Column: Interactive Quote Request Form & Inquiry Tracker */}
            <div className="rounded-3xl border border-navy/10 dark:border-white/10 bg-white dark:bg-navy p-8 shadow-xl sm:p-10">
              {/* Tab Selector */}
              <div className="flex rounded-2xl bg-slate-100 dark:bg-white/5 p-1.5 mb-8 ring-1 ring-slate-200/50 dark:ring-white/10">
                <button
                  type="button"
                  onClick={() => setContactTab("form")}
                  className={`flex-1 flex items-center justify-center gap-2 rounded-xl py-2.5 text-xs sm:text-sm font-bold transition ${
                    contactTab === "form"
                      ? "bg-navy dark:bg-gold text-white dark:text-navy-darker shadow-sm"
                      : "text-slate-600 hover:text-navy dark:text-white/70 dark:hover:text-white"
                  }`}
                >
                  <Send className="h-4 w-4" />
                  <span>Request Quote</span>
                </button>
                <button
                  type="button"
                  onClick={() => setContactTab("track")}
                  className={`flex-1 flex items-center justify-center gap-2 rounded-xl py-2.5 text-xs sm:text-sm font-bold transition ${
                    contactTab === "track"
                      ? "bg-navy dark:bg-gold text-white dark:text-navy-darker shadow-sm"
                      : "text-slate-600 hover:text-navy dark:text-white/70 dark:hover:text-white"
                  }`}
                >
                  <Search className="h-4 w-4" />
                  <span>Track Inquiry Status</span>
                </button>
              </div>

              {contactTab === "form" ? (
                <>
                  <h3 className="text-2xl font-black text-navy dark:text-white">
                    Submit Proposal or Quotation Request
                  </h3>
                  <p className="mt-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
                    Fill in project specifications. An atomic reference number will be generated immediately for live follow-up.
                  </p>

                  {submitted && generatedRef ? (
                    <div className="mt-6 rounded-2xl bg-emerald-50 dark:bg-emerald-950/30 p-6 ring-1 ring-emerald-300 dark:ring-emerald-700/50 space-y-4">
                      <div className="flex items-center gap-3">
                        <CheckCircle2 className="h-6 w-6 text-emerald-600 dark:text-emerald-400 shrink-0" />
                        <div>
                          <h4 className="text-sm font-black text-emerald-950 dark:text-emerald-200">
                            Request Successfully Submitted
                          </h4>
                          <p className="text-xs text-emerald-700 dark:text-emerald-300">
                            Your inquiry has been logged in our corporate enterprise database.
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center justify-between rounded-xl bg-white dark:bg-navy p-3 border border-emerald-200 dark:border-emerald-800">
                        <div>
                          <span className="block text-[11px] text-slate-500">Tracking Reference Number</span>
                          <span className="block text-base font-black font-mono text-navy dark:text-gold">
                            {generatedRef}
                          </span>
                        </div>
                        <button
                          type="button"
                          onClick={() => {
                            navigator.clipboard.writeText(generatedRef);
                            setCopied(true);
                            toast.success("Reference number copied!");
                            setTimeout(() => setCopied(false), 2000);
                          }}
                          className="inline-flex items-center gap-1 rounded-lg bg-slate-100 dark:bg-white/10 px-3 py-1.5 text-xs font-bold text-navy dark:text-white hover:bg-gold hover:text-navy-darker transition"
                        >
                          {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
                          <span>{copied ? "Copied" : "Copy"}</span>
                        </button>
                      </div>

                      <div className="flex flex-wrap gap-2 pt-2">
                        <button
                          type="button"
                          onClick={() => {
                            setContactTab("track");
                            setTrackInput(generatedRef);
                          }}
                          className="rounded-xl bg-navy dark:bg-gold px-4 py-2 text-xs font-bold text-white dark:text-navy-darker"
                        >
                          Track Status Live
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setSubmitted(false);
                            setGeneratedRef("");
                          }}
                          className="rounded-xl border border-slate-300 dark:border-white/20 px-4 py-2 text-xs font-bold text-slate-700 dark:text-white"
                        >
                          Submit Another Request
                        </button>
                      </div>
                    </div>
                  ) : (
                    <form onSubmit={handleSubmit(onSubmit)} className="mt-6 space-y-4">
                      {submitError && (
                        <div className="flex items-center gap-2 rounded-xl bg-rose-50 p-4 text-xs font-bold text-rose-700 ring-1 ring-rose-200">
                          <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
                          <span>{submitError}</span>
                        </div>
                      )}

                      <div>
                        <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                          Full Name / Company Name *
                        </label>
                        <input
                          type="text"
                          {...register("name")}
                          placeholder="e.g. John Doe / General Enterprise Ltd."
                          className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                        />
                        {errors.name && (
                          <p className="mt-1 text-xs text-rose-500 font-semibold">{errors.name.message}</p>
                        )}
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                          <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                            Phone / WhatsApp Number *
                          </label>
                          <input
                            type="tel"
                            {...register("phone")}
                            placeholder="+967 ... or 776999942"
                            className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm font-mono text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                          />
                          {errors.phone && (
                            <p className="mt-1 text-xs text-rose-500 font-semibold">{errors.phone.message}</p>
                          )}
                        </div>

                        <div>
                          <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                            Email Address (Optional)
                          </label>
                          <input
                            type="email"
                            {...register("email")}
                            placeholder="name@company.com"
                            className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                          />
                          {errors.email && (
                            <p className="mt-1 text-xs text-rose-500 font-semibold">{errors.email.message}</p>
                          )}
                        </div>
                      </div>

                      <div>
                        <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                          Required Service Sector *
                        </label>
                        <select
                          {...register("service")}
                          value={selectedService}
                          onChange={(e) => setSelectedService(e.target.value)}
                          className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                        >
                          {EN_SITE_CONFIG.sectorOptions.map((opt) => (
                            <option key={opt} value={opt}>
                              {opt}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div>
                        <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                          Project Scope & Details (Optional)
                        </label>
                        <textarea
                          rows={4}
                          {...register("message")}
                          placeholder="Provide project location, BOQ summary, execution timeline, or specific engineering requirements..."
                          className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30 resize-none"
                        />
                      </div>

                      <div className="flex flex-col sm:flex-row items-center gap-3 pt-2">
                        <button
                          type="submit"
                          disabled={isSubmitting}
                          className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-gold px-8 py-3 text-sm font-extrabold text-navy-darker hover:bg-gold-light transition shadow-md disabled:opacity-50"
                        >
                          {isSubmitting ? (
                            <>
                              <Loader2 className="h-4 w-4 animate-spin" />
                              <span>Submitting Proposal...</span>
                            </>
                          ) : (
                            <>
                              <Send className="h-4 w-4" />
                              <span>Submit Official Proposal Request</span>
                            </>
                          )}
                        </button>
                        <a
                          href={`https://wa.me/${EN_SITE_CONFIG.contacts.general.waNumber}?text=${whatsappMessage}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-500/10 px-5 py-3 text-xs font-bold text-emerald-700 dark:text-emerald-300 ring-1 ring-emerald-500/30 hover:bg-emerald-500 hover:text-white transition"
                        >
                          <MessageSquare className="h-4 w-4" />
                          <span>Direct WhatsApp Quote</span>
                        </a>
                      </div>
                    </form>
                  )}
                </>
              ) : (
                /* Tab 2: Track Inquiry Status */
                <div className="space-y-6">
                  <div>
                    <h3 className="text-2xl font-black text-navy dark:text-white">
                      Track Inquiry & Proposal Status
                    </h3>
                    <p className="mt-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300">
                      Query real-time processing milestones using your reference number and secure token.
                    </p>
                  </div>

                  {savedRefNumber && (
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 rounded-2xl bg-gold/10 p-4 ring-1 ring-gold/30">
                      <div className="flex items-center gap-2 text-navy dark:text-white text-xs font-bold">
                        <Clock className="h-4 w-4 text-gold shrink-0" />
                        <span>Recent submission:</span>
                        <span className="font-mono font-black text-sm tracking-wider">
                          {savedRefNumber}
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleQuickTrack(savedRefNumber)}
                        className="inline-flex items-center justify-center gap-1.5 rounded-xl bg-gold px-4 py-2 text-xs font-extrabold text-navy-darker hover:bg-gold-light transition shadow-sm"
                      >
                        <Search className="h-3.5 w-3.5" />
                        <span>Query This Ref</span>
                      </button>
                    </div>
                  )}

                  <form onSubmit={handleTrackSubmit} className="space-y-4">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                          Inquiry Reference Number *
                        </label>
                        <input
                          type="text"
                          required
                          value={trackInput}
                          onChange={(e) => setTrackInput(e.target.value)}
                          placeholder="e.g. INC-2026-000001"
                          className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm font-mono uppercase text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-bold text-navy dark:text-white mb-1.5">
                          Secure Tracking Token
                        </label>
                        <input
                          type="text"
                          value={trackTokenInput}
                          onChange={(e) => setTrackTokenInput(e.target.value)}
                          placeholder="Security Token"
                          className="w-full rounded-xl border border-slate-200 dark:border-white/10 bg-slate-50/60 dark:bg-navy-darker px-4 py-3 text-sm font-mono text-slate-900 dark:text-white focus:border-gold focus:outline-none focus:ring-2 focus:ring-gold/30"
                        />
                      </div>
                    </div>

                    <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-2">
                      <p className="text-[11px] text-slate-500">
                        🔒 Security token verifies tender identity and protects confidential commercial replies.
                      </p>
                      <button
                        type="submit"
                        disabled={isTracking}
                        className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-gold px-8 py-3 text-xs sm:text-sm font-bold text-navy-darker hover:bg-gold-light transition shadow-md disabled:opacity-50"
                      >
                        {isTracking ? (
                          <>
                            <Loader2 className="h-4 w-4 animate-spin" />
                            <span>Querying...</span>
                          </>
                        ) : (
                          <>
                            <Search className="h-4 w-4" />
                            <span>Query Status</span>
                          </>
                        )}
                      </button>
                    </div>
                  </form>

                  {trackErrorMessage && (
                    <div className="flex items-center gap-2 rounded-xl bg-rose-50 p-4 text-xs font-bold text-rose-700 ring-1 ring-rose-200">
                      <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
                      <span>{trackErrorMessage}</span>
                    </div>
                  )}

                  {/* Tracking Result Card */}
                  {trackingResult && (
                    <div className="rounded-2xl bg-slate-50 dark:bg-navy-darker/60 p-6 ring-1 ring-slate-200 dark:ring-white/10 space-y-4">
                      <div className="flex items-center justify-between border-b border-slate-200 dark:border-white/10 pb-3">
                        <span className="text-xs font-bold text-slate-500">Reference Number:</span>
                        <span className="font-mono text-sm font-black text-navy dark:text-gold">
                          {trackingResult.refNumber}
                        </span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 dark:border-white/10 pb-3">
                        <span className="text-xs font-bold text-slate-500">Subject:</span>
                        <span className="text-xs sm:text-sm font-bold text-slate-800 dark:text-white">
                          {trackingResult.subject}
                        </span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 dark:border-white/10 pb-3">
                        <span className="text-xs font-bold text-slate-500">Recorded Date:</span>
                        <span className="text-xs text-slate-700 dark:text-slate-300">
                          {trackingResult.receivedAt
                            ? new Date(trackingResult.receivedAt).toLocaleDateString("en-US", {
                                year: "numeric",
                                month: "long",
                                day: "numeric",
                              })
                            : "—"}
                        </span>
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <span className="text-xs font-bold text-slate-500">Current Milestone:</span>
                        {(() => {
                          const badge = getStatusBadge(trackingResult.status);
                          return (
                            <span className={`inline-flex items-center gap-2 rounded-full px-3 py-0.5 text-xs font-bold ${badge.badgeClass}`}>
                              <span className={`h-2 w-2 rounded-full ${badge.dotClass}`} />
                              <span>{badge.label}</span>
                            </span>
                          );
                        })()}
                      </div>

                      {/* 4-Step Milestone Progress */}
                      <div className="pt-4 border-t border-slate-200 dark:border-white/10">
                        <span className="block text-xs font-bold text-slate-600 dark:text-slate-400 mb-3">
                          Processing Timeline:
                        </span>
                        {(() => {
                          const currentStep = getTimelineStep(trackingResult.status);
                          const steps = [
                            { num: 1, label: "Received", desc: "Logged in system" },
                            { num: 2, label: "Technical Review", desc: "Engineering study" },
                            { num: 3, label: "Proposal Formulated", desc: "Commercial audit" },
                            { num: 4, label: "Formal Resolution", desc: "Response issued" },
                          ];
                          return (
                            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                              {steps.map((s) => {
                                const isDone = s.num <= currentStep;
                                const isCurrent = s.num === currentStep;
                                return (
                                  <div
                                    key={s.num}
                                    className={`flex flex-col items-center text-center p-2.5 rounded-xl border text-xs ${
                                      isCurrent
                                        ? "border-gold bg-gold/10 ring-1 ring-gold/40"
                                        : isDone
                                        ? "border-emerald-200 bg-emerald-50/60 dark:bg-emerald-950/20"
                                        : "border-slate-200 dark:border-white/10 opacity-50"
                                    }`}
                                  >
                                    <div
                                      className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold mb-1 ${
                                        isCurrent
                                          ? "bg-gold text-navy-darker"
                                          : isDone
                                          ? "bg-emerald-500 text-white"
                                          : "bg-slate-200 text-slate-600"
                                      }`}
                                    >
                                      {isDone && !isCurrent ? <Check className="h-3.5 w-3.5" /> : s.num}
                                    </div>
                                    <span className="font-bold text-navy dark:text-white leading-tight">{s.label}</span>
                                    <span className="text-[10px] text-slate-500 mt-0.5">{s.desc}</span>
                                  </div>
                                );
                              })}
                            </div>
                          );
                        })()}
                      </div>

                      {/* Official Verified Reply */}
                      {trackingResult.reply && (
                        <div className="pt-4 border-t border-slate-200 dark:border-white/10">
                          <div className="rounded-2xl border border-emerald-300/80 bg-emerald-50/60 dark:bg-emerald-950/30 p-4">
                            <div className="flex items-center justify-between mb-2">
                              <span className="text-xs font-black text-emerald-900 dark:text-emerald-200 flex items-center gap-1.5">
                                <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                                <span>Official Corporate Response</span>
                              </span>
                              {trackingResult.reply.refNumber && (
                                <span className="font-mono text-[10px] text-emerald-700">
                                  Ref: {trackingResult.reply.refNumber}
                                </span>
                              )}
                            </div>
                            <div className="rounded-xl bg-white dark:bg-navy p-3 text-xs leading-relaxed text-slate-800 dark:text-slate-200 whitespace-pre-wrap">
                              {trackingResult.reply.body}
                            </div>
                            <div className="mt-2 text-right">
                              <button
                                type="button"
                                onClick={() => {
                                  if (trackingResult.reply?.body) {
                                    navigator.clipboard.writeText(trackingResult.reply.body);
                                    toast.success("Reply text copied!");
                                  }
                                }}
                                className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-700 dark:text-emerald-300 hover:underline"
                              >
                                <Copy className="h-3 w-3" />
                                <span>Copy Response</span>
                              </button>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* English Site Footer (Matching Arabic footer layout) */}
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
              &copy; {new Date().getFullYear()} Al-Fada Al-Wasaa Company for Telecom Services & General Contracting. All rights reserved.
            </p>
            <p>
              Yemeni Commercial Registry & Sovereign Classifications Verified.
            </p>
          </div>
        </div>
      </footer>

      {/* Floating Speed-Dial Contact Widget (English) */}
      <div className="fixed bottom-6 right-6 z-50 flex flex-col items-center gap-3">
        <AnimatePresence>
          {showTopBtn && (
            <motion.button
              initial={{ opacity: 0, scale: 0.7, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.7, y: 10 }}
              transition={{ type: "spring", stiffness: 400, damping: 25 }}
              whileHover={{ scale: 1.1, backgroundColor: "#c6954a" }}
              whileTap={{ scale: 0.9 }}
              onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
              aria-label="Scroll to top"
              className="flex h-11 w-11 items-center justify-center rounded-full bg-navy/90 text-white shadow-lg backdrop-blur-md ring-1 ring-white/20 transition-colors hover:text-navy-darker"
            >
              <ArrowUp className="h-5 w-5" />
            </motion.button>
          )}
        </AnimatePresence>

        {/* Speed-Dial Menu */}
        <AnimatePresence>
          {floatingMenuOpen && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              transition={{ duration: 0.2 }}
              className="mb-2 w-72 rounded-3xl border border-gold/30 bg-navy-deep/98 p-4 text-white shadow-2xl backdrop-blur-xl"
            >
              <div className="flex items-center justify-between border-b border-white/10 pb-3 mb-3">
                <span className="text-xs font-bold text-gold-light">Quick Contact Channels</span>
                <button
                  type="button"
                  onClick={() => setFloatingMenuOpen(false)}
                  aria-label="Close speed dial"
                  className="rounded-lg p-1 text-white/60 hover:bg-white/10 hover:text-white"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="space-y-3">
                {/* General Management */}
                <div className="rounded-2xl bg-white/5 p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <Building2 className="h-4 w-4 text-gold-light" />
                    <span className="text-xs font-bold text-white">General Management</span>
                  </div>
                  <div className="grid grid-cols-2 gap-1.5">
                    <a
                      href={EN_SITE_CONFIG.contacts.general.telHref}
                      className="flex items-center justify-center gap-1 rounded-xl bg-white/10 py-1.5 text-[11px] font-bold hover:bg-gold hover:text-navy-darker transition"
                    >
                      <Phone className="h-3 w-3" />
                      <span>Call</span>
                    </a>
                    <a
                      href={EN_SITE_CONFIG.contacts.general.waHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/20 py-1.5 text-[11px] font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                    >
                      <MessageSquare className="h-3 w-3" />
                      <span>WhatsApp</span>
                    </a>
                  </div>
                </div>

                {/* Deputy Director */}
                <div className="rounded-2xl bg-white/5 p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <Phone className="h-4 w-4 text-gold-light" />
                    <span className="text-xs font-bold text-white">Deputy Director</span>
                  </div>
                  <div className="grid grid-cols-2 gap-1.5">
                    <a
                      href={EN_SITE_CONFIG.contacts.deputy.telHref}
                      className="flex items-center justify-center gap-1 rounded-xl bg-white/10 py-1.5 text-[11px] font-bold hover:bg-gold hover:text-navy-darker transition"
                    >
                      <Phone className="h-3 w-3" />
                      <span>Call</span>
                    </a>
                    <a
                      href={EN_SITE_CONFIG.contacts.deputy.waHref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center gap-1 rounded-xl bg-emerald-500/20 py-1.5 text-[11px] font-bold text-emerald-300 ring-1 ring-emerald-500/40 hover:bg-emerald-500 hover:text-white transition"
                    >
                      <MessageSquare className="h-3 w-3" />
                      <span>WhatsApp</span>
                    </a>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Speed-dial Toggle Button */}
        <motion.button
          whileHover={{ scale: 1.08 }}
          whileTap={{ scale: 0.92 }}
          onClick={() => setFloatingMenuOpen((v) => !v)}
          aria-label="Direct Contact Channels"
          className="relative flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-tr from-emerald-600 to-emerald-500 text-white shadow-xl ring-2 ring-white/30"
        >
          <span className="absolute -top-1 -right-1 flex h-4 w-4">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex h-4 w-4 rounded-full bg-emerald-400" />
          </span>
          <MessageSquare className="h-7 w-7" />
        </motion.button>
      </div>
    </div>
  );
}
