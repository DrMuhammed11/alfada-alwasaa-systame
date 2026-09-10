import { z } from "zod";
import { SITE_CONFIG } from "@/config/site";

/**
 * مخطط التحقق من صحة مدخلات نموذج التواصل وطلب التسعير
 * مطابقة دقيقة لحقول InquiryPayload في api.ts مع رسائل خطأ عربية واضحة
 */
export const inquirySchema = z.object({
  name: z
    .string()
    .trim()
    .min(2, { message: "يرجى كتابة الاسم الكريم (حرفان على الأقل)" })
    .max(100, { message: "الاسم طويل جداً (الحد الأقصى 100 حرف)" }),

  phone: z
    .string()
    .trim()
    .min(8, { message: "يرجى إدخال رقم هاتف صحيح (8 أرقام على الأقل)" })
    .max(20, { message: "رقم الهاتف طويل جداً" })
    .regex(/^[+0-9][0-9\s-]{7,19}$/, {
      message: "يرجى إدخال رقم هاتف صحيح (مثال: 776999942 أو +967...)",
    }),

  email: z
    .string()
    .trim()
    .email({ message: "يرجى إدخال بريد إلكتروني صالح (مثال: name@domain.com)" })
    .optional()
    .or(z.literal("")),

  service: z
    .string()
    .trim()
    .min(1, { message: "يرجى اختيار الخدمة المطلوبة" }),

  message: z
    .string()
    .trim()
    .max(1500, { message: "نص الرسالة يجب ألا يتجاوز 1500 حرف" })
    .optional()
    .or(z.literal("")),
});

export type InquiryFormValues = z.infer<typeof inquirySchema>;

