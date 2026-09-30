/// Cold Start — how long the app took to put its FIRST frame on screen,
/// measured from the kit's own start.
///
/// Reference point: the kit's own start (`Boosthis.start()`, which the host
/// calls from `main()`), NOT the OS process launch — pure Dart cannot see the
/// process start instant. Everything the engine and the Dart VM did before
/// `main()` reached that call is therefore OUTSIDE this figure, which makes
/// the reading a PARTIAL one: it is a real measurement of a real slice of the
/// launch, and it is not the whole launch.
///
/// A partial reading is never scored and never rated — see
/// `docs/cold-start-boundary-contract.md`. It travels as the number plus a
/// `measuredTo` code naming the interval, with `score: null` and
/// `rating: 'pending'`, and the server writes the words for it. No bands
/// apply here for the same reason: a verdict would be a claim about an
/// interval this kit cannot see.
///
/// The Swift and Kotlin kits DO read the real process start (`kinfo_proc` and
/// `Process.getStartUptimeMillis()`), so their first-frame figure is the whole
/// cold start and IS rated. A Flutter figure and a native-mobile figure are
/// not the same measurement and must not be compared.
///
/// Warming contract: null (OMITTED) until the first frame is marked — the
/// in-app panel shows "warming up · needs the first frame" for exactly that
/// gap. LATCHED ONCE per process: the first frame IS the cold start, so later
/// frames never overwrite it.
///
/// Additive + display-only: like every other axis it never feeds the
/// TTFF/TTI/FID speed composite.
library;

import '../meters/meter_axes.dart' show AxisRating;

/// coldStart covers the kit's start → first frame drawn. PARTIAL: the engine
/// bring-up before `main()` reached `Boosthis.start()` is not in it, so this
/// code is never rated.
const int kColdStartMeasuredToKitStartFirstFrame = 5;

int _kitStartMs = 0;
int? _coldStartMs;

/// Record the kit's start instant, in epoch ms. Called once from the facade's
/// start path. A later call is ignored so a re-entrant start cannot move the
/// reference point out from under an already-latched measurement.
void markKitStart(int nowMs) {
  if (_kitStartMs != 0) return;
  if (nowMs <= 0) return;
  _kitStartMs = nowMs;
}

/// Latch the first frame, in epoch ms. Called from the adapter's post-frame
/// callback; only the FIRST call counts.
void markFirstFrameAt(int nowMs) {
  if (_coldStartMs != null) return; // already latched — first frame wins
  if (_kitStartMs == 0) return; // no reference point — stay warming
  final d = nowMs - _kitStartMs;
  if (d < 0) return; // clock stepped backwards — refuse a nonsense value
  _coldStartMs = d;
}

/// The Cold Start axis. Pure read — never throws.
///   • first frame not marked yet → null (OMITTED / warming),
///   • otherwise { score: null, rating: 'pending', measuredTo, startupMs }.
///
/// Unrated on purpose: the interval begins at the kit's own start rather than
/// at the launch, so a rating here would judge the app on a slice of its
/// start-up. The number is still reported, and the panel and the server both
/// say which interval it covers.
Map<String, Object?>? readColdStart() {
  try {
    final ms = _coldStartMs;
    if (ms == null) return null;
    return <String, Object?>{
      'score': null,
      'rating': AxisRating.pending,
      'measuredTo': kColdStartMeasuredToKitStartFirstFrame,
      // startupMs, NOT coldStartMs: this is the cross-runtime field name for
      // the coldStart axis (the Node/Python kits emit it, the server's ingest
      // allowlist names it, and the dashboard reads it to render the detail
      // line). A differently-named field is silently stripped on arrival.
      'startupMs': ms,
    };
  } catch (_) {
    return null;
  }
}

/// Clear the latch (telemetry.forget() hook + tests).
void resetColdStart() {
  _kitStartMs = 0;
  _coldStartMs = null;
}

/// Test hooks — deterministic, with no dependence on a real frame pipeline.
class ColdStartInternals {
  static int get kitStartMs => _kitStartMs;
  static int? get coldStartMs => _coldStartMs;
  static void reset() => resetColdStart();
}
