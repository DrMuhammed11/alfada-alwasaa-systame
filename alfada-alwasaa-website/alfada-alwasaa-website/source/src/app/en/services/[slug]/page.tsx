import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { EN_SERVICES_DATA } from "@/config/en-services-data";
import { EN_SITE_CONFIG } from "@/config/en-site";
import { ServiceDetailView } from "@/components/site/service-detail-view";

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

  const canonical = `https://www.alfadaalwasaa.com/en/services/${slug}`;
  return {
    title: service.seoTitle,
    description: service.seoDescription,
    keywords: service.keywords,
    alternates: {
      canonical,
      languages: {
        ar: `https://www.alfadaalwasaa.com/services/${slug}`,
        en: canonical,
      },
    },
    openGraph: {
      title: service.seoTitle,
      description: service.seoDescription,
      url: canonical,
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

  // Structured schemas: FAQ + Breadcrumb + Service
  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: service.faqs.map((faq) => ({
      "@type": "Question",
      name: faq.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.a,
      },
    })),
  };

  const breadcrumbSchema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: "https://www.alfadaalwasaa.com/en",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Services",
        item: "https://www.alfadaalwasaa.com/en#services",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: service.title,
        item: `https://www.alfadaalwasaa.com/en/services/${service.slug}`,
      },
    ],
  };

  const serviceSchema = {
    "@context": "https://schema.org",
    "@type": "Service",
    name: service.title,
    description: service.subtitle,
    provider: {
      "@type": "Organization",
      name: EN_SITE_CONFIG.company.fullName,
      url: "https://www.alfadaalwasaa.com/en",
    },
    areaServed: {
      "@type": "Country",
      name: "Yemen",
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(serviceSchema) }}
      />
      <ServiceDetailView service={service} locale="en" />
    </>
  );
}
