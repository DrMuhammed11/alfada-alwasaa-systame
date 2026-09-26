import dynamic from "next/dynamic";
import { EnHeader } from "@/components/site/EnHeader";
import { EnHero } from "@/components/site/EnHero";
import { EnFooter } from "@/components/site/EnFooter";
import { EnFloatingContact } from "@/components/site/EnFloatingContact";
import {
  getSectors,
  getProjects,
  getFaqs,
  type ContentSector,
  type ContentProject,
  type ContentFaq,
} from "@/lib/content";

// Fixed-height skeleton to prevent Cumulative Layout Shift (CLS) on dynamic sections
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

// Dynamic below-the-fold imports matching Arabic page.tsx pattern
const EnPartnersMarquee = dynamic(
  () => import("@/components/site/EnPartnersMarquee").then((m) => ({ default: m.EnPartnersMarquee })),
  { loading: SectionSkeleton, ssr: true }
);

const EnSectors = dynamic(
  () => import("@/components/site/EnSectors").then((m) => ({ default: m.EnSectors })),
  { loading: SectionSkeleton, ssr: true }
);

const EnServicesTabs = dynamic(
  () => import("@/components/site/EnServicesTabs").then((m) => ({ default: m.EnServicesTabs })),
  { loading: SectionSkeleton, ssr: true }
);

const EnPosition = dynamic(
  () => import("@/components/site/EnPosition").then((m) => ({ default: m.EnPosition })),
  { loading: SectionSkeleton, ssr: true }
);

const EnVisionMission = dynamic(
  () => import("@/components/site/EnVisionMission").then((m) => ({ default: m.EnVisionMission })),
  { loading: SectionSkeleton, ssr: true }
);

const EnTrackRecord = dynamic(
  () => import("@/components/site/EnTrackRecord").then((m) => ({ default: m.EnTrackRecord })),
  { loading: SectionSkeleton, ssr: true }
);


const EnWhyUs = dynamic(
  () => import("@/components/site/EnWhyUs").then((m) => ({ default: m.EnWhyUs })),
  { loading: SectionSkeleton, ssr: true }
);

const EnFaq = dynamic(
  () => import("@/components/site/EnFaq").then((m) => ({ default: m.EnFaq })),
  { loading: SectionSkeleton, ssr: true }
);

const EnConclusion = dynamic(
  () => import("@/components/site/EnConclusion").then((m) => ({ default: m.EnConclusion })),
  { loading: SectionSkeleton, ssr: true }
);

const EnContactSection = dynamic(
  () => import("@/components/site/EnContactSection").then((m) => ({ default: m.EnContactSection })),
  { loading: SectionSkeleton, ssr: true }
);

export default async function EnglishHomePage() {
  const [cmsSectors, cmsProjects, cmsFaqs] = await Promise.all([
    getSectors(),
    getProjects(),
    getFaqs(),
  ]);
  // درع ضد أي شكل بيانات غير متوقع من الـ CMS — الموقع لا يسقط أبداً بسبب محتوى
  const safe = <T,>(fn: () => T): T | undefined => {
    try {
      return fn();
    } catch {
      return undefined;
    }
  };
  // تمرير خام: مكوّنات EN تقوم بالتحويل إلى صيغة العرض داخليًا مع بدائل آمنة
  const sectors = safe(() =>
    cmsSectors.length
      ? (cmsSectors as unknown as import("@/components/site/EnSectors").EnSectorCmsItem[])
      : undefined
  );
  const trackItems = safe(() =>
    cmsProjects.length
      ? (cmsProjects as unknown as import("@/components/site/EnTrackRecord").EnTrackCmsItem[])
      : undefined
  );
  const faqItems = safe(() =>
    cmsFaqs.length
      ? (cmsFaqs as unknown as ContentFaq[]).map((f) => ({ question: f.questionEn, answer: f.answerEn }))
      : undefined
  );

  return (
    <div
      className="flex min-h-screen flex-col bg-white dark:bg-navy-darker text-slate-900 dark:text-white transition-colors duration-300 font-sans"
      dir="ltr"
    >
      <EnHeader />
      <main id="main-content">
        <EnHero />
        <EnPartnersMarquee />
        <EnSectors items={sectors} />
        <EnServicesTabs />
        <EnPosition />
        <EnVisionMission />
        <EnTrackRecord items={trackItems} />
        <EnWhyUs />
        <EnFaq items={faqItems} />
        <EnConclusion />
        <EnContactSection />
      </main>
      <EnFooter />
      <EnFloatingContact />
    </div>
  );
}
