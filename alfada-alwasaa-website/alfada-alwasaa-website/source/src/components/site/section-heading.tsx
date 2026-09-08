import { cn } from "@/lib/utils";
import { Reveal } from "./reveal";

type SectionHeadingProps = {
  kicker?: string;
  title: string;
  center?: boolean;
  light?: boolean;
};

/** Section heading that mirrors the profile's title + gold underline style. */
export function SectionHeading({ kicker, title, center, light }: SectionHeadingProps) {
  return (
    <Reveal className={cn("mb-14", center && "text-center")}>
      {kicker && (
        <span
          className={cn(
            "mb-3 block w-fit rounded-full px-4 py-1.5 text-xs font-bold tracking-wide",
            center && "mx-auto",
            light ? "bg-white/10 text-gold-light" : "bg-gold-soft text-gold"
          )}
        >
          {kicker}
        </span>
      )}
      <h2
        className={cn(
          "gold-rule inline-block pb-2 text-3xl font-extrabold sm:text-4xl lg:text-[2.75rem]",
          center && "center",
          light ? "text-white" : "text-navy"
        )}
      >
        {title}
      </h2>
    </Reveal>
  );
}
