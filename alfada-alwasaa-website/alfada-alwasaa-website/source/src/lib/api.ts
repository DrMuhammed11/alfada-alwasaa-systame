/**
 * مكتبة الربط والتواصل مع الواجهة الخلفية لنظام إدارة المراسلات
 * شركة الفضاء الواسع
 */

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

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
  message: string;
  error?: string;
}

export interface TrackingResult {
  refNumber: string;
  subject: string;
  status: string;
  statusArabic: string;
  receivedAt: string;
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

/** إرسال طلب عرض سعر أو استشارة جديدة إلى نظام المراسلات */
export async function submitInquiry(
  payload: InquiryPayload
): Promise<InquiryResponse> {
  try {
    const res = await fetch(`${API_BASE_URL}/correspondences/public/inquiry`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json().catch(() => ({}));

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
      message: data.message || "تم استلام طلبكم بنجاح",
    };
  } catch (err) {
    console.error("submitInquiry error:", err);
    return {
      success: false,
      message: "تعذر الاتصال بخادم الشركة. يرجى التحقق من الاتصال والمحاولة مجدداً.",
      error: (err as Error).message,
    };
  }
}

/** تتبع حالة طلب أو معاملة برقمها المرجعي الرسمي */
export async function trackInquiry(
  refNumber: string
): Promise<{ success: boolean; data?: TrackingResult; error?: string }> {
  try {
    const cleanRef = refNumber.trim().toUpperCase();
    const res = await fetch(
      `${API_BASE_URL}/correspondences/public/track/${encodeURIComponent(cleanRef)}`,
      {
        method: "GET",
        headers: { Accept: "application/json" },
      }
    );

    const data = await res.json().catch(() => ({}));

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
      },
    };
  } catch (err) {
    console.error("trackInquiry error:", err);
    return {
      success: false,
      error: "تعذر الاتصال بالخادم لمتابعة المعاملة",
    };
  }
}
