import type { ReactNode } from "react";

/**
 * انتقال الصفحات على مستوى التطبيق (Page Transitions)
 * انتقال خفيف جداً (opacity + 8px y) لمدة 200ms عبر CSS فقط (انظر .page-template في globals.css)
 * يُرسَّر مرئياً في HTML الثابت فلا وميض أبيض قبل الـ hydration ولا انتظار لجافاسكربت
 * مع تعطيل كامل للحركة تلقائياً عند تفعيل prefers-reduced-motion
 */
export default function Template({ children }: { children: ReactNode }) {
  return (
    <div className="page-template flex min-h-screen flex-col w-full">
      {children}
    </div>
  );
}
