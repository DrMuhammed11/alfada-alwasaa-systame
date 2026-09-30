/// Boosthis: Swallowed Errors axis source (Flutter).
///
/// A PORT of the RN/Python kit's "swallowedErrors" (Near-Miss Rate) axis —
/// SAME wire shape, SAME rounding, SAME caption sentence pattern, SAME gates
/// and bands, so both runtimes read byte-identically for the same axis key.
///
/// Definition: errors the HOST app LOGGED at error level but did NOT crash on —
/// a "near miss". A calm app logs almost none; a chatty-but-alive app that
/// keeps swallowing errors is riding the edge of a real failure.
///
/// HOST HOOK (Flutter): the honest place to observe caught-and-logged errors is
/// Flutter's `debugPrint` (assignable, exactly like RN's console.error hook)
/// plus framework errors routed through `FlutterError.onError`. The adapter/
/// integration group CHAINS those, never replaces them, and calls
/// [noteSwallowedError] once per observed host-logged error. This module holds
/// only pure-Dart counters — no Flutter import.
///
/// TIMESTAMPS ONLY: the ring holds at most kSwallowedRingCap epoch-ms integers —
/// never the message, arguments, logger name, or stack.
///
/// Gates + bands (copied from the siblings, unchanged):
///   • no minimum count,
///   • a 5-minute minimum window before the axis reports at all,
///   • trailing window capped at 60 minutes,
///   • bands: 1/hour = good, 60/hour = poor,
///   • ring of at most kSwallowedRingCap timestamps.
///
/// HONESTY: NEVER feeds the composite Speed score. NOT LISTENING ⇒ NOT
/// MEASURABLE ({measurable: 0}); WARMING ⇒ OMITTED (null). Wire shape when
/// reported: { score, rating, count, perHour, windowMin, caption }.
library;

import '../core/telemetry.dart' show Telemetry;
import '../meters/meter_axes.dart' show linearScore, ratingFor;
import 'leak_watch.dart'
    show markLeakWatchInstalled, markLeakWatchUninstalled, noteLeakScan;

/// Rate bands (errors per hour). <=1/hr → 100; >=60/hr → 0.
const double kSwallowedGoodPerHour = 1.0;
const double kSwallowedPoorPerHour = 60.0;

/// Minimum observation window before the axis reports (5 minutes).
const int kSwallowedMinWindowMs = 5 * 60000;

/// Trailing window the rate is measured over, capped at 60 minutes.
const int kSwallowedWindowMs = 60 * 60000;

/// Ring cap — at most this many timestamps retained (oldest dropped).
const int kSwallowedRingCap = 400;

/// Max chars we ever hand to the leakWatch scan.
const int _scanStringifyCap = 4096;

bool _installed = false;
int _startedAt = 0;
final List<int> _timestamps = <int>[];

int _nowMs() => Telemetry.nowMs();

/// Mark the shared log chain live. Called by the adapter/integration group once
/// its debugPrint / FlutterError.onError chain is installed. Idempotent; resets
/// the window origin on first install. Marks leakWatch live too (shared chain).
void installSwallowedErrorTracking() {
  if (_installed) return;
  _startedAt = _nowMs();
  _timestamps.clear();
  _installed = true;
  try {
    markLeakWatchInstalled();
  } catch (_) {
    // best-effort — leakWatch stays not-measurable on failure
  }
}

/// Record ONE host-logged error: append a timestamp, cap the ring. Never the
/// message/args. Never throws (bookkeeping only). Called from inside the
/// adapter's log chain AFTER the host call. The [scanText] (already-stringified,
/// bounded) is piggybacked to the leakWatch collector, which classifies and
/// retains ONLY {ts, cat} — the text is never stored here or there.
void noteSwallowedError([String? scanText]) {
  try {
    if (!_installed) return;
    _timestamps.add(_nowMs());
    if (_timestamps.length > kSwallowedRingCap) {
      _timestamps.removeRange(0, _timestamps.length - kSwallowedRingCap);
    }
    if (scanText != null) {
      try {
        final s = scanText.length > _scanStringifyCap
            ? scanText.substring(0, _scanStringifyCap)
            : scanText;
        noteLeakScan(s);
      } catch (_) {
        // best-effort — a scan slip must never reach the host's log call
      }
    }
  } catch (_) {
    // best-effort — a counter slip must never reach the host's logging call
  }
}

/// The Swallowed Errors axis. Pure read — never mutates state, NEVER throws.
///   • not installed → { measurable: 0 } (the tile explains itself),
///   • installed but inside the 5-minute min window → null (OMITTED / warming),
///   • otherwise the full { score, rating, count, perHour, windowMin, caption }.
Map<String, Object?>? readSwallowedErrors() {
  try {
    if (!_installed) {
      return <String, Object?>{'measurable': 0};
    }
    final now = _nowMs();
    var windowMs = now - _startedAt;
    if (windowMs > kSwallowedWindowMs) windowMs = kSwallowedWindowMs;
    if (windowMs < kSwallowedMinWindowMs) {
      return null;
    }
    final cutoff = now - windowMs;
    var count = 0;
    for (final t in _timestamps) {
      if (t >= cutoff) count += 1;
    }
    final hours = windowMs / 3600000;
    final perHour = hours > 0 ? count / hours : 0.0;
    final score =
        linearScore(perHour, kSwallowedGoodPerHour, kSwallowedPoorPerHour);
    final windowMinRounded = (windowMs / 60000).round();
    final caption = count == 0
        ? 'no logged errors \u00b7 $windowMinRounded min watched'
        : '$count error${count != 1 ? 's' : ''} logged, app survived';
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'count': count,
      'perHour': (perHour * 10).round() / 10,
      'windowMin': ((windowMs / 60000) * 10).round() / 10,
      'caption': caption,
    };
  } catch (_) {
    return <String, Object?>{'measurable': 0};
  }
}

/// Restore state and drop all tracking. Idempotent, NEVER throws. Tears down
/// leakWatch too (shared lifecycle). Wired into telemetry.forget().
void uninstallSwallowedErrorTracking() {
  _installed = false;
  _startedAt = 0;
  _timestamps.clear();
  try {
    markLeakWatchUninstalled();
  } catch (_) {
    // best-effort — never throw on teardown
  }
}

/// Test hooks — deterministic, no dependence on a real log chain.
class SwallowedInternals {
  static bool get isInstalled => _installed;
  static int get count => _timestamps.length;

  static void setInstalledForTests(bool v) {
    _installed = v;
    if (v && _startedAt == 0) _startedAt = _nowMs();
  }

  static void fireForTests({int n = 1, int? at}) {
    for (var i = 0; i < (n < 0 ? 0 : n); i++) {
      _timestamps.add(at ?? _nowMs());
    }
    if (_timestamps.length > kSwallowedRingCap) {
      _timestamps.removeRange(0, _timestamps.length - kSwallowedRingCap);
    }
  }

  static void setStartedAtForTests(int ms) {
    _startedAt = ms;
  }

  static void reset() => uninstallSwallowedErrorTracking();
}
