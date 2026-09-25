import type { Metadata } from "next";
import { EN_SITE_CONFIG } from "@/config/en-site";

export const metadata: Metadata = {
  title: {
    // absolute: يتجاوز قالب العنوان العربي في الـ layout الجذري
    absolute: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
    template: "%s | Al-Fada Al-Wasaa",
  },
  description:
    "The official portal of Al-Fada Al-Wasaa — integrated solutions with leading executive efficiency and institutional discipline across Yemen.",
  authors: [{ name: EN_SITE_CONFIG.company.shortName, url: "https://www.alfadaalwasaa.com/en" }],
  creator: EN_SITE_CONFIG.company.shortName,
  publisher: EN_SITE_CONFIG.company.shortName,
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en",
    languages: {
      ar: "https://www.alfadaalwasaa.com",
      en: "https://www.alfadaalwasaa.com/en",
      "x-default": "https://www.alfadaalwasaa.com",
    },
    types: {
      "application/rss+xml": "https://www.alfadaalwasaa.com/en/rss.xml",
    },
  },
  // OpenGraph إنجليزي صريح — كان يُورَّث عربيًا من الجذر فيشارك رابط /en عربيًا
  openGraph: {
    title: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
    description:
      "The official portal of Al-Fada Al-Wasaa — integrated solutions with leading executive efficiency and institutional discipline across Yemen.",
    url: "https://www.alfadaalwasaa.com/en",
    siteName: "Al-Fada Al-Wasaa",
    images: [
      {
        url: "/profile/hero_bg.webp",
        width: 1200,
        height: 630,
        alt: "Al-Fada Al-Wasaa — Telecommunications & General Contracting",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
    description:
      "The official portal of Al-Fada Al-Wasaa — integrated solutions with leading executive efficiency and institutional discipline across Yemen.",
    images: ["/profile/hero_bg.webp"],
  },
};

// لغة الصفحة واتجاهها يُضبطان من الجذر عبر ترويسة x-locale التي يضعها middleware —
// لم يعد هناك حاجة لهجمات تعديل documentElement من العميل
export default function EnglishLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <div dir="ltr" lang="en" className="min-h-screen text-left">{children}</div>;
}
