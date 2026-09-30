/// Runtime-vitals axes (Flutter) — a display-only, additive port of the sibling
/// runtime-vitals meters, keeping ONLY the axes a Flutter app can honestly
/// measure with `dart:` sources.
///
/// SOURCE ON FLUTTER. A device app has no /proc, no cgroup, no load average and
/// no VM Service in release. What `dart:io` DOES expose, in a release build,
/// with no host cooperation, is `ProcessInfo.currentRss` / `maxRss` — the
/// whole-process resident set as the OS sees it. That powers the one honest
/// vital a device runtime can report:
///   - residentGrowth: the slope of whole-process RSS (MB/min) — a native leak
///     the Dart heap alone cannot see (platform textures, native plugins,
///     mmapped assets all count and nothing GCs them back).
///
/// The KEY, field shape, bands and gates are byte-parity with the sibling
/// residentGrowth axis (RSS_GROWTH_GOOD 0.5 / RSS_GROWTH_POOR 5.0, >=12 samples
/// spanning >=300s), so the dashboard renders one shared gauge.
///
/// DELIBERATELY NOT PORTED — no honest Flutter/`dart:` equivalent:
///   - processCpuLoad: `dart:io` exposes no per-process CPU-time clock in a
///     release build (no getrusage, no CLOCK_PROCESS_CPUTIME_ID access), so the
///     process's CPU share cannot be measured. Cannot know → OMITTED.
///   - systemLoad: no load-average source on iOS/Android from pure Dart.
///     Cannot know → OMITTED.
///   - containerPressure: a device app is not in a cgroup; there is no
///     container OOM wall to sit under. Not applicable → OMITTED.
///
/// HONESTY. residentGrowth self-gates on its own evidence floor and is ABSENT
/// (warming) until met — never a fabricated 0/100. ADDITIVE + display-only:
/// nothing here feeds the composite Speed score. GUEST-SAFE: `dart:io` reads
/// are guarded and any failure degrades to an absent axis.
library;

import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import '../core/runtime_flags.dart';
import '../core/safe.dart';
import '../core/score.dart';
import '../core/store.dart';
import '../core/telemetry.dart';

/// Runtime vitals collector (static, one per isolate).
class RuntimeVitals {
  RuntimeVitals._();

  // ── residentGrowth bands (byte-parity with the siblings) ────────────────────
  static const double _rssGrowthGood = 0.5;
  static const double _rssGrowthPoor = 5.0;
  static const int _minRssSamples = 12;
  static const int _minRssSpanMs = 300000;
  static const int _startupDropMs = 60000;
  static const int _lowWaterBucketMs = 30000;
  static const double _riseFloorMb = 1.0;

  /// Throw away a sample landing within this window of the previous one so a
  /// frame burst cannot flood the ring. (Sibling SAMPLE_THROTTLE_MS.)
  static const int _sampleThrottleMs = 1000;

  /// Bounded ring — 300s / 1s of RSS history fits comfortably. (Sibling RING_CAP.)
  static const int _ringCap = 720;

  static const double _bytesPerMb = 1048576.0;
  static const String _storeKey = 'vitals:samples';

  /// Record ONE process-vitals sample into Store. Called once per activity
  /// boundary (the device analogue of the request-boundary sampler). Guest-safe:
  /// no-op under the kill-switch, never throws, throttled. Mirrors Ruby `sample`.
  static void sample() {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      final now = Telemetry.nowMs();
      final rssBytes = _readRssBytes();

      Store.update(_storeKey, (cur) {
        final ring = <Object?>[];
        if (cur is List) ring.addAll(cur);
        final last = ring.isNotEmpty ? ring[ring.length - 1] : null;
        if (last is Map && last['at'] != null &&
            now - _asInt(last['at']) < _sampleThrottleMs) {
          return ring; // throttled: keep the ring untouched
        }
        final entry = <String, Object?>{'at': now};
        if (rssBytes != null) entry['rssBytes'] = rssBytes;
        ring.add(entry);
        while (ring.length > _ringCap) {
          ring.removeAt(0);
        }
        return ring;
      });
    });
  }

  /// Attach every currently-measurable runtime-vital to [axes]. A warming-up or
  /// unmeasurable axis is OMITTED. Guest-safe. Mirrors Ruby `add_vitals`.
  static void addVitals(Map<String, Object?> axes) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      final ring = _ring();
      final rg = _residentGrowth(ring);
      if (rg != null) axes['residentGrowth'] = rg;
    });
  }

  /// residentGrowth — the slope of the WHOLE process's resident memory (MB/min)
  /// as the OS sees it. Absent until >=12 samples span >=300s, and permanently
  /// absent where RSS is unreadable. Carries its sample/window evidence and the
  /// fit's standard error; score is withheld when the fit has no direction.
  static Map<String, Object?>? _residentGrowth(List<Object?> ring) {
    final rss = <Map<String, double>>[];
    for (final s in ring) {
      if (s is! Map) continue;
      if (s['rssBytes'] == null || s['at'] == null) continue;
      rss.add(<String, double>{
        'at': _asInt(s['at']).toDouble(),
        'mb': _asInt(s['rssBytes']) / _bytesPerMb,
      });
    }
    if (rss.isEmpty) return null;
    final cutoff = rss.first['at']! + _startupDropMs;
    final judged = rss.where((s) => s['at']! >= cutoff).toList();
    if (judged.length < _minRssSamples) return null;
    final lows = <Map<String, double>>[];
    for (final sample in judged) {
      final bucket = ((sample['at']! - cutoff) ~/ _lowWaterBucketMs).toDouble();
      if (lows.isEmpty || lows.last['bucket'] != bucket) {
        lows.add({...sample, 'bucket': bucket});
      } else if (sample['mb']! < lows.last['mb']!) {
        lows[lows.length - 1] = {...sample, 'bucket': bucket};
      }
    }
    if (lows.length < 2) return null;
    final spanMs = lows.last['at']! - lows.first['at']!;
    if (spanMs < _minRssSpanMs) return null;
    final fit = _slopeAndSe(lows);
    final growth = fit[0];
    final se = fit[1];
    final windowMin = spanMs / 60000;
    final abstain = growth.abs() <= se;
    final scoreGrowth =
        growth > 0 && growth * windowMin >= _riseFloorMb ? growth : 0.0;
    final score = abstain
        ? null
        : Score.scoreMetric(scoreGrowth, _rssGrowthGood, _rssGrowthPoor);
    return <String, Object?>{
      if (score != null) 'score': score,
      'rating': abstain ? 'not-scored' : Score.getRating(score!),
      'growthMbPerMin': _r1(growth),
      'slopeSeMbPerMin': (se * 100).round() / 100,
      'sampleCount': judged.length,
      'windowMin': _r1(windowMin),
    };
  }

  /// Whole-process resident set size in bytes, or null when unavailable.
  /// `ProcessInfo.currentRss` throws on platforms that cannot report it (e.g.
  /// web), so it is guarded.
  static int? _readRssBytes() {
    return Safe.run<int?>(null, () {
      final rss = ProcessInfo.currentRss;
      return rss > 0 ? rss : null;
    });
  }

  static List<Object?> _ring() {
    return Safe.run(<Object?>[], () {
      final r = Store.get(_storeKey, const <Object?>[]);
      return r is List ? r : <Object?>[];
    });
  }

  // ── Helpers (numeric formatting ported byte-for-byte from the siblings) ─────

  /// Least-squares slope of MB over minutes for {at(ms), mb} points.
  static double _slopePerMin(List<Map<String, double>> samples) {
    final n = samples.length;
    if (n < 2) return 0.0;
    final t0 = samples.first['at']!;
    var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
    for (final s in samples) {
      final x = (s['at']! - t0) / 60000.0;
      final y = s['mb']!;
      sx += x;
      sy += y;
      sxx += x * x;
      sxy += x * y;
    }
    final denom = n * sxx - sx * sx;
    if (denom == 0) return 0.0;
    return (n * sxy - sx * sy) / denom;
  }

  static List<double> _slopeAndSe(List<Map<String, double>> samples) {
    final slope = _slopePerMin(samples);
    final t0 = samples.first['at']!;
    final xs = samples.map((s) => (s['at']! - t0) / 60000).toList();
    final ys = samples.map((s) => s['mb']!).toList();
    final mx = xs.reduce((a, b) => a + b) / xs.length;
    final my = ys.reduce((a, b) => a + b) / ys.length;
    var sxx = 0.0, residual = 0.0;
    for (var i = 0; i < xs.length; i++) {
      sxx += (xs[i] - mx) * (xs[i] - mx);
      final predicted = my + slope * (xs[i] - mx);
      residual += (ys[i] - predicted) * (ys[i] - predicted);
    }
    final se = samples.length > 2 && sxx > 0
        ? math.sqrt(residual / (samples.length - 2) / sxx)
        : 0.0;
    return <double>[slope, se];
  }

  static Object _r1(num n) {
    final v = (n * 10).round() / 10.0;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return 0;
  }
}
