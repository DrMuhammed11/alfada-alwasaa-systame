/**
 * طبقة جلب محتوى الموقع من واجهة /site-content/* في الخادم الخلفي.
 * - تعمل على الخادم فقط (Server Components) مع ISR: revalidate 5 دقائق
 * - عند فشل الخادم تعيد [] ليتحمل كل مستهلك قيمه الافتراضية من ملفات
 *   الكونفغ المحلية — الموقع لا ينكسر إن كان الـ CMS بعيداً
 */

const SERVER_API_BASE =
  process.env.API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

const REVALIDATE_SECONDS = 300;

async function fetchContentList(path: string): Promise<Record<string, unknown>[]> {
  try {
    const res = await fetch(`${SERVER_API_BASE}/site-content/${path}`, {
      next: { revalidate: REVALIDATE_SECONDS },
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

async function fetchContentSetting(key: string): Promise<Record<string, unknown> | null> {
  try {
    const res = await fetch(`${SERVER_API_BASE}/site-content/settings/${key}`, {
      next: { revalidate: REVALIDATE_SECONDS },
      headers: { Accept: "application/json" },
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data && typeof data === "object" ? (data["value"] as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

// ─── الأنواع المطابقة لنماذج الخادم ───

export interface ContentService {
  slug: string;
  titleAr: string;
  titleEn: string;
  shortAr?: string;
  shortEn?: string;
  icon?: string;
  image?: string;
  features?: string[];
  order: number;
}

export interface ContentSector {
  titleAr: string;
  titleEn: string;
  descAr?: string;
  descEn?: string;
  icon?: string;
  services?: string[];
  order: number;
}

export interface ContentProject {
  titleAr: string;
  titleEn: string;
  tagAr?: string;
  tagEn?: string;
  scopeAr?: string;
  scopeEn?: string;
  metrics?: string[];
  image?: string;
  order: number;
}

export interface ContentFaq {
  questionAr: string;
  questionEn: string;
  answerAr: string;
  answerEn: string;
  order: number;
}

// ─── دوال الاستهلاك ───

export const getServices = () => fetchContentList("services").then((d) => d as unknown as ContentService[]);
export const getSectors = () => fetchContentList("sectors").then((d) => d as unknown as ContentSector[]);
export const getProjects = () => fetchContentList("projects").then((d) => d as unknown as ContentProject[]);
export const getFaqs = () => fetchContentList("faqs").then((d) => d as unknown as ContentFaq[]);
export const getSetting = fetchContentSetting;
