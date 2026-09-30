/// Boosthis device-tier bucket (Flutter).
///
/// A coarse, privacy-safe capability bucket for the device this app runs on.
/// Ported from the RN `deviceTier.ts` with the ONE honest source Flutter adds:
/// `Platform.numberOfProcessors` (via `dart:io`), plus an optional
/// adapter-provided view-metrics hint (physical pixels × device pixel ratio).
///
/// The tier is a CLOSED enum — never a device model string — so it carries no
/// fingerprint. Like the RN kit, Boosthis NEVER guesses a fine tier from screen
/// geometry alone (Dimensions / PixelRatio misclassify badly), so:
///   - a host that hands us an accurate bucket via [setDeviceTier] wins;
///   - else we derive a COARSE bucket from CPU count only, which is honest and
///     hard to misread (a low-core device is genuinely constrained);
///   - else "unknown".
///
/// ADDITIVE + display-only: the bucket is attached to samples as privacy-safe
/// metadata and never feeds the composite Speed score. GUEST-SAFE.
library;

import 'dart:io' show Platform;

import '../core/safe.dart';

/// The closed device-tier enum, emitted as its string value on the wire
/// (byte-identical to the RN kit: "low" / "mid" / "high" / "unknown").
class DeviceTier {
  static const String low = 'low';
  static const String mid = 'mid';
  static const String high = 'high';
  static const String unknown = 'unknown';
}

String? _hostTier;
int? _viewLongestSidePx;
double? _devicePixelRatio;

/// Set the device capability bucket from a host that has a real signal. Call
/// once at startup. Ignored (kept "unknown"/derived) unless [next] is one of
/// the closed enum values. Boosthis never guesses a fine tier from screen size.
void setDeviceTier(String next) {
  Safe.fire(() {
    if (next == DeviceTier.low ||
        next == DeviceTier.mid ||
        next == DeviceTier.high ||
        next == DeviceTier.unknown) {
      _hostTier = next == DeviceTier.unknown ? null : next;
    }
  });
}

/// Adapter hook: hand the kit the primary view's metrics once at startup
/// (`FlutterView.physicalSize` longest side in px, and `devicePixelRatio`).
/// Used ONLY as context on the reported reading, NEVER to fabricate a fine
/// tier — CPU count is the load-bearing signal.
void setViewMetrics({required int longestSidePx, required double devicePixelRatio}) {
  Safe.fire(() {
    _viewLongestSidePx = longestSidePx > 0 ? longestSidePx : null;
    _devicePixelRatio = devicePixelRatio > 0 ? devicePixelRatio : null;
  });
}

/// Number of logical processors, or null when the platform cannot report it.
int? _cpuCount() {
  return Safe.run<int?>(null, () {
    final n = Platform.numberOfProcessors;
    return n > 0 ? n : null;
  });
}

/// Read the current device-tier bucket string. A host-set bucket wins; else a
/// COARSE bucket from CPU count (<=2 low, <=5 mid, else high); else "unknown".
String getDeviceTier() {
  return Safe.run(DeviceTier.unknown, () {
    final host = _hostTier;
    if (host != null) return host;
    final cpus = _cpuCount();
    if (cpus == null) return DeviceTier.unknown;
    if (cpus <= 2) return DeviceTier.low;
    if (cpus <= 5) return DeviceTier.mid;
    return DeviceTier.high;
  });
}

/// The device-tier axis as a closed metadata map. Always emits a `tier` (it is
/// honest even at "unknown"), plus the contextual counts when known. This is
/// privacy-safe metadata, not a warming tile. JSON keys: tier, source, cpus,
/// longestSidePx, devicePixelRatio.
Map<String, Object?> deviceTierAxis() {
  return Safe.run(<String, Object?>{'tier': DeviceTier.unknown, 'source': 'none'}, () {
    final cpus = _cpuCount();
    final host = _hostTier;
    final tier = getDeviceTier();
    final map = <String, Object?>{
      'tier': tier,
      'source': host != null ? 'host' : (cpus != null ? 'cpu' : 'none'),
    };
    if (cpus != null) map['cpus'] = cpus;
    if (_viewLongestSidePx != null) map['longestSidePx'] = _viewLongestSidePx;
    if (_devicePixelRatio != null) map['devicePixelRatio'] = _devicePixelRatio;
    return map;
  });
}

/// Reset host-provided device-tier state (parity harness / forget()).
void clearDeviceTier() {
  Safe.fire(() {
    _hostTier = null;
    _viewLongestSidePx = null;
    _devicePixelRatio = null;
  });
}
