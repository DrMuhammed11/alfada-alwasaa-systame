import { SERVICES_DATA } from "@/config/services-data";
import { BLOG_POSTS } from "@/config/blog-data";
import { EN_SERVICES_DATA } from "@/config/en-services-data";
import { EN_BLOG_POSTS } from "@/config/en-blog-data";

export const dynamic = "force-static";

interface SitemapUrl {
  loc: string;
  priority: string;
  changefreq: string;
  alternates?: { ar: string; en: string };
}

export async function GET() {
  const today = new Date().toISOString().split("T")[0];
  const baseUrl = "https://www.alfadaalwasaa.com";

  const staticUrls: SitemapUrl[] = [
    { loc: `${baseUrl}/`, priority: "1.0", changefreq: "daily", alternates: { ar: `${baseUrl}/`, en: `${baseUrl}/en` } },
    { loc: `${baseUrl}/en`, priority: "1.0", changefreq: "daily" },
    { loc: `${baseUrl}/about`, priority: "0.9", changefreq: "monthly", alternates: { ar: `${baseUrl}/about`, en: `${baseUrl}/en/about` } },
    { loc: `${baseUrl}/en/about`, priority: "0.9", changefreq: "monthly" },
    { loc: `${baseUrl}/contact`, priority: "0.9", changefreq: "monthly", alternates: { ar: `${baseUrl}/contact`, en: `${baseUrl}/en/contact` } },
    { loc: `${baseUrl}/en/contact`, priority: "0.9", changefreq: "monthly" },
    { loc: `${baseUrl}/blog`, priority: "0.8", changefreq: "weekly", alternates: { ar: `${baseUrl}/blog`, en: `${baseUrl}/en/blog` } },
    { loc: `${baseUrl}/en/blog`, priority: "0.8", changefreq: "weekly" },
    { loc: `${baseUrl}/privacy`, priority: "0.3", changefreq: "yearly", alternates: { ar: `${baseUrl}/privacy`, en: `${baseUrl}/en/privacy` } },
    { loc: `${baseUrl}/en/privacy`, priority: "0.3", changefreq: "yearly" },
    { loc: `${baseUrl}/terms`, priority: "0.3", changefreq: "yearly", alternates: { ar: `${baseUrl}/terms`, en: `${baseUrl}/en/terms` } },
    { loc: `${baseUrl}/en/terms`, priority: "0.3", changefreq: "yearly" },
  ];

  const serviceUrls: SitemapUrl[] = Object.keys(SERVICES_DATA).flatMap((slug) => [
    {
      loc: `${baseUrl}/services/${slug}`,
      priority: "0.9",
      changefreq: "weekly",
      alternates: { ar: `${baseUrl}/services/${slug}`, en: `${baseUrl}/en/services/${slug}` },
    },
    {
      loc: `${baseUrl}/en/services/${slug}`,
      priority: "0.9",
      changefreq: "weekly",
    },
  ]);

  const blogUrls: SitemapUrl[] = Object.keys(BLOG_POSTS).flatMap((slug) => [
    {
      loc: `${baseUrl}/blog/${slug}`,
      priority: "0.8",
      changefreq: "monthly",
      alternates: { ar: `${baseUrl}/blog/${slug}`, en: `${baseUrl}/en/blog/${slug}` },
    },
    {
      loc: `${baseUrl}/en/blog/${slug}`,
      priority: "0.8",
      changefreq: "monthly",
    },
  ]);

  void EN_SERVICES_DATA;
  void EN_BLOG_POSTS;

  const allUrls = [...staticUrls, ...serviceUrls, ...blogUrls];

  const sitemapXml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${allUrls
  .map((u) => {
    const alternateLines = u.alternates
      ? [
          `    <xhtml:link rel="alternate" hreflang="ar" href="${u.alternates.ar}"/>`,
          `    <xhtml:link rel="alternate" hreflang="en" href="${u.alternates.en}"/>`,
        ].join("\n")
      : "";
    return `  <url>
    <loc>${u.loc}</loc>
${u.alternates ? alternateLines + "\n" : ""}    <lastmod>${today}</lastmod>
    <changefreq>${u.changefreq}</changefreq>
    <priority>${u.priority}</priority>
  </url>`;
  })
  .join("\n")}
</urlset>`;

  return new Response(sitemapXml, {
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control": "public, max-age=86400, stale-while-revalidate=43200",
    },
  });
}
