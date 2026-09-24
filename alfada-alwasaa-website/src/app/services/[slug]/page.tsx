import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { SERVICES_DATA } from "@/config/services-data";
import { SITE_CONFIG } from "@/config/site";
import { ServiceDetailView } from "@/components/site/service-detail-view";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export function generateStaticParams() {
  return Object.keys(SERVICES_DATA).map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const service = SERVICES_DATA[slug];
  if (!service) return {};

  const canonical = `https://www.alfadaalwasaa.com/services/${slug}`;
  return {
    title: service.seoTitle,
    description: service.seoDescription,
    keywords: service.keywords,
    alternates: {
      canonical,
      languages: {
        ar: canonical,
        en: `https://www.alfadaalwasaa.com/en/services/${slug}`,
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
      locale: "ar_YE",
      type: "website",
    },
  };
}

export default async function ServicePage({ params }: PageProps) {
  const { slug } = await params;
  const service = SERVICES_DATA[slug];
  if (!service) notFound();

  // المخططات المنظمة: الأسئلة الشائعة + مسار التنقل + الخدمة
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
        name: "الرئيسية",
        item: "https://www.alfadaalwasaa.com",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "خدماتنا",
        item: "https://www.alfadaalwasaa.com/#services",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: service.title,
        item: `https://www.alfadaalwasaa.com/services/${service.slug}`,
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
      name: SITE_CONFIG.company.fullName,
      url: "https://www.alfadaalwasaa.com",
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
      <ServiceDetailView service={service} locale="ar" />
    </>
  );
}
