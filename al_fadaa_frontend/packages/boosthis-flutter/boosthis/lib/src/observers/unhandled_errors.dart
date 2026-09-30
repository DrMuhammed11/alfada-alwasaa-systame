/// Boosthis: Unhandled-error + async-rejection rate axes (Flutter).
///
/// Two ADDITIVE, display-only meters that count how often the app's global
/// error reporters fire, per foreground hour. Both are error-hygiene signals —
/// DISTINCT from crashFree (which counts crashes the kit's crash reporter
/// captured) because here we simply chain the host's global handlers and TALLY,
/// never suppressing or altering what the host sees.
///
/// NON-NEGOTIABLE (crash-reporter guest-safety): the host handlers are CHAINED,
/// never replaced. The adapter/integration group stores the host's previous
/// `FlutterError.onError` / `PlatformDispatcher.onError` and ALWAYS calls them,
/// then calls the note functions here. We observe ONLY a count — never the
/// error object, message, or stack. If chaining fails the axis reads pending.
///
///   • unhandledErrors    — global framework/uncaught errors per foreground
///     hour (chained FlutterError.onError). Absent until wired.
///   • promiseRejections  — unhandled ASYNC (zone) errors per foreground hour
///     (chained PlatformDispatcher.onError). Absent until wired.
///
/// HONESTY: NEVER feed the composite Speed score. NOT WIRED ⇒ PENDING (null
/// score). A ZERO-count reading stays pending until enough foreground time has
/// passed; a fired error surfaces IMMEDIATELY. Numbers-only wire
/// ({ score, rating, count, perHour, windowMin }). This module is pure-Dart
/// counters; installing the handler chains is the integration group's job.
library;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

/// Errors/rejections per foreground hour bands. <=1/hr → 100; >=30/hr → 0.
const int kUnhandledErrorGood = 1;
const int kUnhandledErrorPoor = 30;
const int kPromiseRejectionGood = 1;
const int kPromiseRejectionPoor = 30;

/// Observe at least this much foreground time before a ZERO-count reading
/// leaves "pending" — an error surfaces immediately regardless.
const int kErrMinActiveMs = 60000;

bool _errorInstalled = false;
int _errorCount = 0;

bool _rejectionInstalled = false;
int _rejectionCount = 0;

/// Mark the unhandled-error chain live. Called by the integration group once it
/// has chained FlutterError.onError. Idempotent.
void installUnhandledErrorTracking() {
  _errorInstalled = true;
}

/// Mark the async-rejection chain live. Called once PlatformDispatcher.onError
/// is chained. Idempotent.
void installPromiseRejectionTracking() {
  _rejectionInstalled = true;
}

/// Observe ONE global/uncaught error. Never throws. Called from inside the
/// chained handler; the host's own handler is always invoked separately.
void noteUnhandledError() {
  try {
    _errorCount += 1;
  } catch (_) {
    // best-effort
  }
}

/// Observe ONE unhandled async (zone/platform) error. Never throws.
void noteRejection() {
  try {
    _rejectionCount += 1;
  } catch (_) {
    // best-effort
  }
}

Map<String, Object?> _rate(
    bool installed, int count, num activeMs, int good, int poor) {
  final ms = activeMs > 0 ? activeMs.toDouble() : 0.0;
  final windowMin = (ms / 60000).round();
  final n = count < 0 ? 0 : count;
  if (!installed) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'count': n,
      'perHour': null,
      'windowMin': windowMin,
    };
  }
  if (n == 0 && ms < kErrMinActiveMs) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'count': 0,
      'perHour': null,
      'windowMin': windowMin,
    };
  }
  final hours = (ms / 3600000) > (1 / 60) ? (ms / 3600000) : (1 / 60);
  final perHour = n / hours;
  final score = linearScore(perHour, good, poor);
  return <String, Object?>{
    'score': score,
    'rating': ratingFor(score),
    'count': n,
    'perHour': (perHour * 10).round() / 10,
    'windowMin': windowMin,
  };
}

/// The Unhandled-error rate axis. Pure read — never throws. [activeMs] is the
/// shared foreground clock (lifecycle_axes).
Map<String, Object?> readUnhandledErrors(num activeMs) {
  try {
    return _rate(_errorInstalled, _errorCount, activeMs, kUnhandledErrorGood,
        kUnhandledErrorPoor);
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'count': 0,
      'perHour': null,
      'windowMin': 0,
    };
  }
}

/// The async-rejection rate axis. Pure read — never throws.
Map<String, Object?> readPromiseRejections(num activeMs) {
  try {
    return _rate(_rejectionInstalled, _rejectionCount, activeMs,
        kPromiseRejectionGood, kPromiseRejectionPoor);
  } catch (_) {
    return <String, Object?>{
      'score': null,
      'rating': 'pending',
      'count': 0,
      'perHour': null,
      'windowMin': 0,
    };
  }
}

/// Drop unhandled-error state. Idempotent, NEVER throws. Wired into
/// telemetry.forget().
void uninstallUnhandledErrorTracking() {
  _errorInstalled = false;
  _errorCount = 0;
}

/// Drop async-rejection state. Idempotent, NEVER throws.
void uninstallPromiseRejectionTracking() {
  _rejectionInstalled = false;
  _rejectionCount = 0;
}

/// Test hooks — deterministic, no dependence on real handlers.
class UnhandledInternals {
  static bool get errorInstalled => _errorInstalled;
  static bool get rejectionInstalled => _rejectionInstalled;
  static int get errorCount => _errorCount;
  static int get rejectionCount => _rejectionCount;

  static void setErrorInstalledForTests(bool v) => _errorInstalled = v;
  static void setRejectionInstalledForTests(bool v) => _rejectionInstalled = v;

  static void fireErrorForTests([int n = 1]) {
    _errorCount += n < 0 ? 0 : n;
  }

  static void fireRejectionForTests([int n = 1]) {
    _rejectionCount += n < 0 ? 0 : n;
  }

  static void reset() {
    uninstallUnhandledErrorTracking();
    uninstallPromiseRejectionTracking();
  }
}
