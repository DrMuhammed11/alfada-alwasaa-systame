/**
 * مكتبة الربط والتواصل مع الواجهة الخلفية لنظام إدارة المراسلات
 * شركة الفضاء الواسع
 */

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

/**
 * تم تحديد المهلة الزمنية بـ 12 ثانية لتغطية زمن استيقاظ الخوادم السحابية المجانية (Cold Starts)
 * وفي نفس الوقت تفادي تعليق واجهة المستخدم لفترة طويلة في حال تعثر الشبكة.
 */
const REQUEST_TIMEOUT_MS = 12000;

export interface InquiryPayload {
  name: string;
  phone: string;
  email?: string;
  service: string;
  message?: string;
}

export interface InquiryResponse {
  success: boolean;
  refNumber?: string;
  trackingToken?: string;
  message: string;
  error?: string;
}

export interface TrackingResult {
  refNumber: string;
  subject: string;
  status: string;
  statusArabic: string;
  receivedAt: string;
  reply?: {
    refNumber?: string;
    body: string;
    sentAt?: string;
  } | null;
}

/** ترجمة الحالات المؤسسية للمراسلة إلى عبارات مفهومة للعميل */
export function getClientStatusLabel(status: string): string {
  switch (status?.toUpperCase()) {
    case "RECEIVED":
    case "UNDER_REVIEW":
      return "مستلمة — قيد الدراسة الفنية";
    case "REFERRED":
    case "IN_PROGRESS":
      return "قيد المعالجة والتسعير لدى الإدارة المختصة";
    case "PENDING_APPROVAL":
    case "APPROVED":
      return "تم إعداد الرد وفي مرحلة المراجعة النهائية";
    case "SENT":
    case "CLOSED":
    case "ARCHIVED":
      return "تم الرد والتواصل مع العميل بنجاح";
    default:
      return status || "قيد المتابعة";
  }
}

/** فحص ما إذا كان الخطأ ناتجاً عن انتهاء المهلة الزمنية */
function isTimeoutError(err: unknown): boolean {
  return (
    (err instanceof DOMException && err.name === "AbortError") ||
    (err instanceof Error && err.name === "AbortError")
  );
}

/** دالة مساعدة لتنفيذ الطلبات مع دعم AbortController والمهلة الزمنية */
async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
  timeoutMs: number = REQUEST_TIMEOUT_MS
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }
}

/** إرسال طلب عرض سعر أو استشارة جديدة إلى نظام المراسلات */
export async function submitInquiry(
  payload: InquiryPayload
): Promise<InquiryResponse> {
  try {
    const res = await fetchWithTimeout(
      `${API_BASE_URL}/correspondences/public/inquiry`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
      }
    );

    const data = await res.json().catch(() => ({}));

    // خطأ من جانب الخادم (Server Error)
    if (!res.ok) {
      const errMsg =
        data.message ||
        (Array.isArray(data.message) ? data.message.join("، ") : null) ||
        "تعذر إرسال الطلب حالياً، يرجى المحاولة لاحقاً";
      return { success: false, message: errMsg, error: errMsg };
    }

    return {
      success: true,
      refNumber: data.refNumber,
      trackingToken: data.trackingToken,
      message: data.message || "تم استلام طلبكم بنجاح",
    };
  } catch (err: unknown) {
    console.error("submitInquiry error:", err);

    // خطأ انتهاء المهلة الزمنية (Timeout Error)
    if (isTimeoutError(err)) {
      return {
        success: false,
        message:
          "استغرق الطلب وقتاً أطول من المتوقع (انتهت المهلة 12 ثانية). يرجى التحقق من الاتصال والمحاولة مجدداً.",
        error: "انتهت مهلة الطلب (Request Timeout)",
      };
    }

    // خطأ في الشبكة أو تعذر الاتصال (Network Error)
    return {
      success: false,
      message:
        "تعذر الاتصال بخادم الشركة. يرجى التحقق من الاتصال والمحاولة مجدداً.",
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/** تتبع حالة طلب أو معاملة برقمها المرجعي الرسمي ورمز التتبع الآمن */
export async function trackInquiry(
  refNumber: string,
  token?: string
): Promise<{ success: boolean; data?: TrackingResult; error?: string }> {
  try {
    const cleanRef = refNumber.trim().toUpperCase();
    const cleanToken = token?.trim() || "";
    const url = `${API_BASE_URL}/correspondences/public/track/${encodeURIComponent(cleanRef)}${
      cleanToken ? `?token=${encodeURIComponent(cleanToken)}` : ""
    }`;
    const res = await fetchWithTimeout(url, {
      method: "GET",
      headers: { Accept: "application/json" },
    });

    const data = await res.json().catch(() => ({}));

    // خطأ من جانب الخادم أو المعاملة غير موجودة (Server/Not Found Error)
    if (!res.ok) {
      return {
        success: false,
        error: data.message || "لم يتم العثور على معاملة بهذا الرقم المرجعي",
      };
    }

    return {
      success: true,
      data: {
        refNumber: data.refNumber,
        subject: data.subject,
        status: data.status,
        statusArabic: getClientStatusLabel(data.status),
        receivedAt: data.receivedAt,
        reply: data.reply ?? null,
      },
    };
  } catch (err: unknown) {
    console.error("trackInquiry error:", err);

    // خطأ انتهاء المهلة الزمنية (Timeout Error)
    if (isTimeoutError(err)) {
      return {
        success: false,
        error:
          "استغرقت عملية الاستعلام وقتاً أطول من المتوقع (انتهت مهلة 12 ثانية). يرجى المحاولة مجدداً.",
      };
    }

    // خطأ في الشبكة أو تعذر الاتصال (Network Error)
    return {
      success: false,
      error: "تعذر الاتصال بالخادم لمتابعة المعاملة",
    };
  }
}
