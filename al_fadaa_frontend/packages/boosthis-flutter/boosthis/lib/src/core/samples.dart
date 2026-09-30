import 'dart:math' as math;

import 'runtime_flags.dart';
import 'safe.dart';
import 'sample_uploader.dart';
import 'score.dart';
import 'store.dart';
import 'telemetry.dart';

/// The measurement ring — the rolling window of RECENT completed measurements.
///
/// Lives in Store's process-wide map (persisted only in memory; a rolling perf
/// window need not survive a restart). Entries are compact triples
/// `[route, durationMs, atMs]`, matching the sibling wire shape so a snapshot
/// reads identically across runtimes.
///
/// Nothing here is user data: a route label has already passed the route guard,
/// a duration is a number, and a timestamp is a clock reading.
class Samples {
  Samples._();

  static const String key = 'samples';

  /// Hard cap. A busy app must never grow this window without bound.
  static const int maxSamples = 500;

  /// Samples older than this are dropped on write — the meters are about now.
  static const int maxAgeMs = 3600000;

  /// Record one completed measurement. Silently ignores an unsafe label.
  static void record(String route, num durationMs, [int? atMs]) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      if (_routeLabelHasPii(route)) return;
      final at = atMs ?? Telemetry.nowMs();
      final d = math.max(0, durationMs).round();
      final rating = Score.getDurationRating(d.toDouble());
      Store.update(key, <Object?>[], (cur) {
        final list = <Object?>[];
        if (cur is List) list.addAll(cur);
        list.add(<Object?>[route, d, at]);
        final cutoff = at - maxAgeMs;
        final kept = <Object?>[];
        for (final s in list) {
          if (s is List && s.length == 3) {
            final ts = _asInt(s[2]);
            if (ts >= cutoff) kept.add(s);
          }
        }
        if (kept.length > maxSamples) {
          return kept.sublist(kept.length - maxSamples);
        }
        return kept;
      });
      // Feed the upload queue at the single record boundary, reusing the exact
      // label and normalized duration just written to the local ring.
      SampleUploader.enqueue(route, d, rating);
    });
  }

  /// Oldest-first list of samples as `{route, durationMs, at}` — string keys,
  /// matching the siblings and every consumer.
  static List<Map<String, Object?>> all() {
    final raw = Store.get(key, <Object?>[]);
    if (raw is! List) return <Map<String, Object?>>[];
    final out = <Map<String, Object?>>[];
    for (final s in raw) {
      if (s is List && s.length == 3) {
        out.add(<String, Object?>{
          'route': '${s[0]}',
          'durationMs': _asInt(s[1]),
          'at': _asInt(s[2]),
        });
      }
    }
    return out;
  }

  /// Durations only, oldest-first.
  static List<int> durations() =>
      all().map((s) => _asInt(s['durationMs'])).toList();

  static int count() => all().length;

  static void clear() => Store.delete(key);

  /// Percentile over a list of numbers. FROZEN gate (identical to every other
  /// kit): `idx = min(len - 1, (len * p).floor())` on a sorted copy. Returns
  /// 0.0 for an empty list.
  static double percentile(List<num> values, double p) {
    if (values.isEmpty) return 0.0;
    final sorted = List<num>.from(values)..sort();
    final len = sorted.length;
    var idx = (len * p).floor();
    if (idx > len - 1) idx = len - 1;
    if (idx < 0) idx = 0;
    return sorted[idx].toDouble();
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.round();
    return 0;
  }

  /// Route-label PII guard hook. The Pii group (a sibling ownership group) wires
  /// the real check via [setRouteLabelGuard]; it returns the denied fragment, or
  /// null when the label is clean. Until wired, the default is a conservative
  /// pass (clean) so a not-yet-loaded guard never drops every measurement —
  /// route labels are code-defined screen names, not user input. The guard is
  /// still applied before any label leaves the device by transmit's own PII
  /// screen, so this hook is a first, not last, line of defence.
  static String? Function(String label) _routeGuard = (_) => null;

  /// Wire the route-label PII guard. Called by the Pii/observers group.
  static void setRouteLabelGuard(String? Function(String label) guard) {
    _routeGuard = guard;
  }

  static bool _routeLabelHasPii(String route) {
    return Safe.run<bool>(true, () => _routeGuard(route) != null);
  }
}
