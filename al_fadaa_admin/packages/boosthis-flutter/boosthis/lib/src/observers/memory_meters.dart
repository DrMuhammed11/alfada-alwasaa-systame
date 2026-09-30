/// Boosthis: Memory Stability axis source (Flutter).
///
/// The reused `memoryStability` axis. Flutter's honest substitute for the
/// GC/heap axes (the VM Service — and thus the allocation profile — is compiled
/// OUT of release builds) is the process RSS trend and peak, read from
/// `dart:io`'s `ProcessInfo.currentRss` / `ProcessInfo.maxRss`.
///
/// This module SAMPLES RSS itself (a cheap, non-blocking read) each time the
/// meters snapshot is built, keeping a bounded ring of readings. It scores the
/// RSS TREND (growth from the first to the recent samples): a stable app holds
/// roughly flat RSS; a leaking app trends steadily upward. peakMB is the
/// high-water mark from maxRss.
///
/// HONESTY / INVARIANTS:
///   • NEVER feeds the composite Speed score. Display-only.
///   • HONESTLY ABSENT where unavailable: on a platform where ProcessInfo
///     returns 0 (unsupported), the axis is uploaded as
///     { present: true, measurable: 0, reason: "..." } so the tile explains
///     itself instead of warming forever (the RN release-build Profiler
///     precedent). It is NOT a warming null and NOT a fake score.
///   • OMIT WHILE WARMING until 12 post-startup samples span five minutes.
///   • Bands: linearScore(growthMbPerMin, good=2, poor=25).
library;

import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// RSS growth-trend bands (megabytes per minute).
const double kMemoryTrendGoodMbPerMin = 2;
const double kMemoryTrendPoorMbPerMin = 25;

/// Samples needed before the trend axis leaves "pending".
const int kMemoryMinSamples = 12;
const int kMemoryMinSpanMs = 300000;
const int kMemoryStartupDropMs = 60000;
const int kMemoryBucketMs = 30000;
const double kMemoryRiseFloorMb = 1;

/// Bounded ring of (epoch-ms, rssBytes) samples.
const int kMemoryRingCap = 240;

final List<int> _sampleTimes = <int>[];
final List<int> _sampleRss = <int>[];
int _peakBytes = 0;
bool _everReadable = false;

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Read the process RSS safely. Returns 0 when unavailable (unsupported
/// platform or a throwing ProcessInfo). Never throws.
int _readRss() {
  try {
    final rss = ProcessInfo.currentRss;
    return rss > 0 ? rss : 0;
  } catch (_) {
    return 0;
  }
}

int _readMaxRss() {
  try {
    final m = ProcessInfo.maxRss;
    return m > 0 ? m : 0;
  } catch (_) {
    return 0;
  }
}

/// Take one RSS sample. Best-effort, NEVER throws. Call each time the meters
/// snapshot is built. A zero read means RSS is unsupported on this platform;
/// [_everReadable] stays false so the axis reports honest not-measurable.
void sampleMemory() {
  try {
    final rss = _readRss();
    if (rss <= 0) return; // unsupported — never recorded as a fake 0
    _everReadable = true;
    _sampleTimes.add(_nowMs());
    _sampleRss.add(rss);
    if (_sampleTimes.length > kMemoryRingCap) {
      _sampleTimes.removeRange(0, _sampleTimes.length - kMemoryRingCap);
      _sampleRss.removeRange(0, _sampleRss.length - kMemoryRingCap);
    }
    final maxRss = _readMaxRss();
    final peak = maxRss > rss ? maxRss : rss;
    if (peak > _peakBytes) _peakBytes = peak;
  } catch (_) {
    // best-effort
  }
}

/// The Memory Stability axis. Pure read — never mutates state, NEVER throws.
///   • RSS never readable → { present: true, measurable: 0, reason: ... }
///     (the tile explains itself instead of warming forever),
///   • warming evidence floor → null,
///   • otherwise the contract §3.2 trend wire shape.
Map<String, Object?>? readMemoryStability() {
  try {
    // Probe once so a caller that never called sampleMemory() still gets an
    // honest not-measurable verdict rather than a false warming state.
    if (!_everReadable && _readRss() <= 0) {
      return <String, Object?>{
        'present': true,
        'measurable': 0,
        'reason': 'ProcessInfo RSS not available on this platform',
      };
    }
    if (_sampleRss.isEmpty) {
      return null;
    }
    final cutoff = _sampleTimes.first + kMemoryStartupDropMs;
    final points = <List<double>>[];
    for (var i = 0; i < _sampleRss.length; i++) {
      if (_sampleTimes[i] < cutoff) continue;
      final bucket = ((_sampleTimes[i] - cutoff) ~/ kMemoryBucketMs).toDouble();
      final mb = _sampleRss[i] / (1024 * 1024);
      if (points.isEmpty || points.last[0] != bucket) {
        points.add(<double>[_sampleTimes[i].toDouble(), mb]);
      } else if (mb < points.last[1]) {
        points.last[0] = _sampleTimes[i].toDouble();
        points.last[1] = mb;
      }
    }
    if (points.length < 2) return null;
    final sampleCount = _sampleTimes
        .where((int at) => at >= cutoff)
        .length;
    final spanMs = points.last[0] - points.first[0];
    if (sampleCount < kMemoryMinSamples || spanMs < kMemoryMinSpanMs) return null;
    final fit = _fit(points);
    final growth = fit[0];
    final se = fit[1];
    final windowMin = spanMs / 60000;
    final abstain = growth.abs() <= se;
    final materialGrowth =
        growth > 0 && growth * windowMin >= kMemoryRiseFloorMb ? growth : 0.0;
    final score = abstain
        ? null
        : linearScore(materialGrowth, kMemoryTrendGoodMbPerMin,
            kMemoryTrendPoorMbPerMin);
    return <String, Object?>{
      if (score != null) 'score': score,
      'rating': abstain ? 'not-scored' : ratingFor(score!),
      'growthMbPerMin': (growth * 10).round() / 10,
      'slopeSeMbPerMin': (se * 100).round() / 100,
      'sampleCount': sampleCount,
      'windowMin': (windowMin * 10).round() / 10,
    };
  } catch (_) {
    return <String, Object?>{
      'present': true,
      'measurable': 0,
      'reason': 'memory sampling failed',
    };
  }
}

/// Kernel-kept process high-water mark. ProcessInfo.maxRss is exact, so this
/// raw, deliberately unscored reading always carries sampleCount=1/exact=1.
Map<String, Object?>? readPeakRss() {
  try {
    final peak = _readMaxRss();
    final rss = _readRss();
    if (peak <= 0 || rss <= 0) return null;
    return <String, Object?>{
      'peakRssMb': (peak / (1024 * 1024) * 10).round() / 10,
      'rssMb': (rss / (1024 * 1024) * 10).round() / 10,
      'sampleCount': 1,
      'exact': 1,
    };
  } catch (_) {
    return null;
  }
}

List<double> _fit(List<List<double>> points) {
  final t0 = points.first[0];
  final xs = points.map((p) => (p[0] - t0) / 60000).toList();
  final ys = points.map((p) => p[1]).toList();
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = ys.reduce((a, b) => a + b) / ys.length;
  var sxx = 0.0, sxy = 0.0;
  for (var i = 0; i < xs.length; i++) {
    sxx += (xs[i] - mx) * (xs[i] - mx);
    sxy += (xs[i] - mx) * (ys[i] - my);
  }
  final slope = sxx == 0 ? 0.0 : sxy / sxx;
  var residual = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final predicted = my + slope * (xs[i] - mx);
    residual += (ys[i] - predicted) * (ys[i] - predicted);
  }
  final se = xs.length > 2 && sxx > 0
      ? math.sqrt(residual / (xs.length - 2) / sxx)
      : 0.0;
  return <double>[slope, se];
}

/// Clear all samples (telemetry.forget() hook + tests).
void resetMemoryMeters() {
  _sampleTimes.clear();
  _sampleRss.clear();
  _peakBytes = 0;
  _everReadable = false;
}

/// Test hooks — deterministic, no dependence on real ProcessInfo.
class MemoryInternals {
  static int get sampleCount => _sampleRss.length;
  static bool get everReadable => _everReadable;

  /// Push a synthetic (epoch-ms, rssBytes) sample, bypassing the real RSS read.
  static void pushSampleForTests(int atMs, int rssBytes) {
    _everReadable = true;
    _sampleTimes.add(atMs);
    _sampleRss.add(rssBytes);
    if (rssBytes > _peakBytes) _peakBytes = rssBytes;
    if (_sampleTimes.length > kMemoryRingCap) {
      _sampleTimes.removeRange(0, _sampleTimes.length - kMemoryRingCap);
      _sampleRss.removeRange(0, _sampleRss.length - kMemoryRingCap);
    }
  }

  static void reset() => resetMemoryMeters();
}
