/// Boosthis: Lifecycle & device-context axes (Flutter).
///
/// Four ADDITIVE, display-only meters driven ENTIRELY by the adapter's
/// `WidgetsBindingObserver` / `PlatformDispatcher` change callbacks — no new
/// permanent poller, no loop that stays alive while backgrounded. This module
/// is pure-Dart state + math; the adapter feeds it lifecycle transitions and
/// change events, and reads the axes for the snapshot.
///
/// Axes (numbers-only wire shape):
///   • foregroundResidency — share of observed session time that is actually
///     foreground, so a short visit isn't mistaken for a well-observed run.
///     (Higher fraction = better.)
///   • backgroundRecovery — how long the app takes to resume a useful frame
///     after returning to "resumed". The adapter times ONE post-resume frame on
///     each background→foreground transition (never a standing loop) and reports
///     it via [recordBackgroundRecovery]. Absent until the app has been
///     backgrounded and returned at least once.
///   • dimensionChurn — window-size / orientation change events per foreground
///     hour (MediaQuery / view-metrics changes).
///   • appearanceChurn — system theme/appearance (platform brightness) change
///     notifications per foreground hour.
///
/// HONESTY: NEVER feed the composite Speed score. OMIT WHILE WARMING / NOT
/// WIRED: readers return null when the relevant feed never attached or too
/// little (one-minute foreground window) has been observed → the axis is
/// dropped from the upload. Counts + durations only.
library;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// foregroundResidency / dimensionChurn / appearanceChurn / memoryWarnings
/// carry NO bands: they are published as measurements and never graded. See
/// docs/decisions/meter-verdicts-that-are-not-about-the-app.md — how long a
/// person keeps an app open, how often they rotate the phone, when they switch
/// to dark mode, and when the OS decides this DEVICE is short of memory are
/// not things the app's author can change. The bands were deleted rather than
/// left unused so the next reader cannot re-wire them.

/// Background-return recovery bands (ms to the first frame after resume).
/// GRADED: the clock starts at the OS handover, so what fills it is the app's
/// own resume work.
const int kBackgroundRecoveryGood = 120;
const int kBackgroundRecoveryPoor = 1000;

/// One-minute FOREGROUND window before the residency / churn axes report.
/// Read against the foreground clock, never the observed-session clock: a
/// reading whose quantity is a share of foreground time must not open on time
/// the app spent in someone's pocket.
const int kLifecycleMinActiveMs = 60000;

/// A single unbroken background stretch contributes at most this much to the
/// observed-session clock. A phone pocketed for an hour is not an hour of the
/// app failing to be in front.
const int kBackgroundSpanCapMs = 5 * 60000;

/// Cap on retained background-recovery samples (bounded memory).
const int kRecoveryRingCap = 200;

/// Frame deltas above this are treated as a backgrounding, not a real resume.
const int kRecoverySaneMaxMs = 5000;

bool _appStateWired = false;
int _foregroundMs = 0; // accumulated foreground time (ms)
int _observedMs = 0; // accumulated total observed time (fg + bg)
int _lastStateAt = 0; // monotonic ms of the last state transition
bool _currentActive = true; // are we currently foregrounded?
/// Background time already charged to [_observedMs] for the CURRENT unbroken
/// background stretch. The cap is per STRETCH, not per notification: inactive,
/// then paused, then hidden are three lifecycle events for one trip out of the
/// foreground, and giving each its own allowance would put a pocketed hour
/// back in the denominator. Reset on the way IN to the foreground.
int _backgroundChargedMs = 0;
final List<int> _recoverySamples = <int>[];
int _recoveryWorstMs = 0;

bool _dimensionWired = false;
int _dimensionCount = 0;
bool _appearanceWired = false;
int _appearanceCount = 0;
bool _memoryWarningsWired = false;
int _memoryWarningCount = 0;

int _monoNow() => DateTime.now().microsecondsSinceEpoch ~/ 1000;

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

/// Fold the time since the last transition into the fg/observed clocks. A
/// background stretch is bounded ([kBackgroundSpanCapMs]) before it reaches the
/// observed clock, so a pocketed phone cannot inflate the denominator.
void _accrue(int now) {
  if (_lastStateAt > 0) {
    final dt = now - _lastStateAt;
    if (dt > 0 && dt < 24 * 3600000) {
      if (_currentActive) {
        _observedMs += dt;
        _foregroundMs += dt;
      } else {
        // What is LEFT of this unbroken stretch's allowance, never a fresh one.
        final room = kBackgroundSpanCapMs - _backgroundChargedMs;
        final left = room > 0 ? room : 0;
        final charged = dt < left ? dt : left;
        _observedMs += charged;
        _backgroundChargedMs += charged;
      }
    }
  }
  _lastStateAt = now;
}

/// Mark the lifecycle feed live (adapter attached WidgetsBindingObserver).
/// [initialActive] is whether the app launched foregrounded (defaults true, as
/// AppLifecycleState.resumed on launch). Idempotent for the app-state feed.
void installLifecycleTracking({bool initialActive = true}) {
  if (_appStateWired) return;
  _currentActive = initialActive;
  _lastStateAt = _monoNow();
  _appStateWired = true;
  _memoryWarningsWired = true;
}

/// Feed one app lifecycle transition. [active] is true for a foreground/resumed
/// state, false for paused/inactive/detached/hidden. Never throws.
void noteLifecycleState(bool active) {
  try {
    _noteLifecycleStateAt(active, _monoNow());
  } catch (_) {
    // best-effort
  }
}

/// The transition itself, at an explicit monotonic timestamp. The test hook
/// drives THIS, so a test session cannot diverge from the shipped path.
void _noteLifecycleStateAt(bool active, int now) {
  _accrue(now);
  _currentActive = active;
  // A stretch ends when the app comes back to the front, and only then.
  if (active) _backgroundChargedMs = 0;
}

/// Report a timed post-resume recovery latency (ms). The adapter times ONE
/// frame after each background→foreground transition. Never throws.
void recordBackgroundRecovery(num ms) {
  try {
    final dt = ms.round();
    if (dt > 0 && dt < kRecoverySaneMaxMs) {
      _recoverySamples.add(dt);
      if (_recoverySamples.length > kRecoveryRingCap) {
        _recoverySamples.removeRange(
            0, _recoverySamples.length - kRecoveryRingCap);
      }
      if (dt > _recoveryWorstMs) _recoveryWorstMs = dt;
    }
  } catch (_) {
    // best-effort
  }
}

/// Mark the dimension-change feed live + count one event.
void noteDimensionChange() {
  _dimensionWired = true;
  _dimensionCount += 1;
}

/// Mark the appearance-change feed live + count one event.
void noteAppearanceChange() {
  _appearanceWired = true;
  _appearanceCount += 1;
}

/// Count one WidgetsBindingObserver.didHaveMemoryPressure notification.
void noteMemoryWarning() {
  _memoryWarningsWired = true;
  _memoryWarningCount += 1;
}

/// Mark the dimension feed wired without an event (adapter attached the hook).
void markDimensionWired() => _dimensionWired = true;

/// Mark the appearance feed wired without an event.
void markAppearanceWired() => _appearanceWired = true;

/// Remove every lifecycle feed and drop all state. Idempotent, NEVER throws.
/// Wired into telemetry.forget().
void uninstallLifecycleTracking() {
  _appStateWired = false;
  _dimensionWired = false;
  _appearanceWired = false;
  _memoryWarningsWired = false;
  _foregroundMs = 0;
  _observedMs = 0;
  _lastStateAt = 0;
  _currentActive = true;
  _backgroundChargedMs = 0;
  _recoverySamples.clear();
  _recoveryWorstMs = 0;
  _dimensionCount = 0;
  _appearanceCount = 0;
  _memoryWarningCount = 0;
}

/// Snapshot the foreground clock without mutating it (folds the in-progress
/// segment for reads only). Returns [fg, observed] ms.
List<int> _residencySnapshot() {
  final now = _monoNow();
  var fg = _foregroundMs;
  var obs = _observedMs;
  if (_lastStateAt > 0) {
    final dt = now - _lastStateAt;
    if (dt > 0 && dt < 24 * 3600000) {
      // Same bound as _accrue(): a still-running background stretch gets what
      // is LEFT of the current stretch's allowance, never a fresh one.
      if (_currentActive) {
        obs += dt;
        fg += dt;
      } else {
        final room = kBackgroundSpanCapMs - _backgroundChargedMs;
        final left = room > 0 ? room : 0;
        obs += dt < left ? dt : left;
      }
    }
  }
  return <int>[fg, obs];
}

Map<String, Object?> readForegroundResidency() {
  try {
    final snap = _residencySnapshot();
    final fg = snap[0];
    final observed = snap[1];
    final activeMin = (fg / 60000).round();
    // The gate reads the FOREGROUND clock, because foreground time is the
    // quantity the reading is about. It used to read `observed`, which counts
    // background: a phone left in a pocket satisfied "enough evidence" while
    // the foreground clock was still near zero.
    if (!_appStateWired || fg < kLifecycleMinActiveMs) {
      return <String, Object?>{
        'score': null,
        'rating': 'pending',
        'foregroundPct': null,
        'activeMin': activeMin,
      };
    }
    final frac = observed > 0 ? (fg / observed).clamp(0.0, 1.0) : 0.0;
    // NEVER GRADED. How long someone keeps an app open is a fact about that
    // person, not about the app. The number stays; the verdict goes.
    return <String, Object?>{
      'score': null,
      'rating': 'not-scored',
      'measurable': 1,
      'foregroundPct': (frac * 1000).round() / 10,
      'activeMin': activeMin,
    };
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'foregroundPct': null,
      'activeMin': 0,
    };
  }
}

Map<String, Object?> readBackgroundRecovery() {
  try {
    final count = _recoverySamples.length;
    if (!_appStateWired || count == 0) {
      return <String, Object?>{
        'score': null,
        'rating': 'pending',
        'p75Ms': null,
        'worstMs': _recoveryWorstMs,
        'returnCount': count,
      };
    }
    final v = _p75(_recoverySamples);
    final score =
        linearScore(v, kBackgroundRecoveryGood, kBackgroundRecoveryPoor);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'p75Ms': v,
      'worstMs': _recoveryWorstMs,
      'returnCount': count,
    };
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'p75Ms': null,
      'worstMs': 0,
      'returnCount': 0,
    };
  }
}

Map<String, Object?> _readChurn(bool wired, int count) {
  final snap = _residencySnapshot();
  final fg = snap[0];
  final activeMin = (fg / 60000).round();
  if (!wired || fg < kLifecycleMinActiveMs) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'perHour': null,
      'count': count,
      'activeMin': activeMin,
    };
  }
  final hours = (fg / 3600000) > (1 / 60) ? (fg / 3600000) : (1 / 60);
  final perHour = count / hours;
  // NEVER GRADED. Rotating a phone and switching to dark mode are things the
  // person holding the device does; the app cannot stop them.
  return <String, Object?>{
    'score': null,
    'rating': 'not-scored',
    'measurable': 1,
    'perHour': (perHour * 10).round() / 10,
    'count': count,
    'activeMin': activeMin,
  };
}

Map<String, Object?> readDimensionChurn() {
  try {
    return _readChurn(_dimensionWired, _dimensionCount);
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'perHour': null,
      'count': 0,
      'activeMin': 0,
    };
  }
}

Map<String, Object?> readAppearanceChurn() {
  try {
    return _readChurn(_appearanceWired, _appearanceCount);
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'perHour': null,
      'count': 0,
      'activeMin': 0,
    };
  }
}

/// OS memory warnings within the stated foreground-session window.
///
/// The gate can never open on an empty numerator: a count of zero has to WAIT
/// for one observed foreground minute before it is stated, and a warning that
/// actually fired surfaces immediately. Previously the zero-count branch was
/// reachable with no foreground time at all whenever `fg` had been inflated by
/// background, so the axis could publish "0 warnings in 0 min".
///
/// NEVER GRADED: the OS decides when to warn, and it decides largely on how
/// much memory the DEVICE has. See
/// docs/decisions/meter-verdicts-that-are-not-about-the-app.md.
Map<String, Object?>? readMemoryWarnings() {
  try {
    final fg = _residencySnapshot()[0];
    if (!_memoryWarningsWired) return null;
    // A zero count is only publishable once we have genuinely watched.
    if (_memoryWarningCount == 0 && fg < kLifecycleMinActiveMs) return null;
    // And a count, zero or not, is only publishable against a real window.
    if (fg <= 0) return null;
    final windowMin = (fg / 60000 * 10).round() / 10;
    return <String, Object?>{
      'present': 1,
      'measurable': 1,
      'count': _memoryWarningCount,
      'windowMin': windowMin,
      'score': null,
      'rating': 'not-scored',
    };
  } catch (_) {
    return null;
  }
}

/// The shared foreground clock (ms) other observers reuse for their rate
/// denominators (e.g. unhandled_errors activeMs). Never throws.
int foregroundActiveMs() {
  try {
    return _residencySnapshot()[0];
  } catch (_) {
    return 0;
  }
}

/// Test hooks — deterministic, no dependence on real lifecycle callbacks.
class LifecycleInternals {
  static bool get isInstalled => _appStateWired;

  static void setWiredForTests(
      {bool? appState, bool? dimension, bool? appearance}) {
    if (appState != null) _appStateWired = appState;
    if (dimension != null) _dimensionWired = dimension;
    if (appearance != null) _appearanceWired = appearance;
  }

  static void setClockForTests(int fgMs, int observedMs, {bool active = true}) {
    _foregroundMs = fgMs < 0 ? 0 : fgMs;
    _observedMs = observedMs < _foregroundMs ? _foregroundMs : observedMs;
    _currentActive = active;
    _backgroundChargedMs = 0;
    _lastStateAt = 0; // freeze: reads won't fold an in-progress segment
  }

  /// Observed-session clock (ms) — what the residency fraction divides by.
  static int get observedMsForTests => _observedMs;

  /// Start a session at an explicit monotonic timestamp, then drive real
  /// transitions at explicit timestamps, so a multi-hour session can be walked
  /// without waiting for one.
  static void startSessionAtForTests(int nowMs, {bool active = true}) {
    _appStateWired = true;
    _currentActive = active;
    _lastStateAt = nowMs;
    _foregroundMs = 0;
    _observedMs = 0;
    _backgroundChargedMs = 0;
  }

  static void noteLifecycleStateAtForTests(bool active, int nowMs) =>
      _noteLifecycleStateAt(active, nowMs);

  /// How much of the current unbroken background stretch's allowance has been
  /// spent (ms). Exposed so a test can prove the cap is per STRETCH.
  static int get backgroundChargedMsForTests => _backgroundChargedMs;

  static void fireDimensionForTests([int n = 1]) {
    _dimensionCount += n < 0 ? 0 : n;
  }

  static void fireAppearanceForTests([int n = 1]) {
    _appearanceCount += n < 0 ? 0 : n;
  }

  static void fireMemoryWarningForTests([int n = 1]) {
    _memoryWarningsWired = true;
    _memoryWarningCount += n < 0 ? 0 : n;
  }

  static void fireRecoveryForTests(List<int> msValues) {
    for (final ms in msValues) {
      _recoverySamples.add(ms);
      if (ms > _recoveryWorstMs) _recoveryWorstMs = ms;
    }
  }

  static void reset() => uninstallLifecycleTracking();
}
