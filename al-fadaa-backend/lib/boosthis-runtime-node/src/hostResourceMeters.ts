/* Host-resource readings. Additive/display-only; never part of Speed. */
import {
  closeSync,
  existsSync,
  fstatSync,
  openSync,
  readFileSync,
  readdirSync,
  statfsSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { availableParallelism, cpus, loadavg, uptime } from "node:os";
import { join } from "node:path";
import { linearScore, ratingFor } from "./healthAxes";
import type { ExtraAxis } from "./extraMeters";
import { windowMinOf, windowPhrase } from "./rateHonesty";

export const DISK_USED_PCT_GOOD = 75;
export const DISK_USED_PCT_POOR = 95;
export const IO_GOOD_MB_PER_SEC = 2;
export const IO_POOR_MB_PER_SEC = 100;
export const FAULT_GOOD_PER_MIN = 1;
export const FAULT_POOR_PER_MIN = 100;
export const FDMIX_SOCK_PCT_GOOD = 70;
export const FDMIX_SOCK_PCT_POOR = 95;
export const FDMIX_MIN_FDS = 20;
export const FDMIX_SCAN_CAP = 4096;
export const SYSTEM_LOAD_GOOD = 0.7;
export const SYSTEM_LOAD_POOR = 2.0;
export const HOST_RATE_MIN_SPAN_MS = 60_000;

// kit-probe-file observation point constants (contract table §6/§8).
export const STORAGE_LATENCY_GOOD_MS = 8;
export const STORAGE_LATENCY_POOR_MS = 120;
export const STORAGE_FAILURE_GOOD_PCT = 1;
export const STORAGE_FAILURE_POOR_PCT = 10;
export const STORAGE_MIN_OPERATIONS = 5;
export const STORAGE_RING_CAP = 200;

const MB = 1024 * 1024;
/** One tick of the two /proc counters. Each half is independently nullable:
 *  a host that publishes /proc/self/stat but not /proc/self/io (a sandbox, a
 *  hardened container) can still be asked about page faults, and reading the
 *  two as one sample made the missing source silence the reading that did not
 *  need it. */
type CounterSample = {
  at: number;
  read: number | null;
  written: number | null;
  major: number | null;
};
let samples: CounterSample[] = [];
let storageDurations: number[] = [];
let storageAttempts = 0;
let storageFailures = 0;
let containerCache: boolean | undefined;

function r1(n: number): number { return Math.round(n * 10) / 10; }
function r2(n: number): number { return Math.round(n * 100) / 100; }

export function hostVolumeScopeCode(): 2 | 3 {
  if (containerCache !== undefined) return containerCache ? 2 : 3;
  let boxed = false;
  try { boxed = existsSync("/.dockerenv"); } catch { boxed = false; }
  if (!boxed) {
    try {
      const cgroup = readFileSync("/proc/self/cgroup", "utf8");
      boxed = /docker|kubepods|containerd|lxc/.test(cgroup);
    } catch { boxed = false; }
  }
  containerCache = boxed;
  return boxed ? 2 : 3;
}

function scored(value: number, good: number, poor: number): Pick<ExtraAxis, "score" | "rating"> {
  const score = linearScore(value, good, poor);
  return { score, rating: ratingFor(score) };
}

function readCounters(now: number): void {
  if (process.platform !== "linux") return;
  let read: number | null = null;
  let written: number | null = null;
  let major: number | null = null;
  try {
    let r = -1, w = -1;
    for (const line of readFileSync("/proc/self/io", "utf8").split("\n")) {
      if (line.startsWith("read_bytes:")) r = Number(line.slice(11).trim());
      if (line.startsWith("write_bytes:")) w = Number(line.slice(12).trim());
    }
    if (r >= 0 && w >= 0) { read = r; written = w; }
  } catch { /* source absent/refused: this half is omitted, not the sample */ }
  try {
    const raw = readFileSync("/proc/self/stat", "utf8");
    const fields = raw.slice(raw.lastIndexOf(") ") + 2).trim().split(/\s+/);
    const m = Number(fields[9]); // field 12; suffix begins at field 3.
    if (Number.isFinite(m)) major = m;
  } catch { /* same */ }
  if (read === null && major === null) return;
  samples.push({ at: now, read, written, major });
  if (samples.length > 240) samples = samples.slice(-240);
}

/** First and last sample whose own half of the counter pair is readable, and
 *  the span between them — or null while the window is too short to divide
 *  by. Each reading asks for the half it publishes, so one absent source
 *  never withdraws the other's number. */
function counterWindow(
  has: (s: CounterSample) => boolean,
): { a: CounterSample; b: CounterSample; span: number } | null {
  const usable = samples.filter(has);
  if (usable.length < 2) return null;
  const a = usable[0]!, b = usable[usable.length - 1]!;
  const span = b.at - a.at;
  return span < HOST_RATE_MIN_SPAN_MS ? null : { a, b, span };
}

function diskPressure(): ExtraAxis | null {
  try {
    const dir = process.env.BOOSTHIS_STATE_DIR || process.cwd();
    const s = statfsSync(dir, { bigint: true });
    const total = Number(s.blocks * s.bsize);
    const free = Number(s.bavail * s.bsize);
    if (!(total > 0) || free < 0) return null;
    const usedPct = r1(100 * (total - free) / total);
    return {
      ...scored(usedPct, DISK_USED_PCT_GOOD, DISK_USED_PCT_POOR),
      usedPct, freeMb: Math.round(free / MB), totalMb: Math.round(total / MB),
      scopeCode: hostVolumeScopeCode(),
      caption: `${usedPct}% used`,
    };
  } catch { return null; }
}

function ioPressure(): ExtraAxis | null {
  const win = counterWindow((s) => s.read !== null && s.written !== null);
  if (!win) return null;
  const { a, b, span } = win;
  const windowMin = windowMinOf(span);
  const readBytes = Math.max(0, b.read! - a.read!);
  const writtenBytes = Math.max(0, b.written! - a.written!);
  const rate = ((readBytes + writtenBytes) / MB) / (span / 1000);
  return {
    ...scored(rate, IO_GOOD_MB_PER_SEC, IO_POOR_MB_PER_SEC),
    mbPerSec: r2(rate), readMb: Math.round(readBytes / MB),
    writtenMb: Math.round(writtenBytes / MB), windowMin,
    scopeCode: 1, caption: `${r2(rate)} MB/s storage I/O · ${windowPhrase(windowMin)}`,
  };
}

function pageFaults(): ExtraAxis | null {
  const win = counterWindow((s) => s.major !== null);
  if (!win) return null;
  const { a, b, span } = win;
  const windowMin = windowMinOf(span);
  const majorFaults = Math.max(0, b.major! - a.major!);
  const rate = majorFaults / (span / 60_000);
  return {
    ...scored(rate, FAULT_GOOD_PER_MIN, FAULT_POOR_PER_MIN),
    majorFaults, majorPerMin: r1(rate), windowMin,
    scopeCode: 1, caption: `${r1(rate)} major faults/min · ${windowPhrase(windowMin)}`,
  };
}

function descriptorMix(): ExtraAxis | null {
  if (process.platform !== "linux") return null;
  try {
    let sockets = 0, pipes = 0, files = 0, otherFds = 0;
    for (const name of readdirSync("/proc/self/fd").slice(0, FDMIX_SCAN_CAP)) {
      try {
        const s = fstatSync(Number(name));
        if (s.isSocket()) sockets++;
        else if (s.isFIFO()) pipes++;
        else if (s.isFile()) files++;
        else otherFds++;
      } catch { /* descriptor closed during walk */ }
    }
    const total = sockets + pipes + files + otherFds;
    if (total < FDMIX_MIN_FDS) return null;
    const socketsPct = Math.round(100 * sockets / total);
    return {
      ...scored(socketsPct, FDMIX_SOCK_PCT_GOOD, FDMIX_SOCK_PCT_POOR),
      sockets, pipes, files, otherFds, socketsPct, scopeCode: 1,
      caption: `${sockets} sockets · ${files} files · ${pipes} pipes · ${otherFds} other`,
    };
  } catch { return null; }
}

function systemLoad(): ExtraAxis | null {
  try {
    if (uptime() < 60) return null;
    const load = loadavg()[0];
    const count = typeof availableParallelism === "function" ? availableParallelism() : cpus().length;
    if (!Number.isFinite(load) || count <= 0) return null;
    const loadPerCpu = r2(load / count);
    return {
      ...scored(loadPerCpu, SYSTEM_LOAD_GOOD, SYSTEM_LOAD_POOR),
      loadPerCpu, load: r2(load), cpus: count, scopeCode: 3,
      caption: `${loadPerCpu} load per CPU`,
    };
  } catch { return null; }
}

function takeStorageProbe(): void {
  const dir = process.env.BOOSTHIS_STATE_DIR;
  if (!dir) return;
  storageAttempts++;
  const path = join(dir, `.boosthis-storage-probe-${process.pid}`);
  const started = performance.now();
  let fd: number | undefined;
  try {
    fd = openSync(path, "w");
    writeFileSync(fd, "1");
    closeSync(fd); fd = undefined;
    readFileSync(path);
    unlinkSync(path);
    storageDurations.push(Math.max(0, performance.now() - started));
    if (storageDurations.length > STORAGE_RING_CAP) storageDurations.shift();
  } catch {
    storageFailures++;
    if (fd !== undefined) try { closeSync(fd); } catch { /* best effort */ }
    try { unlinkSync(path); } catch { /* best effort */ }
  }
}

function storagePair(): Record<string, ExtraAxis> {
  if (!process.env.BOOSTHIS_STATE_DIR || storageAttempts < STORAGE_MIN_OPERATIONS) return {};
  const scopeCode = hostVolumeScopeCode();
  const failPct = r1(100 * storageFailures / storageAttempts);
  const out: Record<string, ExtraAxis> = {
    storageFailures: {
      ...scored(failPct, STORAGE_FAILURE_GOOD_PCT, STORAGE_FAILURE_POOR_PCT),
      failPct, failCount: storageFailures, opCount: storageAttempts, scopeCode,
      caption: `${failPct}% failed`,
    },
  };
  if (storageDurations.length) {
    const sorted = [...storageDurations].sort((a, b) => a - b);
    const p75Ms = r1(sorted[Math.ceil(sorted.length * .75) - 1]);
    const worstMs = r1(sorted[sorted.length - 1]);
    out.storageLatency = {
      ...scored(p75Ms, STORAGE_LATENCY_GOOD_MS, STORAGE_LATENCY_POOR_MS),
      p75Ms, worstMs, opCount: storageAttempts, scopeCode,
      caption: `${p75Ms} ms p75`,
    };
  } else {
    out.storageLatency = {
      score: null, rating: "pending", present: 1, measurable: 0,
      reasonCode: 8, scopeCode,
    };
  }
  return out;
}

export function readHostResourceMeters(now = Date.now()): Record<string, ExtraAxis> {
  readCounters(now);
  takeStorageProbe();
  const out: Record<string, ExtraAxis> = { ...storagePair() };
  const put = (key: string, value: ExtraAxis | null): void => { if (value) out[key] = value; };
  put("diskPressure", diskPressure());
  put("ioPressure", ioPressure());
  put("pageFaults", pageFaults());
  put("descriptorMix", descriptorMix());
  put("systemLoad", systemLoad());
  return out;
}

export function clearHostResourceMeters(): void {
  samples = []; storageDurations = []; storageAttempts = 0; storageFailures = 0;
  containerCache = undefined;
}

/** @internal hermetic test hooks. */
export const _hostResourceInternals = {
  diskPressure,
  ioPressure,
  pageFaults,
  descriptorMix,
  systemLoad,
  storagePair,
  takeStorageProbe,
  setSamples(value: CounterSample[]): void { samples = value; },
  setStorage(attempts: number, failures: number, durations: number[]): void {
    storageAttempts = attempts;
    storageFailures = failures;
    storageDurations = durations.slice(-STORAGE_RING_CAP);
  },
};
