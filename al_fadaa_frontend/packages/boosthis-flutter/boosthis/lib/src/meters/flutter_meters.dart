/// Boosthis frame-pipeline meters (Flutter) — the FRAME axes.
///
/// This file owns the math over a pure-Dart [FrameSample] struct fed by the
/// adapter. In Flutter the engine hands us a `FrameTiming` for EVERY frame via
/// `SchedulerBinding.instance.addTimingsCallback`, with build, raster, vsync
/// overhead and total span SEPARATED — the strongest signal any device runtime
/// gives us. React Native has to infer jank from a JS-side rAF sampler; Flutter
/// reports it from the engine, INCLUDING the raster thread that RN cannot see
/// at all.
///
/// The axes here mirror the RN frame axes' math and gates exactly where they
/// overlap (smoothness, stability, scroll, frustration, frozenFrames, appHang),
/// plus one NEW axis Flutter alone can compute: `rasterJank` (jank attributed
/// to the RASTER thread vs the build thread). No `package:flutter` import — the
/// adapter translates each engine `FrameTiming` into a plain [FrameSample].
///
/// ADDITIVE + display-only: nothing here feeds the composite Speed score.
/// GUEST-SAFE: every public entry point is Safe.run/Safe.fire wrapped, so a bug
/// degrades to a pending axis, never a throw into the host UI isolate.
library;

import 'dart:math' as math;

import '../core/safe.dart';
import '../core/score.dart';
import 'meter_axes.dart';

/// One engine frame, as translated from a Flutter `FrameTiming` by the adapter.
/// Microsecond fields mirror the engine's own units; [timestampMs] is the
/// wall-clock (epoch ms) the frame completed at, for the fixed-window frameFloor.
/// LABEL-FREE — pure numbers, no widget/route identity ever reaches this layer.
class FrameSample {
  const FrameSample({
    required this.buildMicros,
    required this.rasterMicros,
    required this.vsyncOverheadMicros,
    required this.totalSpanMicros,
    required this.timestampMs,
  });

  /// UI/build-thread duration (µs) — `FrameTiming.buildDuration`.
  final int buildMicros;

  /// Raster/GPU-thread duration (µs) — `FrameTiming.rasterDuration`. The signal
  /// no other runtime can see.
  final int rasterMicros;

  /// Vsync overhead (µs) — `FrameTiming.vsyncOverhead` (scheduling latency
  /// before the build began).
  final int vsyncOverheadMicros;

  /// Total on-screen span (µs) — `FrameTiming.totalSpan` (vsyncStart →
  /// rasterFinish). This is what the user actually waited for.
  final int totalSpanMicros;

  /// Epoch ms the frame completed at.
  final int timestampMs;
}

// ── Frame classification thresholds (mirror the RN FrameSampler cutoffs) ──────

/// A total span above this (ms) missed the 60fps budget — a "janky" frame.
/// (RN JANK_THRESHOLD_MS.)
const int kJankThresholdMs = 32;

/// A total span at/above this (ms) is a JS/UI-thread "long task" — a
/// perceptible stall. (RN LONG_TASK_MS.)
const int kLongTaskMs = 50;

/// Anything above this (ms) is a backgrounded suspension, not jank, and is
/// excluded from every frame axis. (RN SUSPENSION_CUTOFF_MS.)
const int kSuspensionCutoffMs = 500;

/// Industry (Sentry) frozen-frame threshold: a foreground span >= this (ms) is
/// a visibly FROZEN frame, not mere jank. (RN FROZEN_FRAME_MS.)
const int kFrozenFrameMs = 700;

/// Sentry app-hang threshold: the frame pipeline was unresponsive >= this (ms).
/// The HONEST watchdog — a frame that took >= 5s — NOT a native ANR.
/// (RN APP_HANG_MS.)
const int kAppHangMs = 5000;

// ── Smoothness (frame health) ─────────────────────────────────────────────────

/// (RN SMOOTHNESS_THRESHOLDS — janky-frame fraction.)
const double kSmoothnessGood = 0.02;
const double kSmoothnessPoor = 0.1;

// ── Stability (long-task rate) ────────────────────────────────────────────────

/// (RN STABILITY_THRESHOLDS — >=50ms blocks per minute.)
const int kStabilityGood = 2;
const int kStabilityPoor = 20;

/// Minimum foreground time before stability leaves "pending".
/// (RN STABILITY_MIN_ACTIVE_MS.)
const int kStabilityMinActiveMs = 10000;

// ── Scroll / list health ──────────────────────────────────────────────────────

/// (RN SCROLL_THRESHOLDS — janky-frame fraction during scroll.)
const double kScrollGood = 0.05;
const double kScrollPoor = 0.2;

/// Minimum frames sampled while scrolling before scroll leaves "pending".
/// (RN SCROLL_MIN_FRAMES.)
const int kScrollMinFrames = 60;

// ── Frustration (rage taps) ───────────────────────────────────────────────────

/// (RN FRUSTRATION_THRESHOLDS — confirmed rage bursts per minute.)
const double kFrustrationGood = 0.5;
const double kFrustrationPoor = 3.0;

/// Minimum foreground time before frustration leaves "pending".
/// (RN FRUSTRATION_MIN_ACTIVE_MS.)
const int kFrustrationMinActiveMs = 10000;

// ── frozenFrames / appHang warm-up gates ──────────────────────────────────────

/// (RN FROZEN_FRAMES_THRESHOLDS — frozen frames per foreground hour.)
const int kFrozenFramesGood = 1;
const int kFrozenFramesPoor = 30;

/// (RN FROZEN_MIN_ACTIVE_MS.)
const int kFrozenMinActiveMs = 60000;

/// (RN APP_HANG_THRESHOLDS — app hangs per foreground hour.)
const int kAppHangGood = 0;
const int kAppHangPoor = 2;

/// (RN APP_HANG_MIN_ACTIVE_MS.)
const int kAppHangMinActiveMs = 5 * 60000;

// ── rasterJank (NEW — the Flutter-only axis) ──────────────────────────────────

/// Fraction of JANKY frames whose overrun is attributed to the RASTER thread,
/// scored on the shared band. See [_computeRasterJank] for the attribution rule.
/// A raster-jank-dominated app is stuttering because of the GPU/paint step
/// (expensive shaders, saveLayer/opacity, unclipped overdraw), which no other
/// runtime can distinguish from build-thread jank.
const double kRasterJankGood = 0.2;
const double kRasterJankPoor = 0.8;

/// Minimum janky frames before rasterJank leaves "pending" — below this, one
/// stray frame would define the whole attribution.
const int kRasterJankMinJanky = 20;

int _round(num n) => n.round();

Object _r1(num n) {
  final v = (n * 10).round() / 10.0;
  return v == v.roundToDouble() ? v.toInt() : v;
}

/// The frame-pipeline meter collector. A singleton fed one [FrameSample] per
/// engine frame by the adapter; the axis readers difference/aggregate its
/// counters. Holds only counts + durations, never widget/route identity.
class FlutterMeters {
  FlutterMeters._();

  // ── Cumulative session counters (reset only on clearMeters) ────────────────
  static int _frameCount = 0;
  static int _jankyCount = 0;
  static int _longTaskCount = 0;
  static int _worstBlockMs = 0;
  static int _activeMs = 0; // foreground time backed by non-suspension frames

  // Scroll window (only frames painted while a scroll is active).
  static bool _scrolling = false;
  static int _scrollFrameCount = 0;
  static int _scrollJankyCount = 0;

  // Frustration (coordinate-free rage-tap aggregate fed by the adapter).
  static int _rageBurstCount = 0;
  static int _rageWorstDelayMs = 0;

  // frozenFrames / appHang (confirmed-foreground, from the engine spans).
  static int _frozenCount = 0;
  static int _hangCount = 0;
  static int _worstHangMs = 0;

  // rasterJank attribution over janky frames.
  static int _rasterJankyCount = 0; // janky frames raster-dominated
  static int _buildJankyCount = 0; // janky frames build-dominated

  // frameFloor input — bounded ring of {totalSpanMs, atMs}.
  static final List<FrameSpanSample> _frameSpans = <FrameSpanSample>[];

  /// Bounds the frameFloor ring so a long session can never grow it unbounded.
  static const int _frameSpanRingCap = 4096;

  /// Record ONE engine frame. Called from the adapter's `addTimingsCallback`
  /// bridge, once per `FrameTiming`. Guest-safe, never throws, never blocks.
  static void recordFrame(FrameSample f) {
    Safe.fire(() {
      final totalMs = f.totalSpanMicros / 1000.0;
      // A backgrounded suspension is not jank — exclude it from EVERY axis so a
      // tab-away never reads as a giant frozen frame.
      if (totalMs <= 0 || totalMs >= kSuspensionCutoffMs) {
        // Still classify the extreme freeze/hang buckets below the suspension
        // cutoff only; a true suspension is dropped entirely here.
        _classifyFreeze(totalMs);
        return;
      }

      _frameCount += 1;
      // Approximate the foreground clock from the frames themselves: each
      // non-suspension frame contributes its own span (the engine only fires a
      // timing while the app is producing frames, i.e. foreground/active).
      _activeMs += totalMs.round();

      final janky = totalMs > kJankThresholdMs;
      if (janky) {
        _jankyCount += 1;
        _attributeJank(f);
      }
      if (totalMs >= kLongTaskMs) {
        _longTaskCount += 1;
        final blk = totalMs.round();
        if (blk > _worstBlockMs) _worstBlockMs = blk;
      }

      if (_scrolling) {
        _scrollFrameCount += 1;
        if (janky) _scrollJankyCount += 1;
      }

      _classifyFreeze(totalMs);

      _frameSpans.add(FrameSpanSample(
        totalSpanMs: totalMs.round(),
        atMs: f.timestampMs,
      ));
      if (_frameSpans.length > _frameSpanRingCap) {
        _frameSpans.removeRange(0, _frameSpans.length - _frameSpanRingCap);
      }
    });
  }

  /// Frozen-frame / app-hang classification. A span >= 5s is an app hang; a
  /// span in [700ms, 5s) is a frozen frame. Both are confirmed-foreground by
  /// construction (the engine only emits a timing while producing frames), and
  /// a span past the suspension cutoff but below the freeze/hang thresholds is
  /// ignored here.
  static void _classifyFreeze(double totalMs) {
    if (totalMs >= kAppHangMs) {
      _hangCount += 1;
      final ms = totalMs.round();
      if (ms > _worstHangMs) _worstHangMs = ms;
    } else if (totalMs >= kFrozenFrameMs) {
      _frozenCount += 1;
    }
  }

  /// rasterJank attribution rule (documented): a JANKY frame's overrun is
  /// attributed to whichever engine phase dominated its work — the RASTER
  /// thread if `rasterMicros >= buildMicros`, otherwise the BUILD thread. We
  /// compare the two phase durations directly (not against the vsync overhead,
  /// which is scheduling latency, not app work), because the axis answers "when
  /// this app stutters, is it the paint/GPU step or the widget-build step?".
  /// Ties go to raster — a raster-bound frame at parity is the more expensive,
  /// harder-to-fix class the axis is built to surface.
  static void _attributeJank(FrameSample f) {
    if (f.rasterMicros >= f.buildMicros) {
      _rasterJankyCount += 1;
    } else {
      _buildJankyCount += 1;
    }
  }

  /// onScrollStart bridge — opens the scroll attribution window. Idempotent.
  static void beginScroll() {
    Safe.fire(() {
      _scrolling = true;
    });
  }

  /// onScrollEnd bridge — closes the scroll attribution window. Idempotent.
  static void endScroll() {
    Safe.fire(() {
      _scrolling = false;
    });
  }

  /// Record a CONFIRMED rage-tap burst (coordinate-free): >=3 jabs in one spot
  /// within ~700ms while the measured input delay was high. Only the count and
  /// the worst delay reach this layer — never a touch position. Fed by the
  /// adapter's gesture bridge.
  static void recordRageBurst(int worstDelayMs) {
    Safe.fire(() {
      _rageBurstCount += 1;
      if (worstDelayMs > _rageWorstDelayMs) _rageWorstDelayMs = worstDelayMs;
    });
  }

  /// The frame-span ring for the [computeFrameFloor] axis (owned by
  /// meter_axes). Returns a defensive copy.
  static List<FrameSpanSample> frameSpans() =>
      Safe.run(<FrameSpanSample>[], () => List<FrameSpanSample>.from(_frameSpans));

  // ── Axis readers — each a closed wire map, or null while pending ────────────

  /// smoothness — janky-frame fraction over all frames. Closed 4-key map, or
  /// null when no frames sampled. JSON keys: score, rating, jankPct, sampleCount.
  static Map<String, Object?>? smoothness() {
    return Safe.run(null, () {
      if (_frameCount == 0) return null;
      final jankFraction = _jankyCount / _frameCount;
      final score = linearScore(jankFraction, kSmoothnessGood, kSmoothnessPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'jankPct': _r1(jankFraction * 100.0),
        'sampleCount': _frameCount,
      };
    });
  }

  /// stability — >=50ms blocks per minute of foreground time. Closed 5-key map,
  /// or null while pending (< 10s foreground). JSON keys: score, rating,
  /// longTasksPerMin, longTaskCount, worstBlockMs.
  static Map<String, Object?>? stability() {
    return Safe.run(null, () {
      if (_activeMs < kStabilityMinActiveMs) return null;
      final perMin = _longTaskCount / (_activeMs / 60000.0);
      final score = linearScore(perMin, kStabilityGood, kStabilityPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'longTasksPerMin': _r1(perMin),
        'longTaskCount': _longTaskCount,
        'worstBlockMs': _worstBlockMs,
      };
    });
  }

  /// scroll — janky-frame fraction DURING active scroll. Closed 4-key map, or
  /// null while pending (< 60 scroll frames). JSON keys: score, rating, jankPct,
  /// frameCount.
  static Map<String, Object?>? scroll() {
    return Safe.run(null, () {
      if (_scrollFrameCount < kScrollMinFrames) return null;
      final jankFraction = _scrollJankyCount / _scrollFrameCount;
      final score = linearScore(jankFraction, kScrollGood, kScrollPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'jankPct': _r1(jankFraction * 100.0),
        'frameCount': _scrollFrameCount,
      };
    });
  }

  /// frustration — confirmed rage-tap bursts per minute of foreground time.
  /// Closed 5-key map, or null while pending (< 10s foreground). JSON keys:
  /// score, rating, ragePerMin, burstCount, worstDelayMs.
  static Map<String, Object?>? frustration() {
    return Safe.run(null, () {
      if (_activeMs < kFrustrationMinActiveMs) return null;
      final perMin = _rageBurstCount / (_activeMs / 60000.0);
      final score = linearScore(perMin, kFrustrationGood, kFrustrationPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'ragePerMin': _round2(perMin),
        'burstCount': _rageBurstCount,
        'worstDelayMs': _rageWorstDelayMs,
      };
    });
  }

  /// frozenFrames — confirmed-foreground frozen frames (>=700ms) per foreground
  /// hour. Closed 5-key map, or null while the foreground window is too short
  /// to carry a per-hour rate. JSON keys: score, rating, frozenCount,
  /// frozenPerHour, windowMin.
  ///
  /// The axis used to surface a frozen frame IMMEDIATELY, before the window
  /// was real. That looked helpful and was not: with a few seconds of
  /// foreground time the denominator below falls back to its one-minute
  /// floor, so two frozen frames published "120 an hour" as a confident poor
  /// verdict while the SAME map reported windowMin: 0. Every stored Flutter
  /// snapshot carried that pair. A rate whose own window rounds to nothing is
  /// not a measurement, so the axis now abstains until the window can carry
  /// it. Nothing is lost: the count keeps accruing and the axis reports as
  /// soon as the window is real.
  static Map<String, Object?>? frozenFrames() {
    return Safe.run(null, () {
      final windowMin = _round(_activeMs / 60000.0);
      if (_activeMs < kFrozenMinActiveMs) return null;
      final hours = math.max(_activeMs / 3600000.0, 1 / 60);
      final perHour = _frozenCount / hours;
      final score = linearScore(perHour, kFrozenFramesGood, kFrozenFramesPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'frozenCount': _frozenCount,
        'frozenPerHour': _r1(perHour),
        'windowMin': windowMin,
      };
    });
  }

  /// appHang — confirmed-foreground app hangs (>=5s) per foreground hour. The
  /// HONEST watchdog, NOT a native ANR. Closed 5-key map, or null while the
  /// foreground window is too short to carry a per-hour rate. JSON keys:
  /// score, rating, hangCount, worstHangMs, windowMin.
  ///
  /// Same correction as frozenFrames above, and for the same reason: this axis
  /// shares that per-hour denominator and its one-minute floor, so a hang seen
  /// early published a projected rate over a window it reported as zero
  /// minutes. It has never produced in a stored snapshot only because no rig
  /// has ever hung; the defect was latent, not absent.
  static Map<String, Object?>? appHang() {
    return Safe.run(null, () {
      final windowMin = _round(_activeMs / 60000.0);
      if (_activeMs < kAppHangMinActiveMs) return null;
      final hours = math.max(_activeMs / 3600000.0, 1 / 60);
      final perHour = _hangCount / hours;
      final score = linearScore(perHour, kAppHangGood, kAppHangPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'hangCount': _hangCount,
        'worstHangMs': _worstHangMs,
        'windowMin': windowMin,
      };
    });
  }

  /// rasterJank (Flutter-only) — of the janky frames, the fraction whose
  /// overrun was raster-thread-dominated, scored so a raster-bound stutter
  /// reads red. Closed 5-key map, or null while pending (< 20 janky frames).
  /// JSON keys: score, rating, rasterSharePct, rasterJankyCount, buildJankyCount.
  static Map<String, Object?>? rasterJank() {
    return Safe.run(null, () {
      final janky = _rasterJankyCount + _buildJankyCount;
      if (janky < kRasterJankMinJanky) return null;
      final rasterShare = _rasterJankyCount / janky;
      final score = linearScore(rasterShare, kRasterJankGood, kRasterJankPoor);
      return <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'rasterSharePct': _r1(rasterShare * 100.0),
        'rasterJankyCount': _rasterJankyCount,
        'buildJankyCount': _buildJankyCount,
      };
    });
  }

  /// Attach every measurable frame-pipeline axis to [axes]. Absent while
  /// pending. Guest-safe.
  static void addFrameAxes(Map<String, Object?> axes) {
    Safe.fire(() {
      _add(axes, 'smoothness', smoothness());
      _add(axes, 'stability', stability());
      _add(axes, 'scroll', scroll());
      _add(axes, 'frustration', frustration());
      _add(axes, 'frozenFrames', frozenFrames());
      _add(axes, 'appHang', appHang());
      _add(axes, 'rasterJank', rasterJank());
    });
  }

  static void _add(Map<String, Object?> axes, String key, Map<String, Object?>? axis) {
    if (axis != null) axes[key] = axis;
  }

  /// Foreground time (ms) sampled from the frame stream — the rate denominator
  /// the sibling meter groups (e.g. unhandledErrors) share.
  static int activeMs() => Safe.run(0, () => _activeMs);

  /// Reset all frame-pipeline state (the parity harness calls this between
  /// scenarios, via meter_axes clearMeters). Idempotent, guest-safe.
  static void clearMeters() {
    Safe.fire(() {
      _frameCount = 0;
      _jankyCount = 0;
      _longTaskCount = 0;
      _worstBlockMs = 0;
      _activeMs = 0;
      _scrolling = false;
      _scrollFrameCount = 0;
      _scrollJankyCount = 0;
      _rageBurstCount = 0;
      _rageWorstDelayMs = 0;
      _frozenCount = 0;
      _hangCount = 0;
      _worstHangMs = 0;
      _rasterJankyCount = 0;
      _buildJankyCount = 0;
      _frameSpans.clear();
    });
  }
}

Object _round2(num n) {
  final v = (n * 100).round() / 100.0;
  return v == v.roundToDouble() ? v.toInt() : v;
}
