import type { Metadata, Viewport } from "next";
import { headers } from "next/headers";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as SonnerToaster } from "sonner";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { LenisProvider } from "@/components/providers/lenis-provider";
import { CookieConsent } from "@/components/site/cookie-consent";
import { SkipLink } from "@/components/site/skip-link";
import { SITE_CONFIG } from "@/config/site";

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#0a3453" },
    { media: "(prefers-color-scheme: dark)", color: "#051e31" },
  ],
  colorScheme: "light dark",
  width: "device-width",
  initialScale: 1,
  // ضروري لتفعيل env(safe-area-inset-*) في globals.css على أجهزة النوتش
  viewportFit: "cover",
};

const cairo = Cairo({
  variable: "--font-cairo",
  subsets: ["arabic", "latin"],
  weight: ["500", "600", "700", "800", "900"],
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
    "شركة الفضاء الواسع",
    "خدمات الاتصالات اليمن",
    "المقاولات العامة صنعاء",
    "إنشاء وصيانة الطرق والجسور",
    "التخليص الجمركي والشحن",
    "التوريدات والتموينات العامة",
    "Al-Fada Al-Wasaa Company",
    "General Contracting Yemen",
  ],
  authors: [{ name: "شركة الفضاء الواسع", url: "https://www.alfadaalwasaa.com" }],
  creator: "شركة الفضاء الواسع",
  publisher: "شركة الفضاء الواسع",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com",
    languages: {
      ar: "https://www.alfadaalwasaa.com",
      en: "https://www.alfadaalwasaa.com/en",
      "x-default": "https://www.alfadaalwasaa.com",
    },
    types: {
      "application/rss+xml": "https://www.alfadaalwasaa.com/rss.xml",
    },
  },
  manifest: "/manifest.webmanifest",
  verification: {
    google: "016da0dfa06d1301",
    other: {
      "google-site-verification": [
        "google016da0dfa06d1301.html",
        "016da0dfa06d1301",
      ],
    },
  },
  icons: {
    icon: "/profile/logo_mark.png",
    apple: "/profile/logo_mark.png",
  },
  openGraph: {
    title: "شركة الفضاء الواسع | لخدمات الاتصالات والمقاولات العامة",
    description:
      "الموقع الرسمي لشركة الفضاء الواسع — حلول متكاملة تجمع بين الكفاءة الهندسية والانضباط المؤسسي الميداني في اليمن.",
    url: "https://www.alfadaalwasaa.com",
    siteName: "شركة الفضاء الواسع",
    images: [
      {
        url: "/profile/hero_bg.webp",
        width: 1200,
        height: 630,
        alt: "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة",
      },
    ],
    locale: "ar_YE",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "شركة الفضاء الواسع | لخدمات الاتصالات والمقاولات العامة",
    description:
      "الموقع الرسمي لشركة الفضاء الواسع — حلول متكاملة وكفاءة تنفيذية رائدة.",
    images: ["/profile/hero_bg.webp"],
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
      name: SITE_CONFIG.company.fullName,
      alternateName: [
        SITE_CONFIG.company.shortName,
        SITE_CONFIG.company.enName,
        "الفضاء الواسع",
        "شركة الفضاء الواسع",
        "Al-Fada Al-Wasaa",
        "alfadaalwasaa",
      ],
      description: SITE_CONFIG.company.brief,
      url: "https://www.alfadaalwasaa.com",
      logo: `https://www.alfadaalwasaa.com${SITE_CONFIG.assets.logoMark}`,
      email: SITE_CONFIG.contacts.email.address,
      telephone: SITE_CONFIG.contacts.general.raw,
      address: {
        "@type": "PostalAddress",
        streetAddress: SITE_CONFIG.contacts.location.fullAddress,
        addressLocality: SITE_CONFIG.contacts.location.city,
        addressCountry: "YE",
      },
      contactPoint: [
        {
          "@type": "ContactPoint",
          telephone: SITE_CONFIG.contacts.general.raw,
          contactType: "customer service",
          areaServed: "YE",
          availableLanguage: ["Arabic", "English"],
        },
        {
          "@type": "ContactPoint",
          telephone: SITE_CONFIG.contacts.deputy.raw,
          contactType: "project management",
          areaServed: "YE",
          availableLanguage: ["Arabic", "English"],
        },
      ],
      hasOfferCatalog: {
        "@type": "OfferCatalog",
        name: "منظومة خدمات وقطاعات شركة الفضاء الواسع",
        itemListElement: SITE_CONFIG.servicesList.map((service, index) => ({
          "@type": "Offer",
          itemOffered: {
            "@type": "Service",
            name: service.title,
            description: service.desc,
          },
          position: index + 1,
        })),
      },
    },
    {
      "@type": "GeneralContractor",
      "@id": "https://www.alfadaalwasaa.com/#business",
      name: SITE_CONFIG.company.fullName,
      image: `https://www.alfadaalwasaa.com${SITE_CONFIG.assets.logoMark}`,
      url: "https://www.alfadaalwasaa.com",
      telephone: SITE_CONFIG.contacts.general.raw,
      email: SITE_CONFIG.contacts.email.address,
      priceRange: "$$",
      address: {
        "@type": "PostalAddress",
        streetAddress: SITE_CONFIG.contacts.location.fullAddress,
        addressLocality: SITE_CONFIG.contacts.location.city,
        addressRegion: "صنعاء",
        addressCountry: "YE",
      },
      geo: {
        "@type": "GeoCoordinates",
        latitude: "15.3694",
        longitude: "44.1910",
      },
      openingHoursSpecification: [
        {
          "@type": "OpeningHoursSpecification",
          dayOfWeek: [
            "Saturday",
            "Sunday",
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
          ],
          opens: "08:00",
          closes: "18:00",
        },
      ],
      areaServed: {
        "@type": "Country",
        name: "Yemen",
      },
      knowsAbout: [
        "المقاولات العامة والإنشاءات",
        "شق وتعبيد الطرق",
        "الحفريات والردميات الهندسية",
        "أبراج وشبكات الاتصالات",
        "الشحن والتخليص الجمركي",
        "التوريدات العامة والتجهيزات",
        "التسويق العقاري والفرص الاستثمارية",
      ],
      // أزيلت aggregateRating وreview المزيفة ذاتيًا — مخالفة موثقة لإرشادات
      // Google للبيانات المنظمة وتعرّض الموقع لإجراء يدوي
    },
    {
      "@type": "WebSite",
      "@id": "https://www.alfadaalwasaa.com/#website",
      url: "https://www.alfadaalwasaa.com",
      name: SITE_CONFIG.company.shortName,
      publisher: {
        "@id": "https://www.alfadaalwasaa.com/#organization",
      },
      inLanguage: "ar",
    },
  ],
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const gaId = process.env.NEXT_PUBLIC_GA_ID;

  // اللغة والاتجاه يُحدَّدان من ترويسة x-locale التي يضعها middleware حسب المسار (/en*)
  // — إشارة HTML صحيحة للزواحف وقارئات الشاشة في كلتا اللغتين، بلا هجمات عميل
  const requestHeaders = await headers();
  const locale = requestHeaders.get("x-locale") === "en" ? "en" : "ar";
  const dir = locale === "en" ? "ltr" : "rtl";

  return (
    <html lang={locale} dir={dir} suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        {/* preload لصورة الهيرو يولّدها Next تلقائياً من Image priority في hero.tsx
            (الوسم اليدوي السابق كان يضاعفه ويحمّل الصورة في صفحات بلا هيرو) */}
        {gaId && (
          <>
            <script
              async
              src={`https://www.googletagmanager.com/gtag/js?id=${gaId}`}
            />
            <script
              dangerouslySetInnerHTML={{
                __html: `
                  window.dataLayer = window.dataLayer || [];
                  function gtag(){dataLayer.push(arguments);}
                  gtag('js', new Date());
                  gtag('config', '${gaId}');
                `,
              }}
            />
          </>
        )}
      </head>
      <body
        className={`${cairo.variable} font-cairo antialiased bg-background text-foreground`}
      >
        {/* رابط تجاوز المحتوى للوصولية — يظهر عند التركيز بلوحة المفاتيح فقط (يتبع لغة الصفحة) */}
        <SkipLink />
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          <LenisProvider>
            {children}
            <CookieConsent />
            <Toaster />
            <SonnerToaster richColors position="top-center" dir="rtl" />
          </LenisProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
