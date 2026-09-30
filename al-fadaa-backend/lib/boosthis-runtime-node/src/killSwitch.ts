/* ─── Boosthis: remote kill-switch / entitlement client (Node) ──────────
 *
 * Faithful port of `lib/boosthis-runtime-rn/src/killSwitch.ts` (Rung 1 of the
 * kit-protection design). The RN doctrine applies verbatim: the VALUE lives on
 * the server and the kit only ever asks "am I still entitled?". When the server
 * says anything other than "active" the kit goes fully INERT: no bubble panel,
 * no measuring, no telemetry of any kind, no fix/community fetch.
 *
 * Node differences from the RN port (kept idiomatic):
 *   - persistence is the Node `storage` file store (async get/set/remove),
 *   - the check-in fetch uses the global `fetch` (Node 18+) bounded by a
 *     `Promise.race` timer — NO AbortController (parity with the RN contract),
 *   - the monotonic clock is `performance.now()` (`node:perf_hooks`),
 *   - there is no React UI: `getEntitlementGateKind()` drives the injected dev
 *     bubble's blocking lock overlay, and `subscribeEntitlement()` lets the
 *     panel endpoint reflect a live flip.
 *
 * Offline policy = GRACE (7 days). Cache the last confirmed-"active" answer and
 * keep working offline for `graceSeconds`; die the moment we (a) learn a
 * non-active status (sticky immediately, across restarts) or (b) the grace
 * window lapses with no successful re-check.
 *
 * ACTIVATION LOCK (ships locked): a copy that has NEVER completed a successful
 * server handshake is fully inert. "Activated" = the PRESENCE of a persisted
 * entitlement cache (even a revoked one — a registered-but-killed install must
 * keep heartbeating so it can learn it was restored). `forget()`/`clear...`
 * wipes the cache, re-locking the kit.
 *
 * CRITICAL invariants (identical to RN):
 *  - `isRuntimeInert()` is SYNCHRONOUS (transmit hot path + panel endpoint call
 *    it). It reads an in-memory flag hydrated asynchronously from cache.
 *  - The check-in itself MUST bypass the inert gate (it is the recovery path).
 *  - The check-in fetch bounds itself with a Promise.race timer, NEVER an
 *    AbortController signal.
 *  - This module imports ONLY runtimeFlags / no-pii / storage — never
 *    telemetry / transmit (those import IT), so there is no import cycle.
 */

import { performance as perfHooks } from "node:perf_hooks";
import { isBoosthisDisabled } from "./runtimeFlags";
import { checkNoPII } from "./no-pii";
import { storage, storageDurable } from "./storage";
import { isServerlessMode } from "./serverless";

/** The wire entitlement states. Mirrors the server's `EntitlementCheckResponse`
 *  status enum. "paused" is the calm variant of the owner's dashboard
 *  Disconnect pause; the kit goes inert on it exactly like "revoked". */
export type EntitlementStatus =
  | "active"
  | "revoked"
  | "unpaid"
  | "tampered"
  | "paused";

/** Storage key for the cached last-good answer. Versioned so the shape can
 *  evolve without misreading an old record. Byte-equal to the RN key. */
const CACHE_KEY = "boosthis.entitlement.v1";

/** Default offline grace if the server answer omits one. 7 days — matches the
 *  server's `GRACE_SECONDS`. Only a fallback; the server is canonical. */
const DEFAULT_GRACE_SECONDS = 7 * 24 * 60 * 60;

/** Hard ceiling on a cached grace window (30 days) — clamps a corrupt/tampered
 *  grace so it can never indefinitely defeat the kill-switch. */
const MAX_GRACE_SECONDS = 30 * 24 * 60 * 60;

/** Clock-jitter tolerance for a cache whose `checkedAt` sits in the future. */
const CLOCK_SKEW_TOLERANCE_MS = 5 * 60 * 1000;

/** Periodic heartbeat interval once started. 6h — unchanged from RN. */
const DEFAULT_INTERVAL_MS = 6 * 60 * 60 * 1000;

/** Network timeout for a single check-in. */
const DEFAULT_TIMEOUT_MS = 8000;

/** Minimum spacing between FORCED on-open entitlement checks. The dev bubble /
 *  panel opening is a user-driven enforcement edge (VAULT contract), but a user
 *  who opens/closes repeatedly must not hammer the server, so a forced on-open
 *  check runs at most once per this window. The periodic 6h heartbeat and the
 *  unconditional launch check are unaffected. */
const FORCE_CHECK_THROTTLE_MS = 60 * 1000;

interface EntitlementCache {
  status: EntitlementStatus;
  /** ms-epoch when the server confirmed this answer. */
  checkedAt: number;
  graceSeconds: number;
  /** High-water mark: the maximum wall-clock time ever OBSERVED for this active
   *  answer, so a clock rollback across a restart can't shrink proven elapsed
   *  time. Absent on legacy caches (treated as `checkedAt`). */
  maxSeenWallMs?: number;
}

/* ─── In-memory state (the synchronous source of truth for the gate) ──── */

let memStatus: EntitlementStatus = "active";
let memInert = false;
let memMessage: string | null = null;
let hydrated = false;
let hydrating: Promise<void> | null = null;

/** ACTIVATION LOCK tri-state: null = pre-hydration (LOCKED, fail-closed),
 *  false = no valid cache (LOCKED), true = handshake proven (normal model). */
let memActivated: boolean | null = null;

const LOCKED_MESSAGE =
  "Boosthis is locked. Connect this app to Boosthis with your project key to activate it.";

/** Serverless: there is nowhere to cache the last answer, so a cold start
 *  begins with no answer AT ALL. That is not the same thing as being locked
 *  out, and it must not read like it — the registration reply that arrives in
 *  this same invocation carries the entitlement and settles it within
 *  milliseconds. Surfaces that would otherwise say "locked" say "waiting for
 *  the first answer" while this is true. */
let awaitingFirstAnswer = false;

const AWAITING_MESSAGE =
  "Boosthis is waiting for its first answer from the server on this function. " +
  "Nothing is uploaded until it arrives.";

/** True when the kit has never had a server answer AND has nowhere to have
 *  cached one — a function's normal first few milliseconds, never a fault. */
export function isAwaitingFirstAnswer(): boolean {
  return awaitingFirstAnswer && memActivated !== true;
}

/** Active-answer grace timing (see RN notes). */
let memCheckedAt: number | null = null;
let memGraceSeconds: number = DEFAULT_GRACE_SECONDS;
let memInitialAgeMs = 0;
let memMonoAt: number | null = null;
let memMaxSeenWall: number | null = null;

/** Monotonic timestamp (ms) of the last forced on-open check dispatched, or
 *  null if none this run. In-memory only. */
let lastForcedCheckAt: number | null = null;

/* ─── Check-in configuration (installed by enableTelemetry) ───────────── */

export interface EntitlementCheckinConfig {
  /** API origin + base path, e.g. "https://www.boosthis.com/api". */
  endpoint: string;
  installId: string;
  /** Lazy getter — the token (read OR delete) is issued by consent AFTER
   *  enableTelemetry runs, so read the latest value on every check-in. */
  getToken: () => string | null;
  /** The kit RUNTIME_VERSION, reported for admin visibility. */
  kitVersion: string;
  /** Tamper-evidence signal (Rung 2), forwarded from the host config. */
  integrity?: { status?: string; manifestHash?: string | null } | null;
  fetchImpl?: typeof fetch;
  intervalMs?: number;
  timeoutMs?: number;
}

let config: EntitlementCheckinConfig | null = null;
let timer: ReturnType<typeof setInterval> | null = null;

/* ─── Change subscription (lets the panel re-read when the gate flips) ── */

const listeners = new Set<() => void>();

function notify(): void {
  for (const l of listeners) {
    try {
      l();
    } catch {
      /* a listener throwing must never break the kit */
    }
  }
}

/**
 * Subscribe to inert-state changes. Returns an unsubscribe function. On first
 * subscription this also kicks a lazy hydrate so a host that serves the bubble
 * panel before `enableTelemetry` still respects a cached kill from a previous
 * launch.
 */
export function subscribeEntitlement(listener: () => void): () => void {
  listeners.add(listener);
  if (!hydrated) void hydrateEntitlement();
  return () => {
    listeners.delete(listener);
  };
}

/* ─── The synchronous gate ────────────────────────────────────────────── */

/**
 * The single combined gate every hot path consults. True ⇒ the kit must do
 * NOTHING. The global env kill-switch always wins; the ACTIVATION LOCK comes
 * next; the server-controlled entitlement state is the lever on top of both.
 */
export function isRuntimeInert(): boolean {
  return (
    isBoosthisDisabled() ||
    memActivated !== true ||
    memInert ||
    activeGraceExpired()
  );
}

/** How the kit UI should present the current gate. Distinct from the boolean
 *  `isRuntimeInert()` measuring gate: measuring/uploads are ALWAYS off when
 *  inert, but the owner's UX requirement is that a REVOKED or UNPAID project is
 *  shown as VISIBLY LOCKED (a blocking overlay in the dev bubble panel), not
 *  silently gone.
 *
 *  - "none"    — not inert (or the env kill-switch, which stays a SILENT total
 *                off-switch): render normally / render nothing.
 *  - "hidden"  — inert, but the kit must vanish rather than show a lock overlay
 *                (env kill-switch, tampered, grace-expired offline). NOT the
 *                never-checked-in case.
 *  - "unregistered" — running, but no check-in has ever succeeded. The bubble
 *                DRAWS and the panel renders its own "Not registered yet"
 *                notice: no lock overlay, nothing measured or uploaded (that
 *                gate is `inert`). See docs/kit-bubble-draw-contract.md.
 *  - "revoked" — the account owner revoked this project's access. Blocking
 *                overlay; the bubble stays visible and opens straight to it.
 *  - "unpaid"  — the account's subscription is unpaid/frozen. Same visible-lock
 *                treatment with payment-oriented copy.
 *  - "paused"  — the owner paused (reversible) — calm blocking notice. */
export type EntitlementGateKind =
  | "none"
  | "unregistered"
  | "hidden"
  | "revoked"
  | "unpaid"
  | "paused";

/**
 * Classify how the kit UI should present the gate (see `EntitlementGateKind`).
 * SYNCHRONOUS. The env kill-switch always resolves to "hidden" (it must stay a
 * silent, total off-switch — never a visible overlay).
 */
export function getEntitlementGateKind(): EntitlementGateKind {
  if (isBoosthisDisabled()) return "hidden";
  if (!isRuntimeInert()) return "none";
  // Never handshaken (ACTIVATION LOCK). NOT a silent state: the bubble draws
  // and the panel renders its own "Not registered yet" notice, which is the
  // only readable explanation a developer gets when the check-in cannot
  // complete at all. Measuring/uploading stay gated on `inert`, untouched.
  // See docs/kit-bubble-draw-contract.md.
  if (memActivated !== true) return "unregistered";
  switch (memStatus) {
    case "revoked":
      return "revoked";
    case "unpaid":
      return "unpaid";
    case "paused":
      return "paused";
    // "active" here means the offline grace window lapsed: no server verdict to
    // explain → vanish. "tampered" also hides (no user-facing overlay copy).
    default:
      return "hidden";
  }
}

/**
 * @internal Killed-only variant of the gate: TRUE when the env kill-switch, a
 * non-active server answer, or a lapsed grace window silences the kit — but NOT
 * when the kit is merely LOCKED (never activated). Used only by the
 * consent/registration transmit path so a fresh install can still register.
 */
export function _isRuntimeKilledInternal(): boolean {
  if (isBoosthisDisabled()) return true;
  // A real server answer — revoked / unpaid / paused / tampered. Sticky, and
  // registration is not a way around it.
  if (memStatus !== "active") return memInert;
  // Inert under an ACTIVE answer can only be a grace window that ran out. That
  // term is the one that can trap an install for good, because registration is
  // the only way back and this gate stands in front of it: an install holding
  // NO credential cannot check in either (the check-in needs the token it has
  // not got), so refusing its registration leaves nothing that could ever
  // clear the state. So a lapsed grace silences the install that EARNED it,
  // and no other — which is also what the comment above has always claimed.
  if (!(memInert || activeGraceExpired())) return false;
  return hasCheckinConfig();
}

/** True once this copy has proven a completed server handshake. */
export function isActivated(): boolean {
  return memActivated === true;
}

/** Whether a check-in could even be attempted: telemetry configured AND a
 *  registration token on hand. Lets a caller tell "we never asked because
 *  there is nothing to ask with" apart from "we asked and got no answer" —
 *  the difference between an unconfigured app and an unreachable server. */
export function hasCheckinConfig(): boolean {
  if (credentialForTests !== undefined) return credentialForTests !== null;
  const cfg = config;
  if (!cfg) return false;
  try {
    const token = cfg.getToken();
    return typeof token === "string" && token !== "";
  } catch {
    return false; // a throwing getter is treated as "no credential"
  }
}

let credentialForTests: string | null | undefined = undefined;

/** @internal test hook — stand in for a registration that has (not) landed.
 *  The sibling of the same hook in the RN and web kits. */
export function _setInstallCredentialForTests(
  token: string | null | undefined,
): void {
  credentialForTests = token;
}

function clampGrace(graceSeconds: number): number {
  let g = graceSeconds;
  if (!(g > 0)) g = DEFAULT_GRACE_SECONDS;
  if (g > MAX_GRACE_SECONDS) g = MAX_GRACE_SECONDS;
  return g;
}

/** Read a monotonic clock, never throwing — the synchronous gate stays crash-
 *  proof. */
function monoNow(): number {
  try {
    return perfHooks.now();
  } catch {
    return Date.now();
  }
}

function recordActiveTiming(
  checkedAt: number,
  graceSeconds: number,
  maxSeenWallMs?: number,
): void {
  memCheckedAt = checkedAt;
  memGraceSeconds = clampGrace(graceSeconds);
  memInitialAgeMs = Math.max(0, Date.now() - checkedAt);
  memMonoAt = monoNow();
  memMaxSeenWall =
    typeof maxSeenWallMs === "number" && maxSeenWallMs > checkedAt
      ? maxSeenWallMs
      : checkedAt;
}

function clearActiveTiming(): void {
  memCheckedAt = null;
  memMonoAt = null;
  memInitialAgeMs = 0;
  memMaxSeenWall = null;
}

/** True iff we hold an ACTIVE answer whose grace window has now lapsed.
 *  Effective age = MAX(wall delta, monotonic age, high-water age) so rolling
 *  the clock backward can only make the kit expire sooner, never later. */
function activeGraceExpired(): boolean {
  if (memStatus !== "active" || memCheckedAt === null) return false;
  const wallAgeMs = Date.now() - memCheckedAt;
  const monoAgeMs =
    memMonoAt === null
      ? Number.NEGATIVE_INFINITY
      : memInitialAgeMs + (monoNow() - memMonoAt);
  const highWaterAgeMs =
    memMaxSeenWall === null
      ? Number.NEGATIVE_INFINITY
      : memMaxSeenWall - memCheckedAt;
  const ageMs = Math.max(wallAgeMs, monoAgeMs, highWaterAgeMs);
  if (ageMs < 0) return false;
  return ageMs > memGraceSeconds * 1000;
}

function maybeExpireActiveGrace(): void {
  if (!memInert && activeGraceExpired()) {
    memInert = true;
    notify();
  }
}

/** Write the last-good answer to whatever store this host has. Best-effort by
 *  design: on a function with nothing writable there is simply nowhere to put
 *  it, and that is not an error — the next cold start gets its answer on the
 *  registration reply instead. */
async function persistCache(
  status: EntitlementStatus,
  graceSeconds: number,
): Promise<void> {
  try {
    const now = Date.now();
    const cache: EntitlementCache = {
      status,
      checkedAt: now,
      graceSeconds,
      ...(status === "active" ? { maxSeenWallMs: now } : {}),
    };
    await storage.set(CACHE_KEY, JSON.stringify(cache));
  } catch {
    /* cache write failure is non-fatal */
  }
}

async function bumpAndPersistMaxSeenWall(): Promise<void> {
  if (memStatus !== "active" || memCheckedAt === null) return;
  const now = Date.now();
  if (memMaxSeenWall !== null && now <= memMaxSeenWall) return;
  memMaxSeenWall = now;
  try {
    const cache: EntitlementCache = {
      status: "active",
      checkedAt: memCheckedAt,
      graceSeconds: memGraceSeconds,
      maxSeenWallMs: memMaxSeenWall,
    };
    await storage.set(CACHE_KEY, JSON.stringify(cache));
  } catch {
    /* non-fatal — the in-memory high-water mark already advanced */
  }
}

async function onOfflineCheckin(): Promise<void> {
  await bumpAndPersistMaxSeenWall();
  maybeExpireActiveGrace();
}

/** Last known entitlement status (cached). For the panel's inert message. */
export function getEntitlementStatus(): EntitlementStatus {
  return memStatus;
}

/** Human-readable reason for the current non-active status, if any. */
export function getEntitlementMessage(): string | null {
  if (!isBoosthisDisabled() && memActivated !== true && !memInert) {
    return isAwaitingFirstAnswer() ? AWAITING_MESSAGE : LOCKED_MESSAGE;
  }
  return memMessage;
}

/* ─── Hydration from cache ────────────────────────────────────────────── */

function applyCache(cache: EntitlementCache): void {
  memActivated = true;
  memStatus = cache.status;
  if (cache.status !== "active") {
    memInert = true;
    clearActiveTiming();
    return;
  }
  let checkedAt = cache.checkedAt;
  const ageMs = Date.now() - checkedAt;
  if (ageMs < 0) {
    if (-ageMs <= CLOCK_SKEW_TOLERANCE_MS) {
      checkedAt = Date.now();
    } else {
      memInert = true;
      clearActiveTiming();
      return;
    }
  }
  recordActiveTiming(checkedAt, cache.graceSeconds, cache.maxSeenWallMs);
  memInert = activeGraceExpired();
}

/**
 * Read the cached last-good answer into the in-memory gate. Idempotent — runs
 * its real work at most once. No valid cache ⇒ the ACTIVATION LOCK stays
 * engaged (fail-closed). Never throws.
 */
export function hydrateEntitlement(): Promise<void> {
  if (hydrated) return Promise.resolve();
  if (hydrating) return hydrating;
  hydrating = (async () => {
    let activated = false;
    // NOTHING WRITABLE. On a function host there is no cache and there never
    // was one — reading its absence as "we lost the last answer" is what turns
    // a healthy function into a kit that locks itself and goes quiet. Skip the
    // read, record that we are WAITING for a first answer rather than locked
    // out of one, and let the registration reply (which arrives in this same
    // invocation, carrying the entitlement) settle it.
    if (!storageDurable()) {
      awaitingFirstAnswer = true;
      if (memActivated !== true) memActivated = false;
      hydrated = true;
      notify();
      return;
    }
    try {
      const raw = await storage.get(CACHE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as Partial<EntitlementCache>;
        if (
          parsed &&
          (parsed.status === "active" ||
            parsed.status === "revoked" ||
            parsed.status === "unpaid" ||
            parsed.status === "tampered" ||
            parsed.status === "paused") &&
          typeof parsed.checkedAt === "number"
        ) {
          applyCache({
            status: parsed.status,
            checkedAt: parsed.checkedAt,
            graceSeconds:
              typeof parsed.graceSeconds === "number"
                ? parsed.graceSeconds
                : DEFAULT_GRACE_SECONDS,
            maxSeenWallMs:
              typeof parsed.maxSeenWallMs === "number"
                ? parsed.maxSeenWallMs
                : undefined,
          });
          activated = true;
        }
      }
    } catch {
      /* storage unreadable ⇒ LOCKED (fail-closed) */
    } finally {
      // Never DOWNGRADE: a live server answer may have activated the kit while
      // the storage read was in flight.
      if (memActivated !== true) memActivated = activated;
      hydrated = true;
      notify();
    }
  })();
  return hydrating;
}

/* ─── The check-in (recovery path — never gated by inert) ──────────────── */

function applyServerAnswer(
  status: EntitlementStatus,
  graceSeconds: number,
  message: string | null,
): void {
  const wasInert = isRuntimeInert();
  awaitingFirstAnswer = false;
  memActivated = true;
  memStatus = status;
  memMessage = status === "active" ? null : message;
  if (status === "active") {
    recordActiveTiming(Date.now(), graceSeconds);
    memInert = false;
  } else {
    memInert = true;
    clearActiveTiming();
  }
  if (isRuntimeInert() !== wasInert) notify();
}

/**
 * Adopt an entitlement answer that arrived on ANOTHER reply — specifically the
 * registration reply, which a function-hosted kit sends on every cold start
 * anyway.
 *
 * This is what collapses the cold path: the server already knows the
 * entitlement when it answers a registration, so carrying it back costs nothing
 * and saves a whole round trip on a request that may only live 200 ms. The
 * answer is applied through exactly the same path as a check-in answer — same
 * grace clock, same sticky non-active states — so there is one verdict, not
 * two. It is also cached, so a warm instance with a scratch directory need not
 * ask again.
 */
export function adoptEntitlementAnswer(answer: {
  status: EntitlementStatus;
  graceSeconds?: number;
  message?: string | null;
}): void {
  if (isBoosthisDisabled()) return;
  const status = answer.status;
  if (
    status !== "active" &&
    status !== "revoked" &&
    status !== "unpaid" &&
    status !== "tampered" &&
    status !== "paused"
  ) {
    return;
  }
  const grace =
    typeof answer.graceSeconds === "number" && answer.graceSeconds >= 0
      ? answer.graceSeconds
      : DEFAULT_GRACE_SECONDS;
  applyServerAnswer(status, grace, answer.message ?? null);
  hydrated = true; // this answer IS the truth — never hydrate a cache over it
  void persistCache(status, grace);
}

/** POST the check-in, bounded by a Promise.race timer (NO AbortController). */
async function postCheckin(
  cfg: EntitlementCheckinConfig,
  token: string,
  timeoutOverrideMs?: number,
): Promise<Response | null> {
  const f =
    cfg.fetchImpl ??
    (typeof fetch === "function" ? (fetch as typeof fetch) : undefined);
  // No usable fetch → return null (no server status to apply), like an offline
  // tick. The check-in must never throw on a transport problem.
  if (!f) return null;
  const url = `${cfg.endpoint.replace(/\/$/, "")}/entitlements/check`;
  const body: {
    installId: string;
    kitVersion: string;
    integrity?: { status: "ok" | "mismatch"; manifestHash?: string };
  } = { installId: cfg.installId, kitVersion: cfg.kitVersion };
  const integ = cfg.integrity;
  if (integ && (integ.status === "ok" || integ.status === "mismatch")) {
    body.integrity = {
      status: integ.status,
      ...(typeof integ.manifestHash === "string" && integ.manifestHash
        ? { manifestHash: integ.manifestHash }
        : {}),
    };
  }
  // Defence-in-depth: the payload is fully code-defined, but run the shared PII
  // guard anyway. A hit means abort the send (never throw).
  if (checkNoPII(body)) return null;
  // An exit flush passes its own, much shorter budget: the ordinary check-in
  // timeout is time a shutting-down process does not have.
  const timeoutMs =
    typeof timeoutOverrideMs === "number" && timeoutOverrideMs > 0
      ? timeoutOverrideMs
      : (cfg.timeoutMs ?? DEFAULT_TIMEOUT_MS);
  const timeout = new Promise<null>((resolve) =>
    setTimeout(() => resolve(null), timeoutMs).unref?.(),
  );
  const req = Promise.resolve()
    .then(() =>
      f(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      }),
    )
    .catch(() => null);
  return Promise.race([req, timeout]);
}

/**
 * A refusal that NAMES a deliberate cut is an ANSWER, not an outage.
 *
 * Without this, a revoked install can never learn it was revoked: the only
 * check that would tell it authenticates with the very credential the revoke
 * just cut, so the kit sees a bare 401, treats it exactly like an unreachable
 * server, and goes on reporting itself ACTIVE forever.
 *
 * ONLY the exact `credentials_cut` code counts. A ROTATED credential — a
 * sibling copy that took the token — also answers 401, but as `unauthorized`,
 * and that case must keep falling through to the offline path so it can
 * re-consent and recover. Silence is never an answer either. Reading the body
 * can never throw into the host.
 */
async function readCredentialsCut(
  res: { status: number; json: () => Promise<unknown> } | null,
): Promise<{ status: EntitlementStatus; message: string | null } | null> {
  if (!res || res.status !== 401) return null;
  try {
    const body = (await res.json()) as {
      error?: unknown;
      reason?: unknown;
      detail?: unknown;
    } | null;
    if (!body || body.error !== "credentials_cut") return null;
    const reason = body.reason;
    // A cut is never "active", whatever the body says.
    const status: EntitlementStatus =
      reason === "revoked" ||
      reason === "unpaid" ||
      reason === "tampered" ||
      reason === "paused"
        ? reason
        : "revoked";
    return {
      status,
      message: typeof body.detail === "string" ? body.detail : null,
    };
  } catch {
    return null; // unreadable body ⇒ an outage, never an answer
  }
}

/**
 * Apply AND persist a server answer. One path, so a named cut and an ordinary
 * check-in answer can never drift apart.
 */
async function adoptAnswer(
  status: EntitlementStatus,
  graceSeconds: number,
  message: string | null,
): Promise<EntitlementStatus> {
  applyServerAnswer(status, graceSeconds, message);
  try {
    const now = Date.now();
    const cache: EntitlementCache = {
      status,
      checkedAt: now,
      graceSeconds,
      ...(status === "active" ? { maxSeenWallMs: now } : {}),
    };
    await storage.set(CACHE_KEY, JSON.stringify(cache));
  } catch {
    /* cache write failure is non-fatal */
  }
  hydrated = true;
  return status;
}

/**
 * Run ONE check-in using the installed config. Returns the resolved status, or
 * null when the check couldn't complete. A null result deliberately leaves the
 * cached state intact — only an explicit server answer changes it (fail-open /
 * sticky-kill).
 *
 * NOTE: intentionally NOT gated by `isRuntimeInert()` — this is the path by
 * which a revoked install learns it has been restored.
 */
export async function checkEntitlementNow(
  timeoutOverrideMs?: number,
): Promise<EntitlementStatus | null> {
  if (isBoosthisDisabled()) return null;
  const cfg = config;
  if (!cfg) return null;
  const token = cfg.getToken();
  if (!token) return null; // not registered yet — the kit stays LOCKED
  try {
    const res = await postCheckin(cfg, token, timeoutOverrideMs);
    if (!res || !res.ok) {
      // A refusal that NAMES a deliberate cut is an ANSWER, not an outage.
      const cut = await readCredentialsCut(res);
      if (cut) {
        return adoptAnswer(cut.status, DEFAULT_GRACE_SECONDS, cut.message);
      }
      // Unreachable / bare 401 / 429 → keep the cached answer, advance the
      // high-water marker, and let a lapsed active grace expire.
      await onOfflineCheckin();
      return null;
    }
    const data = (await res.json()) as {
      status?: string;
      graceSeconds?: number;
      message?: string | null;
    };
    const status = data.status;
    if (
      status !== "active" &&
      status !== "revoked" &&
      status !== "unpaid" &&
      status !== "tampered" &&
      status !== "paused"
    ) {
      return null; // unexpected shape — don't act on it
    }
    const graceSeconds =
      typeof data.graceSeconds === "number"
        ? data.graceSeconds
        : DEFAULT_GRACE_SECONDS;
    applyServerAnswer(status, graceSeconds, data.message ?? null);
    try {
      const now = Date.now();
      const cache: EntitlementCache = {
        status,
        checkedAt: now,
        graceSeconds,
        ...(status === "active" ? { maxSeenWallMs: now } : {}),
      };
      await storage.set(CACHE_KEY, JSON.stringify(cache));
    } catch {
      /* cache write failure is non-fatal */
    }
    hydrated = true;
    return status;
  } catch {
    await onOfflineCheckin();
    return null; // never let a check-in throw into the host
  }
}

/**
 * Trigger a FRESH server entitlement check — the on-open / cold-start
 * enforcement edge of the VAULT contract. Unlike the cached synchronous gate,
 * this always attempts to reconfirm with the server (subject to the throttle);
 * it does NOT short-circuit on a cache-satisfied "active" answer.
 *
 * Non-blocking, fully self-guarded (never throws into the host, no
 * AbortController, Promise.race-bounded fetch). The verdict is applied by
 * `checkEntitlementNow()` when it lands, flipping the synchronous gate +
 * notifying subscribers so the open panel re-reads (a revoked verdict arriving
 * while the panel is open swaps it to the blocking lock overlay).
 *
 * Offline / unreachable stays UNCHANGED: a network failure keeps the cached
 * answer + grace window, so a transient outage can never brick a paying app —
 * EXCEPT a sticky revoked/killed answer, which the cache holds inert.
 *
 * @param force When true (cold start / init), bypass the throttle. When
 *   false/omitted (on-open), dispatch at most once per FORCE_CHECK_THROTTLE_MS.
 */
export function forceEntitlementCheck(force = false): void {
  if (isBoosthisDisabled()) return;
  if (!config) return;
  if (!force) {
    const now = monoNow();
    if (
      lastForcedCheckAt !== null &&
      now - lastForcedCheckAt < FORCE_CHECK_THROTTLE_MS
    ) {
      return; // throttled — a forced check ran within the window
    }
    lastForcedCheckAt = now;
  } else {
    // A forced (launch) check resets the throttle window so an on-open check
    // immediately after cold start doesn't fire a redundant second knock.
    lastForcedCheckAt = monoNow();
  }
  void checkEntitlementNow();
}

/* ─── Lifecycle (called by enableTelemetry / forget) ──────────────────── */

/**
 * Install the check-in config and start the heartbeat: hydrate the cache, run
 * an immediate FORCED launch check-in, then poll on an interval. Safe to call
 * repeatedly — it replaces any prior config and timer. All async work is fire-
 * and-forget and self-guarded so it can never crash the host.
 */
export function startEntitlementCheckin(cfg: EntitlementCheckinConfig): void {
  config = cfg;
  stopTimer();

  // SERVERLESS. "Start-up" happens on every cold start, so a launch check here
  // would put a blocking network call in front of every cold request — on a
  // function that answers in 200 ms, that is not overhead, that is the
  // workload. And a six-hourly heartbeat cannot fire in a process that is
  // frozen the moment it answers. So neither runs: the entitlement rides back
  // on the registration reply the kit was already going to send
  // (`adoptEntitlementAnswer`), which is why being alive costs one round trip
  // rather than two.
  if (isServerlessMode()) {
    void hydrateEntitlement().catch(() => {
      /* never throw into the host */
    });
    return;
  }

  void (async () => {
    try {
      await hydrateEntitlement();
      // Cold-start / init enforcement edge (VAULT contract): a FORCED launch
      // check that bypasses the cache-satisfied fast path.
      await checkEntitlementNow();
    } catch {
      /* never throw into the host */
    }
  })();
  // A launch check just ran — seed the throttle so an immediate on-open check
  // doesn't fire a redundant second knock.
  lastForcedCheckAt = monoNow();
  const interval = cfg.intervalMs ?? DEFAULT_INTERVAL_MS;
  timer = setInterval(() => {
    void checkEntitlementNow();
  }, interval);
  // Don't keep the process alive just for the heartbeat.
  (timer as unknown as { unref?: () => void }).unref?.();
}

function stopTimer(): void {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

/** Stop the heartbeat and drop the config. Called from `forget()`. */
export function stopEntitlementCheckin(): void {
  stopTimer();
  config = null;
}

/**
 * Erase the persisted entitlement cache and RE-LOCK the kit. Called from
 * `forget()`. Best-effort, never throws.
 */
export async function clearEntitlementCache(): Promise<void> {
  const wasInert = isRuntimeInert();
  memActivated = false;
  memStatus = "active";
  memInert = false;
  memMessage = null;
  clearActiveTiming();
  memGraceSeconds = DEFAULT_GRACE_SECONDS;
  hydrated = true; // the (now empty) state IS the truth — don't rehydrate over it
  hydrating = null;
  try {
    await storage.remove(CACHE_KEY);
  } catch {
    /* storage failure is non-fatal — the in-memory lock is already engaged */
  }
  if (isRuntimeInert() !== wasInert) notify();
}

/* ─── Test helpers ────────────────────────────────────────────────────── */

/** Reset ALL module state to first-run defaults (pre-hydration ⇒ LOCKED). */
export function _resetEntitlementForTests(): void {
  stopTimer();
  config = null;
  memActivated = null;
  memStatus = "active";
  memInert = false;
  memMessage = null;
  memCheckedAt = null;
  memGraceSeconds = DEFAULT_GRACE_SECONDS;
  memInitialAgeMs = 0;
  memMonoAt = null;
  memMaxSeenWall = null;
  lastForcedCheckAt = null;
  hydrated = false;
  hydrating = null;
  listeners.clear();
}

/** Force the in-memory gate (bypasses cache/network) for assertions. */
export function _setEntitlementStateForTests(
  status: EntitlementStatus,
  inert: boolean,
  message: string | null = null,
): void {
  memActivated = true;
  memStatus = status;
  memInert = inert;
  memMessage = message;
  memCheckedAt = null;
  memGraceSeconds = DEFAULT_GRACE_SECONDS;
  memInitialAgeMs = 0;
  memMonoAt = null;
  memMaxSeenWall = null;
  hydrated = true;
  notify();
}
