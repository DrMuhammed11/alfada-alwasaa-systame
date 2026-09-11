import Image from "next/image";
import { Quote, Route, ClipboardCheck, RadioTower, Package, Ship } from "lucide-react";
import { Reveal } from "./reveal";
import { SectionHeading } from "./section-heading";

const TRACK_ITEMS = [
  {
    caption: "أعمال الطرق والحفريات",
    src: "/profile/track_roller.webp",
    Icon: Route,
  },
  {
    caption: "التخليص الجمركي",
    src: "/profile/track_ship.webp",
    Icon: ClipboardCheck,
  },
  {
    caption: "خدمات الاتصالات والدعم الفني",
    src: "/profile/track_tower.webp",
    Icon: RadioTower,
  },
  {
    caption: "التوريدات والتموينات",
    src: "/profile/track_forklift.webp",
    Icon: Package,
  },
  {
    caption: "الخدمات اللوجستية والشحن",
    src: "/profile/track_truck.webp",
    Icon: Ship,
  },
];

export function TrackRecord() {
  return (
    <section id="track" className="relative overflow-hidden bg-mist py-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-start gap-10 lg:grid-cols-[0.9fr_1.1fr]">
          <SectionHeading kicker="سابقة الأعمال" title="سابقة تُعتمد" />
          <Reveal delay={0.1}>
            <div className="mb-2 flex items-start gap-3 rounded-2xl border border-gold/30 bg-white/70 p-4">
              <Quote className="mt-1 h-6 w-6 shrink-0 text-gold" strokeWidth={2} />
              <p className="text-lg font-extrabold text-navy">
                شواهد على الثقة والإنجاز
              </p>
            </div>
            {/* Exact paragraph from the profile */}
            <p className="mt-4 text-justify text-[1.05rem] leading-9 text-slate-700">
              نفذت شركة الفضاء الواسع لخدمات الاتصالات والمقاولات عددًا من المشاريع
              المتنوعة التي شملت أعمال الطرق والحفريات، والتوريدات، والخدمات اللوجستية،
              والشحن، والتخليص الجمركي، إضافة إلى خدمات الاتصالات والدعم الفني، بما يعكس
              خبرتها المتعددة وقدرتها على تنفيذ الأعمال وفق أعلى معايير الجودة والالتزام.
            </p>
          </Reveal>
        </div>

        {/* Photo strip — the five fields from the profile with fully balanced responsive layout */}
        <div className="mt-14 grid grid-cols-2 gap-3.5 sm:gap-4 md:grid-cols-5">
          {TRACK_ITEMS.map((item, idx) => (
            <Reveal 
              key={item.caption} 
              delay={idx * 0.08}
              className={idx === 4 ? "col-span-2 sm:col-span-1 md:col-span-1 max-w-[280px] sm:max-w-none mx-auto w-full" : "w-full"}
            >
              <figure className="group flex h-full flex-col justify-between overflow-hidden rounded-2xl bg-white shadow-[0_15px_45px_-25px_rgba(10,52,83,0.35)] ring-1 ring-navy/5 transition-all duration-500 hover:-translate-y-1.5 hover:shadow-[0_25px_60px_-25px_rgba(10,52,83,0.45)]">
                <div className="relative aspect-[4/3] overflow-hidden">
                  <Image
                    src={item.src}
                    alt={item.caption}
                    fill
                    sizes="(max-width: 640px) 45vw, (max-width: 1024px) 20vw, 220px"
                    className="object-cover transition-transform duration-700 group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/55 via-transparent to-transparent opacity-0 transition-opacity duration-500 group-hover:opacity-100" />
                </div>
                <figcaption className="flex flex-1 flex-col items-center justify-center gap-2 px-2.5 py-3.5 text-center">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-navy text-gold-light transition-colors duration-500 group-hover:bg-gold group-hover:text-navy-darker sm:h-11 sm:w-11">
                    <item.Icon className="h-5 w-5" strokeWidth={1.8} />
                  </span>
                  <span className="text-[0.78rem] font-extrabold leading-5 text-navy sm:text-[0.82rem]">
                    {item.caption}
                  </span>
                </figcaption>
              </figure>
            </Reveal>
          ))}
        </div>

        {/* Closing strip — literal from the profile page */}
        <Reveal delay={0.15}>
          <p className="mt-12 text-center text-sm font-bold tracking-wide text-navy/60">
            شريكك .. لاستقبال أوسع
          </p>
        </Reveal>
      </div>
    </section>
  );
}
