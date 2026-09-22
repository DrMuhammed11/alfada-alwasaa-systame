import { SERVICES_DATA } from "@/config/services-data";
import { BLOG_POSTS } from "@/config/blog-data";

export const dynamic = "force-static";

export async function GET() {
  const today = new Date().toISOString().split("T")[0];
  const baseUrl = "https://www.alfadaalwasaa.com";

  const staticUrls = [
    { loc: `${baseUrl}/`, priority: "1.0", changefreq: "daily" },
    { loc: `${baseUrl}/about`, priority: "0.9", changefreq: "monthly" },
    { loc: `${baseUrl}/contact`, priority: "0.9", changefreq: "monthly" },
    { loc: `${baseUrl}/blog`, priority: "0.8", changefreq: "weekly" },
  ];

  const serviceUrls = Object.keys(SERVICES_DATA).map((slug) => ({
    loc: `${baseUrl}/services/${slug}`,
    priority: "0.9",
    changefreq: "weekly",
  }));

  const blogUrls = Object.keys(BLOG_POSTS).map((slug) => ({
    loc: `${baseUrl}/blog/${slug}`,
    priority: "0.8",
    changefreq: "monthly",
  }));

  const allUrls = [...staticUrls, ...serviceUrls, ...blogUrls];

  const sitemapXml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${allUrls
  .map(
    (u) => `  <url>
    <loc>${u.loc}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>${u.changefreq}</changefreq>
    <priority>${u.priority}</priority>
  </url>`
  )
  .join("\n")}
</urlset>`;

  return new Response(sitemapXml, {
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control": "public, max-age=86400, stale-while-revalidate=43200",
    },
  });
}