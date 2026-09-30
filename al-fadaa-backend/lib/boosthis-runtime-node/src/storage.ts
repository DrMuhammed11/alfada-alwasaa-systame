/** Tiny persistent key/value store for the Node runtime.
 *
 * The RN runtime persists candidate rules + baselines through a platform
 * storage abstraction (AsyncStorage). Node has no such platform, so we mirror
 * the Ruby, Rust, PHP, .NET and Elixir kits, which keep one directory per
 * application under a base the host can choose. State is kept in a single JSON
 * file so credentials, candidate recurrence and fix baselines survive a process
 * restart (a long-lived server may be restarted on deploy).
 *
 * ## Nothing writable
 *
 * A serverless function has no writable home directory, and on several hosts
 * the whole filesystem except one scratch directory is read-only. The store
 * therefore CHOOSES its backing at first use and says which one it picked:
 *
 *   1. `BOOSTHIS_STATE_DIR` when set (tests, and hosts that hand us a volume)
 *   2. `~/.boosthis` when the home directory is genuinely writable
 *   3. the OS scratch directory (`/tmp/.boosthis`) — survives for the life of
 *      a warm function instance, which is exactly as long as anything else in
 *      that instance survives
 *   4. memory only — the process still works; it simply forgets on exit
 *
 * The choice is probed by WRITING, not by reading a permission bit: a home
 * directory can exist, look writable and still refuse (read-only overlay).
 *
 * ## Several processes, one machine
 *
 * This file used to be ONE fixed path — `<base>/node-runtime-store.json` — for
 * every Node application on the machine, written with a plain whole-file
 * `writeFileSync` and no coordination of any kind. Two services sharing a
 * machine shared their install identity, their consent tokens and their crash
 * buffer; cluster workers of ONE app did the same by design, and each one's
 * whole-file write silently dropped every key the others had written since it
 * last read. A torn write read back as invalid JSON, which the loader treated
 * as "no state at all" — every credential simply gone, quietly.
 *
 * Three decisions replace that, and they are the isolation model the kit
 * documents (README, "Running several processes"):
 *
 *   • SCOPE — state lives in `<base>/boosthis-<scope>/`, where `<scope>` is a
 *     short hash of the application root (`BOOSTHIS_PROJECT_ROOT`, else the
 *     working directory). Two unrelated services on one machine therefore
 *     never meet. Every worker of ONE app resolves the SAME scope and shares
 *     one file on purpose: they are one install, they hold one project key,
 *     and splitting them would mint an install per worker. The naming matches
 *     the Ruby, Rust, PHP, .NET and Elixir kits exactly, so a polyglot app
 *     lands in one directory per application rather than one per language.
 *
 *   • ATOMIC — every write goes to a temp file in the same directory and is
 *     renamed over the target. A reader sees the whole old file or the whole
 *     new one; a half-written file is not a state this store can produce.
 *
 *   • MERGE UNDER A LOCK — a write re-reads what is on disk inside an
 *     interprocess lock and applies its own change to THAT, so a worker with a
 *     stale in-memory view can no longer drop a key another worker wrote. The
 *     lock is advisory and bounded: if it cannot be taken the write still
 *     happens (atomically, on freshly-read state), because losing a credential
 *     is worse than a rare lost update. `updateSync` exposes the whole
 *     read-modify-write to callers that need one, which is how the crash
 *     buffer keeps one process from eating another's crashes.
 *
 * ## An unreadable file is not an empty one
 *
 * Nothing in the kit may treat "the store was unreadable" as a reason to stop
 * measuring — the store is a cache, never an authority. But it must not read as
 * a fresh install either. A file that exists and cannot be parsed is set aside
 * (kept, not deleted) and reported; a file that exists and cannot be READ at
 * all switches durable state off for the run rather than overwriting state we
 * cannot see. Both say so on stderr, once, and through `storageStateLoss()`.
 * `storageDurable()` still exists so the paths that used to fail closed on an
 * unreadable cache can tell "we lost the answer" apart from "there was never
 * anywhere to keep it".
 */

import { createHash } from "node:crypto";
import { homedir, hostname, tmpdir } from "node:os";
import { join } from "node:path";
import {
  chmodSync,
  closeSync,
  existsSync,
  fstatSync,
  mkdirSync,
  openSync,
  readFileSync,
  renameSync,
  rmSync,
  statSync,
  unlinkSync,
  writeFileSync,
  writeSync,
} from "node:fs";

/** Which backing the store settled on. Reported on the kit's own surfaces so a
 *  developer is never left guessing why a restart forgot everything. */
export type StorageBackend = "configured" | "home" | "scratch" | "memory";

/** Why the state that WAS on disk is not in this process.
 *
 *  `corrupt`    — the file existed and was not valid JSON. Set aside, so the
 *                 bytes are still there for a human, and this process starts
 *                 with nothing.
 *  `unreadable` — the file existed and could not be read at all (permissions,
 *                 a directory in its place). Left untouched: we will not write
 *                 over state we cannot see. */
export interface StorageStateLoss {
  kind: "corrupt" | "unreadable";
  /** The path that could not be used. */
  file: string;
  /** Where the unreadable bytes were moved, when they were moved. */
  setAsideAs?: string;
  /** The OS error code, when there was one. */
  code?: string;
  at: number;
}

const STORE_FILE = "node-runtime-store.json";
const LOCK_FILE = "node-runtime-store.lock";
/** One directory per application, named the same way in every kit that keeps
 *  state on disk. */
const DIR_PREFIX = "boosthis-";

/** How long a write that would rather MISS its update (see `requireLock`)
 *  waits for the interprocess lock. A write is a read plus a rename —
 *  microseconds — so anything near this bound means contention, not slowness. */
const LOCK_WAIT_MS = 500;
/** A lock file older than this is presumed abandoned by a process that died
 *  holding it, and is broken. Must be comfortably longer than any real hold. */
const LOCK_STALE_MS = 3_000;
/** How long every other write waits: until the holder releases, or until its
 *  lock is old enough to be broken as abandoned. Every write replaces the
 *  WHOLE file, so one that went ahead beside a live holder would publish a
 *  copy erasing that holder's change (or have its own erased). Only a sibling
 *  frozen mid-write ever makes a write wait this long. */
const LOCK_WAIT_ORDINARY_MS = LOCK_STALE_MS + 250;

let backend: StorageBackend | null = null;
let resolvedBase: string | null = null;
let resolvedDir: string | null = null;
/** Does the settled backing actually accept a write? Probed once, alongside
 *  the backing itself. `false` for memory, and for a configured directory the
 *  host named but cannot write. */
let backingUsable = false;
/** Set when the state file exists but cannot be read: we then refuse to write
 *  over it for the rest of the process. */
let writesRefused = false;
let stateLoss: StorageStateLoss | null = null;
let lossAnnounced = false;
let appRootMemo: string | null = null;
let scopeMemo: string | null = null;
/** True only when the current view came from an existing on-disk document.
 * Memory fallback must never be reported as a restored install. */
let restoredFromDisk = false;
let restoredKeys = new Set<string>();
let writeDegraded = false;

/* ─── Which application is this? ──────────────────────────────────── */

function envValue(...names: string[]): string | undefined {
  for (const name of names) {
    const v = process.env[name];
    if (typeof v === "string" && v.length > 0) return v;
  }
  return undefined;
}

/**
 * The application root this process belongs to.
 *
 * Resolved ONCE per process: a later `chdir` must not silently move a running
 * app's state to a different scope — and therefore away from its own
 * credentials.
 *
 *   1. `BOOSTHIS_PROJECT_ROOT` — the explicit answer, for a host that boots
 *      from somewhere other than its own directory, or that wants two
 *      processes pinned to one scope on purpose.
 *   2. the working directory — the app root for an ordinary `node server.js`,
 *      a cluster worker, a PM2 process or a container entrypoint.
 *   3. the scratch directory, only if the working directory is unusable (it
 *      has been deleted under a running process).
 */
function appRoot(): string {
  if (appRootMemo !== null) return appRootMemo;
  const candidates = [
    envValue("BOOSTHIS_PROJECT_ROOT", "BOOSTEN_PROJECT_ROOT"),
    (() => {
      try {
        return process.cwd();
      } catch {
        return undefined;
      }
    })(),
  ];
  for (const candidate of candidates) {
    if (!candidate) continue;
    try {
      if (statSync(candidate).isDirectory()) {
        appRootMemo = candidate;
        return appRootMemo;
      }
    } catch {
      /* not a usable root — try the next one */
    }
  }
  appRootMemo = tmpdir();
  return appRootMemo;
}

/** Short, stable, non-secret name for this application's state directory. The
 *  same function in every kit: first 16 hex of the SHA-1 of the app root. */
function scopeKey(): string {
  if (scopeMemo !== null) return scopeMemo;
  let key: string;
  try {
    key = createHash("sha1").update(appRoot()).digest("hex").slice(0, 16);
  } catch {
    // A runtime without a usable hash still has to land somewhere stable.
    key = "0000000000000000";
  }
  scopeMemo = key;
  return key;
}

/* ─── Where does it live? ─────────────────────────────────────────── */

/** Can we actually create this directory and write inside it? Probes with a
 *  real write; cleans up after itself. Never throws. */
function dirIsWritable(dir: string): boolean {
  try {
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true, mode: 0o700 });
    const probe = join(dir, `.probe-${process.pid}`);
    writeFileSync(probe, "1", { mode: 0o600 });
    try {
      unlinkSync(probe);
    } catch {
      /* the write succeeded, which is the only thing being asked */
    }
    return true;
  } catch {
    return false;
  }
}

/**
 * One-time move of state written by a kit that had no scope.
 *
 * Older versions kept `<base>/node-runtime-store.json` — one file for every
 * Node app on the machine. An upgraded install must not read as a fresh one, so
 * the first scoped process to find that file takes it. If two apps really were
 * sharing it, exactly one keeps the old credentials and the other registers
 * again on its next knock; that is the self-heal path, and it is strictly
 * better than both of them continuing to overwrite one identity.
 */
function adoptUnscopedStore(): void {
  if (resolvedBase === null || resolvedDir === null) return;
  const legacy = join(resolvedBase, STORE_FILE);
  const scoped = join(resolvedDir, STORE_FILE);
  try {
    if (!existsSync(legacy) || existsSync(scoped)) return;
    try {
      renameSync(legacy, scoped);
    } catch {
      // Different device, or another worker took it a moment ago.
      if (existsSync(scoped) || !existsSync(legacy)) return;
      writeFileSync(scoped, readFileSync(legacy), { mode: 0o600 });
      try {
        unlinkSync(legacy);
      } catch {
        /* the copy is what matters */
      }
    }
    try {
      chmodSync(scoped, 0o600);
    } catch {
      /* Windows */
    }
  } catch {
    // Never let a migration stop the kit from starting.
  }
}

/** Settle on a backing directory ONCE. */
function resolveBacking(): void {
  if (backend !== null) return;
  const scoped = DIR_PREFIX + scopeKey();
  const configured = envValue("BOOSTHIS_STATE_DIR", "BOOSTEN_STATE_DIR");
  if (configured) {
    // An explicitly configured directory is used even if the probe fails: the
    // host asked for it, and silently writing somewhere else would be worse
    // than not writing at all. Tests depend on this.
    //
    // But the probe still RUNS, because "which directory" and "can anything be
    // kept there" are two different questions. A function host that names a
    // state directory it cannot write to is exactly the case this task exists
    // for: if that counted as durable, an unreadable cache would read as "the
    // last answer is gone" and the kit would lock itself and go quiet — on a
    // configuration we support and ask people to use.
    //
    // The per-application subdirectory applies here too. A host that points
    // several services at one volume is the shared-machine case again, not an
    // exception to it; a host that wants two processes to share one scope says
    // so with BOOSTHIS_PROJECT_ROOT, which is what that setting is for.
    resolvedBase = configured;
    resolvedDir = join(configured, scoped);
    backend = "configured";
    backingUsable = dirIsWritable(resolvedDir);
    if (backingUsable) adoptUnscopedStore();
    return;
  }
  try {
    const home = join(homedir(), ".boosthis");
    if (dirIsWritable(join(home, scoped))) {
      resolvedBase = home;
      resolvedDir = join(home, scoped);
      backend = "home";
      backingUsable = true;
      adoptUnscopedStore();
      return;
    }
  } catch {
    /* fall through to scratch */
  }
  try {
    const scratch = join(tmpdir(), ".boosthis");
    if (dirIsWritable(join(scratch, scoped))) {
      resolvedBase = scratch;
      resolvedDir = join(scratch, scoped);
      backend = "scratch";
      backingUsable = true;
      adoptUnscopedStore();
      return;
    }
  } catch {
    /* fall through to memory */
  }
  resolvedBase = null;
  resolvedDir = null;
  backend = "memory";
  backingUsable = false;
}

/** Which backing the store is using. Resolves it on first call. */
export function storageBackend(): StorageBackend {
  resolveBacking();
  return backend ?? "memory";
}

/** True when what we write here can outlive this process — which needs BOTH a
 *  real directory and the ability to write in it. False on a function host with
 *  nothing but memory, false for a configured directory that cannot be written,
 *  and false once we have found a state file we cannot read (we will not write
 *  over it, so nothing can be kept this run): in every case a caller must not
 *  read "nothing stored" as "the answer was lost". */
export function storageDurable(): boolean {
  storageBackend();
  return backend !== "memory" && backingUsable && !writesRefused && !writeDegraded;
}

/** State that was on disk and is not in this process, or null when nothing was
 *  lost. Read by the kit's own status surfaces: an install whose credentials
 *  went missing must be able to say WHY. */
export function storageStateLoss(): StorageStateLoss | null {
  return stateLoss;
}

function stateDir(): string | null {
  resolveBacking();
  return resolvedDir;
}

function storeFile(): string | null {
  const dir = stateDir();
  return dir === null ? null : join(dir, STORE_FILE);
}

/* ─── Saying what was lost ────────────────────────────────────────── */

/**
 * One ungated line, once per process, naming the file and what happened to it.
 *
 * An install that silently forgets its credentials looks exactly like an
 * install that never had any: the same "not registered" everywhere, with no
 * cause anywhere. This is the only place that difference can be stated at the
 * moment it is discovered.
 */
function noteLoss(loss: StorageStateLoss): void {
  stateLoss = loss;
  if (lossAnnounced) return;
  lossAnnounced = true;
  try {
    const line =
      loss.kind === "corrupt"
        ? `[boosthis] Saved state at ${loss.file} could not be read (not valid JSON) and has been set aside as ${loss.setAsideAs ?? "a copy beside it"}. This process starts with no stored credentials and will register again; measurements already uploaded are unaffected.`
        : `[boosthis] Saved state at ${loss.file} exists but could not be read${loss.code ? ` (${loss.code})` : ""}. Boosthis is keeping state in memory for this process and will NOT write over that file. Fix its ownership, or point BOOSTHIS_STATE_DIR at a directory this process owns.`;
    process.stderr.write(line + "\n");
  } catch {
    // A host that replaced stderr must not turn a lost file into a crash.
  }
}

/* ─── The interprocess lock ───────────────────────────────────────── */

/** Sleep without a timer — the write path is synchronous by contract (the
 *  crash reporter calls it while the process is dying). Falls back to a short
 *  spin where SharedArrayBuffer is unavailable. */
function sleepSync(ms: number): void {
  try {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
  } catch {
    const until = Date.now() + ms;
    while (Date.now() < until) {
      /* spin */
    }
  }
}

/** A process's start, in clock ticks since boot (field 22 of /proc/<pid>/stat)
 *  — the part of its identity a reused pid does not share. Null off Linux. */
function startTicks(pid: number | "self"): string | null {
  try {
    const stat = readFileSync(`/proc/${pid}/stat`, "utf8");
    // The command name (field 2) may hold spaces: count from its closing paren.
    return stat.slice(stat.lastIndexOf(")") + 2).split(" ")[19] ?? null;
  } catch {
    return null;
  }
}

let ownStart: string | null | undefined;

/** What the lock file says about its holder: pid, host, and start when known. */
function lockIdentity(): string {
  if (ownStart === undefined) ownStart = startTicks("self");
  return `${process.pid}@${hostname()}${ownStart === null ? "" : `@${ownStart}`}`;
}

/** True when the lock names a process on THIS host that is still running — the
 *  same process, where its start can be read, not a later one given its pid.
 *  A lock from an older kit or another host names nobody we can check, so its
 *  age alone decides. A confirmed-live holder's lock is
 *  never broken on age: a write waits for it or stays in memory. */
function holderAlive(lockPath: string): boolean {
  let text: string;
  try {
    text = readFileSync(lockPath, "utf8");
  } catch {
    return false;
  }
  const m = /^(\d+)@([^@]+)(?:@(\d+))?$/.exec(text.trim());
  if (m === null || m[2] !== hostname()) return false;
  const pid = Number(m[1]);
  // This very pid included: a worker thread of this process shares it, and
  // its start identity matches ours while that thread still holds the lock.
  if (!Number.isSafeInteger(pid) || pid <= 0) return false;
  try {
    process.kill(pid, 0);
  } catch (err) {
    if ((err as NodeJS.ErrnoException)?.code !== "EPERM") return false;
  }
  const named = m[3];
  const now = named === undefined ? null : startTicks(pid);
  return now === null || now === named;
}

/** Take the lock. Null when no lock can be made here (a read-only directory:
 *  the caller writes anyway, atomically, and learns it could not); "busy" when
 *  a live holder still has it at the end of the budget. */
function acquireLock(lockPath: string, waitMs: number): number | null | "busy" {
  const deadline = Date.now() + waitMs;
  for (;;) {
    try {
      const fd = writeLockFile(lockPath);
      return fd;
    } catch (err) {
      const code = (err as NodeJS.ErrnoException)?.code;
      if (code !== "EEXIST") return null; // read-only directory: nothing to wait for
      try {
        const age = Date.now() - statSync(lockPath).mtimeMs;
        if (age > LOCK_STALE_MS && !holderAlive(lockPath)) {
          // The holder died. Break it and try again.
          try {
            unlinkSync(lockPath);
          } catch {
            /* someone else broke it first */
          }
          continue;
        }
      } catch {
        // It vanished between the failed create and the stat — retry at once.
        continue;
      }
      if (Date.now() >= deadline) return "busy";
      sleepSync(2);
    }
  }
}

/** Exclusive create — `wx` fails with EEXIST when the file is already there,
 *  which IS the lock. The pid inside is only a hint for a human reading it. */
function writeLockFile(lockPath: string): number {
  const fd = openSync(lockPath, "wx", 0o600);
  try {
    writeSync(fd, lockIdentity());
  } catch {
    /* the file is the lock; its contents are only a hint for a human */
  }
  return fd;
}

function releaseLock(fd: number | null, lockPath: string): void {
  if (fd === null) return;
  // Only OUR lock comes off: if ours was broken as abandoned, the file there
  // now is another writer's, and removing it would let a third one in.
  let ours = false;
  try {
    ours = fstatSync(fd).ino === statSync(lockPath).ino;
  } catch {
    ours = false;
  }
  try {
    closeSync(fd);
  } catch {
    /* already closed */
  }
  if (!ours) return;
  try {
    unlinkSync(lockPath);
  } catch {
    /* broken as stale by someone else */
  }
}

/* ─── Reading ─────────────────────────────────────────────────────── */

let mem: Record<string, string> | null = null;
/** Identity of the file `mem` was read from — inode, size and mtime. Every
 *  write lands a NEW inode (temp file + rename), so this changes whenever any
 *  process writes, including within the same millisecond. */
let memStamp: string | null = null;

function stampOf(file: string): string | null {
  try {
    const st = statSync(file);
    return `${st.ino}:${st.size}:${st.mtimeMs}`;
  } catch {
    return null;
  }
}

type DiskRead =
  | { ok: true; data: Record<string, string> }
  | { ok: false; reason: "missing" }
  | { ok: false; reason: "corrupt"; raw: string }
  | { ok: false; reason: "unreadable"; code?: string };

function readDisk(file: string): DiskRead {
  let raw: string;
  try {
    raw = readFileSync(file, "utf8");
  } catch (err) {
    const code = (err as NodeJS.ErrnoException)?.code;
    if (code === "ENOENT") return { ok: false, reason: "missing" };
    return { ok: false, reason: "unreadable", code };
  }
  try {
    const obj = JSON.parse(raw);
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) {
      return { ok: false, reason: "corrupt", raw };
    }
    const data: Record<string, string> = {};
    for (const [k, v] of Object.entries(obj as Record<string, unknown>)) {
      if (typeof v === "string") data[k] = v;
    }
    return { ok: true, data };
  } catch {
    return { ok: false, reason: "corrupt", raw };
  }
}

/** Move a file we cannot parse out of the way, keeping the bytes. Returns where
 *  it went, or null if it could not be moved (in which case it is overwritten
 *  by the next write, which is still better than reading nothing forever). */
function setAside(file: string): string | null {
  const target = `${file}.unreadable-${new Date().toISOString().replace(/[:.]/g, "-")}`;
  try {
    renameSync(file, target);
    return target;
  } catch {
    return null;
  }
}

/** Turn a failed read into the in-memory view this process will use, recording
 *  what was lost. Returns the (empty) map. */
function handleFailedRead(file: string, read: DiskRead): Record<string, string> {
  if (read.ok || read.reason === "missing") return {};
  if (read.reason === "corrupt") {
    const setAsideAs = setAside(file);
    noteLoss({
      kind: "corrupt",
      file,
      ...(setAsideAs ? { setAsideAs } : {}),
      at: Date.now(),
    });
    return {};
  }
  // Exists, cannot be read. Do not write over what we cannot see.
  writesRefused = true;
  noteLoss({
    kind: "unreadable",
    file,
    ...(read.code ? { code: read.code } : {}),
    at: Date.now(),
  });
  return {};
}

/**
 * The current view of the store.
 *
 * The in-memory map is a CACHE of the file, not the truth: another worker of
 * the same app writes to the same file, so the cache is revalidated against the
 * file's identity (a stat) on every read. A stat is cheap; reading another
 * process's consent token as absent is not.
 */
function load(): Record<string, string> {
  const file = storeFile();
  if (file === null) {
    if (!mem) mem = {};
    return mem;
  }
  const stamp = stampOf(file);
  if (mem && stamp === memStamp) return mem;
  const read = readDisk(file);
  const data = read.ok ? read.data : handleFailedRead(file, read);
  mem = data;
  memStamp = read.ok ? stamp : stampOf(file);
  if (read.ok && Object.keys(data).length > 0) {
    restoredFromDisk = true;
    for (const key of Object.keys(data)) restoredKeys.add(key);
  }
  return data;
}

/* ─── Writing ─────────────────────────────────────────────────────── */

let tmpCounter = 0;

function writeAtomic(dir: string, file: string, data: Record<string, string>): void {
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true, mode: 0o700 });
  // Harden directory permissions even if it pre-existed without them (e.g.
  // created by an older version of the runtime before this fix shipped).
  try {
    chmodSync(dir, 0o700);
  } catch {
    // Best-effort: ignore on platforms that don't support chmod (Windows).
  }
  const tmp = join(dir, `.${STORE_FILE}.tmp-${process.pid}-${tmpCounter++}`);
  try {
    writeFileSync(tmp, JSON.stringify(data), { mode: 0o600 });
    try {
      chmodSync(tmp, 0o600);
    } catch {
      // Best-effort: ignore on platforms that don't support chmod (Windows).
    }
    // The replace itself. A reader either sees the whole previous file or the
    // whole new one; there is no moment at which it sees half of either, which
    // is what made a concurrent writer able to erase every credential.
    renameSync(tmp, file);
  } catch (err) {
    try {
      unlinkSync(tmp);
    } catch {
      /* nothing to clean up */
    }
    throw err;
  }
  // Harden the file even if it already existed with permissive permissions
  // (e.g. written by an older runtime version before this fix shipped).
  try {
    chmodSync(file, 0o600);
  } catch {
    // Best-effort: ignore on platforms that don't support chmod (Windows).
  }
}

/**
 * Apply one change to the store: lock, re-read, mutate what is on DISK, write
 * atomically, and adopt the result as the in-memory view.
 *
 * Starting from the disk state rather than from `mem` is the whole point. A
 * worker that read the file ten minutes ago and writes its own view back is how
 * a sibling's freshly-minted token disappeared.
 */
/** Options for a write whose caller would rather MISS an update than LOSE one. */
interface MutateOptions {
  /** Refuse to publish without the interprocess lock. */
  requireLock?: boolean;
  /** Set by `mutate` when `requireLock` met a lock still contended at the end
   *  of its budget: nothing was applied, on disk or in memory. */
  skipped?: boolean;
}

function mutate(
  apply: (data: Record<string, string>) => void | boolean,
  opts?: MutateOptions,
): boolean {
  const dir = stateDir();
  const file = storeFile();
  if (dir === null || file === null || !backingUsable || writesRefused) {
    // Memory-only: still apply, so the process behaves normally for its own
    // lifetime. It simply forgets on exit, which `storageDurable()` reports.
    apply(load());
    return false;
  }
  const lockPath = join(dir, LOCK_FILE);
  let fd: number | null = null;
  try {
    const got = acquireLock(
      lockPath,
      opts?.requireLock === true ? LOCK_WAIT_MS : LOCK_WAIT_ORDINARY_MS,
    );
    fd = got === "busy" ? null : got;
    if (got === "busy" && opts?.requireLock !== true) {
      // A live sibling has held the lock past the whole budget — frozen, not
      // slow. Publishing beside it would erase its write or have ours erased,
      // so this change stays in memory for this process and reports so.
      apply(load());
      return false;
    }
    if (got === "busy" && opts?.requireLock === true) {
      // The budget ran out with a sibling still holding the lock. Writing now
      // could replace the record that sibling is about to publish, so this
      // caller's change is dropped whole instead — not applied in memory
      // either, or this process would read a state no file holds and the next
      // ordinary write would silently discard it. The caller's next pass
      // re-reads what the holder left and applies its change to THAT.
      opts.skipped = true;
      return false;
    }
    // Stamped BEFORE the read: a write landing in between makes the check
    // below re-read once for nothing, never miss a change.
    let seen = stampOf(file);
    const read = readDisk(file);
    if (!read.ok && read.reason === "unreadable") {
      // We cannot see what is there, so we must not replace it.
      handleFailedRead(file, read);
      apply(load());
      return false;
    }
    let data = read.ok ? read.data : handleFailedRead(file, read);
    if (apply(data) === false) {
      mem = data;
      memStamp = stampOf(file);
      return true;
    }
    // A sibling's write can still land between this read and the rename: one
    // frozen so long that its lock was broken as abandoned, resuming now.
    // Publishing the copy read above would erase that write, so re-read and
    // re-apply this change to what is there now.
    for (let tries = 0; tries < 3; tries++) {
      const current = stampOf(file);
      if (current === seen) break;
      const again = readDisk(file);
      if (!again.ok) {
        // What is there now cannot be read, so it must not be replaced with
        // the copy read before it — the same refusal as an unreadable first
        // read. Memory keeps the change for this process.
        apply(load());
        return false;
      }
      seen = current;
      data = again.data;
      if (apply(data) === false) {
        mem = data;
        memStamp = stampOf(file);
        return true;
      }
    }
    writeAtomic(dir, file, data);
    mem = data;
    memStamp = stampOf(file);
    return true;
  } catch {
    // Best-effort: an unwritable directory just means no cross-restart cache.
    writeDegraded = true;
    return false;
  } finally {
    releaseLock(fd, lockPath);
  }
}

export const storage = {
  async get(key: string): Promise<string | null> {
    return load()[key] ?? null;
  },
  async set(key: string, value: string): Promise<void> {
    mutate((data) => {
      data[key] = value;
    });
  },
  async remove(key: string): Promise<void> {
    mutate((data) => {
      delete data[key];
    });
  },
  // Synchronous variants. The backing store is a single JSON file whose read
  // and write are already synchronous (readFileSync / renameSync), so these are
  // the SAME operations without the async wrapper. The crash reporter uses
  // setSync at capture time so a FATAL crash that kills the process before a
  // network flush completes still persists the pending buffer to disk — it
  // cannot await an async write mid-crash.
  getSync(key: string): string | null {
    return load()[key] ?? null;
  },
  setSync(key: string, value: string): void {
    mutate((data) => {
      data[key] = value;
    });
  },
  removeSync(key: string): void {
    mutate((data) => {
      delete data[key];
    });
  },
  /**
   * Read-modify-write ONE key with the file locked for the whole span.
   *
   * `getSync` then `setSync` is two separate locks with a gap in the middle,
   * and anything a sibling worker wrote in that gap is lost. A caller whose
   * value is a collection — the crash buffer is the one that matters — must use
   * this instead, so its merge sees what the other workers actually left.
   *
   * `update` receives the value on disk (null when absent) and returns the new
   * value, or null to remove the key. It must not throw; if it does, the store
   * is left exactly as it was. Returns what was stored.
   */
  updateSync(
    key: string,
    update: (current: string | null) => string | null,
  ): string | null {
    return storage.updateSyncPersisted(key, update).value;
  },
  /**
   * `updateSync`, and whether the new value actually reached DISK.
   *
   * Every write in this store is best-effort: a full disk, a directory that
   * turned read-only, or no writable directory at all leaves the value in
   * memory and returns quietly, because losing a cached token is not worth
   * crashing somebody's server over. For ONE caller that silence is the bug
   * rather than the kindness — the crash buffer, whose entire purpose is to
   * outlive the process. It cannot infer failure from an exception, because
   * there is none, so it asks here instead and says, in the kit's own words,
   * that the crash it caught will not survive.
   *
   * `persisted: false` means exactly "this value is in memory only". It is not
   * an error and nothing else need react to it.
   */
  updateSyncPersisted(
    key: string,
    update: (current: string | null) => string | null,
  ): { value: string | null; persisted: boolean } {
    const { value, persisted } = updateKey(key, update);
    return { value, persisted };
  },
  /**
   * `updateSyncPersisted` for a caller that would rather MISS an update than
   * LOSE one.
   *
   * The ordinary write waits for a live holder until it releases or its lock
   * is old enough to break as abandoned, because a credential must land. A
   * record of COUNTS would rather not hold the host's thread that long:
   * skipping costs one pass that the caller re-applies next time. So when the
   * lock is still contended after a short wait, nothing is applied — not on
   * disk and not in memory — and `skipped` is true.
   *
   * A store with no durable backing has no siblings to race; there the update
   * applies to memory exactly as `updateSyncPersisted` would.
   */
  updateSyncExclusive(
    key: string,
    update: (current: string | null) => string | null,
  ): { value: string | null; persisted: boolean; skipped: boolean } {
    return updateKey(key, update, { requireLock: true });
  },
};

/** The read-modify-write both update methods share. */
function updateKey(
  key: string,
  update: (current: string | null) => string | null,
  opts?: MutateOptions,
): { value: string | null; persisted: boolean; skipped: boolean } {
  let result: string | null = null;
  const persisted = mutate((data) => {
    const previous = data[key] ?? null;
    const next = update(previous);
    result = next;
    if (next === previous) return false;
    if (next === null) delete data[key];
    else data[key] = next;
    return true;
  }, opts);
  return { value: result, persisted, skipped: opts?.skipped === true };
}

/** Test helper — drop the in-memory view, any on-disk file, and the settled
 *  backing choice. */
export function _resetStorageForTests(): void {
  const dir = resolvedDir;
  const base = resolvedBase;
  mem = null;
  memStamp = null;
  try {
    const file = storeFile();
    if (file !== null) rmSync(file);
  } catch {
    // ignore — file may not exist
  }
  try {
    if (dir !== null) rmSync(join(dir, LOCK_FILE));
  } catch {
    // ignore — no lock held
  }
  try {
    if (base !== null) rmSync(join(base, STORE_FILE));
  } catch {
    // ignore — no unscoped leftover
  }
  backend = null;
  resolvedBase = null;
  resolvedDir = null;
  backingUsable = false;
  writesRefused = false;
  stateLoss = null;
  lossAnnounced = false;
  restoredFromDisk = false;
  restoredKeys = new Set<string>();
  writeDegraded = false;
  appRootMemo = null;
  scopeMemo = null;
}

/** Where this process's state actually lives, for tests and for the kit's own
 *  status surfaces. Resolving the backing is a side effect of asking. */
export const _storageInternals = {
  STORE_FILE,
  LOCK_FILE,
  DIR_PREFIX,
  appRoot,
  scopeKey,
  dir: (): string | null => stateDir(),
  file: (): string | null => storeFile(),
  base: (): string | null => {
    resolveBacking();
    return resolvedBase;
  },
};

/** Whether a particular value was restored from the on-disk document. */
export function storageKeyRestored(key: string): boolean {
  load();
  return restoredKeys.has(key);
}

/** Whether this process found an existing persisted state document. */
export function storageRestored(): boolean {
  load();
  return restoredFromDisk;
}
