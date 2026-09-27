import type { ReactNode } from "react";
import { HashScrollFix } from "@/components/site/hash-scroll-fix";

/**
 * انتقال الصفحات على مستوى التطبيق (Page Transitions)
 * انتقال خفيف (opacity + y + scale) عبر CSS فقط (انظر .page-template في globals.css)
 * يُرسَّر مرئياً في HTML الثابت فلا وميض أبيض قبل الـ hydration ولا انتظار لجافاسكربت
 * مع تعطيل كامل للحركة تلقائياً عند تفعيل prefers-reduced-motion
 * + HashScrollFix: يضمن الوصول الدقيق لأقسام الصفحة عند التنقل بروابط الهاش
 */
export default function Template({ children }: { children: ReactNode }) {
  return (
    <div className="page-template flex min-h-screen flex-col w-full">
      <HashScrollFix />
      {children}
    </div>
  );
}
