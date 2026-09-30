/// Boosthis: outbound retry-storm / fan-out detector (Flutter).
///
/// A port of the Ruby/PHP/Java/Go LiveDetectors. Two observe-only detectors
/// that surface outbound anti-patterns the per-route timer cannot see, emitted
/// as ordinary crossCutting findings so they ride the EXISTING snapshot
/// pipeline (no new server route, no new table):
///
///   • retry-storm — the same outbound host is hammered many times in a short
///     window with no backoff (a missing-retry-budget bug).
///   • api-thundering-herd — many DISTINCT hosts contacted inside one very
///     short window (a fan-out burst), derived from the SAME attempt buffer.
///
/// EXPLICIT-API-ONLY, exactly like the siblings. A drop-in kit never swaps the
/// host's HTTP client, so detection is fed ONLY when the host calls
/// [recordOutboundAttempt] (or the kit's own chained HttpOverrides / Dio
/// interceptor). Host apps see nothing unless they opt in.
///
/// PRIVACY: the finding `name` is a bare outbound HOSTNAME (retry-storm) or a
/// fixed label (fan-out) — never a path, query, userinfo, or port — and is
/// PII-guarded again at the transmit chokepoint. The snapshot number
/// `events.retryBurstMax10s` is an anonymous COUNT only. Silenced entirely by
/// the kill-switch.
///
/// Tunables and algorithms are byte-parity with the siblings.
library;

import '../core/runtime_flags.dart' show RuntimeFlags;
import '../core/safe.dart' show Safe;
import '../core/store.dart' show Store;
import '../core/telemetry.dart' show Telemetry;

/// Rolling window for counting outbound attempts to one host (ms).
const int kRetryWindowMs = 10000;

/// Attempts to one host within the window before it counts as a storm.
const int kRetryStormThreshold = 5;

/// Median inter-attempt gap (ms) at/above which we assume real backoff.
const int kRetryBackoffMs = 1000;

/// Cap distinct tracked hosts so a fan-out app can't grow this unbounded.
const int kMaxTrackedHosts = 200;

/// Many DISTINCT hosts contacted this close together (ms) = a fan-out.
const int kClusterWindowMs = 50;

/// Distinct hosts within kClusterWindowMs at/above which we flag it.
const int kClusterHostThreshold = 3;

// Cross-request state keys (byte-parity with the siblings).
const String _keyAttempts = 'live.attemptsByHost';
const String _keyIgnored = 'live.ignoredHosts';
const String _keyBurstPeak = 'live.retryBurstPeak';

/// Outbound outcome buckets (forwarded to the network meter axis).
const int outboundOk = 0;
const int outboundError = 1;
const int outboundTimeout = 2;
const int outboundStall = 3;

/// Extract a bare, non-PII hostname from a URL/origin/host string. Returns ""
/// when nothing host-shaped is present. Never throws. Path, query, userinfo,
/// and port are all discarded.
String hostOf(Object? target) {
  if (target == null) return '';
  return Safe.run('', () {
    var s = target.toString().trim();
    if (s.isEmpty) return '';
    if (s.contains('://')) {
      final uri = Uri.tryParse(s);
      if (uri != null && uri.host.isNotEmpty) return uri.host.toLowerCase();
    }
    final at = s.lastIndexOf('@');
    if (at >= 0) s = s.substring(at + 1); // strip userinfo
    s = s.split('/').first;
    s = s.split('?').first;
    s = s.split(':').first; // strip port
    return s.toLowerCase();
  });
}

/// Exclude a host from retry-storm accounting (Boosthis's own endpoint, so the
/// kit's flushes never self-trigger a finding naming our own API host).
/// Idempotent; only a bare hostname is ever stored.
void ignoreHost(Object? target) {
  final host = hostOf(target);
  if (host.isEmpty) return;
  Safe.fire(() {
    Store.update(_keyIgnored, <String, Object?>{}, (cur) {
      final set = cur is Map ? Map<String, Object?>.from(cur) : <String, Object?>{};
      set[host] = true;
      return set;
    });
  });
}

/// Record one outbound attempt to [target] (a URL, origin, or bare host). Safe
/// to call on every request; a no-op under the kill-switch. Never throws.
void recordOutboundAttempt(Object? target) {
  if (RuntimeFlags.disabled) return;
  final host = hostOf(target);
  if (host.isEmpty) return;
  Safe.fire(() {
    final ignored = Store.get(_keyIgnored, <String, Object?>{});
    if (ignored is Map && ignored[host] == true) return;

    final now = Telemetry.nowMs();
    Store.update(_keyAttempts, <String, Object?>{}, (cur) {
      final byHost =
          cur is Map ? Map<String, Object?>.from(cur) : <String, Object?>{};
      if (!byHost.containsKey(host)) {
        if (byHost.length >= kMaxTrackedHosts) return byHost; // bounded
        byHost[host] = <int>[];
      }
      final arr = byHost[host] is List
          ? List<int>.from((byHost[host] as List).map((e) => (e as num).toInt()))
          : <int>[];
      arr.add(now);
      final cutoff = now - kRetryWindowMs;
      while (arr.isNotEmpty && arr[0] < cutoff) {
        arr.removeAt(0);
      }
      byHost[host] = arr;
      return byHost;
    });

    // Session-peak burst counter (events.retryBurstMax10s): only qualifying
    // storms count — enough attempts in the window AND no real backoff.
    final byHost = Store.get(_keyAttempts, <String, Object?>{});
    final arr = (byHost is Map && byHost[host] is List)
        ? List<int>.from((byHost[host] as List).map((e) => (e as num).toInt()))
        : <int>[];
    if (arr.length >= kRetryStormThreshold && medianGapMs(arr) < kRetryBackoffMs) {
      final size = arr.length;
      Store.update(_keyBurstPeak, 0, (cur) {
        final c = cur is int ? cur : 0;
        return size > c ? size : c;
      });
    }
  });
}

/// Record the COMPLETION of a previously-observed outbound attempt — duration
/// (ms) and a coarse outcome bucket. The network meter axis is a sibling class;
/// this method is the SAME host-owned observation surface. Degrades to a no-op
/// when that meter is not present. No-op under the kill-switch; never throws.
void recordOutboundResult(num durationMs, int outcome) {
  if (RuntimeFlags.disabled) return;
  Safe.fire(() {
    // The network meter forwards counts + durations only. It is a separate
    // sibling part; the integration/meters group wires the forward. Absent →
    // no-op (nothing to forward to here).
  });
}

/// Median inter-attempt gap of an ascending timestamp list (0 for < 2).
double medianGapMs(List<int> sortedTs) {
  final n = sortedTs.length;
  if (n < 2) return 0.0;
  final gaps = <int>[];
  for (var i = 1; i < n; i++) {
    gaps.add(sortedTs[i] - sortedTs[i - 1]);
  }
  gaps.sort();
  final g = gaps.length;
  final mid = g ~/ 2;
  if (g.isEven) {
    return (gaps[mid - 1] + gaps[mid]) / 2.0;
  }
  return gaps[mid].toDouble();
}

/// Drain the current live-detector findings so they ride the same crossCutting
/// + snapshot path as every other finding. Empty under the kill-switch. Never
/// throws.
List<Map<String, Object?>> collectDetectorFindings() {
  if (RuntimeFlags.disabled) return <Map<String, Object?>>[];
  return Safe.run(<Map<String, Object?>>[], () {
    final now = Telemetry.nowMs();
    final raw = Store.get(_keyAttempts, <String, Object?>{});
    final byHost = raw is Map ? raw : <String, Object?>{};
    final findings = _collectRetryStorms(byHost, now);
    for (final f in _collectConcurrentClusters(byHost, now)) {
      findings.add(f);
    }
    return findings;
  });
}

/// Session-peak same-destination retry-burst strength; 0 when no storm was
/// observed. Ships as the anonymous `events.retryBurstMax10s` number. No-op (0)
/// under the kill-switch.
int peakRetryBurst() {
  if (RuntimeFlags.disabled) return 0;
  return Safe.run(0, () {
    final v = Store.get(_keyBurstPeak, 0);
    return v is int ? v : 0;
  });
}

/// Wipe all detector state (wired into forget()). Idempotent.
void clearDetectors() {
  Safe.fire(() {
    Store.delete(_keyAttempts);
    Store.delete(_keyIgnored);
    Store.delete(_keyBurstPeak);
  });
}

List<Map<String, Object?>> _collectRetryStorms(Map byHost, int now) {
  final out = <Map<String, Object?>>[];
  final cutoff = now - kRetryWindowMs;
  byHost.forEach((host, ts) {
    final arr = ts is List
        ? List<int>.from(ts.map((e) => (e as num).toInt()))
        : <int>[];
    while (arr.isNotEmpty && arr[0] < cutoff) {
      arr.removeAt(0);
    }
    if (arr.length < kRetryStormThreshold) return;
    if (medianGapMs(arr) >= kRetryBackoffMs) return; // backoff present → fine
    out.add(<String, Object?>{
      'kind': 'retry-storm',
      'name': host.toString(),
      'p95': arr[arr.length - 1] - arr[0],
      'count': arr.length,
    });
  });
  return out;
}

/// Detect an outbound fan-out burst: many DISTINCT hosts all contacted within a
/// very short window. Algorithm byte-identical to the siblings.
List<Map<String, Object?>> _collectConcurrentClusters(Map byHost, int now) {
  final cutoff = now - kRetryWindowMs;
  final idx = <List<int>>[]; // [ts, hostIndex]
  final hostIndex = <Object, int>{};
  var nextIndex = 0;
  byHost.forEach((host, ts) {
    final arr = ts is List ? ts : const <dynamic>[];
    for (final t in arr) {
      final ti = (t as num).toInt();
      if (ti < cutoff) continue;
      if (!hostIndex.containsKey(host)) {
        hostIndex[host] = nextIndex;
        nextIndex += 1;
      }
      idx.add(<int>[ti, hostIndex[host]!]);
    }
  });
  if (idx.length < kClusterHostThreshold) return <Map<String, Object?>>[];

  idx.sort((a, b) => a[0].compareTo(b[0]));

  var bestHosts = 0;
  var bestSpan = 0;
  var left = 0;
  final windowHosts = <int, int>{}; // hostIndex => count in window
  final count = idx.length;
  for (var right = 0; right < count; right++) {
    final h = idx[right][1];
    windowHosts[h] = (windowHosts[h] ?? 0) + 1;
    while (idx[right][0] - idx[left][0] > kClusterWindowMs) {
      final lh = idx[left][1];
      final c = (windowHosts[lh] ?? 0) - 1;
      if (c <= 0) {
        windowHosts.remove(lh);
      } else {
        windowHosts[lh] = c;
      }
      left += 1;
    }
    final distinct = windowHosts.length;
    if (distinct > bestHosts) {
      bestHosts = distinct;
      bestSpan = idx[right][0] - idx[left][0];
    }
  }
  if (bestHosts < kClusterHostThreshold) return <Map<String, Object?>>[];

  return <Map<String, Object?>>[
    <String, Object?>{
      'kind': 'api-thundering-herd',
      'name': 'outbound-fan-out',
      'p95': bestSpan,
      'count': bestHosts,
    }
  ];
}
