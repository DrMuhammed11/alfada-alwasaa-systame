export const dynamic = "force-static";

export async function GET() {
  const robotsTxt = `User-agent: *
Allow: /

Sitemap: https://www.alfadaalwasaa.com/sitemap.xml`;

  return new Response(robotsTxt, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=86400",
    },
  });
}
