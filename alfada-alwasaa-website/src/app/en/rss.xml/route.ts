import { EN_BLOG_POSTS } from "@/config/en-blog-data";

export const dynamic = "force-static";

function escapeXml(unsafe: string): string {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

export async function GET() {
  const baseUrl = "https://www.alfadaalwasaa.com";
  const posts = Object.values(EN_BLOG_POSTS);

  const rssItems = posts
    .map((post) => {
      const postUrl = `${baseUrl}/en/blog/${post.slug}`;
      const pubDate = new Date(post.date).toUTCString();

      return `    <item>
      <title>${escapeXml(post.title)}</title>
      <link>${postUrl}</link>
      <guid isPermaLink="true">${postUrl}</guid>
      <description>${escapeXml(post.description)}</description>
      <category>${escapeXml(post.category)}</category>
      <pubDate>${pubDate}</pubDate>
    </item>`;
    })
    .join("\n");

  const rssXml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Al-Fada Al-Wasaa | Corporate Insights &amp; Engineering Blog</title>
    <link>${baseUrl}/en</link>
    <description>Technical analysis, field execution standards, and engineering insights from Al-Fada Al-Wasaa in telecom networks, general contracting, and nationwide logistics in Yemen.</description>
    <language>en-us</language>
    <atom:link href="${baseUrl}/en/rss.xml" rel="self" type="application/rss+xml"/>
${rssItems}
  </channel>
</rss>`;

  return new Response(rssXml, {
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control": "public, max-age=86400, stale-while-revalidate=43200",
    },
  });
}
