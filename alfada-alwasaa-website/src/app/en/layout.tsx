import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Al-Fada Al-Wasaa | Telecommunications & General Contracting Services",
  description:
    "Official corporate portal of Al-Fada Al-Wasaa Company for Telecom Services, General Contracting, and Supplies in Yemen. Integrated engineering, procurement, and execution solutions across major infrastructure projects.",
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en",
    languages: {
      ar: "https://www.alfadaalwasaa.com",
      en: "https://www.alfadaalwasaa.com/en",
    },
  },
  openGraph: {
    title: "Al-Fada Al-Wasaa | Telecom & Contracting Services",
    description: "Integrated solutions within one ecosystem combining executive expertise and institutional discipline.",
    locale: "en_US",
  },
};

export default function EnglishLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div dir="ltr" lang="en" className="min-h-screen text-left">
      {children}
    </div>
  );
}
