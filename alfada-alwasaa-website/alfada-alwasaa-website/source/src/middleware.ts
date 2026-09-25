import { NextResponse, type NextRequest } from "next/server";

/**
 * يضع ترويسة x-locale حسب مسار الطلب (/en*) ليقرأها الـ layout الجذري
 * ويصيّر <html lang dir> الصحيحة على الخادم — i18n بنيوي بلا hack عميل.
 */
export function middleware(request: NextRequest) {
  const isEnglish =
    request.nextUrl.pathname === "/en" || request.nextUrl.pathname.startsWith("/en/");

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-locale", isEnglish ? "en" : "ar");

  return NextResponse.next({ request: { headers: requestHeaders } });
}

export const config = {
  // كل المسارات ما عدا ملفات Next الثابتة وواجهة API والملفات ذات الامتدادات
  matcher: ["/((?!_next/static|_next/image|api/|.*\\..*).*)"],
};
