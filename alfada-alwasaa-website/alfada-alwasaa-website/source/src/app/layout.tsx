import type { Metadata } from "next";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const cairo = Cairo({
  variable: "--font-cairo",
  subsets: ["arabic", "latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
});

export const metadata: Metadata = {
  title: "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات | حلول متكاملة ضمن منظومة واحدة",
  description:
    "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات — كيان مهني متعدد الخدمات يقدم حلولاً متكاملة في مجالات المقاولات والاتصالات والخدمات المساندة، بين القوة في التنفيذ والرقّي في التعامل والدقة في الأداء.",
  keywords: [
    "الفضاء الواسع",
    "Al-Fada Al-Wasaa",
    "خدمات الاتصالات",
    "المقاولات العامة",
    "حلول متكاملة",
    "الشحن والتخليص الجمركي",
    "التوريدات والتموينات",
  ],
  icons: {
    icon: "/profile/logo_mark.png",
  },
  openGraph: {
    title: "شركة الفضاء الواسع | حلول متكاملة ضمن منظومة واحدة",
    description:
      "كيان مهني متعدد الخدمات، تأسس على رؤية واضحة تقوم على تقديم حلول متكاملة تجمع بين الخبرة التنفيذية والانضباط المؤسسي.",
    type: "website",
    locale: "ar_SA",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <body
        className={`${cairo.variable} font-cairo antialiased bg-background text-foreground`}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
