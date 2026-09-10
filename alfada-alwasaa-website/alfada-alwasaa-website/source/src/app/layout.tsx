import type { Metadata } from "next";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const cairo = Cairo({
  variable: "--font-cairo",
  subsets: ["arabic", "latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  display: "swap",
  preload: true,
  adjustFontFallback: true,
  fallback: ["Tahoma", "Segoe UI", "system-ui", "sans-serif"],
});

/**
 * إعدادات البيانات الوصفية (Metadata) وتحسين محركات البحث (SEO)
 * موجهة للغة العربية والظهور في نتائج البحث ووسائل التواصل
 */
export const metadata: Metadata = {
  // النطاق الأساسي لتوحيد روابط OpenGraph ومحركات البحث
  metadataBase: new URL("https://www.alfadaalwasaa.com"),
  title: {
    default: "شركة الفضاء الواسع | لخدمات الاتصالات والمقاولات العامة",
    template: "%s | شركة الفضاء الواسع",
  },
  description:
    "الموقع الرسمي لشركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة والتوريدات في اليمن وصنعاء. حلول متكاملة، كفاءة هندسية، ودقة تنفيذية في إدارة وتنفيذ أضخم المشاريع.",
  keywords: [
    "الفضاء الواسع",
    "شركة الفضاء الواسع",
    "موقع شركة الفضاء الواسع",
    "الفضاء الواسع للمقاولات",
    "الفضاء الواسع للاتصالات",
    "شركة الفضاء الواسع صنعاء",
    "Al-Fada Al-Wasaa",
    "alfada alwasaa",
    "alfadaalwasaa",
    "خدمات الاتصالات",
    "المقاولات العامة",
    "العوازل المائية والحرارية",
    "الشحن والتخليص الجمركي",
    "التوريدات والتموينات",
    "صنعاء اليمن",
  ],
  authors: [{ name: "شركة الفضاء الواسع", url: "https://www.alfadaalwasaa.com" }],
  creator: "شركة الفضاء الواسع",
  publisher: "شركة الفضاء الواسع",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com",
  },
  icons: {
    icon: "/profile/logo_mark.png",
    apple: "/profile/logo_mark.png",
  },
  openGraph: {
    title: "شركة الفضاء الواسع | لخدمات الاتصالات والمقاولات العامة",
    description:
      "الموقع الرسمي لشركة الفضاء الواسع — حلول متكاملة ضمن منظومة واحدة تجمع بين الخبرة التنفيذية والانضباط المؤسسي.",
    url: "https://www.alfadaalwasaa.com",
    siteName: "شركة الفضاء الواسع",
    images: [
      {
        url: "/profile/logo_mark.png",
        width: 800,
        height: 600,
        alt: "شعار شركة الفضاء الواسع الرسمي",
      },
    ],
    locale: "ar_YE",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "شركة الفضاء الواسع | لخدمات الاتصالات والمقاولات العامة",
    description:
      "الموقع الرسمي لشركة الفضاء الواسع — حلول متكاملة ضمن منظومة واحدة.",
    images: ["/profile/logo_mark.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://www.alfadaalwasaa.com/#organization",
      name: "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات",
      alternateName: [
        "الفضاء الواسع",
        "شركة الفضاء الواسع",
        "Al-Fada Al-Wasaa",
        "alfadaalwasaa",
      ],
      url: "https://www.alfadaalwasaa.com",
      logo: "https://www.alfadaalwasaa.com/profile/logo_mark.png",
      email: "info@alfadaalwasaa.com",
      telephone: "+967776999942",
      address: {
        "@type": "PostalAddress",
        streetAddress: "جوار مصنع شملان",
        addressLocality: "صنعاء",
        addressCountry: "YE",
      },
      contactPoint: [
        {
          "@type": "ContactPoint",
          telephone: "+967776999942",
          contactType: "customer service",
          areaServed: "YE",
          availableLanguage: ["Arabic", "English"],
        },
      ],
    },
    {
      "@type": "WebSite",
      "@id": "https://www.alfadaalwasaa.com/#website",
      url: "https://www.alfadaalwasaa.com",
      name: "شركة الفضاء الواسع",
      publisher: {
        "@id": "https://www.alfadaalwasaa.com/#organization",
      },
      inLanguage: "ar",
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body
        className={`${cairo.variable} font-cairo antialiased bg-background text-foreground`}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
