import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  BookOpen,
  Calendar,
  Clock,
  ArrowRight,
  ChevronRight
} from "lucide-react";
import { EN_BLOG_POSTS } from "@/config/en-blog-data";
import { EnHeader } from "@/components/site/en-header";
import { EnFooter } from "@/components/site/en-footer";
import { EnFloatingContact } from "@/components/site/en-floating-contact";

export const metadata: Metadata = {
  title: "Engineering & Technical Blog | Al-Fada Al-Wasaa Articles and News in Yemen",
  description: "Articles, case studies, and specialized engineering and technical guidance in general contracting, telecom, supplies, and energy solutions across Yemen.",
  keywords: [
    "Al-Fada Al-Wasaa blog",
    "Yemen contracting articles",
    "telecom sector news Sana'a",
    "construction and engineering guide Yemen"
  ],
  alternates: {
    canonical: "https://www.alfadaalwasaa.com/en/blog",
    languages: {
      ar: "https://www.alfadaalwasaa.com/blog",
      en: "https://www.alfadaalwasaa.com/en/blog",
    },
  },
  openGraph: {
    title: "Al-Fada Al-Wasaa Blog | Engineering & Technical Articles",
    description: "The latest articles and technical studies in the contracting and telecom sectors in Yemen.",
    url: "https://www.alfadaalwasaa.com/en/blog",
    images: [{ url: "/profile/hero_bg.webp", width: 1200, height: 630, alt: "Al-Fada Al-Wasaa Blog" }],
    locale: "en_US",
    type: "website",
  },
};

export default function EnBlogListPage() {
  const posts = Object.values(EN_BLOG_POSTS);

  const blogListSchema = {
    "@context": "https://schema.org",
    "@type": "Blog",
    name: "Al-Fada Al-Wasaa Engineering & Technical Blog",
    description: "Specialized articles, case studies, and engineering and technical guidance in Yemen.",
    url: "https://www.alfadaalwasaa.com/en/blog",
    blogPost: posts.map((post) => ({
      "@type": "BlogPosting",
      headline: post.title,
      description: post.description,
      datePublished: post.date,
      url: `https://www.alfadaalwasaa.com/en/blog/${post.slug}`,
      image: `https://www.alfadaalwasaa.com${post.image}`,
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
        name: "Engineering Blog",
        item: "https://www.alfadaalwasaa.com/en/blog",
      },
    ],
  };

  return (
    <div className="flex min-h-screen flex-col bg-slate-50">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(blogListSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <EnHeader />

      <main id="main-content" className="flex-1 pt-[76px]">
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-gradient-to-b from-navy-darker via-navy to-navy py-16 text-white sm:py-20">
          <div className="dot-grid absolute inset-0 opacity-15 pointer-events-none" />
          <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <nav className="mb-6 flex items-center gap-2 text-xs font-semibold text-white/70" aria-label="Breadcrumb">
              <Link href="/en" className="hover:text-gold transition">
                Home
              </Link>
              <ChevronRight className="h-3 w-3 text-gold" />
              <span className="text-gold-light font-bold">Engineering Blog</span>
            </nav>

            <div className="max-w-3xl">
              <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-1.5 text-xs font-extrabold text-gold-light shadow-sm">
                <BookOpen className="h-4 w-4 text-gold" />
                Knowledge & Field Expertise
              </span>

              <h1 className="mt-4 text-3xl font-black leading-tight text-white sm:text-4xl lg:text-5xl">
                Al-Fada Al-Wasaa Blog
              </h1>

              <p className="mt-5 text-base leading-8 text-white/80 sm:text-lg">
                Specialized articles, engineering guidance, and technical studies for partners and professionals in the contracting, telecom, and development sectors across Yemen.
              </p>
            </div>
          </div>
        </section>

        {/* Articles Grid */}
        <section className="py-16 sm:py-20 bg-white">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
              {posts.map((post) => (
                <article
                  key={post.slug}
                  className="group flex flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm transition-all duration-300 hover:-translate-y-1.5 hover:border-gold/50 hover:shadow-xl"
                >
                  <Link href={`/en/blog/${post.slug}`} className="relative aspect-[16/10] overflow-hidden bg-slate-100">
                    <Image
                      src={post.image}
                      alt={post.title}
                      fill
                      sizes="(max-width: 768px) 100vw, 400px"
                      className="object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                    <span className="absolute start-4 top-4 rounded-full bg-navy/85 px-3 py-1 text-xs font-bold text-gold-light backdrop-blur-sm">
                      {post.category}
                    </span>
                  </Link>

                  <div className="flex flex-1 flex-col justify-between p-6 sm:p-7">
                    <div>
                      <div className="flex items-center gap-4 text-xs font-semibold text-slate-500 mb-3">
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3.5 w-3.5 text-gold" />
                          <span>{post.date}</span>
                        </span>
                        <span className="flex items-center gap-1">
                          <Clock className="h-3.5 w-3.5 text-gold" />
                          <span>{post.readTime}</span>
                        </span>
                      </div>

                      <h2 className="text-lg font-black leading-snug text-navy group-hover:text-gold-dark transition-colors">
                        <Link href={`/en/blog/${post.slug}`}>
                          {post.title}
                        </Link>
                      </h2>

                      <p className="mt-3 text-xs leading-6 text-slate-600 line-clamp-3">
                        {post.description}
                      </p>
                    </div>

                    <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between">
                      <span className="text-[11px] font-bold text-slate-500">{post.author}</span>
                      <Link
                        href={`/en/blog/${post.slug}`}
                        className="inline-flex items-center gap-1.5 text-xs font-extrabold text-gold hover:text-gold-dark transition"
                      >
                        <span>Read More</span>
                        <ArrowRight className="h-3.5 w-3.5" />
                      </Link>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>
      </main>

      <EnFooter />
      <EnFloatingContact />
    </div>
  );
}
