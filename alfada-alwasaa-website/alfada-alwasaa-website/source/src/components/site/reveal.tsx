"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ReactNode } from "react";

type RevealProps = {
  children: ReactNode;
  delay?: number;
  y?: number;
  className?: string;
  once?: boolean;
};

/** Lightweight, ultra-smooth scroll-reveal wrapper */
export function Reveal({ children, delay = 0, y = 14, className, once = true }: RevealProps) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      className={className}
      initial={reduce ? false : { opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once, margin: "-15px" }}
      transition={{ 
        duration: 0.42, 
        delay: Math.min(delay, 0.18), 
        ease: [0.16, 1, 0.3, 1] 
      }}
    >
      {children}
    </motion.div>
  );
}
