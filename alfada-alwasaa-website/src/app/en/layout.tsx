import type { Metadata } from "next";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { LangSync } from "@/components/site/lang-sync";

export const metadata: Metadata = {
  title: {
    // absolute: يتجاوز قالب العنوان العربي في الـ layout الجذري
    absolute: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
    template: "%s | Al-Fada Al-Wasaa",
  },
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
  },
  twitter: {
    card: "summary_large_image",
    title: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
    description:
      "The official portal of Al-Fada Al-Wasaa — integrated solutions with leading executive efficiency and institutional discipline across Yemen.",
    images: ["/profile/hero_bg.webp"],
  },
};

export default function EnglishLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div dir="ltr" lang="en" className="min-h-screen text-left">
      <script
        dangerouslySetInnerHTML={{
          __html: `document.documentElement.lang="en";document.documentElement.dir="ltr";`,
        }}
      />
      <LangSync lang="en" dir="ltr" />
      {children}
    </div>
  );
}
