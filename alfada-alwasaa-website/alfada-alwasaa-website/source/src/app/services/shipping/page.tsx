import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { SERVICES_DATA } from "@/config/services-data";
import { ServicePageView } from "@/components/site/service-page-view";

const service = SERVICES_DATA["shipping"];

export const metadata: Metadata = {
  title: service.seoTitle,
  description: service.seoDescription,
  keywords: service.keywords,
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/services/shipping",
    languages: {
      ar: "https://www.alfadaalwasaa.com/services/shipping",
      en: "https://www.alfadaalwasaa.com/en/services/shipping",
    },
  },
  openGraph: {
    title: service.seoTitle,
    description: service.seoDescription,
    url: "https://www.alfadaalwasaa.com/services/shipping",
    images: [
      {
        url: service.image,
        width: 1200,
        height: 630,
        alt: service.title,
      },
    ],
    locale: "ar_YE",
    type: "website",
  },
};

export default function ServicePage() {
  if (!service) notFound();
  return <ServicePageView service={service} />;
}