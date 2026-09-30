/// Boosthis meter axes — ADDITIVE on-device perf signals (Flutter kit).
///
/// Ported from the React Native kit's `meterAxes.ts`. These axes ENRICH the
/// dashboard without ever touching the shared composite Speed score
/// (TTFF·0.25 + TTI·0.45 + FID·0.30, defined in `thresholds.dart`) — that stays
/// byte-identical to every sibling runtime. Everything here lives in its OWN
/// module with its OWN thresholds, stays on the device, and never alters or
/// replaces the speed score.
///
/// This file owns the SHARED axis primitives the meters/observers groups all
/// import (`linearScore`, `ratingFor`, [AxisRating]) plus the pure-math axis
/// computations over pure-Dart structs ([RouteSeries], [NetworkStats],
/// [FrameSpanSample]). No `package:flutter` import — pure `dart:` only.
///
/// GUEST-SAFE: every public entry point is Safe-wrapped, so a bug degrades to a
/// pending axis, never a throw into the host UI isolate.
library;

import 'dart:math' as math;

import '../core/safe.dart';
import '../core/inverted_axis_band_error.dart';
export '../core/inverted_axis_band_error.dart';
import 'flutter_meters.dart' show FlutterMeters;
import 'suspend_sensor.dart' show SuspendSensor;

// ─── Rating bands (shared, string-valued so the wire keys stay byte-identical
//     to every sibling kit) ──────────────────────────────────────────────────

/// The Lighthouse-style axis rating buckets, as the exact STRING values every
/// sibling runtime emits on the wire. Kept as a class of `String` constants
/// (not an `enum`) so an axis map's `rating` field is a plain wire string.
///
/// (RN `AxisRating = "good" | "needs-work" | "poor" | "pending"`.)
class AxisRating {
  AxisRating._();
  static const String good = 'good';
  static const String needsWork = 'needs-work';
  static const String poor = 'poor';
  static const String pending = 'pending';

  /// A real measurement that carries NO verdict, because the thing measured is
  /// not something the app's author can change (see
  /// docs/decisions/meter-verdicts-that-are-not-about-the-app.md). Distinct
  /// from [pending], which promises a verdict later.
  static const String notScored = 'not-scored';
}

/// Warming gate shared by every axis: an axis with fewer than this many samples
/// is ABSENT, never zero. FROZEN across all kits.
/// (RN `MIN_SAMPLES_FOR_AXES` / `CONFIDENCE_CUTOFFS.medium`.)
const int kMinSamplesForAxes = 5;

/// A band is a pair of constants in our source: [good] assigns 100 and [poor]
/// assigns 0, with linear interpolation between. Equal, reversed or non-finite
/// ends are our typo, never the customer's app. This used to silently answer
/// 100 and hide a backwards meter behind a perfect verdict. The throw is the
/// BACKSTOP: scripts' axis-band-inversion gate reads declared constants out
/// of every shipped kit and fails the release before an inverted pair reaches
/// anybody.
int linearScore(num value, num good, num poor) {
  if (!good.isFinite || !poor.isFinite || poor <= good) {
    throw InvertedAxisBandError(good, poor);
  }
  if (value <= good) return 100;
  if (value >= poor) return 0;
  return (100 * (1 - (value - good) / (poor - good))).round();
}

/// Map a 0-100 axis score onto the shared rating bands.
/// (RN `ratingFor`: good >= 85, needs-work >= 60, else poor.)
String ratingFor(num score) {
  if (score >= 85) return AxisRating.good;
  if (score >= 60) return AxisRating.needsWork;
  return AxisRating.poor;
}

// ─── Percentile helpers (the FROZEN index policies) ───────────────────────────

/// Percentile FLOOR rule: `idx = min(len - 1, (len * p).floor())` on a sorted
/// copy. Returns 0 for an empty list. Never mutates the input. FROZEN —
/// byte-identical to every other kit's sampler.
int percentileFloor(List<int> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = List<int>.from(values)..sort();
  final len = sorted.length;
  var idx = (len * p).floor();
  if (idx > len - 1) idx = len - 1;
  if (idx < 0) idx = 0;
  return sorted[idx];
}

/// Percentile CEIL rule: `idx = (len * q).ceil() - 1` on a sorted copy, clamped
/// into range. Used by the resilience tail. Returns 0 for an empty list, never
/// mutates the input.
int percentileCeil(List<int> values, double q) {
  if (values.isEmpty) return 0;
  final sorted = List<int>.from(values)..sort();
  final len = sorted.length;
  var idx = (len * q).ceil() - 1;
  if (idx > len - 1) idx = len - 1;
  if (idx < 0) idx = 0;
  return sorted[idx];
}

/// The median of a list as a double: 0.0 for an empty list, the average of the
/// two middle elements for an even length, the middle element for an odd one.
/// Never mutates the input.
double median(List<int> values) {
  if (values.isEmpty) return 0.0;
  final sorted = List<int>.from(values)..sort();
  final len = sorted.length;
  final mid = len ~/ 2;
  if (len.isOdd) return sorted[mid].toDouble();
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

/// Round a number to at most one decimal, collapsing a whole value to an int so
/// the wire carries `100` not `100.0`.
Object _r1(num n) {
  final v = (n * 10).round() / 10.0;
  return v == v.roundToDouble() ? v.toInt() : v;
}

// ─── Confidence (sample count) ────────────────────────────────────────────────

/// How much data backs the numbers, so one lucky fast/slow sample isn't
/// mistaken for a trend. (RN `CONFIDENCE_CUTOFFS = { medium: 5, high: 20 }`.)
String confidenceLevel(int sampleCount) {
  if (sampleCount <= 0) return 'none';
  if (sampleCount < kMinSamplesForAxes) return 'low';
  if (sampleCount < 20) return 'medium';
  return 'high';
}

/// Pre-derived rating for the confidence axis on the shared bands.
String confidenceRatingFor(String level) {
  switch (level) {
    case 'high':
      return AxisRating.good;
    case 'medium':
      return AxisRating.needsWork;
    case 'low':
      return AxisRating.poor;
    default:
      return AxisRating.pending;
  }
}

/// Human caption for the confidence axis, shared by every consumer so the copy
/// can't drift between the device panel and the web mirror.
String confidenceCaptionFor(String level) {
  switch (level) {
    case 'high':
      return 'well-sampled';
    case 'medium':
      return 'moderate samples';
    case 'low':
      return 'few samples';
    default:
      return 'no samples yet';
  }
}

/// A route's ordered durations (ms), oldest-first — the pure-Dart struct the
/// route-based axes consume. LABEL-FREE: only numbers ever reach this layer.
class RouteSeries {
  RouteSeries(this.durations);

  /// Completed measurement durations (ms) for one route, oldest-first.
  final List<int> durations;

  int get sampleCount => durations.length;
}

/// How many samples back the LEAST-sampled SCORABLE route — the weakest
/// contributor to the averaged headline. Only routes with at least
/// [kMinSamplesForAxes] samples count; returns 0 when none is scorable yet.
/// (RN `leastScorableMounts`, keyed off the minimum not the total.)
int leastScoredRouteMounts(List<RouteSeries> series) {
  return Safe.run<int>(0, () {
    final scorable = series
        .where((s) => s.sampleCount >= kMinSamplesForAxes)
        .map((s) => s.sampleCount)
        .toList();
    if (scorable.isEmpty) return 0;
    return scorable.reduce(math.min);
  });
}

// ─── Budget compliance (baseline 20 / recent 20, 1.5×) ────────────────────────

/// Minimum samples on a route before it is scorable for the budget axis.
const int _kBudgetMinSamples = 20;

/// A route is over budget when its recent median regresses past this multiple
/// of its baseline median.
const double _kBudgetRegressFactor = 1.5;

/// Share of scorable routes still on budget. Returns null while no route has
/// warmed up ([_kBudgetMinSamples] samples). Closed wire map otherwise:
/// score, rating, onBudget, total, pct.
Map<String, Object?>? computeBudget(List<RouteSeries> series) {
  return Safe.run<Map<String, Object?>?>(null, () {
    final scorable =
        series.where((s) => s.sampleCount >= _kBudgetMinSamples).toList();
    if (scorable.isEmpty) return null;

    var onBudget = 0;
    for (final s in scorable) {
      final d = s.durations;
      final baseline = median(d.sublist(0, _kBudgetMinSamples));
      final recent = median(d.sublist(d.length - _kBudgetMinSamples));
      if (baseline <= 0 || recent < baseline * _kBudgetRegressFactor) {
        onBudget += 1;
      }
    }
    final total = scorable.length;
    final pct = ((onBudget / total) * 100).round();
    return <String, Object?>{
      'score': pct,
      'rating': ratingFor(pct),
      'onBudget': onBudget,
      'total': total,
      'pct': pct,
    };
  });
}

// ─── Baseline anomaly (min 6, recent 3, good 1.2 poor 2.0, min delta 50ms) ────

const int _kBaselineMinSamples = 6;
const int _kBaselineRecent = 3;
const double _kBaselineGoodRatio = 1.2;
const double _kBaselinePoorRatio = 2.0;

/// A regression under this many ms is noise, never an anomaly (a slow route
/// that goes 10ms → 25ms has doubled but is imperceptible).
const int _kBaselineMinDeltaMs = 50;

/// Per-route regression detector. Returns null while no route has warmed up
/// ([_kBaselineMinSamples] samples). Closed wire map otherwise: score, rating,
/// anomalyCount, worstRatio, scoredRoutes, unscoredRoutes, measurable.
///
/// `scoredRoutes` is NOT decoration: with no anomaly to report the dashboard
/// captions this tile "<scoredRoutes> screens steady", so omitting it makes a
/// healthy app read "0 screens steady" — a claim the kit never measured. It
/// counts routes that COMPLETED a comparison: a route whose earlier window is
/// too fast to divide by is counted in `unscoredRoutes` instead, and when that
/// leaves nothing compared the map abstains (`measurable` 0, rating "pending")
/// rather than scoring 100.
Map<String, Object?>? computeBaselineScore(List<RouteSeries> series) {
  return Safe.run<Map<String, Object?>?>(null, () {
    final scorable =
        series.where((s) => s.sampleCount >= _kBaselineMinSamples).toList();
    if (scorable.isEmpty) return null;

    var anomalyCount = 0;
    var scoredRoutes = 0;
    var unscoredRoutes = 0;
    var worstRatio = 1.0;
    for (final s in scorable) {
      final d = s.durations;
      final baseline = median(d.sublist(0, d.length - _kBaselineRecent));
      final recent = median(d.sublist(d.length - _kBaselineRecent));
      // A sub-millisecond route records every duration as 0 (whole-ms capture),
      // so its earlier window medians to 0 and there is no ratio to take.
      // Reading that as ratio 1.0 (steady) is what let a hundred-fold
      // regression on a fast route report good — abstain and SAY SO.
      if (baseline <= 0) {
        unscoredRoutes += 1;
        continue;
      }
      scoredRoutes += 1;
      final delta = recent - baseline;
      final ratio = recent / baseline;
      // A high ratio with an imperceptible absolute delta is not an anomaly.
      final effectiveRatio =
          (delta >= _kBaselineMinDeltaMs && ratio > 1.0) ? ratio : 1.0;
      if (effectiveRatio >= _kBaselineGoodRatio) anomalyCount += 1;
      if (effectiveRatio > worstRatio) worstRatio = effectiveRatio;
    }
    if (scoredRoutes == 0) {
      // Nothing was compared: abstain rather than report a perfect score. Still
      // emitted — omitting it would read as "warming up" forever.
      return <String, Object?>{
        'score': null,
        'rating': 'pending',
        'anomalyCount': 0,
        'worstRatio': _r1(1.0),
        'scoredRoutes': 0,
        'unscoredRoutes': unscoredRoutes,
        'measurable': 0,
      };
    }
    final score =
        linearScore(worstRatio, _kBaselineGoodRatio, _kBaselinePoorRatio);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'anomalyCount': anomalyCount,
      'worstRatio': _r1(worstRatio),
      'scoredRoutes': scoredRoutes,
      'unscoredRoutes': unscoredRoutes,
      'measurable': 1,
    };
  });
}

// ─── Network reliability (worse-of latency vs silent stalls) ──────────────────

const int _kNetworkMinAttempts = 3;
const int _kNetworkP75GoodMs = 800;
const int _kNetworkP75PoorMs = 3000;
const double _kNetworkStallRateGood = 0.01;
const double _kNetworkStallRatePoor = 0.1;

/// Coordinate-free network aggregate — counts + durations only, never a URL,
/// host, path or status. Mirrors `networkSampler.getStats()`.
class NetworkStats {
  const NetworkStats({
    this.attemptCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.timeoutCount = 0,
    this.stallCount = 0,
    this.durations = const <int>[],
    this.worstMs = 0,
  });

  final int attemptCount;
  final int completedCount;
  final int failedCount;
  final int timeoutCount;
  final int stallCount;
  final List<int> durations;
  final int worstMs;
}

/// The `network` axis: scores the WORSE of two independent problems — p75
/// latency and the silent-stall rate (timeout+stall / attempts). Loud failures
/// are context only, never scored. Returns null while pending
/// (< [_kNetworkMinAttempts] attempts). The closed 9-key wire map otherwise.
Map<String, Object?>? computeNetworkScore(NetworkStats stats) {
  return Safe.run<Map<String, Object?>?>(null, () {
    if (stats.attemptCount < _kNetworkMinAttempts) return null;
    final p75 = percentileFloor(stats.durations, 0.75);
    final stallRate =
        (stats.timeoutCount + stats.stallCount) / stats.attemptCount;
    final latencyScore =
        linearScore(p75, _kNetworkP75GoodMs, _kNetworkP75PoorMs);
    final stallScore =
        linearScore(stallRate, _kNetworkStallRateGood, _kNetworkStallRatePoor);
    final score = math.min(latencyScore, stallScore);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'stallPct': _r1(stallRate * 100.0),
      'attemptCount': stats.attemptCount,
      'failedCount': stats.failedCount,
      'timeoutCount': stats.timeoutCount,
      'stallCount': stats.stallCount,
      'p75Ms': p75,
      'worstMs': stats.worstMs,
    };
  });
}

// ─── Resilience (0.6·tail + 0.4·poorRate, min 8 pooled) ───────────────────────

/// A p99 at or below this is not a tail worth acting on.
const int kResilienceTailFloorMs = 50;
/// Below this count a p99 is just the slowest of a handful.
const int kResilienceMinTailSamples = 20;
/// A median below capture resolution is unmeasured, not small.
const int kResilienceMinMedianMs = 1;
const double _kResilienceTailGood = 2.0;
const double _kResilienceTailPoor = 10.0;
const int _kResiliencePoorMs = 1500; // TTI poor line
const double _kResiliencePoorRateGood = 0.05;
const double _kResiliencePoorRatePoor = 0.5;

/// Tail-heaviness + poor-rate blend over the POOLED durations of every route.
/// Returns null until at least [kResilienceMinTailSamples] durations are pooled.
/// Closed wire map otherwise: score, rating, tailRatio, poorPct, sampleCount.
Map<String, Object?>? computeResilienceScore(List<RouteSeries> series) {
  return Safe.run<Map<String, Object?>?>(null, () {
    final pooled = <int>[];
    for (final s in series) {
      pooled.addAll(s.durations);
    }
    if (pooled.length < kResilienceMinTailSamples) return null;

    final p50 = percentileFloor(pooled, 0.5);
    final p99 = percentileCeil(pooled, 0.99);
    final poorCount = pooled.where((d) => d >= _kResiliencePoorMs).length;
    final poorRate = poorCount / pooled.length;

    // Tail contract: tiny fast tails and zero medians gave false verdicts.
    if (p99 > kResilienceTailFloorMs && p50 < kResilienceMinMedianMs) {
      return <String, Object?>{
        'score': null,
        'rating': AxisRating.pending,
        'tailRatio': null,
        'poorPct': _r1(poorRate * 100.0),
        'p50Ms': p50,
        'p99Ms': p99,
        'sampleCount': pooled.length,
      };
    }

    final tail = p50 >= kResilienceMinMedianMs ? p99 / p50 : null;
    final tailScore = p99 <= kResilienceTailFloorMs
        ? 100
        : linearScore(tail!, _kResilienceTailGood, _kResilienceTailPoor);
    final poorScore = linearScore(
        poorRate, _kResiliencePoorRateGood, _kResiliencePoorRatePoor);
    final score = (0.6 * tailScore + 0.4 * poorScore).round();
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'tailRatio': tail == null ? null : _r1(tail),
      'poorPct': _r1(poorRate * 100.0),
      'p50Ms': p50,
      'p99Ms': p99,
      'sampleCount': pooled.length,
    };
  });
}

// ─── Frame floor (fixed 10s windowing, worst-window p95) ──────────────────────

/// One engine frame's on-screen span (ms) and the wall-clock ms it completed
/// at — the input to the fixed-window [computeFrameFloor]. LABEL-FREE.
class FrameSpanSample {
  const FrameSpanSample({required this.totalSpanMs, required this.atMs});

  /// Total on-screen span of the frame (ms).
  final int totalSpanMs;

  /// Epoch ms the frame completed at.
  final int atMs;
}

/// Width of a frame-floor window (ms). FROZEN.
const int _kFrameFloorWindowMs = 10000;

/// Minimum COMPLETED windows before the axis leaves pending.
const int _kFrameFloorMinWindows = 3;

/// Frame-rate bands, shared with the sibling kits: a floor at or above
/// [_kFrameFloorGoodFps] means even the worst window stayed fluid, and at or
/// below [_kFrameFloorPoorFps] the app was visibly stuttering for a whole
/// window. FROZEN — the same two numbers every other kit scores against.
const int _kFrameFloorGoodFps = 50;
const int _kFrameFloorPoorFps = 20;

/// The highest floor this axis will ever claim. A 4ms frame would read as
/// 250fps, but nobody SEES more than the display refresh, so the reported
/// number is capped. Capping can only understate a good window — never
/// flatter a bad one, which is the only direction that would lie.
const int _kFrameFloorMaxFps = 60;

/// "How bad was the WORST completed 10-second window?" Buckets spans into fixed
/// 10s windows by their completion time, EXCLUDES the still-filling current
/// window (`atMs ~/ 10000 >= now ~/ 10000`), and reports the worst completed
/// window's p95 span. Returns null until at least [_kFrameFloorMinWindows]
/// windows have completed.
///
/// The headline is the SIBLING contract — score, rating and floorFps — so the
/// dashboard reads this tile exactly as it reads every other kit's: a frame
/// floor is a frame rate, not a millisecond count. floorFps is derived from
/// the worst window's p95 span (a p95 frame of 33ms IS a 30fps window), and
/// the span that produced it stays on the wire as worstP95Ms. Scored on the
/// SHORTFALL below the good floor so that, as everywhere else, 100 is best.
///
/// The inverse is FLOORED, never rounded: a 20.4ms p95 is 49fps, and rounding
/// it up to 50 would hand the "good" band to a window that missed it. Flooring
/// (like the 60fps cap) can only understate a good window, never flatter a bad
/// one — the direction an honest meter must err in.
Map<String, Object?>? computeFrameFloor(List<FrameSpanSample> spans, int now) {
  return Safe.run<Map<String, Object?>?>(null, () {
    if (spans.isEmpty) return null;
    final currentWindow = now ~/ _kFrameFloorWindowMs;
    final byWindow = <int, List<int>>{};
    for (final s in spans) {
      final w = s.atMs ~/ _kFrameFloorWindowMs;
      if (w >= currentWindow) continue; // exclude the still-filling window
      (byWindow[w] ??= <int>[]).add(s.totalSpanMs);
    }
    if (byWindow.length < _kFrameFloorMinWindows) return null;

    var worstP95 = 0;
    for (final windowSpans in byWindow.values) {
      final p95 = percentileFloor(windowSpans, 0.95);
      if (p95 > worstP95) worstP95 = p95;
    }
    final floorFps = worstP95 <= 0
        ? _kFrameFloorMaxFps
        : math.min(_kFrameFloorMaxFps, (1000 / worstP95).floor());
    final shortfall = math.max(0, _kFrameFloorGoodFps - floorFps);
    final score =
        linearScore(shortfall, 0, _kFrameFloorGoodFps - _kFrameFloorPoorFps);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'floorFps': floorFps,
      'windowCount': byWindow.length,
      'worstP95Ms': worstP95,
    };
  });
}

/// The parity-harness reset entry point: drop every meter group's session
/// state between scenarios. Delegates to the real collectors — the MATH never
/// lives here. Idempotent, guest-safe.
void clearMeters() {
  Safe.fire(() {
    FlutterMeters.clearMeters();
    SuspendSensor.clear();
  });
}
