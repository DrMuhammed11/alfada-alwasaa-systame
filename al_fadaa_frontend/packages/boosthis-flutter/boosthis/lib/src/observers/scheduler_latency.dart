/// Boosthis: Scheduler Latency axis source (Flutter) — the reused
/// `schedulerLatency` axis.
///
/// Event-loop lag, measured HONESTLY: a low-frequency periodic `Timer` is
/// scheduled at a fixed interval and we compare when it ACTUALLY fires against
/// when it was DUE (a monotonic `Stopwatch`). The drift = actual − expected is
/// the time the main isolate's event loop kept the callback waiting — a direct
/// event-loop-lag signal the RN kit can only approximate. The axis reports the
/// p75 drift across ticks.
///
/// This is a pure-Dart meter (`dart:async` only) and OWNS its one timer, so it
/// works with no host cooperation. The timer is low-frequency (2s) and single;
/// it never keeps the app awake beyond what the app already does and is
/// cancelled on teardown. Every tick is guarded.
///
/// HONESTY / INVARIANTS:
///   • NEVER feeds the composite Speed score. Display-only.
///   • OMIT WHILE WARMING: readSchedulerLatency() returns null until >= 5 ticks.
///   • NUMERIC-ONLY: { score, rating, p75Ms, worstMs, ticks }.
///   • Bands: linearScore(p75Ms, good=16, poor=200) — <=16 ms drift is a
///     healthy event loop (one frame); >=200 ms means the loop is badly backed
///     up.
library;

import 'dart:async' show Timer, unawaited;

import '../meters/meter_axes.dart' show linearScore, ratingFor;
import 'cpu_scheduling.dart'
    show noteCpuSchedulingTick, resetCpuScheduling, sampleCpuScheduling;

/// Event-loop drift bands (ms). <=16 ms → 100; >=200 ms → 0.
const int kSchedulerLatencyGoodMs = 16;
const int kSchedulerLatencyPoorMs = 200;

/// Ticks needed before the axis leaves "pending".
const int kSchedulerMinTicks = 5;

/// Fixed sampling interval (ms). Low-frequency so the meter is near-free.
const int kSchedulerIntervalMs = 2000;

/// Bounded ring of drift samples (ms).
const int kSchedulerRingCap = 300;

Timer? _timer;
Stopwatch? _stopwatch;
int _expectedElapsedMs = 0;
final List<int> _drifts = <int>[];
int _worstMs = 0;

/// Start the scheduler-latency probe. Idempotent, best-effort, NEVER throws.
/// Owns ONE low-frequency periodic timer. Call from telemetry start.
void installSchedulerLatencyTracking() {
  if (_timer != null) return;
  try {
    _stopwatch = Stopwatch()..start();
    _expectedElapsedMs = 0;
    _timer = Timer.periodic(
        const Duration(milliseconds: kSchedulerIntervalMs), _onTick);
  } catch (_) {
    // Wiring failed — stay off; the axis reads warming/pending.
    _timer = null;
    _stopwatch = null;
  }
}

void _onTick(Timer _) {
  try {
    final sw = _stopwatch;
    if (sw == null) return;
    _expectedElapsedMs += kSchedulerIntervalMs;
    final actual = sw.elapsedMilliseconds;
    var drift = actual - _expectedElapsedMs;
    // A negative drift (timer fired slightly early) is not lag — floor at 0.
    if (drift < 0) drift = 0;
    // Processor/thread facts and blockingAsync ride this EXISTING tick. The
    // procfs reads are asynchronous and no second sampler timer is started.
    noteCpuSchedulingTick(actual, drift);
    unawaited(sampleCpuScheduling(actual));
    _drifts.add(drift);
    if (_drifts.length > kSchedulerRingCap) {
      _drifts.removeRange(0, _drifts.length - kSchedulerRingCap);
    }
    if (drift > _worstMs) _worstMs = drift;
  } catch (_) {
    // best-effort — a tick slip must never reach the host
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

/// The Scheduler Latency axis, or a pending reading while warming (<5 ticks).
/// Pure read — never mutates state, NEVER throws. Numbers-only wire shape.
Map<String, Object?> readSchedulerLatency() {
  try {
    final ticks = _drifts.length;
    if (ticks < kSchedulerMinTicks) {
      return <String, Object?>{
        'score': null,
        'rating': 'pending',
        'p75Ms': null,
        'worstMs': _worstMs,
        'ticks': ticks,
      };
    }
    final v = _p75(_drifts);
    final score =
        linearScore(v, kSchedulerLatencyGoodMs, kSchedulerLatencyPoorMs);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'p75Ms': v,
      'worstMs': _worstMs,
      'ticks': ticks,
    };
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'p75Ms': null,
      'worstMs': 0,
      'ticks': 0,
    };
  }
}

/// Stop the probe and drop all state. Idempotent, NEVER throws. Wired into
/// telemetry.forget().
void uninstallSchedulerLatencyTracking() {
  try {
    _timer?.cancel();
  } catch (_) {
    // best-effort — never throw on teardown
  }
  _timer = null;
  try {
    _stopwatch?.stop();
  } catch (_) {
    // best-effort
  }
  _stopwatch = null;
  _expectedElapsedMs = 0;
  _drifts.clear();
  _worstMs = 0;
  resetCpuScheduling();
}

/// Test hooks — deterministic, no dependence on a real timer.
class SchedulerLatencyInternals {
  static bool get isInstalled => _timer != null;
  static int get tickCount => _drifts.length;
  static int get monotonicElapsedMs => _stopwatch?.elapsedMilliseconds ?? 0;

  /// Push synthetic drift samples (ms) without a real timer.
  static void fireForTests(List<int> driftsMs) {
    for (final d in driftsMs) {
      _drifts.add(d);
      if (d > _worstMs) _worstMs = d;
      if (_drifts.length > kSchedulerRingCap) {
        _drifts.removeRange(0, _drifts.length - kSchedulerRingCap);
      }
    }
  }

  static void reset() => uninstallSchedulerLatencyTracking();
}
