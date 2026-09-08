"use client";

import { useState } from "react";
import { 
  Phone, 
  Mail, 
  MapPin, 
  Send, 
  CheckCircle2, 
  MessageSquare, 
  Clock, 
  Building2,
  ArrowLeft,
  Search,
  Copy,
  Check,
  AlertCircle,
  FileText
} from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";
import { SITE_CONFIG } from "@/config/site";
import { submitInquiry, trackInquiry, type TrackingResult } from "@/lib/api";

const SECTORS_OPTIONS = SITE_CONFIG.sectorOptions;

interface ContactFormData {
  name: string;
  phone: string;
  email: string;
  service: string;
  message: string;
}

export function Contact() {
  const [activeTab, setActiveTab] = useState<"form" | "track">("form");
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [generatedRef, setGeneratedRef] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  // حالة التتبع
  const [trackInput, setTrackInput] = useState("");
  const [trackLoading, setTrackLoading] = useState(false);
  const [trackResult, setTrackResult] = useState<TrackingResult | null>(null);
  const [trackError, setTrackError] = useState<string | null>(null);

  const [formData, setFormData] = useState<ContactFormData>({
    name: "",
    phone: "",
    email: "",
    service: SECTORS_OPTIONS[0],
    message: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMessage(null);

    const res = await submitInquiry({
      name: formData.name.trim(),
      phone: formData.phone.trim(),
      email: formData.email.trim() || undefined,
      service: formData.service,
      message: formData.message.trim() || undefined,
    });

    setLoading(false);
    if (res.success) {
      setGeneratedRef(res.refNumber || "");
      setSubmitted(true);
    } else {
      setErrorMessage(res.message);
    }
  };

  const handleTrack = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!trackInput.trim()) return;
    setTrackLoading(true);
    setTrackError(null);
    setTrackResult(null);

    const res = await trackInquiry(trackInput);
    setTrackLoading(false);
    if (res.success && res.data) {
      setTrackResult(res.data);
    } else {
      setTrackError(res.error || "لم يتم العثور على المعاملة");
    }
  };

  const handleCopyRef = () => {
    if (generatedRef) {
      navigator.clipboard.writeText(generatedRef);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const whatsappMessage = encodeURIComponent(
    `السلام عليكم ورحمة الله، أود الاستفسار عن خدمات شركة الفضاء الواسع بخصوص: ${formData.service || "خدمات الشركة"}`
  );

  return (
    <section id="contact" className="relative overflow-hidden bg-mist py-24">
      {/* Decorative corner accents */}
      <div
        aria-hidden
        className="corner-ribbon start-0 top-0 bg-[linear-gradient(135deg,var(--color-navy)_0%,var(--color-navy)_38%,transparent_38.5%)]"
      />
      <div
        aria-hidden
        className="corner-ribbon end-0 top-0 bg-[linear-gradient(-135deg,var(--color-gold)_0%,var(--color-gold)_30%,transparent_30.5%)] opacity-70"
      />

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

        <div className="mt-14 grid gap-10 lg:grid-cols-[1.1fr_1.3fr] items-start">
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
                    setSubmitted(false);
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

                  {errorMessage && (
                    <div className="mt-6 flex items-center gap-3 rounded-xl bg-rose-50 p-4 text-sm text-rose-700 ring-1 ring-rose-200">
                      <AlertCircle className="h-5 w-5 shrink-0 text-rose-600" />
                      <span>{errorMessage}</span>
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
                        <div className="mt-6 inline-flex flex-col sm:flex-row items-center gap-3 rounded-2xl bg-white p-4 ring-1 ring-emerald-300 shadow-sm">
                          <span className="text-xs font-bold text-slate-500">الرقم المرجعي للمعاملة:</span>
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
                      )}

                      <div className="mt-6">
                        <button
                          type="button"
                          onClick={() => {
                            setSubmitted(false);
                            setGeneratedRef("");
                            setFormData({
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
                      </div>
                    </div>
                  ) : (
                    <form onSubmit={handleSubmit} className="mt-8 space-y-5">
                      <div className="grid gap-5 sm:grid-cols-2">
                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            الاسم الكامل / اسم الجهة <span className="text-rose-500">*</span>
                          </label>
                          <input
                            type="text"
                            required
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="مثال: م. فهد العتيبي"
                            className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            رقم الجوال <span className="text-rose-500">*</span>
                          </label>
                          <input
                            type="tel"
                            required
                            value={formData.phone}
                            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                            placeholder="776XXXXXX"
                            className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right"
                          />
                        </div>
                      </div>

                      <div className="grid gap-5 sm:grid-cols-2">
                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            البريد الإلكتروني
                          </label>
                          <input
                            type="email"
                            value={formData.email}
                            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                            placeholder="example@domain.com"
                            className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-bold text-navy mb-2">
                            المجال أو الخدمة المطلوبة <span className="text-rose-500">*</span>
                          </label>
                          <select
                            value={formData.service}
                            onChange={(e) => setFormData({ ...formData, service: e.target.value })}
                            className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30"
                          >
                            {SECTORS_OPTIONS.map((opt) => (
                              <option key={opt} value={opt}>
                                {opt}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>

                      <div>
                        <label className="block text-sm font-bold text-navy mb-2">
                          تفاصيل المشروع أو الاستفسار
                        </label>
                        <textarea
                          rows={4}
                          value={formData.message}
                          onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                          placeholder="اذكر بإيجاز طبيعة المشروع، الموقع، والجدول الزمني المتوقع إن وجد..."
                          className="w-full rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 resize-none"
                        />
                      </div>

                      <div className="pt-2">
                        <button
                          type="submit"
                          disabled={loading}
                          className="group inline-flex w-full items-center justify-center gap-3 rounded-2xl bg-gold px-8 py-4 text-base font-extrabold text-navy-darker shadow-[0_15px_35px_-10px_rgba(198,149,74,0.5)] transition hover:bg-gold-light hover:shadow-[0_20px_40px_-10px_rgba(198,149,74,0.65)] disabled:opacity-60"
                        >
                          {loading ? (
                            <span>جارٍ تسجيل الطلب في النظام...</span>
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

                  <form onSubmit={handleTrack} className="space-y-4">
                    <div>
                      <label className="block text-sm font-bold text-navy mb-2">
                        الرقم المرجعي للمعاملة
                      </label>
                      <div className="flex flex-col sm:flex-row gap-2">
                        <input
                          type="text"
                          required
                          value={trackInput}
                          onChange={(e) => setTrackInput(e.target.value)}
                          placeholder="مثال: INC-2026-000001"
                          className="flex-1 rounded-xl border border-slate-200 bg-slate-50/60 px-4 py-3 text-sm font-mono uppercase text-slate-900 transition focus:border-gold focus:bg-white focus:outline-none focus:ring-2 focus:ring-gold/30 dir-ltr text-right"
                        />
                        <button
                          type="submit"
                          disabled={trackLoading}
                          className="inline-flex items-center justify-center gap-2 rounded-xl bg-gold px-6 py-3 text-sm font-bold text-navy-darker hover:bg-gold-light transition disabled:opacity-50"
                        >
                          {trackLoading ? (
                            <span>جارٍ الاستعلام...</span>
                          ) : (
                            <>
                              <Search className="h-4 w-4" />
                              <span>استعلام</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  </form>

                  {trackError && (
                    <div className="flex items-center gap-3 rounded-xl bg-rose-50 p-4 text-sm text-rose-700 ring-1 ring-rose-200">
                      <AlertCircle className="h-5 w-5 shrink-0 text-rose-600" />
                      <span>{trackError}</span>
                    </div>
                  )}

                  {trackResult && (
                    <div className="rounded-2xl bg-slate-50 p-6 ring-1 ring-slate-200 space-y-4">
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">رقم المعاملة:</span>
                        <span className="font-mono text-base font-black text-navy" dir="ltr">{trackResult.refNumber}</span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">موضوع الطلب:</span>
                        <span className="text-sm font-bold text-slate-800">{trackResult.subject}</span>
                      </div>
                      <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                        <span className="text-xs font-bold text-slate-500">تاريخ التسجيل:</span>
                        <span className="text-sm text-slate-700">
                          {new Date(trackResult.receivedAt).toLocaleDateString("ar-SA", {
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </span>
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <span className="text-xs font-bold text-slate-500">الحالة الراهنة:</span>
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-800">
                          <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                          <span>{trackResult.statusArabic}</span>
                        </span>
                      </div>
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

