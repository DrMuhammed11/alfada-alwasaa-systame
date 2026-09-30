/// Boosthis: Image Weight axis source (Flutter).
///
/// The reused `imageWeight` axis. Unlike RN (which ESTIMATES decoded-vs-
/// displayed overfetch), Flutter reads the engine's own image cache EXACTLY:
/// `PaintingBinding.instance.imageCache.currentSizeBytes` and `liveImageCount`.
/// The adapter samples those numbers and feeds them here via [recordCacheSample]
/// — this module holds only pure-Dart state + math (no Flutter import).
///
/// The axis scores the app's PEAK decoded-image cache footprint against a
/// budget: a healthy screen keeps only what it paints in cache; a heavy screen
/// holds tens of MB of decoded bitmaps it isn't showing. peakBytes is the
/// high-water mark of currentSizeBytes observed; liveImages is the last
/// liveImageCount seen.
///
/// HONESTY / INVARIANTS:
///   • NEVER feeds the composite Speed score. Display-only.
///   • Works in RELEASE builds (imageCache is always present).
///   • OMIT WHILE WARMING: readImageWeight() returns pending until >= 5 samples.
///   • NUMERIC-ONLY on the wire: { score, rating, peakMB, liveImages,
///     samples }. No caption — the server rebuilds it.
///   • Bands: linearScore(peakMB, good=24, poor=192) — 24 MB of decoded cache
///     is comfortable; 192 MB is a heavy retained-bitmap footprint.
library;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// Peak decoded-image-cache footprint bands (megabytes). <=24 MB → 100;
/// >=192 MB → 0.
const double kImageWeightGoodMb = 24;
const double kImageWeightPoorMb = 192;

/// Samples needed before the axis leaves "pending".
const int kImageWeightMinSamples = 5;

int _samples = 0;
int _peakBytes = 0;
int _liveImages = 0;

/// Record one image-cache sample: the exact `currentSizeBytes` and
/// `liveImageCount` read from the engine's imageCache. Best-effort, NEVER
/// throws. Ignores negative inputs.
void recordCacheSample(num currentSizeBytes, num liveImageCount) {
  try {
    final bytes = currentSizeBytes.toInt();
    if (bytes < 0) return;
    _samples += 1;
    if (bytes > _peakBytes) _peakBytes = bytes;
    final live = liveImageCount.toInt();
    if (live >= 0) _liveImages = live;
  } catch (_) {
    // best-effort — a bookkeeping slip must never reach the host
  }
}

/// The Image Weight axis, or a pending reading while warming up (<5 samples).
/// Pure read — never mutates state, NEVER throws. Numbers-only wire shape.
Map<String, Object?> readImageWeight() {
  try {
    if (_samples < kImageWeightMinSamples) {
      return <String, Object?>{
        'score': null,
        'rating': 'pending',
        'peakMB': null,
        'liveImages': _liveImages,
        'samples': _samples,
      };
    }
    final peakMb = _peakBytes / (1024 * 1024);
    final score = linearScore(peakMb, kImageWeightGoodMb, kImageWeightPoorMb);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'peakMB': (peakMb * 10).round() / 10,
      'liveImages': _liveImages,
      'samples': _samples,
    };
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'peakMB': null,
      'liveImages': 0,
      'samples': 0,
    };
  }
}

/// Clear measured samples (telemetry.forget() hook + tests).
void resetImageWeight() {
  _samples = 0;
  _peakBytes = 0;
  _liveImages = 0;
}

/// Test hooks.
class ImageWeightInternals {
  static int get sampleCount => _samples;
  static int get peakBytes => _peakBytes;

  static void reset() => resetImageWeight();
}
