"use client";

import { useEffect, useRef } from "react";
import { cn } from "@/lib/utils";
import { Reveal } from "./reveal";

type SectionHeadingProps = {
  kicker?: string;
  title: string;
  center?: boolean;
  light?: boolean;
};

/** عنوان القسم مع الخط الذهبي المتحرك الذي يمتد عند دخول مجال الرؤية */
export function SectionHeading({ kicker, title, center, light }: SectionHeadingProps) {
  const h2Ref = useRef<HTMLHeadingElement>(null);

  // IntersectionObserver: يُضيف كلاس in-view مرة واحدة لتشغيل gold-rule animation
  useEffect(() => {
    const node = h2Ref.current;
    if (!node) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          node.classList.add("in-view");
          observer.disconnect();
        }
      },
      { threshold: 0.3 }
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  return (
    <Reveal className={cn("mb-8 sm:mb-10", center && "text-center")}>
      {kicker && (
        <span
          className={cn(
            "mb-3 block w-fit rounded-full px-4 py-1.5 text-xs font-bold tracking-wide",
            center && "mx-auto",
            light ? "bg-white/10 text-gold-light" : "bg-gold-soft text-gold dark:bg-gold/20 dark:text-gold-light"
          )}
        >
          {kicker}
        </span>
      )}
      <h2
        ref={h2Ref}
        className={cn(
          "gold-rule inline-block pb-2 text-3xl font-extrabold sm:text-4xl lg:text-[2.75rem]",
          center && "center",
          light ? "text-white" : "text-navy dark:text-white"
        )}
      >
        {title}
      </h2>
    </Reveal>
  );
}
