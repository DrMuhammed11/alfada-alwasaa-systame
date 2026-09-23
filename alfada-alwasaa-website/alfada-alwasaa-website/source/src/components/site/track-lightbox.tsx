"use client";

import { useEffect, useCallback } from "react";
import Image from "next/image";
import * as Dialog from "@radix-ui/react-dialog";
import { motion, AnimatePresence } from "framer-motion";
import { 
  X, 
  ChevronRight, 
  ChevronLeft, 
  CheckCircle2, 
  ShieldCheck, 
  ExternalLink 
} from "lucide-react";

export type TrackItem = {
  id: string;
  title: string;
  tag: string;
  scope: string;
  metrics: string[];
  src: string;
  alt: string;
  Icon: React.ElementType;
};

type TrackLightboxProps = {
  isOpen: boolean;
  onClose: () => void;
  item: TrackItem | null;
  items: TrackItem[];
  onSelect: (item: TrackItem) => void;
};

export function TrackLightbox({
  isOpen,
  onClose,
  item,
  items,
  onSelect,
}: TrackLightboxProps) {
  const currentIndex = item ? items.findIndex((i) => i.id === item.id) : -1;

  const handlePrev = useCallback(() => {
    if (currentIndex > 0) {
      onSelect(items[currentIndex - 1]);
    } else {
      onSelect(items[items.length - 1]);
    }
  }, [currentIndex, items, onSelect]);

  const handleNext = useCallback(() => {
    if (currentIndex < items.length - 1) {
      onSelect(items[currentIndex + 1]);
    } else {
      onSelect(items[0]);
    }
  }, [currentIndex, items, onSelect]);

  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft") handleNext();
      if (e.key === "ArrowRight") handlePrev();
      if (e.key === "Escape") onClose();
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, handleNext, handlePrev, onClose]);

  if (!item) return null;

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <AnimatePresence>
        {isOpen && (
          <Dialog.Portal forceMount>
            {/* Backdrop */}
            <Dialog.Overlay asChild>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
                className="fixed inset-0 z-50 bg-navy-darker/90 backdrop-blur-md"
              />
            </Dialog.Overlay>

            {/* Modal Dialog Content */}
            <Dialog.Content asChild>
              <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 overflow-y-auto">
                <motion.div
                  initial={{ opacity: 0, scale: 0.95, y: 15 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: 15 }}
                  transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                  className="relative my-auto flex w-full max-w-4xl flex-col overflow-hidden rounded-3xl border border-white/15 bg-gradient-to-b from-navy via-navy to-navy-darker text-white shadow-2xl"
                  onClick={(e) => e.stopPropagation()}
                >
                  {/* Top Bar with Tag, Counter & Close Button */}
                  <div className="flex items-center justify-between border-b border-white/10 px-5 py-3.5 sm:px-6">
                    <div className="flex items-center gap-3">
                      <span className="rounded-full border border-gold/40 bg-gold/10 px-3 py-1 text-xs font-bold text-gold-light">
                        {item.tag}
                      </span>
                      <span className="text-xs font-mono text-white/60">
                        {currentIndex + 1} من {items.length}
                      </span>
                    </div>

                    <Dialog.Close asChild>
                      <button
                        type="button"
                        aria-label="إغلاق المعرض"
                        className="flex h-9 w-9 items-center justify-center rounded-xl bg-white/10 text-white ring-1 ring-white/15 transition hover:bg-white/20 hover:text-gold-light"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </Dialog.Close>
                  </div>

                  {/* Main Modal Body */}
                  <div className="grid gap-6 p-5 sm:p-7 md:grid-cols-12 md:gap-8 items-center">
                    {/* Image Area with Navigation Buttons (7 cols) */}
                    <div className="relative aspect-[16/11] w-full overflow-hidden rounded-2xl border border-white/15 bg-black/40 md:col-span-7">
                      <Image
                        src={item.src}
                        alt={item.alt}
                        fill
                        sizes="(max-width: 768px) 100vw, 55vw"
                        className="object-cover"
                        priority
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-navy-darker/60 via-transparent to-transparent" />

                      {/* Navigation Overlay Arrows */}
                      <button
                        type="button"
                        onClick={handlePrev}
                        aria-label="المشروع السابق"
                        className="absolute start-3 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-navy/80 text-white shadow-lg ring-1 ring-white/20 backdrop-blur-sm transition hover:bg-gold hover:text-navy-darker"
                      >
                        <ChevronRight className="h-5 w-5" />
                      </button>

                      <button
                        type="button"
                        onClick={handleNext}
                        aria-label="المشروع التالي"
                        className="absolute end-3 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-navy/80 text-white shadow-lg ring-1 ring-white/20 backdrop-blur-sm transition hover:bg-gold hover:text-navy-darker"
                      >
                        <ChevronLeft className="h-5 w-5" />
                      </button>
                    </div>

                    {/* Engineering & Technical Details (5 cols) */}
                    <div className="flex flex-col justify-between md:col-span-5">
                      <div>
                        <Dialog.Title className="text-xl sm:text-2xl font-black text-white leading-snug">
                          {item.title}
                        </Dialog.Title>
                        {/* وصف مخفي لقارئات الشاشة — وصولية a11y */}
                        <Dialog.Description className="sr-only">
                          {`مشروع ${item.title} — ${item.tag} — ${item.scope}`}
                        </Dialog.Description>

                        <div className="mt-4">
                          <span className="text-xs font-black uppercase tracking-wider text-gold-light">
                            نطاق التنفيذ الهندسي:
                          </span>
                          <p className="mt-2 text-sm leading-7 text-white/80 text-justify">
                            {item.scope}
                          </p>
                        </div>

                        <div className="mt-5 border-t border-white/10 pt-4">
                          <span className="text-xs font-black uppercase tracking-wider text-gold-light">
                            شواهد المطابقة والجودة:
                          </span>
                          <ul className="mt-2.5 space-y-2">
                            {item.metrics.map((metric, mIdx) => (
                              <li
                                key={mIdx}
                                className="flex items-start gap-2 text-xs leading-5 text-white/90 font-medium"
                              >
                                <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-gold" />
                                <span>{metric}</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>

                      {/* Modal Footer Actions */}
                      <div className="mt-6 flex items-center gap-3 pt-4 border-t border-white/10">
                        <a
                          href="#contact"
                          onClick={() => onClose()}
                          className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-gold py-2.5 text-xs font-black text-navy-darker shadow-md transition hover:bg-gold-light"
                        >
                          <ShieldCheck className="h-4 w-4" />
                          <span>طلب دراسة لمشروع مماثل</span>
                        </a>
                      </div>
                    </div>
                  </div>
                </motion.div>
              </div>
            </Dialog.Content>
          </Dialog.Portal>
        )}
      </AnimatePresence>
    </Dialog.Root>
  );
}
