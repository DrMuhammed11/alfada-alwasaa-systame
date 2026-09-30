// Network sampler (FIELD-CAPABLE, instrumented-outbound-only).
//
// The Flutter sibling of the RN networkSampler. It surfaces the class of bug
// where an outbound call silently HANGS or DROPS — invisible because nothing
// ever rejects and nothing is logged. The host app (or the kit's Dio/http
// interceptor / chained HttpOverrides) reports, per network attempt, only how
// long it took and how it ended.
//
// PRIVACY CONTRACT (load-bearing): the public API accepts ONLY a duration and a
// coarse outcome bucket. There is deliberately NO parameter for a URL, host,
// path, query string, header, body, status code, or any per-request label — so
// nothing that could identify a request, user, or destination ever reaches this
// layer. The aggregate it exposes (counts + durations only) clears the shared
// PII guard exactly like every other axis.
//
// INSTRUMENTED-OUTBOUND-ONLY: only calls the host routed through the kit's
// wrapper are ever counted; the kit never silently intercepts every socket.
//
// This is the `network` axis input source. It stays "pending" until the host
// reports a few attempts, and it never touches the composite speed score.

import '../core/runtime_flags.dart';
import 'trace.dart';

/// How an attempt ended. Coarse buckets only — never a status code or message.
///   - "ok":      the request completed (success or not)
///   - "error":   the request failed loudly (the app KNEW it failed)
///   - "timeout": the caller's own timer fired before any response
///   - "stall":   completed, but slow enough to flag as a near-hang
class NetworkOutcome {
  NetworkOutcome._();
  static const String ok = 'ok';
  static const String error = 'error';
  static const String timeout = 'timeout';
  static const String stall = 'stall';

  static const List<String> valid = <String>[ok, error, timeout, stall];
}

/// Pure-Dart outbound sample recorder + the `network` axis inputs.
class NetworkSampler {
  NetworkSampler._();

  /// Keep the percentile window bounded so a long session can't grow memory.
  static const int maxDurations = 200;

  /// Defensive clamp: never let a bogus caller duration skew worst/p75.
  static const int maxDurationMs = 120000;

  static int _attempts = 0;
  static int _completed = 0;
  static int _failed = 0;
  static int _timeouts = 0;
  static int _stalls = 0;
  static double _worst = 0;
  static final List<double> _durations = <double>[];

  /// Report one network attempt. Counts + duration only — NO URL/label ever.
  /// No-op when Boosthis is disabled or the outcome bucket is unrecognised.
  static void record({required double durationMs, required String outcome}) {
    if (RuntimeFlags.disabled) return;
    if (!NetworkOutcome.valid.contains(outcome)) return;

    var d = durationMs.isFinite ? durationMs : 0.0;
    if (d < 0) d = 0;
    if (d > maxDurationMs) d = maxDurationMs.toDouble();

    _attempts++;
    switch (outcome) {
      case NetworkOutcome.ok:
        _completed++;
        break;
      case NetworkOutcome.error:
        _failed++;
        break;
      case NetworkOutcome.timeout:
        _timeouts++;
        break;
      case NetworkOutcome.stall:
        _stalls++;
        break;
    }
    if (d > _worst) _worst = d;
    _durations.add(d);
    if (_durations.length > maxDurations) {
      _durations.removeAt(0);
    }
  }

  /// Pure read — does not mutate counters. Counts + durations only.
  static Map<String, Object?> getStats() => <String, Object?>{
        'attemptCount': _attempts,
        'completedCount': _completed,
        'failedCount': _failed,
        'timeoutCount': _timeouts,
        'stallCount': _stalls,
        'p75Ms': _percentile(_durations, 75),
        'worstMs': _worst.round(),
      };

  /// Percentile over the recent-attempt ring, byte-identical index policy to
  /// the RN sampler: idx = min(len - 1, max(0, floor((p/100) * len))).
  static int _percentile(List<double> values, int p) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    var idx = ((p / 100) * sorted.length).floor();
    if (idx < 0) idx = 0;
    if (idx > sorted.length - 1) idx = sorted.length - 1;
    return sorted[idx].round();
  }

  /// Convenience wrapper: time a Future-returning network call and report the
  /// attempt automatically. Records "ok" on success (or "stall" when a stallMs
  /// threshold is given and exceeded) and "error" on failure, then re-throws so
  /// the caller's own error handling is unchanged. Like [record], it never sees
  /// a URL/label — pass the bare call.
  static Future<T> measure<T>(Future<T> Function() fn, {int? stallMs}) async {
    final start = Trace.nowMs();
    try {
      final result = await fn();
      final durationMs = Trace.nowMs() - start;
      record(
        durationMs: durationMs,
        outcome: (stallMs != null && stallMs > 0 && durationMs >= stallMs)
            ? NetworkOutcome.stall
            : NetworkOutcome.ok,
      );
      return result;
    } catch (_) {
      record(durationMs: Trace.nowMs() - start, outcome: NetworkOutcome.error);
      rethrow;
    }
  }

  /// Reset all counters (forget() hook + tests). Idempotent.
  static void clear() {
    _attempts = 0;
    _completed = 0;
    _failed = 0;
    _timeouts = 0;
    _stalls = 0;
    _worst = 0;
    _durations.clear();
  }
}
