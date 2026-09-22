"use client";

import React, { useRef, useState, useEffect } from "react";
import { motion, useReducedMotion } from "framer-motion";

interface MagneticButtonProps {
  children: React.ReactNode;
  className?: string;
  maxOffset?: number; // default 6px
}

/**
 * زر بتأثير جاذبية مغناطيسية خفيف باتجاه مؤشر الفأرة على أجهزة سطح المكتب فقط
 * يُعطَّل تلقائياً على الشاشات اللمسية ومستخدمي prefers-reduced-motion
 */
export function MagneticButton({
  children,
  className = "",
  maxOffset = 6,
}: MagneticButtonProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isFinePointer, setIsFinePointer] = useState(false);
  const reduce = useReducedMotion();

  useEffect(() => {
    // Check if pointer is fine (mouse) and not touch
    const fine = window.matchMedia("(pointer: fine)").matches;
    setIsFinePointer(fine);
  }, []);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!isFinePointer || reduce || !ref.current) return;

    const rect = ref.current.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    const distanceX = (e.clientX - centerX) * 0.18;
    const distanceY = (e.clientY - centerY) * 0.18;

    // Clamp to maxOffset (default <= 6px)
    const clampedX = Math.max(-maxOffset, Math.min(maxOffset, distanceX));
    const clampedY = Math.max(-maxOffset, Math.min(maxOffset, distanceY));

    setPosition({ x: clampedX, y: clampedY });
  };

  const handleMouseLeave = () => {
    setPosition({ x: 0, y: 0 });
  };

  if (!isFinePointer || reduce) {
    return <div className={className}>{children}</div>;
  }

  return (
    <motion.div
      ref={ref}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      animate={{ x: position.x, y: position.y }}
      transition={{ type: "spring", stiffness: 350, damping: 25, mass: 0.5 }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
