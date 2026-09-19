import dynamic from "next/dynamic";
import { SiteHeader } from "@/components/site/header";
import { Hero } from "@/components/site/hero";
import { Stats } from "@/components/site/stats";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

// Skeleton بسيط للأقسام أثناء التحميل
function SectionSkeleton() {
  return (
    <div className="w-full py-20 animate-pulse">
      <div className="mx-auto max-w-7xl px-6 space-y-4">
        <div className="h-8 w-48 rounded-lg bg-navy/10 dark:bg-white/10 mx-auto" />
        <div className="h-4 w-96 rounded-lg bg-navy/8 dark:bg-white/8 mx-auto" />
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

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-white dark:bg-navy-darker transition-colors duration-300">
      <SiteHeader />
      <main id="main-content">
        <Hero />
        <Stats />
        <Sectors />
        <Services />
        <Position />
        <VisionMission />
        <TrackRecord />
        <WhyUs />
        <Conclusion />
        <Contact />
      </main>
      <SiteFooter />
      <FloatingContact />
    </div>
  );
}
