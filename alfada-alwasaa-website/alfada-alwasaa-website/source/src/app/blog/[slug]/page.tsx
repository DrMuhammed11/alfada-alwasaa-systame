import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { 
  Calendar, 
  Clock, 
  User, 
  ChevronLeft, 
  Share2, 
  Building2, 
  ArrowLeft 
} from "lucide-react";
import { BLOG_POSTS } from "@/config/blog-data";
import { SiteHeader } from "@/components/site/header";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";
import { ReadingProgress } from "@/components/site/reading-progress";

export function generateStaticParams() {
  return Object.keys(BLOG_POSTS).map((slug) => ({ slug }));
}

interface Props {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = BLOG_POSTS[slug];
  if (!post) return {};

  return {
    title: `${post.title} | مدونة الفضاء الواسع`,
    description: post.description,
    keywords: post.keywords,
    alternates: {
      canonical: `https://www.alfadaalwasaa.com/blog/${slug}`,
      languages: {
        ar: `https://www.alfadaalwasaa.com/blog/${slug}`,
        en: `https://www.alfadaalwasaa.com/en/blog/${slug}`,
      },
    },
    openGraph: {
      title: post.title,
      description: post.description,
      url: `https://www.alfadaalwasaa.com/blog/${slug}`,
      images: [{ url: post.image, width: 1200, height: 630, alt: post.title }],
      locale: "ar_YE",
      type: "article",
    },
  };
}

export default async function SingleBlogPostPage({ params }: Props) {
  const { slug } = await params;
  const post = BLOG_POSTS[slug];
  if (!post) notFound();

  const otherPosts = Object.values(BLOG_POSTS).filter((p) => p.slug !== slug);

  // Article Schema for Google Search
  const articleSchema = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    description: post.description,
    image: `https://www.alfadaalwasaa.com${post.image}`,
    datePublished: post.date,
    dateModified: post.date,
    author: {
      "@type": "Organization",
      name: "شركة الفضاء الواسع لخدمات الاتصالات والمقاولات العامة",
      url: "https://www.alfadaalwasaa.com",
    },
    publisher: {
      "@type": "Organization",
      name: "شركة الفضاء الواسع",
      logo: {
        "@type": "ImageObject",
        url: "https://www.alfadaalwasaa.com/profile/logo_mark.png",
      },
    },
    mainEntityOfPage: {
      "@type": "WebPage",
      "@id": `https://www.alfadaalwasaa.com/blog/${slug}`,
    },
  };

  // BreadcrumbList Schema for Google Search
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
        name: "مدونة الفضاء الواسع",
        item: "https://www.alfadaalwasaa.com/blog",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: post.title,
        item: `https://www.alfadaalwasaa.com/blog/${slug}`,
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50">
      <ReadingProgress />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <SiteHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Header section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-14 text-white sm:py-20">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="مسار التنقل">
              <Link href="/" className="hover:text-gold transition">
                الرئيسية
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <Link href="/blog" className="hover:text-gold transition">
                المدونة
              </Link>
              <ChevronLeft className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold truncate max-w-[200px]">{post.category}</span>
            </nav>

            <span className="inline-block rounded-full bg-gold/20 px-3 py-1 text-xs font-black text-gold-light border border-gold/30 mb-4">
              {post.category}
            </span>

            <h1 className="text-2xl font-black leading-tight text-white sm:text-3xl lg:text-4xl">
              {post.title}
            </h1>

            <div className="mt-6 flex flex-wrap items-center gap-5 text-xs text-white/70">
              <span className="flex items-center gap-1.5">
                <User className="h-4 w-4 text-gold" />
                <span>{post.author}</span>
              </span>
              <span className="flex items-center gap-1.5">
                <Calendar className="h-4 w-4 text-gold" />
                <span>{post.date}</span>
              </span>
              <span className="flex items-center gap-1.5">
                <Clock className="h-4 w-4 text-gold" />
                <span>{post.readTime}</span>
              </span>
            </div>
          </div>
        </section>

        {/* Content & Body */}
        <article className="py-14 bg-white">
          <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
            {/* Featured Image */}
            <div className="relative aspect-[16/9] overflow-hidden rounded-3xl border border-slate-200 shadow-lg mb-10 bg-navy-darker">
              <Image
                src={post.image}
                alt={post.title}
                fill
                sizes="(max-width: 1024px) 100vw, 896px"
                className="object-cover"
                priority
              />
            </div>

            {/* Intro Lead */}
            <p className="text-lg leading-9 font-semibold text-slate-800 border-s-4 border-gold ps-5 my-8">
              {post.content.intro}
            </p>

            {/* Sections */}
            <div className="space-y-10 my-8">
              {post.content.sections.map((sec, idx) => (
                <section key={idx} className="space-y-4">
                  <h2 className="text-xl font-black text-navy sm:text-2xl">
                    {sec.heading}
                  </h2>
                  {sec.paragraphs.map((p, pIdx) => (
                    <p key={pIdx} className="text-base leading-8 text-slate-700">
                      {p}
                    </p>
                  ))}
                </section>
              ))}
            </div>

            {/* Conclusion box */}
            <div className="mt-12 rounded-2xl bg-slate-50 border border-slate-200 p-6 sm:p-8">
              <h3 className="text-lg font-black text-navy mb-3">خلاصة القول</h3>
              <p className="text-base leading-8 text-slate-700">
                {post.content.conclusion}
              </p>
            </div>

            {/* CTA in Article */}
            <div className="mt-12 rounded-3xl bg-navy p-8 text-white text-center sm:text-start sm:flex sm:items-center sm:justify-between gap-6">
              <div>
                <h3 className="text-xl font-black">بحاجة إلى استشارة هندسية لمشروعك؟</h3>
                <p className="text-xs text-white/75 mt-1">تواصل مباشرة مع المهندسين والمختصين في شركة الفضاء الواسع.</p>
              </div>
              <Link
                href="/contact"
                className="mt-4 sm:mt-0 inline-block shrink-0 rounded-full bg-gold px-6 py-3 text-xs font-black text-navy-darker hover:bg-gold-light transition"
              >
                تواصل معنا
              </Link>
            </div>
          </div>
        </article>

        {/* Other articles */}
        {otherPosts.length > 0 && (
          <section className="py-14 bg-slate-50 border-t border-slate-200">
            <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
              <div className="flex items-center justify-between mb-8">
                <h3 className="text-xl font-black text-navy">مقالات أخرى قد تهمك</h3>
                <Link href="/blog" className="inline-flex items-center gap-1 text-xs font-bold text-gold hover:text-gold-dark">
                  <span>كل المقالات</span>
                  <ArrowLeft className="h-3.5 w-3.5" />
                </Link>
              </div>

              <div className="grid gap-6 sm:grid-cols-2">
                {otherPosts.map((other) => (
                  <Link
                    key={other.slug}
                    href={`/blog/${other.slug}`}
                    className="group flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-gold hover:shadow-md"
                  >
                    <span className="text-[11px] font-bold text-gold mb-1">{other.category}</span>
                    <h4 className="text-sm font-black text-navy group-hover:text-gold-dark transition-colors line-clamp-2">
                      {other.title}
                    </h4>
                    <p className="text-xs text-slate-500 mt-2 line-clamp-2">{other.description}</p>
                  </Link>
                ))}
              </div>
            </div>
          </section>
        )}
      </main>

      <SiteFooter />
      <FloatingContact />
    </div>
  );
}