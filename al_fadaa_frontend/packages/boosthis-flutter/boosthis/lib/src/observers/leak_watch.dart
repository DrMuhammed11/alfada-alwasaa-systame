/// Boosthis: Leak Watch axis source (Flutter).
///
/// Detects the HOST app leaking stack traces, secrets/keys, or personal
/// details TO ITS OWN USERS. On Flutter the only user-visible surface a kit
/// can honestly observe is logged output — `debugPrint` and framework error
/// dumps render logged stack traces, and app code funnels leaked values
/// through them. So this axis PIGGYBACKS the SAME log chain that
/// swallowed_errors installs (see swallowed_errors.dart): there is NO second
/// wrapper and NO second hook. The swallowed_errors chain calls [noteLeakScan]
/// with the stringified text; we classify and count here.
///
/// ABSOLUTE PRIVACY RULE: the matched text, the matched value, and the log line
/// NEVER leave the local classification scope. Nothing but a timestamp and a
/// category enum is retained.
///
/// Categories (each observation classified into EXACTLY ONE, priority
/// secret > pii > stack, so stackCount + secretCount + piiCount === count):
///   • secret — JWT / bearer / AWS key id / PEM private key / api_key=… assign
///   • pii    — the kit's canonical email regex (reused from pii.dart)
///   • stack  — a stack-frame shape (rendered to the user)
///
/// Gates + bands (mirror swallowed_errors mechanics exactly):
///   • 5-minute minimum observation window before the axis reports at all,
///   • 60-minute trailing window,
///   • bounded ring of {ts, cat}, cap 200,
///   • score = 100 when count === 0; otherwise max(0, 70 - round(perHour*10)).
///
/// HONESTY: NEVER feeds the composite Speed score. WARMING ⇒ OMITTED (null).
/// The caption reads "no leaks observed" (absence of evidence), never "you are
/// protected".
library;

import '../core/telemetry.dart' show Telemetry;
import '../meters/meter_axes.dart' show ratingFor;
import 'pii.dart' show piiEmailRe;

/// Trailing window the rate is measured over (60 minutes).
const int kLeakWindowMs = 60 * 60000;

/// Minimum observation window before the axis reports (5 minutes).
const int kLeakMinWindowMs = 5 * 60000;

/// Ring cap — at most this many {ts, cat} events retained (oldest dropped).
const int kLeakRingCap = 200;

/// Only the first this-many chars of a stringified message are scanned.
const int kLeakScanLimit = 4096;

/// The three closed leak categories.
enum LeakCategory { secret, pii, stack }

// Detection patterns (conservative; ONLY these). Match SHAPES, never capture.
final RegExp _stackJsFrameRe = RegExp(r'\bat .{1,200}\(.{1,200}:\d+:\d+\)');
final RegExp _stackJsErrorRe = RegExp(r'Error:[\s\S]*?\n\s+at ');
final RegExp _stackPyRe = RegExp(r'Traceback \(most recent call last\)');
final RegExp _stackGoRe = RegExp(r'goroutine \d+ \[|\.go:\d+ \+0x');
final RegExp _stackJavaRe = RegExp(r'\bat [\w.$]+\([\w$]+\.java:\d+\)');
// Dart stack frames ("#0  Foo.bar (package:app/x.dart:12:3)") render to the
// user through FlutterError dumps just like the others.
final RegExp _stackDartRe = RegExp(r'#\d+\s+.+\(.+\.dart:\d+(?::\d+)?\)');

final RegExp _secretJwtRe =
    RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+');
final RegExp _secretBearerRe = RegExp(r'bearer\s+\S{8,}', caseSensitive: false);
final RegExp _secretAwsRe = RegExp(r'AKIA[0-9A-Z]{16}');
final RegExp _secretPemRe = RegExp(r'-----BEGIN [\s\S]*?PRIVATE KEY');
final RegExp _secretAssignRe = RegExp(
    r'''(api[_-]?key|secret|token)["']?\s*[:=]\s*["']?[A-Za-z0-9_\-]{16,}''',
    caseSensitive: false);

/// Classify a bounded slice into EXACTLY ONE category (priority
/// secret > pii > stack) or null. Content is examined only locally.
LeakCategory? _classify(String text) {
  if (_secretJwtRe.hasMatch(text) ||
      _secretBearerRe.hasMatch(text) ||
      _secretAwsRe.hasMatch(text) ||
      _secretPemRe.hasMatch(text) ||
      _secretAssignRe.hasMatch(text)) {
    return LeakCategory.secret;
  }
  if (piiEmailRe.hasMatch(text)) return LeakCategory.pii;
  if (_stackJsFrameRe.hasMatch(text) ||
      _stackJsErrorRe.hasMatch(text) ||
      _stackPyRe.hasMatch(text) ||
      _stackGoRe.hasMatch(text) ||
      _stackJavaRe.hasMatch(text) ||
      _stackDartRe.hasMatch(text)) {
    return LeakCategory.stack;
  }
  return null;
}

/// One retained event — a TIMESTAMP and a CATEGORY only. Never any content.
class _LeakEvent {
  final int ts;
  final LeakCategory cat;
  _LeakEvent(this.ts, this.cat);
}

bool _installed = false;
int _startedAt = 0;
final List<_LeakEvent> _events = <_LeakEvent>[];

int _nowMs() => Telemetry.nowMs();

/// Mark the leakWatch collector live. Called by the shared log chain once the
/// wrapper is installed — leakWatch has NO wrapper of its own. Idempotent;
/// resets the window origin on first install.
void markLeakWatchInstalled() {
  if (_installed) return;
  _installed = true;
  _startedAt = _nowMs();
  _events.clear();
}

/// Mark the collector off (shared wrapper uninstalled). Drops all state.
void markLeakWatchUninstalled() {
  _installed = false;
  _startedAt = 0;
  _events.clear();
}

/// Scan ONE logged output for leaks. Called from INSIDE the shared log chain
/// (swallowed_errors), AFTER the host call. [text] is the already-stringified
/// message. We slice to kLeakScanLimit, classify into exactly one category, and
/// retain ONLY {ts, cat}. Never throws, never returns or stores content.
void noteLeakScan(String text) {
  try {
    if (!_installed) return;
    if (text.isEmpty) return;
    final slice =
        text.length > kLeakScanLimit ? text.substring(0, kLeakScanLimit) : text;
    final cat = _classify(slice);
    if (cat == null) return;
    _events.add(_LeakEvent(_nowMs(), cat));
    if (_events.length > kLeakRingCap) {
      _events.removeRange(0, _events.length - kLeakRingCap);
    }
  } catch (_) {
    // best-effort — a scan slip must never reach the host's logging call
  }
}

/// The Leak Watch axis. Pure read — never mutates state, NEVER throws.
///   • not installed → { measurable: 0 } (the tile explains itself),
///   • installed but inside the 5-minute min window → null (OMITTED / warming),
///   • otherwise the full reading.
Map<String, Object?>? readLeakWatch() {
  try {
    if (!_installed) {
      return <String, Object?>{'measurable': 0};
    }
    final now = _nowMs();
    var windowMs = now - _startedAt;
    if (windowMs > kLeakWindowMs) windowMs = kLeakWindowMs;
    if (windowMs < kLeakMinWindowMs) {
      return null;
    }
    final cutoff = now - windowMs;
    var count = 0;
    var stackCount = 0;
    var secretCount = 0;
    var piiCount = 0;
    for (final e in _events) {
      if (e.ts < cutoff) continue;
      count += 1;
      if (e.cat == LeakCategory.secret) {
        secretCount += 1;
      } else if (e.cat == LeakCategory.pii) {
        piiCount += 1;
      } else {
        stackCount += 1;
      }
    }
    final hours = windowMs / 3600000;
    final perHour = hours > 0 ? count / hours : 0.0;
    final score = count == 0
        ? 100
        : (70 - (perHour * 10).round() < 0 ? 0 : 70 - (perHour * 10).round());
    final windowMinRounded = (windowMs / 60000).round();
    final caption = count == 0
        ? 'no leaks observed in this window \u00b7 $windowMinRounded min watched'
        : _leakSummary(count, secretCount, piiCount, stackCount);
    return <String, Object?>{
      'score': score,
      'rating': ratingFor(score),
      'count': count,
      'perHour': (perHour * 10).round() / 10,
      'windowMin': ((windowMs / 60000) * 10).round() / 10,
      'stackCount': stackCount,
      'secretCount': secretCount,
      'piiCount': piiCount,
      'caption': caption,
    };
  } catch (_) {
    return <String, Object?>{'measurable': 0};
  }
}

/// Build a counts-and-category-words-only caption. NEVER content.
String _leakSummary(int count, int secretCount, int piiCount, int stackCount) {
  final parts = <String>[];
  if (secretCount > 0) parts.add('$secretCount secret-like');
  if (piiCount > 0) parts.add('$piiCount personal-detail');
  if (stackCount > 0) {
    parts.add('$stackCount stack trace${stackCount != 1 ? 's' : ''}');
  }
  final noun = 'possible leak${count != 1 ? 's' : ''}';
  return '$count $noun observed (${parts.join(', ')})';
}

/// Test hooks — deterministic, no dependence on a real log chain.
class LeakWatchInternals {
  static bool get isInstalled => _installed;
  static int get count => _events.length;

  static LeakCategory? classifyForTests(String text) => _classify(
      text.length > kLeakScanLimit ? text.substring(0, kLeakScanLimit) : text);

  static void setInstalledForTests(bool v) {
    _installed = v;
    if (v && _startedAt == 0) _startedAt = _nowMs();
  }

  static void fireForTests(LeakCategory cat, {int n = 1, int? at}) {
    for (var i = 0; i < (n < 0 ? 0 : n); i++) {
      _events.add(_LeakEvent(at ?? _nowMs(), cat));
    }
    if (_events.length > kLeakRingCap) {
      _events.removeRange(0, _events.length - kLeakRingCap);
    }
  }

  static void setStartedAtForTests(int ms) {
    _startedAt = ms;
  }

  static void reset() => markLeakWatchUninstalled();
}
