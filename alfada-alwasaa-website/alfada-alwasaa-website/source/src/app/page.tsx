import { SiteHeader } from "@/components/site/header";
import { Hero } from "@/components/site/hero";
import { Stats } from "@/components/site/stats";
import { Sectors } from "@/components/site/sectors";
import { Services } from "@/components/site/services";
import { Position } from "@/components/site/position";
import { VisionMission } from "@/components/site/vision-mission";
import { TrackRecord } from "@/components/site/track-record";
import { WhyUs } from "@/components/site/why-us";
import { Conclusion } from "@/components/site/conclusion";
import { Contact } from "@/components/site/contact";
import { SiteFooter } from "@/components/site/footer";
import { FloatingContact } from "@/components/site/floating-contact";

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
