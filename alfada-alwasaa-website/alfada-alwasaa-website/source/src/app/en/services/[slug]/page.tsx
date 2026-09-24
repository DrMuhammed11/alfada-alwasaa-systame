import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { EN_SERVICES_DATA } from "@/config/en-services-data";
import { EnServicePageView } from "@/components/site/en-service-page-view";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export function generateStaticParams() {
  return Object.keys(EN_SERVICES_DATA).map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const service = EN_SERVICES_DATA[slug];
  if (!service) return {};

  return {
    title: service.seoTitle,
    description: service.seoDescription,
    keywords: service.keywords,
    alternates: {
      canonical: `https://www.alfadaalwasaa.com/en/services/${slug}`,
      languages: {
        ar: `https://www.alfadaalwasaa.com/services/${slug}`,
        en: `https://www.alfadaalwasaa.com/en/services/${slug}`,
      },
    },
    openGraph: {
      title: service.seoTitle,
      description: service.seoDescription,
      url: `https://www.alfadaalwasaa.com/en/services/${slug}`,
      images: [
        {
          url: service.image,
          width: 1200,
          height: 630,
          alt: service.title,
        },
      ],
      locale: "en_US",
      type: "website",
    },
  };
}

export default async function EnServicePage({ params }: PageProps) {
  const { slug } = await params;
  const service = EN_SERVICES_DATA[slug];
  if (!service) notFound();
  return <EnServicePageView service={service} />;
}
