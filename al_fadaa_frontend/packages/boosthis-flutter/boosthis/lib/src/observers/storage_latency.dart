/// Boosthis: Storage Latency + Storage Failures axis sources (Flutter).
///
/// Two readings about the SAME observation point, because a slow store and a
/// failing store are different problems and one number cannot carry both:
///
///   • `storageLatency`  — p75 round-trip of the probe (how LONG it took).
///   • `storageFailures` — the share of probes that FAILED, separate from
///     their timing. A store that answers instantly and refuses every write
///     reads as perfectly healthy if only the speed is reported.
///
/// Both time the kit's OWN state-dir IO — a small write + read + delete of a
/// probe file inside `BOOSTHIS_STATE_DIR` (the same directory the store already
/// uses), never the host's files and never user data. The p75 round-trip
/// latency scores how responsive the device's storage is for the kind of tiny
/// persistence the kit itself does; the failure share scores how often that
/// same round trip does not complete at all.
///
/// The probe runs off the critical path (the adapter schedules [sampleStorage]
/// occasionally); it is fully guarded so a missing/unwritable filesystem simply
/// yields an honest not-measurable verdict, never a throw into the host and
/// never a UI-isolate block (the probe is async and bounded).
///
/// The shared rules both readings obey — observe-never-replace, record no keys
/// and no values, absent rather than zero, never a composite score, and which
/// bands belong to which observation point — are written down once in
/// docs/local-store-reading-contract.md and read back out of this file by
/// scripts/src/__tests__/local-store-reading-contract.test.ts. Change the
/// contract first; a number changed only here is reported as drift, by name.
///
/// HONESTY / INVARIANTS:
///   • NEVER feeds the composite Speed score. Display-only.
///   • NO STORE ⇒ NOTHING: when the host named no place for its own state
///     there is nothing to probe, so BOTH axes are absent — no key on the
///     payload at all. A declared silence would claim we looked at a store
///     this app does not have.
///   • DECLARED SILENCE is for a store that IS there and cannot be timed:
///     once the gate is met with no probe having completed, `storageLatency`
///     uploads { present: true, measurable: 0, reason: "..." } while
///     `storageFailures` reports the 100% that explains it.
///   • OMIT WHILE WARMING: fewer than 5 ATTEMPTED probes → null (warming).
///     One gate, counted once, for both readings — so a panel can never show
///     one of the pair warming and the other already scored.
///   • NUMERIC-ONLY: { score, rating, p75Ms, worstMs, samples } and
///     { score, rating, failPct, failCount, opCount }.
///   • Bands: linearScore(p75Ms, good=8, poor=120) — the `kit-probe-file`
///     observation point — and linearScore(failFraction, good=0.01, poor=0.1),
///     which is the SAME failure band every kit uses.
library;

import 'dart:io' show File, Directory;

import '../core/runtime_flags.dart' show RuntimeFlags;
import '../core/safe.dart' show Safe;
import '../core/store.dart' show Store;
import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// Probe round-trip latency bands (ms). <=8 ms → 100; >=120 ms → 0.
const int kStorageLatencyGoodMs = 8;
const int kStorageLatencyPoorMs = 120;

/// Failure-share bands (failed probes / attempted probes). <=1% is noise
/// (100); >=10% is a chronically failing store (0). The SAME band every kit
/// uses — a share needs no per-platform correction.
const double kStorageFailureGood = 0.01;
const double kStorageFailurePoor = 0.1;

/// Samples needed before the axis leaves "pending".
const int kStorageMinSamples = 5;

/// Bounded ring of probe latencies (ms).
const int kStorageRingCap = 200;

final List<int> _samples = <int>[];
int _worstMs = 0;

/// Probes that actually RAN (completed or threw). A probe never attempted —
/// because there is no state dir to probe — is NOT an attempt: no store is a
/// different answer from a store that failed, and counting it as a failure
/// would invent a 100% failure share for an app that has no local store at
/// all.
///
/// This is also the ONE warm-up gate. Both readings are released by the same
/// count of attempted probes, so the pair always answers together.
int _attempts = 0;

/// Attempted probes that did not complete.
int _failures = 0;

/// Where the kit's own state actually lives on THIS boot, or null when the
/// host named nowhere.
///
/// A normal Flutter app never sets `BOOSTHIS_STATE_DIR`: the adapter hands the
/// app's own documents/support directory to [Store.setHostAppPath] at boot, and
/// the store resolves its directory under that. Reading only the environment
/// flag therefore reported "no writable state dir" on every ordinary boot —
/// an absence the app had no way to fix, standing where a real reading should
/// be. So the probe asks the STORE where it resolved to.
///
/// When the host named nowhere the store falls back to a directory of the
/// kit's own choosing (the system temp dir). That is not the app's local
/// store, and timing it would be a reading about us rather than about them —
/// so there is nothing to probe and both readings stay honestly absent.
String? _probeDir() {
  final named = RuntimeFlags.stateDir ?? Store.hostAppPath;
  if (named == null || named.isEmpty) return null;
  final resolved = Safe.run<String?>(null, () => Store.dir());
  if (resolved == null || resolved.isEmpty) return null;
  return resolved;
}

/// Take one storage-latency sample: write → read → delete a tiny probe file in
/// the kit's state dir, timing the round trip. Async, bounded, NEVER throws,
/// never blocks the UI isolate. Call occasionally from the adapter.
Future<void> sampleStorage() async {
  final dirPath = _probeDir();
  if (dirPath == null || dirPath.isEmpty) {
    // NO STORE to probe: the host named nowhere for its own state, so there
    // is nothing here to be slow or to fail. NOTHING is recorded — not an
    // attempt, not a failure, and not a declared silence either. Both
    // readings stay absent, because "we looked and could not measure it" is
    // a claim about a store this app does not have.
    return;
  }
  _attempts += 1;
  try {
    final dir = Directory(dirPath);
    final probe = File('${dir.path}/.boosthis-io-probe');
    final sw = Stopwatch()..start();
    await probe.writeAsString('boosthis-probe', flush: true);
    await probe.readAsString();
    try {
      await probe.delete();
    } catch (_) {
      // best-effort cleanup — a stuck probe file must not fail the sample
    }
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    _samples.add(ms);
    if (_samples.length > kStorageRingCap) {
      _samples.removeRange(0, _samples.length - kStorageRingCap);
    }
    if (ms > _worstMs) _worstMs = ms;
  } catch (_) {
    // The probe RAN and did not complete: an attempted operation that failed,
    // which is exactly what storageFailures counts.
    _failures += 1;
    // best-effort — a probe failure must never reach the host
  }
}

int _p75(List<int> arr) {
  if (arr.isEmpty) return 0;
  final sorted = List<int>.from(arr)..sort();
  final idx = ((sorted.length - 1) * 0.75).floor();
  final clamped = idx < 0
      ? 0
      : idx > sorted.length - 1
      ? sorted.length - 1
      : idx;
  return sorted[clamped];
}

/// The Storage Latency axis. Pure read — never throws.
///   • no store to probe, or fewer than 5 attempted probes → null (ABSENT /
///     warming: no key on the payload),
///   • gate met but not one probe completed → { present, measurable: 0,
///     reason } (the store is there and cannot be timed; the tile explains
///     itself, and storageFailures carries the 100% that caused it),
///   • otherwise { score, rating, p75Ms, worstMs, samples } over the probes
///     that DID complete, with `samples` naming how many that was.
Map<String, Object?>? readStorageLatency() {
  try {
    // ONE gate for the pair: attempted probes, the same count
    // [readStorageFailures] uses.
    if (_attempts < kStorageMinSamples) {
      return null;
    }
    if (_samples.isEmpty) {
      return <String, Object?>{
        'present': true,
        'measurable': 0,
        'reason': 'no writable state dir for the IO probe',
        'scopeCode': 4,
      };
    }
    final n = _samples.length;
    final v = _p75(_samples);
    final score = linearScore(v, kStorageLatencyGoodMs, kStorageLatencyPoorMs);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'p75Ms': v,
      'worstMs': _worstMs,
      'samples': n,
      'scopeCode': 4,
    };
  } catch (_) {
    return <String, Object?>{
      'present': true,
      'measurable': 0,
      'reason': 'storage sampling failed',
      'scopeCode': 4,
    };
  }
}

/// The Storage Failures axis — the share of attempted probes that did not
/// complete. Pure read, never throws. Same observation point and the SAME
/// warm-up gate as [readStorageLatency] — one count of attempted probes,
/// released once — so the two readings always answer together and always
/// agree about how many operations they are talking about.
///   • no store to probe, or fewer than 5 attempted probes → null (ABSENT /
///     warming: no key on the payload),
///   • otherwise { score, rating, failPct, failCount, opCount }.
///
/// A store that is absent NEVER reads as "0% failed": that zero would be a
/// measurement of something nobody looked at.
Map<String, Object?>? readStorageFailures() {
  try {
    if (_attempts < kStorageMinSamples) {
      return null;
    }
    final frac = _failures / _attempts;
    final score = linearScore(frac, kStorageFailureGood, kStorageFailurePoor);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'failPct': (frac * 1000).round() / 10,
      'failCount': _failures,
      'opCount': _attempts,
      'scopeCode': 4,
    };
  } catch (_) {
    return <String, Object?>{
      'present': true,
      'measurable': 0,
      'reason': 'storage sampling failed',
      'scopeCode': 4,
    };
  }
}

/// Clear all samples (telemetry.forget() hook + tests).
void resetStorageLatency() {
  _samples.clear();
  _worstMs = 0;
  _attempts = 0;
  _failures = 0;
}

/// Test hooks — deterministic, no dependence on a real filesystem.
class StorageLatencyInternals {
  static int get sampleCount => _samples.length;
  static bool get everReadable => _samples.isNotEmpty;
  static int get attemptCount => _attempts;
  static int get failureCount => _failures;

  static void pushSampleForTests(int ms) {
    _attempts += 1;
    _samples.add(ms);
    if (ms > _worstMs) _worstMs = ms;
    if (_samples.length > kStorageRingCap) {
      _samples.removeRange(0, _samples.length - kStorageRingCap);
    }
  }

  /// Record one attempted probe that did not complete (the "fast and broken"
  /// store: an attempt, a failure, and no timing to add to the ring).
  static void pushFailureForTests() {
    _attempts += 1;
    _failures += 1;
  }

  static void reset() => resetStorageLatency();
}
