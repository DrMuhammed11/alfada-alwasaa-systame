/** Full-stack trace — Stage 2: span emission (Node/Express layer).
 *
 * Byte-for-byte the same wire contract as the RN + Python span emitters. Stage 1
 * (see `trace.ts`) only *propagated* a 32-hex correlation id on the
 * `x-boosthis-trace` header; Stage 2 lets the Node layer emit ONE privacy-safe
 * span per handled request so the server can stitch a waterfall
 * (RN → Node → Python) keyed by that id.
 *
 * A span is a tiny, closed, code-derived shape:
 *   { traceId, layer:"node", routeLabel, durationMs, startOffsetMs, rating }
 *
 * Unlike RN (which mints a span at the outbound `traceFetch` call site), the Node
 * layer emits its span from the `boosthis()` middleware's request-finalize hook,
 * reusing the SAME `${METHOD} ${normalizedPath}` label the per-route sampler
 * already builds (ids redacted by `normalizePath`), capped at 100 chars. Nothing
 * here is screen-bearing beyond that code-defined label, and it rides the SAME
 * PII guard as every other transmit (see `telemetry.transmitSpans`).
 *
 * PRIVACY-BY-DEFAULT: `enqueueSpan` is a no-op until a submitter is wired. The
 * telemetry client only wires the span submitter when the snapshot mirror is
 * allowed (full mode, or issues-only after the developer connects an AI), so a
 * private app RETAINS nothing span-shaped until sharing is authorized. The
 * emergency kill-switch (`BOOSTHIS_DISABLED`) and `forget()` both stop and clear
 * it, exactly like the snapshot mirror.
 *
 * Everything here is best-effort: span bookkeeping must NEVER change the host
 * request's behavior or crash the app.
 */

import { rateDuration } from "./thresholds";
import { MAX_PART_NAME } from "./routeInventory";
import { isBoosthisDisabled } from "./runtimeFlags";
import { noteRowsDiscarded, noteRowsDelivered } from "./serverlessMeters";
import { sanitizeSpanId } from "./spanScope";
import {
  sanitizeWorkKind,
  sanitizeOutcome,
  type SpanWorkKind,
  type SpanOutcome,
} from "./spanWork";

export type SpanLayer = "rn" | "node" | "py";
export type SpanRating = "good" | "needs-work" | "poor";

/** One privacy-safe root/child span. Wire shape is byte-identical across all
 *  three runtimes and matches the server's `POST /api/spans` schema.
 *
 *  `spanId`/`parentSpanId` are the causality pair (see spanScope.ts). Both are
 *  OPTIONAL on the wire and are omitted entirely when absent, so a runtime that
 *  does not carry parentage sends exactly the bytes it always did and its spans
 *  still read as a valid — merely flat — trace. */
export interface TraceSpan {
  traceId: string;
  layer: SpanLayer;
  routeLabel: string;
  durationMs: number;
  startOffsetMs: number;
  rating: SpanRating;
  spanId?: string | null;
  parentSpanId?: string | null;
  /** What KIND of work this was, and whether it WORKED. Same rules as the
   *  causality pair: optional, drawn from the shared vocabulary in
   *  `spanWork.ts`, and omitted entirely when the kit has nothing to say —
   *  never sent as a placeholder, because an absent field reads as "this kit
   *  does not report it" and a value would read as a measurement. */
  kind?: SpanWorkKind | null;
  outcome?: SpanOutcome | null;
}

/** Server accepts at most 50 spans per batch. */
export const MAX_SPAN_BATCH = 50;
/** Hard cap on the in-memory buffer (drop-oldest on overflow) so a burst of
 *  requests between flushes can never grow memory without bound. */
export const MAX_BUFFERED_SPANS = 50;
/** Auto-flush cadence. */
export const SPAN_FLUSH_MS = 15_000;
/** Duration hard clamp (matches the server `durationMs` 0..600000 bound). */
export const MAX_SPAN_DURATION_MS = 600_000;

/** Classify a request duration against the shared TTI band — byte-identical to
 *  RN `rateSpanDuration` and Python `rate_duration`. Delegates to the shared
 *  `rateDuration` so there is exactly one Node threshold source. */
export function rateSpanDuration(ms: number): SpanRating {
  return rateDuration(ms);
}

/** Refuse a code-defined route label over the shared bound. The label itself is
 *  built by the middleware (`${METHOD} ${normalizePath(path)}`). */
export function spanLabel(label: string): string | null {
  return label.length <= MAX_PART_NAME ? label : null;
}

export type SpanSubmitter = (spans: TraceSpan[]) => Promise<number>;

let submitter: SpanSubmitter | null = null;
let buffer: TraceSpan[] = [];
let timer: ReturnType<typeof setTimeout> | null = null;
let active = false;
let inFlight = false;

/** Wire (or clear) the transport that ships buffered spans. Clearing it makes
 *  `enqueueSpan` inert immediately — the privacy-by-default gate. */
export function setSpanSubmitter(fn: SpanSubmitter | null): void {
  submitter = fn;
}

/** Drop the in-memory span buffer (called by `forget()`). */
export function clearBufferedSpans(): void {
  buffer = [];
}

/** Buffer one span for the next flush. No-op unless a submitter is wired
 *  (sharing authorized) and the kill-switch is off — so nothing span-shaped is
 *  even RETAINED on a private app. Clamps duration and drops the oldest span
 *  when the buffer is full. */
export function enqueueSpan(span: TraceSpan): void {
  if (!submitter || isBoosthisDisabled()) return;
  if (span.routeLabel.length > MAX_PART_NAME) return;
  const durationMs = Math.max(
    0,
    Math.min(MAX_SPAN_DURATION_MS, Math.round(span.durationMs)),
  );
  const startOffsetMs = Math.max(
    0,
    Math.min(MAX_SPAN_DURATION_MS, Math.round(span.startOffsetMs || 0)),
  );
  // Rebuild a closed span (never spread unknown keys) so the buffered shape
  // stays byte-identical to the other emitters' closed shapes. The causality
  // pair is validated here and ADDED ONLY WHEN PRESENT: a malformed id is
  // dropped rather than forwarded, and a span with nothing to say about its
  // caller sends the same six keys it always did.
  const row: TraceSpan = {
    traceId: span.traceId,
    layer: span.layer,
    routeLabel: span.routeLabel,
    durationMs,
    startOffsetMs,
    rating: span.rating,
  };
  const spanId = sanitizeSpanId(span.spanId);
  if (spanId !== null) row.spanId = spanId;
  const parentSpanId = sanitizeSpanId(span.parentSpanId);
  if (parentSpanId !== null) row.parentSpanId = parentSpanId;
  const kind = sanitizeWorkKind(span.kind);
  if (kind !== null) row.kind = kind;
  const outcome = sanitizeOutcome(span.outcome);
  if (outcome !== null) row.outcome = outcome;
  buffer.push(row);
  // Overflow: the oldest span is thrown away to make room. On a long-running
  // server that is a rare, self-correcting blip. On a function it is the normal
  // consequence of a frozen invocation — the buffer survives the freeze, fills
  // on the next wake, and quietly loses the difference. Count it, so a gap in a
  // customer's data can never read as a quiet period.
  while (buffer.length > MAX_BUFFERED_SPANS) {
    buffer.shift();
    noteRowsDiscarded(1);
  }
}

/** Flush up to one batch. Guarded against re-entrancy + the kill-switch;
 *  swallows any transport error (returns 0). */
async function tick(): Promise<number> {
  if (!submitter || isBoosthisDisabled() || inFlight || buffer.length === 0) {
    return 0;
  }
  inFlight = true;
  // The batch leaves the buffer BEFORE it is sent, so a failed send loses it.
  // That has always been true; what is new is that it is no longer silent —
  // both outcomes are counted, so a gap in a customer's data has a number
  // beside it instead of looking like a quiet period.
  const batch = buffer.splice(0, MAX_SPAN_BATCH);
  try {
    const accepted = await submitter(batch);
    noteRowsDelivered(accepted);
    if (accepted < batch.length) {
      noteRowsDiscarded(batch.length - accepted, "sendFailed");
    }
    return accepted;
  } catch {
    noteRowsDiscarded(batch.length, "sendFailed");
    return 0;
  } finally {
    inFlight = false;
  }
}

/** Manually flush the span buffer now (best-effort). */
export function flushSpansNow(): Promise<number> {
  return tick();
}

/** Start the periodic auto-flush loop. Idempotent. Does NOT fire an immediate
 *  flush (the buffer is empty at wire time). The timer is `unref`'d so it never
 *  keeps a Node process alive on its own. */
export function startSpanAutoFlush(): void {
  if (active) return;
  active = true;
  const loop = (): void => {
    if (!active) return;
    timer = setTimeout(() => {
      void tick().finally(() => {
        if (active) loop();
      });
    }, SPAN_FLUSH_MS);
    // Never hold the event loop open just to flush spans.
    (timer as { unref?: () => void } | null)?.unref?.();
  };
  loop();
}

/** Stop the auto-flush loop. */
export function stopSpanAutoFlush(): void {
  active = false;
  if (timer) {
    clearTimeout(timer);
    timer = null;
  }
}

/** Test/introspection hooks (mirrors the RN `_spanInternals`). */
export const _spanInternals = {
  hasSubmitter: (): boolean => submitter !== null,
  bufferLen: (): number => buffer.length,
  isAutoRunning: (): boolean => active,
  flushMs: (): number => SPAN_FLUSH_MS,
  reset: (): void => {
    stopSpanAutoFlush();
    submitter = null;
    buffer = [];
    inFlight = false;
  },
};
