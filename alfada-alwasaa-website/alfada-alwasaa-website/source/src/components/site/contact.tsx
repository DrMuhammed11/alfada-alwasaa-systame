"use client";

import { useState, useEffect, useSyncExternalStore } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { 
  Phone, 
  Mail, 
  MapPin, 
  Send, 
  CheckCircle2, 
  MessageSquare, 
  Clock, 
  Building2,
  Search,
  Copy,
  Check,
  AlertCircle,
  Loader2,
  RotateCw,
  Paperclip
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { SITE_CONFIG } from "@/config/site";
import { submitInquiry, trackInquiry } from "@/lib/api";
import { inquirySchema, type InquiryFormValues } from "@/lib/validation";

const SECTORS_OPTIONS = SITE_CONFIG.sectorOptions;

/** دالة حساب المرحلة الحالية في المسار الزمني (1 إلى 4) */
function getTrackingTimelineStep(status: string): number {
  const upper = status?.toUpperCase() || "";
  if (["APPROVED", "SENT", "CLOSED", "ARCHIVED"].includes(upper)) return 4;
  if (["IN_PROGRESS", "PENDING_APPROVAL"].includes(upper)) return 3;
  if (["REFERRED", "UNDER_REVIEW"].includes(upper)) return 2;
  return 1;
}

/** دالة مساعدة لتحديد مظهر وتدرج ألوان شارة حالة المعاملة */
function getStatusBadge(status: string, statusArabic: string) {
  const upper = status?.toUpperCase() || "";
  if (upper === "RECEIVED" || upper === "UNDER_REVIEW") {
    return {
      label: statusArabic || "قيد المراجعة الفنية",
      badgeClass: "bg-amber-50 text-amber-800 ring-1 ring-amber-300",
      dotClass: "bg-amber-500",
    };
  }
  if (upper === "REFERRED" || upper === "IN_PROGRESS") {
    return {
      label: statusArabic || "جاري العمل والدراسة",
      badgeClass: "bg-sky-50 text-sky-800 ring-1 ring-sky-300",
      dotClass: "bg-sky-500",
    };
  }
  if (
    upper === "APPROVED" || 
    upper === "SENT" || 
    upper === "CLOSED" || 
    upper === "ARCHIVED"
  ) {
    return {
      label: statusArabic || "مكتمل — تم الرد والإنجاز",
      badgeClass: "bg-emerald-50 text-emerald-800 ring-1 ring-emerald-300",
      dotClass: "bg-emerald-500",
    };
  }
  if (upper === "CANCELLED" || upper === "REJECTED") {
    return {
      label: statusArabic || "طلب ملغي أو معتذر عنه",
      badgeClass: "bg-rose-50 text-rose-800 ring-1 ring-rose-300",
      dotClass: "bg-rose-500",
    };
  }
  return {
    label: statusArabic || "قيد المتابعة",
    badgeClass: "bg-slate-100 text-slate-800 ring-1 ring-slate-300",
    dotClass: "bg-slate-500",
  };
}

function subscribeToStorage(callback: () => void) {
  window.addEventListener("storage", callback);
  return () => window.removeEventListener("storage", callback);
}

function getStoredRefSnapshot(): string | null {
  try {
    return localStorage.getItem("lastInquiryRef");
  } catch {
    return null;
  }
}

function getStoredRefServerSnapshot(): string | null {
  return null;
}

export function Contact() {
  const [activeTab, setActiveTab] = useState<"form" | "track">("form");
  const [submitted, setSubmitted] = useState(false);
  const [generatedRef, setGeneratedRef] = useState("");
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  // استرجاع آخر رقم مرجعي من التخزين المحلي لتسهيل التتبع بطريقة متوافقة مع React 19
  const storedRef = useSyncExternalStore(
    subscribeToStorage,
    getStoredRefSnapshot,
    getStoredRefServerSnapshot
  );
  const [submittedRef, setSubmittedRef] = useState<string | null>(null);
  const savedRefNumber = submittedRef || storedRef;

  const [selectedService, setSelectedService] = useState<string>(SECTORS_OPTIONS[0]);

  // إدارة النموذج بواسطة React Hook Form مع التحقق التلقائي عبر Zod فور لمس الحقل
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<InquiryFormValues>({
    resolver: zodResolver(inquirySchema),
    mode: "onTouched",
    defaultValues: {
      name: "",
      phone: "",
      email: "",
      service: SECTORS_OPTIONS[0],
      message: "",
    },
  });

  // حالة الملف المرفق الاختياري
  const [attachedFileName, setAttachedFileName] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 10 * 1024 * 1024) {
      toast.error("حجم الملف يتجاوز الحد المسموح (10 ميجابايت)");
      return;
    }
    setAttachedFileName(file.name);
    toast.success(`تم اختيار الملف: ${file.name}`);
  };

  const clearAttachedFile = () => {
    setAttachedFileName(null);
  };

  // إرسال النموذج ومعالجة الحالات
  const onSubmit = async (values: InquiryFormValues) => {
    setSubmitError(null);
    try {
      let finalMessage = values.message?.trim() || undefined;
      if (attachedFileName) {
        finalMessage = finalMessage
          ? `${finalMessage}\n\n[ملف مرفق مع الطلب: ${attachedFileName}]`
          : `[ملف مرفق مع الطلب: ${attachedFileName}]`;
      }

      const res = await submitInquiry({
        name: values.name.trim(),
        phone: values.phone.trim(),
        email: values.email?.trim() || undefined,
        service: values.service,
        message: finalMessage,
      });

      if (res.success && res.refNumber) {
        setGeneratedRef(res.refNumber);
        setSubmitted(true);
        setSubmittedRef(res.refNumber);
        setAttachedFileName(null);
        try {
          localStorage.setItem("lastInquiryRef", res.refNumber);
          if (res.trackingToken) {
            localStorage.setItem("lastTrackingToken", res.trackingToken);
            setTrackTokenInput(res.trackingToken);
          }
          window.dispatchEvent(new Event("storage"));
        } catch {
          // تجاهل
        }
        toast.success("تم استلام وتوثيق طلبكم بنجاح!", {
          description: `الرقم المرجعي لمعاملتكم: ${res.refNumber}`,
        });
      } else {
        const msg = res.message || "تعذر إرسال الطلب، يرجى المحاولة لاحقاً";
        setSubmitError(msg);
        toast.error("تعذر إرسال الطلب", {
          description: msg,
        });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "حدث خطأ غير متوقع أثناء إرسال الطلب";
      setSubmitError(msg);
      toast.error("خطأ في الاتصال", {
        description: msg,
      });
    }
  };

  // حالة التتبع عبر React Query
  const [trackInput, setTrackInput] = useState("");
  const [trackTokenInput, setTrackTokenInput] = useState("");
  const [trackQueryRef, setTrackQueryRef] = useState<string | null>(null);
  const [trackQueryToken, setTrackQueryToken] = useState<string | null>(null);

  useEffect(() => {
    try {
      const savedToken = localStorage.getItem("lastTrackingToken");
      if (savedToken && !trackTokenInput) {
        setTrackTokenInput(savedToken);
      }
    } catch {}
  }, []);

  const {
    data: trackingResult,
    isLoading: isTrackLoading,
    isFetching: isTrackFetching,
    error: trackQueryError,
    refetch: refetchTrack,
  } = useQuery({
    queryKey: ["inquiry-tracking", trackQueryRef, trackQueryToken],
    queryFn: async () => {
      if (!trackQueryRef) return null;
      const res = await trackInquiry(trackQueryRef, trackQueryToken || undefined);
      if (!res.success || !res.data) {
        throw new Error(res.error || "لم يتم العثور على معاملة بهذا الرقم المرجعي أو رمز التتبع غير صحيح");
      }
      return res.data;
    },
    enabled: !!trackQueryRef,
    staleTime: 1000 * 60 * 5, // تخزين مؤقت لمدة 5 دقائق
    retry: 1,
  });

  const isTracking = isTrackLoading || isTrackFetching;
  const trackErrorMessage = trackQueryError instanceof Error ? trackQueryError.message : null;

  const handleTrackSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const cleanRef = trackInput.trim().toUpperCase();
    const cleanToken = trackTokenInput.trim();
    if (!cleanRef) return;

    if (cleanRef === trackQueryRef && cleanToken === trackQueryToken) {
      refetchTrack();
    } else {
      setTrackQueryRef(cleanRef);
      setTrackQueryToken(cleanToken);
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
    setTrackQueryRef(ref);
    setTrackQueryToken(token);
  };

  const handleCopyRef = () => {
    if (generatedRef) {
      navigator.clipboard.writeText(generatedRef);
      setCopied(true);
      toast.info("تم نسخ الرقم المرجعي إلى الحافظة");
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const whatsappMessage = encodeURIComponent(
    `السلام عليكم ورحمة الله، أود الاستفسار عن خدمات شركة الفضاء الواسع بخصوص: ${selectedService || "خدمات الشركة"}`
  );

  return (
    <section id="contact" className="relative overflow-hidden bg-mist pt-10 pb-16 sm:pt-14 sm:pb-20">
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading 
          center 
          kicker="تواصل معنا" 
          title="نسعد بخدمتكم وتلبية تطلعات مشاريعكم" 
        />
        
        <Reveal delay={0.1}>
          <p className="mx-auto -mt-6 max-w-2xl text-center text-lg leading-8 text-slate-600">
            فريقنا جاهز لمناقشة متطلبات مشروعك وتقديم عروض أسعار متكاملة تجمع بين السرعة والدقة وأعلى معايير الجودة.
          </p>
        </Reveal>

        <div className="mt-10 sm:mt-12 grid gap-8 lg:grid-cols-[1.1fr_1.3fr] items-start">
          {/* Contact Details & Highlights */}
          <Reveal delay={0.15}>
            <div className="space-y-6">
              <div className="overflow-hidden rounded-3xl bg-navy p-8 text-white shadow-[0_20px_50px_-20px_rgba(10,52,83,0.5)] sm:p-10">
                <div className="inline-flex items-center gap-2 rounded-full bg-gold/20 px-4 py-1.5 text-xs font-bold text-gold-light ring-1 ring-gold/30">
                  <Building2 className="h-4 w-4" />
                  <span>شركة الفضاء الواسع لخدمات الاتصالات والمقاولات</span>
                </div>

                <h3 className="mt-6 text-2xl font-black text-white sm:text-3xl">
                  قنوات التواصل المباشرة
                </h3>
                <p className="mt-3 text-sm leading-7 text-white/75">
                  يسعدنا استقبال استفساراتكم ومشاريعكم عبر القنوات التالية على مدار الساعة.
                </p>

                <div className="mt-8 space-y-4">
                  {/* General Administration Card */}
                  <div className="rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 transition hover:bg-white/10 hover:ring-gold/50">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold text-navy-darker shadow-sm">
                          <Building2 className="h-5 w-5" />
                        </span>
                        <div>
                          <span className="block text-xs font-bold text-gold-light">{SITE_CONFIG.contacts.general.label} / {SITE_CONFIG.contacts.general.sublabel}</span>
                          <span className="block text-base font-black text-white dir-ltr text-right" dir="ltr">
                            {SITE_CONFIG.contacts.general.display}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/10">
                      <a
                        href={SITE_CONFIG.contacts.general.telHref}
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-white/10 py-2 text-xs font-bold text-white transition hover:bg-gold hover:text-navy-darker"
                      >
                        <Phone className="h-3.5 w-3.5" />
                        <span>اتصال مباشر</span>
                      </a>
                      <a
                        href={`https://wa.me/${SITE_CONFIG.contacts.general.waNumber}?text=${whatsappMessage}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500/20 py-2 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 transition hover:bg-emerald-500 hover:text-white"
                      >
                        <MessageSquare className="h-3.5 w-3.5" />
                        <span>واتساب الإدارة</span>
                      </a>
                    </div>
                  </div>

                  {/* Deputy Director Card */}
                  <div className="rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 transition hover:bg-white/10 hover:ring-gold/50">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold text-navy-darker shadow-sm">
                          <Phone className="h-5 w-5" />
                        </span>
                        <div>
                          <span className="block text-xs font-bold text-gold-light">{SITE_CONFIG.contacts.deputy.label}</span>
                          <span className="block text-base font-black text-white dir-ltr text-right" dir="ltr">
                            {SITE_CONFIG.contacts.deputy.display}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/10">
                      <a
                        href={SITE_CONFIG.contacts.deputy.telHref}
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-white/10 py-2 text-xs font-bold text-white transition hover:bg-gold hover:text-navy-darker"
                      >
                        <Phone className="h-3.5 w-3.5" />
                        <span>اتصال بنائب المدير</span>
                      </a>
                      <a
                        href={`https://wa.me/${SITE_CONFIG.contacts.deputy.waNumber}?text=${whatsappMessage}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center justify-center gap-1.5 rounded-xl bg-emerald-500/20 py-2 text-xs font-bold text-emerald-300 ring-1 ring-emerald-500/40 transition hover:bg-emerald-500 hover:text-white"
                      >
                        <MessageSquare className="h-3.5 w-3.5" />
                        <span>واتساب نائب المدير</span>
                      </a>
                    </div>
                  </div>

                  {/* Email */}
                  <a
                    href={SITE_CONFIG.contacts.email.mailHref}
                    className="flex items-center gap-4 rounded-2xl bg-white/5 p-4 ring-1 ring-white/10 transition hover:bg-white/10 hover:ring-gold/50"
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gold/20 text-gold-light ring-1 ring-gold/40">
                      <Mail className="h-5 w-5" />
                    </span>
                    <div>
                      <span className="block text-xs font-medium text-white/60">{SITE_CONFIG.contacts.email.label}</span>
                      <span className="block text-sm font-bold text-white">
                        {SITE_CONFIG.contacts.email.address}
                      </span>
                    </div>
                  </a>

                  {/* Location & Coverage */}
                  <div className="flex items-center gap-4 rounded-2xl bg-white/5 p-4 ring-1 ring-white/10">
                    <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gold/20 text-gold-light ring-1 ring-gold/40">
                      <MapPin className="h-6 w-6" />
                    </span>
                    <div>
                      <span className="block text-xs font-medium text-white/60">المقر الرئيسي ونطاق العمل</span>
                      <span className="block text-sm font-bold text-white">
                        {SITE_CONFIG.contacts.location.fullAddress}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="mt-8 flex items-center gap-3 border-t border-white/10 pt-6 text-xs font-semibold text-white/60">
                  <Clock className="h-4 w-4 text-gold" />
                  <span>أوقات الدوام: السبت - الخميس (8:00 صباحاً - 5:00 مساءً) مع دعم طوارئ ميداني 24/7</span>
                </div>
              </div>
            </div>
          </Reveal>

          {/* Interactive Request / Quote Form */}
          <Reveal delay={0.2}>
            <div className="rounded-3xl border border-navy/10 bg-white p-8 shadow-[0_20px_60px_-30px_rgba(10,52,83,0.3)] sm:p-10">
              {/* تبديل التبويبات بين تقديم طلب جديد وتتبع معاملة */}
              <div className="flex rounded-2xl bg-slate-100 p-1.5 mb-8">
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab("form");
                  }}
                  className={`flex-1 flex items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-bold transition ${
                    activeTab === "form"
                      ? "bg-navy text-white shadow-sm"
                      : "text-slate-600 hover:text-navy"
                  }`}
                >
                  <Send className="h-4 w-4" />
                  <span>طلب عرض سعر أو استشارة</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab("track")}
                  className={`flex-1 flex items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-bold transition ${
                    activeTab === "track"
                      ? "bg-navy text-white shadow-sm"
                      : "text-slate-600 hover:text-navy"
                  }`}
                >
                  <Search className="h-4 w-4" />
                  <span>متابعة حالة طلب سابق</span>
                </button>
              </div>

              {activeTab === "form" ? (
                <>
                  <h3 className="text-2xl font-black text-navy sm:text-3xl">
                    طلب عرض سعر أو استشارة
                  </h3>
                  <p className="mt-2 text-sm text-slate-600">
                    أدخل تفاصيل مشروعك وسيقوم فريقنا المختص بالتواصل معك في أقرب وقت.
                  </p>

                  {/* رسالة الخطأ مع زر إعادة المحاولة */}
                  {submitError && (
                    <div className="mt-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3 rounded-2xl bg-rose-50 p-4 text-sm text-rose-700 ring-1 ring-rose-200">
                      <div className="flex items-center gap-3">
                        <AlertCircle className="h-5 w-5 shrink-0 text-rose-600" />
                        <span>{submitError}</span>
                      </div>
                      <button
                        type="button"
                        onClick={handleSubmit(onSubmit)}
                        className="inline-flex items-center justify-center gap-1.5 rounded-xl bg-rose-600 px-4 py-2 text-xs font-bold text-white transition hover:bg-rose-700 shrink-0"
                      >
                        <RotateCw className="h-3.5 w-3.5" />
                        <span>إعادة المحاولة</span>
                      </button>
                    </div>
                  )}

                  {submitted ? (
                    <div className="mt-8 rounded-2xl bg-emerald-50 p-8 text-center ring-1 ring-emerald-200">
                      <CheckCircle2 className="mx-auto h-16 w-16 text-emerald-600" />
                      <h4 className="mt-4 text-2xl font-black text-navy">
                        تم استلام وتوثيق طلبكم بنجاح!
                      </h4>
                      <p className="mt-3 text-base leading-7 text-slate-700">
                        شكراً لتواصلكم مع شركة الفضاء الواسع. تم تسجيل طلبكم في نظام المراسلات المركزي، وسيتم مراجعته والتواصل معكم في أقرب وقت.
                      </p>

                      {generatedRef && (
                        <div className="mt-6 flex flex-col gap-3 max-w-md mx-auto text-right">
                          <div className="flex flex-col sm:flex-row items-center justify-between gap-3 rounded-2xl bg-white p-4 ring-1 ring-emerald-300 shadow-sm">
                            <span className="text-xs font-bold text-slate-500">الرقم المرجعي:</span>
                            <span className="font-mono text-lg font-black text-navy tracking-wider" dir="ltr">
                              {generatedRef}
                            </span>
                            <button
                              type="button"
                              onClick={handleCopyRef}
                              className="inline-flex items-center gap-1.5 rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-200 transition"
                            >
                              {copied ? (
                                <>
                                  <Check className="h-3.5 w-3.5 text-emerald-600" />
                                  <span className="text-emerald-700 font-bold">تم النسخ</span>
                                </>
                              ) : (
                                <>
                                  <Copy className="h-3.5 w-3.5 text-slate-500" />
                                  <span>نسخ الرقم</span>
                                </>
                              )}
                            </button>
                          </div>

                          {trackTokenInput && (
                            <div className="flex flex-col sm:flex-row items-center justify-between gap-3 rounded-2xl bg-white p-3 ring-1 ring-gold/40 shadow-sm text-xs">
                              <span className="font-bold text-slate-600">رمز التتبع الآمن:</span>
                              <span className="font-mono font-bold text-navy" dir="ltr">
                                {trackTokenInput}
                              </span>
                              <span className="text-[11px] text-emerald-600 font-semibold bg-emerald-50 px-2 py-0.5 rounded-md">
                                محفوظ تلقائياً
                              </span>
                            </div>
                          )}
                        </div>
                      )}

                      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
                        <button
                          type="button"
                          onClick={() => {
                            setSubmitted(false);
                            setGeneratedRef("");
                            setSubmitError(null);
                            reset({
                              name: "",
                              phone: "",
                              email: "",
                              service: SECTORS_OPTIONS[0],
                              message: "",
                            });
                          }}
                          className="inline-flex items-center gap-2 rounded-xl bg-navy px-6 py-2.5 text-sm font-bold text-white transition hover:bg-navy-deep"
                        >
                          إرسال طلب آخر
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setActiveTab("track");
                            if (generatedRef) {
                              handleQuickTrack(generatedRef);
                            }
                          }}
                          className="inline-flex items-center gap-2 rounded-xl bg-gold px-6 py-2.5 text-sm font-bold text-navy-darker transition hover:bg-gold-light"
                        >
                          <Search className="h-4 w-4" />
                          <span>متابعة حالة هذا الطلب</span>
                        </button>
                      </div>
                    </div>
                  ) : (
                    <form onSubmit={handleSubmit(onSubmit)} className="mt-8 space-y-5">
                      <div className="grid gap-5 sm:grid-cols-2">
                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            الاسم الكامل / اسم الجهة <span className="text-rose-500">*</span>
                          </label>
                          <input
                            type="text"
                            {...register("name")}
                            required
                            aria-required="true"
                            placeholder="مثال: م. فهد العتيبي"
                            className={`w-full rounded-xl border ${
                              errors.name ? "border-rose-300 bg-rose-50/30" : "border-slate-200 bg-slate-50/60"
                            } px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30`}
                          />
                          {errors.name && (
                            <p className="mt-1.5 text-xs font-semibold text-rose-600">{errors.name.message}</p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            رقم الجوال <span className="text-rose-500">*</span>
                          </label>
                          <input
                            type="tel"
                            {...register("phone")}
                            required
                            aria-required="true"
                            placeholder="776XXXXXX أو +967..."
                            className={`w-full rounded-xl border ${
                              errors.phone ? "border-rose-300 bg-rose-50/30" : "border-slate-200 bg-slate-50/60"
                            } px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right`}
                          />
                          {errors.phone && (
                            <p className="mt-1.5 text-xs font-semibold text-rose-600">{errors.phone.message}</p>
                          )}
                        </div>
                      </div>

                      <div className="grid gap-5 sm:grid-cols-2">
                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            البريد الإلكتروني
                          </label>
                          <input
                            type="email"
                            {...register("email")}
                            placeholder="example@domain.com"
                            className={`w-full rounded-xl border ${
                              errors.email ? "border-rose-300 bg-rose-50/30" : "border-slate-200 bg-slate-50/60"
                            } px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right`}
                          />
                          {errors.email && (
                            <p className="mt-1.5 text-xs font-semibold text-rose-600">{errors.email.message}</p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            المجال أو الخدمة المطلوبة <span className="text-rose-500">*</span>
                          </label>
                          <select
                            {...register("service")}
                            required
                            aria-required="true"
                            onChange={(e) => {
                              register("service").onChange(e);
                              setSelectedService(e.target.value);
                            }}
                            className={`w-full rounded-xl border ${
                              errors.service ? "border-rose-300 bg-rose-50/30" : "border-slate-200 bg-slate-50/60"
                            } px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30`}
                          >
                            {SECTORS_OPTIONS.map((opt) => (
                              <option key={opt} value={opt}>
                                {opt}
                              </option>
                            ))}
                          </select>
                          {errors.service && (
                            <p className="mt-1.5 text-xs font-semibold text-rose-600">{errors.service.message}</p>
                          )}
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-bold text-navy mb-2">
                          تفاصيل المشروع أو الاستفسار
                        </label>
                        <textarea
                          rows={4}
                          {...register("message")}
                          placeholder="اذكر بإيجاز طبيعة المشروع، الموقع، والجدول الزمني المتوقع إن وجد..."
                          className={`w-full rounded-xl border ${
                            errors.message ? "border-rose-300 bg-rose-50/30" : "border-slate-200 bg-slate-50/60"
                          } px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 resize-none`}
                        />
                        {errors.message && (
                          <p className="mt-1.5 text-xs font-semibold text-rose-600">{errors.message.message}</p>
                        )}
                      </div>

                      {/* حقل إرفاق ملف اختياري (مخطط / كراسة شروط / جدول كميات) */}
                      <div>
                        <label className="block text-sm font-bold text-navy mb-2">
                          إرفاق ملف أو مخطط اختياري (PDF أو صور حتى 10MB)
                        </label>
                        <div className="flex items-center gap-3">
                          <label className="flex-1 cursor-pointer flex items-center justify-center gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50/80 px-4 py-3 text-xs font-semibold text-slate-600 transition hover:border-gold hover:bg-gold/5">
                            <Paperclip className="h-4 w-4 text-gold shrink-0" />
                            <span className="truncate">
                              {attachedFileName ? attachedFileName : "اختر ملفاً لإرفاقه مع طلب التسعير (اختياري)"}
                            </span>
                            <input
                              type="file"
                              accept=".pdf,.jpg,.jpeg,.png,.webp,.doc,.docx,.xls,.xlsx"
                              onChange={handleFileChange}
                              className="hidden"
                            />
                          </label>
                          {attachedFileName && (
                            <button
                              type="button"
                              onClick={clearAttachedFile}
                              className="rounded-xl bg-rose-50 px-3 py-3 text-xs font-bold text-rose-600 ring-1 ring-rose-200 hover:bg-rose-100 transition"
                            >
                              إلغاء
                            </button>
                          )}
                        </div>
                      </div>

                      <div className="pt-2">
                        <button
                          type="submit"
                          disabled={isSubmitting}
                          className="group inline-flex w-full items-center justify-center gap-3 rounded-2xl bg-gold px-8 py-4 text-base font-extrabold text-navy-darker shadow-[0_15px_35px_-10px_rgba(198,149,74,0.5)] transition hover:bg-gold-light hover:shadow-[0_20px_40px_-10px_rgba(198,149,74,0.65)] disabled:opacity-60"
                        >
                          {isSubmitting ? (
                            <>
                              <Loader2 className="h-5 w-5 animate-spin text-navy-darker" />
                              <span>جارٍ إرسال الطلب...</span>
                            </>
                          ) : (
                            <>
                              <span>إرسال طلب الاستشارة / عرض السعر</span>
                              <Send className="h-5 w-5 transition-transform duration-300 group-hover:-translate-x-1" />
                            </>
                          )}
                        </button>
                      </div>
                    </form>
                  )}
                </>
              ) : (
                <div className="space-y-6">
                  <div>
                    <h3 className="text-2xl font-black text-navy sm:text-3xl">
                      متابعة حالة معاملة أو طلب
                    </h3>
                    <p className="mt-2 text-sm text-slate-600">
                      أدخل الرقم المرجعي للمعاملة (مثال: <span className="font-mono font-bold text-navy" dir="ltr">INC-2026-000001</span>) للاستعلام عن حالتها المحدثة.
                    </p>
                  </div>

                  {/* زر التتبع السريع لآخر طلب إن وجد */}
                  {savedRefNumber && (
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 rounded-2xl bg-gold/10 p-4 ring-1 ring-gold/30">
                      <div className="flex items-center gap-2 text-navy text-xs font-bold">
                        <Clock className="h-4 w-4 text-gold shrink-0" />
                        <span>آخر معاملة قمت بتقديمها:</span>
                        <span className="font-mono font-black text-sm tracking-wider" dir="ltr">
                          {savedRefNumber}
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleQuickTrack(savedRefNumber)}
                        className="inline-flex items-center justify-center gap-1.5 rounded-xl bg-gold px-4 py-2 text-xs font-extrabold text-navy-darker hover:bg-gold-light transition shadow-sm"
                      >
                        <Search className="h-3.5 w-3.5" />
                        <span>تتبع هذا الطلب</span>
                      </button>
                    </div>
                  )}

                  <form onSubmit={handleTrackSubmit} className="space-y-4">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-bold text-navy mb-2">
                          الرقم المرجعي للمعاملة
                        </label>
                        <input
                          type="text"
                          required
                          value={trackInput}
                          onChange={(e) => setTrackInput(e.target.value)}
                          placeholder="مثال: INC-2026-000001"
                          className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm font-mono uppercase text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-bold text-navy mb-2">
                          رمز التتبع الآمن (Token)
                        </label>
                        <input
                          type="text"
                          required
                          value={trackTokenInput}
                          onChange={(e) => setTrackTokenInput(e.target.value)}
                          placeholder="رمز التتبع السري"
                          className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm font-mono text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right"
                        />
                      </div>
                    </div>
                    <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
                      <p className="text-xs text-slate-500">
                        🔒 يُطلب رمز التتبع لضمان سرية المعاملة ومنع استعراض الردود دون إذن.
                      </p>
                      <button
                        type="submit"
                        disabled={isTracking}
                        className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-gold px-8 py-3 text-sm font-bold text-navy-darker hover:bg-gold-light transition disabled:opacity-50 shrink-0"
                      >
                        {isTracking ? (
                          <>
                            <Loader2 className="h-4 w-4 animate-spin" />
                            <span>جارٍ الاستعلام...</span>
                          </>
                        ) : (
                          <>
                            <Search className="h-4 w-4" />
                            <span>استعلام عن المعاملة</span>
                          </>
                        )}
                      </button>
                    </div>
                  </form>

                  {/* رسالة الخطأ في التتبع */}
                  {trackErrorMessage && (
                    <div className="flex items-center gap-3 rounded-xl bg-rose-50 p-4 text-sm text-rose-700 ring-1 ring-rose-200">
                      <AlertCircle className="h-5 w-5 shrink-0 text-rose-600" />
                      <span>{trackErrorMessage}</span>
                    </div>
                  )}

                  {/* بطاقة عرض تفاصيل المعاملة */}
                  {trackingResult && (
                    <div className="rounded-2xl bg-slate-50 p-6 ring-1 ring-slate-200 space-y-4 shadow-sm">
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">رقم المعاملة:</span>
                        <span className="font-mono text-base font-black text-navy" dir="ltr">
                          {trackingResult.refNumber}
                        </span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">موضوع الطلب:</span>
                        <span className="text-sm font-bold text-slate-800">
                          {trackingResult.subject}
                        </span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">تاريخ التسجيل:</span>
                        <span className="text-sm text-slate-700">
                          {trackingResult.receivedAt
                            ? new Date(trackingResult.receivedAt).toLocaleDateString("ar-SA", {
                                year: "numeric",
                                month: "long",
                                day: "numeric",
                              })
                            : "—"}
                        </span>
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <span className="text-xs font-bold text-slate-500">الحالة الراهنة:</span>
                        {(() => {
                          const badge = getStatusBadge(trackingResult.status, trackingResult.statusArabic);
                          return (
                            <span
                              className={`inline-flex items-center gap-2 rounded-full px-3.5 py-1 text-xs font-bold ${badge.badgeClass}`}
                            >
                              <span className={`h-2 w-2 rounded-full ${badge.dotClass}`} />
                              <span>{badge.label}</span>
                            </span>
                          );
                        })()}
                      </div>

                      {/* المسار الزمني لمراحل إنجاز المعاملة */}
                      <div className="pt-4 mt-2 border-t border-slate-200">
                        <span className="block text-xs font-bold text-slate-600 mb-3">
                          مسار مراحل إنجاز الطلب:
                        </span>
                        {(() => {
                          const currentStep = getTrackingTimelineStep(trackingResult.status);
                          const steps = [
                            { num: 1, label: "استلام وتوثيق", desc: "قيد فوري بالنظام" },
                            { num: 2, label: "الدراسة الفنية", desc: "لدى القسم المعني" },
                            { num: 3, label: "إعداد العرض", desc: "مراجعة واعتماد" },
                            { num: 4, label: "اكتمال الرد", desc: "إشعار العميل" },
                          ];

                          return (
                            <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-4 sm:gap-2">
                              {steps.map((s) => {
                                const isDone = s.num <= currentStep;
                                const isCurrent = s.num === currentStep;

                                return (
                                  <div
                                    key={s.num}
                                    className={`relative flex flex-col items-center text-center p-3 rounded-xl border transition-all ${
                                      isCurrent
                                        ? "border-gold bg-gold/10 shadow-sm ring-1 ring-gold/40"
                                        : isDone
                                        ? "border-emerald-200 bg-emerald-50/60"
                                        : "border-slate-200 bg-white/70 opacity-60"
                                    }`}
                                  >
                                    <div
                                      className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-black mb-1.5 ${
                                        isCurrent
                                          ? "bg-gold text-navy-darker shadow-sm"
                                          : isDone
                                          ? "bg-emerald-500 text-white"
                                          : "bg-slate-200 text-slate-600"
                                      }`}
                                    >
                                      {isDone && !isCurrent ? (
                                        <Check className="h-4 w-4" />
                                      ) : (
                                        s.num
                                      )}
                                    </div>
                                    <span className="text-xs font-bold text-navy leading-tight">
                                      {s.label}
                                    </span>
                                    <span className="text-[10px] text-slate-500 mt-1 leading-normal">
                                      {s.desc}
                                    </span>
                                  </div>
                                );
                              })}
                            </div>
                          );
                        })()}
                      </div>

                      {/* عرض الرد الرسمي المعتمد من الشركة إن وُجد */}
                      {trackingResult.reply && (
                        <div className="pt-4 mt-2 border-t border-slate-200">
                          <div className="rounded-2xl border border-emerald-300/80 bg-gradient-to-br from-emerald-50/70 to-white p-5 shadow-sm">
                            <div className="flex items-center justify-between gap-3 mb-3 border-b border-emerald-100 pb-3">
                              <div className="flex items-center gap-2">
                                <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-emerald-600 text-white shadow-sm">
                                  <CheckCircle2 className="h-4 w-4" />
                                </span>
                                <div>
                                  <span className="block text-xs font-black text-emerald-950">
                                    الرد الرسمي المعتمد من الشركة
                                  </span>
                                  {trackingResult.reply.refNumber && (
                                    <span className="block text-[10px] font-mono text-emerald-700" dir="ltr">
                                      رقم القيد الصادر: {trackingResult.reply.refNumber}
                                    </span>
                                  )}
                                </div>
                              </div>
                              {trackingResult.reply.sentAt && (
                                <span className="text-[11px] font-medium text-slate-500">
                                  {new Date(trackingResult.reply.sentAt).toLocaleDateString("ar-SA", {
                                    year: "numeric",
                                    month: "short",
                                    day: "numeric",
                                  })}
                                </span>
                              )}
                            </div>

                            <div className="rounded-xl bg-white/90 p-4 border border-emerald-100/70 text-slate-800 text-sm leading-relaxed whitespace-pre-wrap text-justify shadow-inner">
                              {trackingResult.reply.body}
                            </div>

                            <div className="mt-3 flex items-center justify-between text-[11px] text-slate-500">
                              <span>صدر هذا الرد رسمياً من الإدارة المختصة بشركة الفضاء الواسع.</span>
                              <button
                                type="button"
                                onClick={() => {
                                  if (trackingResult.reply?.body) {
                                    navigator.clipboard.writeText(trackingResult.reply.body);
                                    toast.success("تم نسخ نص الرد الرسمي");
                                  }
                                }}
                                className="inline-flex items-center gap-1 font-bold text-emerald-700 hover:text-emerald-900 transition"
                              >
                                <Copy className="h-3.5 w-3.5" />
                                <span>نسخ نص الرد</span>
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
          </Reveal>
        </div>
      </div>
    </section>
  );
}


