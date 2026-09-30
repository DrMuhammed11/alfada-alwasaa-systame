/// Boosthis: Timer Leaks axis source (Flutter) — the NEW `timerLeaks` axis.
///
/// Counts timers still alive after their creating screen/route is gone. Flutter
/// makes this observable through a custom Zone: the integration group installs
/// `Boosthis.run(...)`, whose ZoneSpecification intercepts `createTimer` /
/// `createPeriodicTimer` (and their cancellation) and tags each live timer with
/// the route that was current when it was created. When a route is popped, any
/// timer still alive that was created under it is a LEAK candidate.
///
/// THIS FILE IS PURE-DART COUNTERS ONLY. The Zone itself (the integration
/// group's) calls the note functions below:
///   • [noteTimerCreated] / [noteTimerCancelled] — track the live-timer count,
///   • [noteRouteRetired(liveTimersUnderRoute)] — when a route is popped, the
///     Zone reports how many timers it created that are STILL alive; each is a
///     leak. Periodic timers still alive count as [noteRouteRetired] with the
///     periodic flag so the split is honest.
///
/// The axis reports the count of leaked timers observed and a leak RATE per
/// retired route. A calm app retires routes with zero surviving timers; a leaky
/// one keeps periodic timers ticking behind dead screens.
///
/// HONESTY / INVARIANTS:
///   • NEVER feeds the composite Speed score. Display-only. NEW axis key.
///   • NOT WIRED (no Boosthis.run Zone) ⇒ { present: true, measurable: 0,
///     reason: "..." } so the tile explains itself instead of warming forever.
///   • OMIT WHILE WARMING: wired but no route retired yet → null (warming).
///   • NUMERIC-ONLY: { score, rating, leakedTimers, periodicLeaks,
///     routesRetired, perRoute }.
///   • Bands: linearScore(perRoute, good=0, poor=3) — >0 leaked timers per
///     retired route is already suspect; ~3/route reads as a systematic leak.
library;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// Leaked-timers-per-retired-route bands. 0/route → 100; >=3/route → 0.
const double kTimerLeakGoodPerRoute = 0;
const double kTimerLeakPoorPerRoute = 3;

bool _wired = false;
int _liveTimers = 0;
int _leakedTimers = 0;
int _periodicLeaks = 0;
int _routesRetired = 0;

/// Mark the timer-tracking Zone live (adapter installed Boosthis.run).
/// Idempotent.
void installTimerLeakTracking() {
  _wired = true;
}

/// The Zone observed a timer being created. Never throws.
void noteTimerCreated() {
  try {
    _liveTimers += 1;
  } catch (_) {
    // best-effort
  }
}

/// The Zone observed a timer being cancelled (or a one-shot firing to
/// completion). Never throws. Floors at zero.
void noteTimerCancelled() {
  try {
    if (_liveTimers > 0) _liveTimers -= 1;
  } catch (_) {
    // best-effort
  }
}

/// A route was retired (popped) with [survivingTimers] timers created under it
/// still alive, [survivingPeriodic] of which are periodic. Each surviving timer
/// is a leak. Never throws.
void noteRouteRetired(int survivingTimers, {int survivingPeriodic = 0}) {
  try {
    _routesRetired += 1;
    final n = survivingTimers < 0 ? 0 : survivingTimers;
    _leakedTimers += n;
    final p = survivingPeriodic < 0
        ? 0
        : (survivingPeriodic > n ? n : survivingPeriodic);
    _periodicLeaks += p;
  } catch (_) {
    // best-effort
  }
}

/// The Timer Leaks axis. Pure read — never mutates state, NEVER throws.
///   • not wired → { present: true, measurable: 0, reason: ... },
///   • wired but no route retired yet → null (OMITTED / warming),
///   • otherwise { score, rating, leakedTimers, periodicLeaks, routesRetired,
///     perRoute }.
Map<String, Object?>? readTimerLeaks() {
  try {
    if (!_wired) {
      return <String, Object?>{
        'present': true,
        'measurable': 0,
        'reason': 'timer tracking needs the kit Zone (Boosthis.run)',
      };
    }
    if (_routesRetired == 0) {
      return null;
    }
    final perRoute = _leakedTimers / _routesRetired;
    final score =
        linearScore(perRoute, kTimerLeakGoodPerRoute, kTimerLeakPoorPerRoute);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'leakedTimers': _leakedTimers,
      'periodicLeaks': _periodicLeaks,
      'routesRetired': _routesRetired,
      'perRoute': (perRoute * 10).round() / 10,
    };
  } catch (_) {
    return <String, Object?>{
      'present': true,
      'measurable': 0,
      'reason': 'timer-leak read failed',
    };
  }
}

/// Live timer count observed by the Zone (informational; never uploaded raw).
int liveTimerCount() => _liveTimers;

/// Clear all state (telemetry.forget() hook + tests).
void resetTimerLeaks() {
  _wired = false;
  _liveTimers = 0;
  _leakedTimers = 0;
  _periodicLeaks = 0;
  _routesRetired = 0;
}

/// Test hooks — deterministic, no dependence on a real Zone.
class TimerLeakInternals {
  static bool get isWired => _wired;
  static int get liveTimers => _liveTimers;
  static int get leakedTimers => _leakedTimers;
  static int get routesRetired => _routesRetired;

  static void setWiredForTests(bool v) => _wired = v;

  static void reset() => resetTimerLeaks();
}
