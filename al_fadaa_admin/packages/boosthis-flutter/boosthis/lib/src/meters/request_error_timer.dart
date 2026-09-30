/// Request-path, route-failure and timer readings for Flutter.
///
/// All state is process-local and numbers-only. Phone rates use foreground
/// time, supplied by lifecycle_axes.dart. Readings Flutter cannot obtain from
/// a stable framework boundary explicitly abstain with the phone kits' closed
/// `platform does not expose` reason code (3).
library;

import 'dart:math' as math;

import 'meter_axes.dart' show linearScore, ratingFor;

const int reasonNotWiredByHost = 1;
const int reasonPlatformDoesNotExpose = 3;

// ── upstreamCache ────────────────────────────────────────────────────────────

const List<String> upstreamCacheHeaderNames = <String>[
  'x-vercel-cache',
  'cf-cache-status',
  'x-nextjs-cache',
  'cache-status',
  'x-cache',
];

int _cacheHits = 0;
int _cacheMisses = 0;
int _cacheStale = 0;
int _cacheBypass = 0;

String? _cacheVerdict(String name, String raw) {
  if (raw.isEmpty || raw.length > 120) return null;
  final upper = raw.trim().toUpperCase();
  if (name == 'cache-status') {
    final first = raw.split(',').first;
    for (final part in first.split(';').skip(1)) {
      final value = part.trim().toLowerCase();
      if (value == 'hit') return 'hit';
      if (!value.startsWith('fwd=')) continue;
      final reason = value.substring(4).trim();
      if (reason == 'stale' || reason == 'request') return 'stale';
      if (reason == 'bypass' || reason == 'method') return 'bypass';
      if (reason == 'uri-miss' || reason == 'vary-miss' || reason == 'miss') {
        return 'miss';
      }
    }
    return null;
  }
  if (name == 'x-cache') {
    final word = upper.split(RegExp(r'[\s,]+')).first;
    if (word == 'HIT') return 'hit';
    if (word == 'MISS') return 'miss';
    if (word == 'REFRESHHIT') return 'stale';
    if (word == 'ERROR') return 'bypass';
    return null;
  }
  if (name == 'x-vercel-cache') {
    if (upper == 'HIT' || upper == 'PRERENDER') return 'hit';
    if (upper == 'STALE' || upper == 'REVALIDATED') return 'stale';
    if (upper == 'MISS') return 'miss';
    if (upper == 'BYPASS') return 'bypass';
  } else if (name == 'cf-cache-status') {
    if (upper == 'HIT') return 'hit';
    if (<String>{'EXPIRED', 'STALE', 'UPDATING', 'REVALIDATED'}.contains(upper)) {
      return 'stale';
    }
    if (upper == 'MISS') return 'miss';
    if (<String>{'BYPASS', 'DYNAMIC', 'IGNORED'}.contains(upper)) return 'bypass';
  } else if (name == 'x-nextjs-cache') {
    if (upper == 'HIT') return 'hit';
    if (upper == 'STALE') return 'stale';
    if (upper == 'MISS') return 'miss';
  }
  return null;
}

void noteUpstreamCacheReply(String? Function(String name) readHeader) {
  try {
    String? verdict;
    for (final name in upstreamCacheHeaderNames) {
      final raw = readHeader(name);
      if (raw == null) continue;
      verdict = _cacheVerdict(name, raw);
      if (verdict != null) break;
    }
    if (verdict == 'hit') _cacheHits++;
    if (verdict == 'miss') _cacheMisses++;
    if (verdict == 'stale') _cacheStale++;
    if (verdict == 'bypass') _cacheBypass++;
  } catch (_) {
    // An unreadable reply has no declared cache verdict.
  }
}

Map<String, Object?>? readUpstreamCache() {
  final cacheable = _cacheHits + _cacheMisses + _cacheStale;
  if (cacheable == 0 && _cacheBypass == 0) return null;
  if (cacheable < 5) {
    return <String, Object?>{
      'hitPct': null,
      'checked': cacheable + _cacheBypass,
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'stale': _cacheStale,
      'bypass': _cacheBypass,
      'score': null,
      'rating': 'pending',
    };
  }
  final pct = ((_cacheHits + _cacheStale) * 100 / cacheable).round();
  final score = linearScore(100 - pct, 10, 60);
  return <String, Object?>{
    'hitPct': pct,
    'checked': cacheable + _cacheBypass,
    'hits': _cacheHits,
    'misses': _cacheMisses,
    'stale': _cacheStale,
    'bypass': _cacheBypass,
    'score': score,
    'rating': ratingFor(score),
  };
}

// ── routeFailures ────────────────────────────────────────────────────────────

const int _routePartCap = 100;
final Set<String> _routeParts = <String>{};
int _routeObserved = 0;
int _routeFailed = 0;
int _routeUntracked = 0;

void noteRouteOutboundResult(String? route, {required bool failed}) {
  if (route == null || route.isEmpty) return;
  if (!_routeParts.contains(route) && _routeParts.length >= _routePartCap) {
    _routeUntracked++;
    return;
  }
  _routeParts.add(route);
  _routeObserved++;
  if (failed) _routeFailed++;
}

Map<String, Object?>? readRouteFailures() {
  if (_routeParts.isEmpty && _routeUntracked == 0) return null;
  return <String, Object?>{
    'score': null,
    'rating': 'not-scored',
    'parts': _routeParts.length,
    'observed': _routeObserved,
    'failed': _routeFailed,
    'untracked': _routeUntracked,
  };
}

// ── timerHealth ──────────────────────────────────────────────────────────────

int _outstandingTimers = 0;
int _lastTimerSampleAt = 0;
final List<(int, int)> _timerSamples = <(int, int)>[];

void noteHealthTimerCreated() => _outstandingTimers++;
void noteHealthTimerRetired() {
  if (_outstandingTimers > 0) _outstandingTimers--;
}

void sampleTimerHealth(int nowMs) {
  if (_lastTimerSampleAt != 0 && nowMs - _lastTimerSampleAt < 1000) return;
  _lastTimerSampleAt = nowMs;
  _timerSamples.add((nowMs, _outstandingTimers));
  if (_timerSamples.length > 240) _timerSamples.removeAt(0);
}

double _timerSlope() {
  final t0 = _timerSamples.first.$1;
  final n = _timerSamples.length;
  var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
  for (final p in _timerSamples) {
    final x = (p.$1 - t0) / 60000.0;
    final y = p.$2.toDouble();
    sx += x;
    sy += y;
    sxx += x * x;
    sxy += x * y;
  }
  final denominator = n * sxx - sx * sx;
  return denominator == 0 ? 0 : (n * sxy - sx * sy) / denominator;
}

Map<String, Object?> readTimerHealth() {
  final earned = _timerSamples.length >= 12 &&
      _timerSamples.last.$1 - _timerSamples.first.$1 >= 60000;
  if (!earned) {
    return <String, Object?>{
      'timers': null,
      'growthPerMin': null,
      'sampleCount': _timerSamples.length,
      'unwatchedTimers': 1,
      'score': null,
      'rating': 'pending',
    };
  }
  final growth = _timerSlope();
  final score = linearScore(math.max(0, growth), 1, 30);
  return <String, Object?>{
    'timers': _outstandingTimers,
    'growthPerMin': (growth * 10).round() / 10,
    'sampleCount': _timerSamples.length,
    // Dart Zone timers are watched. Native/platform schedulers are not.
    'unwatchedTimers': 1,
    'score': score,
    'rating': ratingFor(score),
  };
}

// ── Explicit abstentions ─────────────────────────────────────────────────────

Map<String, Object?> readBackgroundWorkUnavailable() => <String, Object?>{
  // Flutter has background execution systems, but no common job/queue hook.
  // Name that blind spot without inventing run or failure counts.
  'unattachedSystems': 1,
  'waitP95Ms': null,
  'missed': null,
  'measurable': 0,
  'reasonCode': reasonNotWiredByHost,
  'score': null,
  'rating': 'pending',
};

Map<String, Object?> readLiveConnectionsUnavailable() => <String, Object?>{
  'reconnectsPerHour': null, 'msgsPerMin': null,
  'measurable': 0, 'flowMeasurable': 0,
  'reasonCode': reasonPlatformDoesNotExpose, 'score': null,
  'rating': 'pending', 'caption': 'not available from Flutter networking',
};

Map<String, Object?> readUptimeStabilityUnavailable() => <String, Object?>{
  'uptimeMin': null, 'observedMin': null, 'driftPct': null,
  'measurable': 0, 'reasonCode': reasonPlatformDoesNotExpose,
  'score': null, 'rating': 'pending',
  'caption': 'Dart exposes no process uptime clock',
};

Map<String, Object?> readIdleUnavailable() => <String, Object?>{
  'idleBusyPct': null,
  'measurable': 0, 'reasonCode': reasonPlatformDoesNotExpose,
  'score': null, 'rating': 'pending',
};

void clearRequestErrorTimerMeters() {
  _cacheHits = _cacheMisses = _cacheStale = _cacheBypass = 0;
  _routeParts.clear();
  _routeObserved = _routeFailed = _routeUntracked = 0;
  _outstandingTimers = _lastTimerSampleAt = 0;
  _timerSamples.clear();
}

class RequestErrorTimerInternals {
  static void reset() => clearRequestErrorTimerMeters();
  static void timerSample(int atMs, int count) {
    _outstandingTimers = count < 0 ? 0 : count;
    _lastTimerSampleAt = atMs;
    _timerSamples.add((atMs, _outstandingTimers));
  }
}