/// Boosthis `platformChannels` axis (Flutter).
///
/// The Flutter analogue of the RN `bridgeTraffic` axis: how chatty the app is
/// across the app↔native platform-channel boundary (MethodChannel /
/// EventChannel / BasicMessageChannel). Fewer, coarser round-trips per active
/// minute is better; a UI that pings native on every frame is the smell.
///
/// OPT-IN (frozen contract): a pure-Dart package cannot silently intercept the
/// engine's channel buffers, so Boosthis counts ONLY calls the host routes
/// through the kit's own channel wrapper. When the host wired no wrapper the
/// axis is NOT measurable — but, per the contract, it is STILL uploaded as
/// `{present:true, measurable:0, reason:"..."}` so the dashboard tile EXPLAINS
/// itself ("wrap your channels to measure this") instead of warming forever or
/// vanishing. This mirrors RN `bridgeTraffic`'s `measurable:0` upload on the
/// new architecture.
///
/// ADDITIVE + display-only: NEVER feeds the composite Speed score. GUEST-SAFE:
/// every entry point is best-effort and can never throw into the host.
library;

import '../meters/meter_axes.dart';

/// Good/poor bands in calls-per-active-minute (byte-parity with RN bridge
/// traffic thresholds). Below `good` scores 100; at/above `poor` scores 0.
const double kPlatformChannelsGoodPerMin = 60;
const double kPlatformChannelsPoorPerMin = 600;

/// Minimum observed active time before a measurable axis leaves "pending".
const int kPlatformChannelsMinSampledMs = 60000;

/// Reason string uploaded when the host wired no channel wrapper — the tile
/// caption the server renders verbatim.
const String kPlatformChannelsOptOutReason =
    'wrap platform channels through the kit to measure app\u2194native chatter';

bool _wired = false;
int _startedAtMs = 0;
int _callCount = 0;

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Turn the axis measurable: the host wired the kit's channel wrapper. From now
/// on [notePlatformChannelCall] contributes to the reading. Idempotent.
void installPlatformChannelTracking() {
  try {
    if (_wired) return;
    _wired = true;
    _startedAtMs = _nowMs();
    _callCount = 0;
  } catch (_) {
    // best-effort — wiring must never reach the host
  }
}

/// Count ONE platform-channel round-trip routed through the kit's wrapper. Only
/// a monotonic count is retained — never the channel name, method or payload
/// (PII contract). No-op until [installPlatformChannelTracking]. Never throws.
void notePlatformChannelCall() {
  try {
    if (!_wired) return;
    _callCount += 1;
  } catch (_) {
    // best-effort
  }
}

/// The `platformChannels` axis. ALWAYS returns a map (never null): when the
/// host wired no wrapper it is the self-explaining opt-out shape
/// `{present:true, measurable:0, reason:...}`; while warming it is
/// `{present:true, measurable:1, score:null, rating:pending}`; once warm it is
/// the scored reading. Pure read — never mutates state, NEVER throws.
Map<String, Object?> readPlatformChannels() {
  try {
    // Not wired → not measurable, but STILL uploaded so the tile explains
    // itself (contract rule). Never absent, never a fabricated zero.
    if (!_wired) {
      return <String, Object?>{
        'present': true,
        'measurable': 0,
        'score': null,
        'rating': AxisRating.pending,
        'reason': kPlatformChannelsOptOutReason,
      };
    }

    var sampledMs = _nowMs() - _startedAtMs;
    if (sampledMs < 0) sampledMs = 0;

    // Wired but not enough active time sampled yet → measurable, pending.
    if (sampledMs < kPlatformChannelsMinSampledMs) {
      return <String, Object?>{
        'present': true,
        'measurable': 1,
        'score': null,
        'rating': AxisRating.pending,
        'callsPerMin': null,
        'sampledMs': sampledMs,
      };
    }

    final perMin = _callCount / (sampledMs / 60000);
    final score = linearScore(
      perMin,
      kPlatformChannelsGoodPerMin,
      kPlatformChannelsPoorPerMin,
    );
    return <String, Object?>{
      'present': true,
      'measurable': 1,
      'score': score,
      'rating': ratingFor(score),
      'callsPerMin': perMin.round(),
      'sampledMs': sampledMs,
    };
  } catch (_) {
    return <String, Object?>{
      'present': true,
      'measurable': 0,
      'score': null,
      'rating': AxisRating.pending,
      'reason': kPlatformChannelsOptOutReason,
    };
  }
}

/// Test / parity-harness seam: reset the module to its unwired state.
void resetPlatformChannels() {
  _wired = false;
  _startedAtMs = 0;
  _callCount = 0;
}

/// Test seam — force the wired state + a synthetic sampled window and call
/// count so the scored path can be exercised without real wall-clock waits.
class PlatformChannelInternals {
  PlatformChannelInternals._();

  static void setWiredForTests({
    required int sampledMs,
    required int callCount,
  }) {
    _wired = true;
    _startedAtMs = _nowMs() - (sampledMs < 0 ? 0 : sampledMs);
    _callCount = callCount < 0 ? 0 : callCount;
  }

  static void reset() => resetPlatformChannels();
}
