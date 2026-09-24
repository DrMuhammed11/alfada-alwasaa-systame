import dynamic from "next/dynamic";
import { SiteHeader } from "@/components/site/header";
import { Hero } from "@/components/site/hero";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

// Skeleton بارتفاع ثابت لمنع CLS عند تحميل الأقسام الديناميكية
function SectionSkeleton() {
  return (
    <div
      className="w-full min-h-[420px] py-20 animate-pulse"
      aria-hidden="true"
    >
      <div className="mx-auto max-w-7xl px-6 space-y-4">
        <div className="h-5 w-20 rounded-full bg-gold/20 mx-auto" />
        <div className="h-8 w-52 rounded-lg bg-navy/10 dark:bg-white/10 mx-auto" />
        <div className="h-4 w-80 rounded-lg bg-navy/8 dark:bg-white/8 mx-auto" />
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 max-w-3xl mx-auto">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-24 rounded-2xl bg-navy/6 dark:bg-white/6" />
          ))}
        </div>
      </div>
    </div>
  );
}

// الاستيراد الديناميكي للأقسام أسفل الصفحة (below the fold)
const Sectors = dynamic(
  () => import("@/components/site/sectors").then((m) => ({ default: m.Sectors })),
  { loading: SectionSkeleton, ssr: true }
);
const Services = dynamic(
  () => import("@/components/site/services").then((m) => ({ default: m.Services })),
  { loading: SectionSkeleton, ssr: true }
);
const Position = dynamic(
  () => import("@/components/site/position").then((m) => ({ default: m.Position })),
  { loading: SectionSkeleton, ssr: true }
);
const VisionMission = dynamic(
  () => import("@/components/site/vision-mission").then((m) => ({ default: m.VisionMission })),
  { loading: SectionSkeleton, ssr: true }
);
const TrackRecord = dynamic(
  () => import("@/components/site/track-record").then((m) => ({ default: m.TrackRecord })),
  { loading: SectionSkeleton, ssr: true }
);
const WhyUs = dynamic(
  () => import("@/components/site/why-us").then((m) => ({ default: m.WhyUs })),
  { loading: SectionSkeleton, ssr: true }
);
const Conclusion = dynamic(
  () => import("@/components/site/conclusion").then((m) => ({ default: m.Conclusion })),
  { loading: SectionSkeleton, ssr: true }
);
const Contact = dynamic(
  () => import("@/components/site/contact").then((m) => ({ default: m.Contact })),
  { loading: SectionSkeleton, ssr: true }
);

const PartnersMarquee = dynamic(
  () => import("@/components/site/partners-marquee").then((m) => ({ default: m.PartnersMarquee })),
  { loading: SectionSkeleton, ssr: true }
);
const Faq = dynamic(
  () => import("@/components/site/faq").then((m) => ({ default: m.Faq })),
  { loading: SectionSkeleton, ssr: true }
);

const BlogPreview = dynamic(
  () => import("@/components/site/blog-preview").then((m) => ({ default: m.BlogPreview })),
  { loading: SectionSkeleton, ssr: true }
);

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-white dark:bg-navy-darker transition-colors duration-300">
      <SiteHeader />
      <main id="main-content">
        <Hero />
        <PartnersMarquee />
        <Sectors />
        <Services />
        <Position />
        <VisionMission />
        <TrackRecord />
        <WhyUs />
        <Faq />
        <BlogPreview />
        <Conclusion />
        <Contact />
      </main>
      <SiteFooter />
      <FloatingContact />
    </div>
  );
}
