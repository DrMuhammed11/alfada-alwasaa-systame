import dynamic from "next/dynamic";
import { SiteHeader } from "@/components/site/header";
import { Hero } from "@/components/site/hero";
import { Stats } from "@/components/site/stats";
import { Sectors } from "@/components/site/sectors";
import { Services } from "@/components/site/services";
import { Position } from "@/components/site/position";
import { VisionMission } from "@/components/site/vision-mission";
import { SiteFooter } from "@/components/site/footer";

/**
 * تحميل أقسام أسفل الصفحة بشكل ديناميكي (Code-splitting مع الحفاظ على SSR)
 * لتقليل حجم حزمة الجافاسكربت عند التحميل الأولي (First Load JS)
 */
const TrackRecord = dynamic(
  () => import("@/components/site/track-record").then((mod) => mod.TrackRecord),
  {
    ssr: true,
    loading: () => <div className="min-h-[420px]" aria-hidden />,
  }
);

const WhyUs = dynamic(
  () => import("@/components/site/why-us").then((mod) => mod.WhyUs),
  {
    ssr: true,
    loading: () => <div className="min-h-[380px]" aria-hidden />,
  }
);

const Conclusion = dynamic(
  () => import("@/components/site/conclusion").then((mod) => mod.Conclusion),
  {
    ssr: true,
    loading: () => <div className="min-h-[260px]" aria-hidden />,
  }
);

const Contact = dynamic(
  () => import("@/components/site/contact").then((mod) => mod.Contact),
  {
    ssr: true,
    loading: () => <div className="min-h-[520px]" aria-hidden />,
  }
);

const FloatingContact = dynamic(
  () =>
    import("@/components/site/floating-contact").then(
      (mod) => mod.FloatingContact
    ),
  {
    ssr: true,
  }
);

export default function Home() {
  return (
    <div className="flex min-h-screen flex-col bg-white">
      <SiteHeader />
      <main>
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

