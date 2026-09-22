"use client";

import Image from "next/image";
import Link from "next/link";
import { Calendar, Clock, ArrowLeft, BookOpen } from "lucide-react";
import { BLOG_POSTS } from "@/config/blog-data";
import { SectionHeading } from "./section-heading";
import { Reveal } from "./reveal";

export function BlogPreview() {
  // أحدث 3 مقالات هندسية
  const latestPosts = Object.values(BLOG_POSTS).slice(0, 3);

  return (
    <section id="blog-preview" className="relative overflow-hidden bg-white dark:bg-navy-darker py-12 sm:py-16 transition-colors duration-300">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <SectionHeading
          center
          kicker="المعرفة والخبرة الميدانية"
          title="أحدث المقالات والدراسات الفنية"
        />

        <Reveal delay={0.08}>
          <p className="-mt-6 text-center text-sm sm:text-base leading-7 text-slate-600 dark:text-slate-300 mb-10 max-w-2xl mx-auto">
            إرشادات هندسية ودراسات فنية متخصصة يكتبها خبراؤنا الميدانيون لدعم ومساندة المشاريع التنموية والتجارية في اليمن.
          </p>
        </Reveal>

        <div className="grid gap-6 sm:gap-8 md:grid-cols-2 lg:grid-cols-3">
          {latestPosts.map((post, idx) => (
            <Reveal key={post.slug} index={idx}>
              <article className="group flex h-full flex-col overflow-hidden rounded-3xl border border-navy/10 dark:border-white/10 bg-slate-50/70 dark:bg-navy shadow-sm transition-all duration-300 hover:-translate-y-1.5 hover:border-gold/60 hover:shadow-xl hover:bg-white dark:hover:bg-navy-deep">
                {/* Media Image */}
                <div className="relative aspect-[16/10] w-full overflow-hidden bg-navy-darker">
                  <Image
                    src={post.image}
                    alt={post.title}
                    fill
                    loading="lazy"
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/80 to-transparent" />
                  
                  {/* Category Pill */}
                  <span className="absolute top-4 start-4 rounded-full bg-navy/90 px-3.5 py-1 text-xs font-bold text-gold-light border border-gold/30 shadow-md backdrop-blur-md">
                    {post.category}
                  </span>
                </div>

                {/* Content */}
                <div className="flex flex-1 flex-col justify-between p-6">
                  <div>
                    {/* Meta info */}
                    <div className="flex items-center gap-4 text-xs font-medium text-slate-500 dark:text-slate-400 mb-3">
                      <span className="flex items-center gap-1.5">
                        <Calendar className="h-3.5 w-3.5 text-gold" />
                        <span>{post.date}</span>
                      </span>
                      <span className="flex items-center gap-1.5">
                        <Clock className="h-3.5 w-3.5 text-gold" />
                        <span>{post.readTime}</span>
                      </span>
                    </div>

                    <h3 className="text-base sm:text-lg font-black leading-snug text-navy dark:text-white group-hover:text-gold transition-colors">
                      <Link href={`/blog/${post.slug}`} className="hover:underline">
                        {post.title}
                      </Link>
                    </h3>

                    <p className="mt-3 text-xs sm:text-sm leading-6 text-slate-600 dark:text-slate-300 line-clamp-3">
                      {post.description}
                    </p>
                  </div>

                  <div className="mt-6 pt-4 border-t border-slate-200/80 dark:border-white/10 flex items-center justify-between">
                    <Link
                      href={`/blog/${post.slug}`}
                      className="inline-flex items-center gap-2 text-xs font-bold text-navy dark:text-gold-light group-hover:text-gold transition-colors"
                    >
                      <span>قراءة المقال الكامل</span>
                      <ArrowLeft className="h-3.5 w-3.5 transition-transform duration-300 group-hover:-translate-x-1" />
                    </Link>
                  </div>
                </div>
              </article>
            </Reveal>
          ))}
        </div>

        {/* Explore all articles button */}
        <Reveal delay={0.2} className="mt-10 text-center">
          <Link
            href="/blog"
            className="inline-flex items-center gap-2 rounded-full border border-navy/20 dark:border-white/20 bg-mist dark:bg-navy px-7 py-3 text-xs sm:text-sm font-black text-navy dark:text-white shadow-sm hover:border-gold/60 hover:text-gold transition hover:scale-105"
          >
            <BookOpen className="h-4 w-4 text-gold" />
            <span>استكشف كافة مقالات ودراسات المدونة ({Object.keys(BLOG_POSTS).length})</span>
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Reveal>
      </div>
    </section>
  );
}
