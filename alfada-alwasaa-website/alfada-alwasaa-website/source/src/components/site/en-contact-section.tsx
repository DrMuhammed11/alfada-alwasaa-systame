"use client";

/**
 * Comprehensive English Contact & Inquiry Tracking Section
 * Extracted verbatim from the English homepage (src/app/en/page.tsx) so all
 * English subpages (/en/contact ...) share the exact same design and behavior.
 */

import { useState, useSyncExternalStore } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import {
  AlertCircle,
  Building2,
  Check,
  CheckCircle2,
  Clock,
  Copy,
  Loader2,
  Mail,
  MapPin,
  MessageSquare,
  Phone,
  Search,
  Send,
} from "lucide-react";
import { EN_SITE_CONFIG } from "@/config/en-site";
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

export function EnContactSection() {
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

  const whatsappMessage = encodeURIComponent(
    `Hello, I would like to inquire about Al-Fada Al-Wasaa Company regarding: ${selectedService || "General Services"}`
  );

  return (
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
  );
}
