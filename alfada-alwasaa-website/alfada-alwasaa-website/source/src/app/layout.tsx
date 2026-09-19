import type { Metadata, Viewport } from "next";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as SonnerToaster } from "sonner";
import { QueryProvider } from "@/components/providers/query-provider";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { LenisProvider } from "@/components/providers/lenis-provider";
import { SITE_CONFIG } from "@/config/site";

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#0a3453" },
    { media: "(prefers-color-scheme: dark)", color: "#051e31" },
  ],
  colorScheme: "light dark",
  width: "device-width",
  initialScale: 1,
};

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
        "إنشاء وصيانة الطرق والجسور",
        "أعمال الحفريات وتسوية المواقع",
        "التوريدات والتموينات البترولية",
        "خدمات الاتصالات والحلول التقنية",
        "الشحن والتخليص الجمركي",
        "التسويق الإلكتروني",
      ],
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

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const gaId = process.env.NEXT_PUBLIC_GA_ID;

  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
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
        <QueryProvider>
          <ThemeProvider
            attribute="class"
            defaultTheme="light"
            enableSystem
            disableTransitionOnChange
          >
            <LenisProvider>
              {children}
              <Toaster />
              <SonnerToaster richColors position="top-center" dir="rtl" />
            </LenisProvider>
          </ThemeProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
