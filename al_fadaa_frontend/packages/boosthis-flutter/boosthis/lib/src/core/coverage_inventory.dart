// What this device kit has actually watched, and what it positively found but
// could not watch. This is only a reader: it arms nothing and starts nothing.
//
// Flutter cannot honestly discover another HTTP client, an unobserved screen,
// or any server-side surface. Silence therefore remains "we have not looked";
// it is never turned into a gap.

import '../integration/nav_tracker.dart';
import '../integration/network_sampler.dart';
import 'runtime_flags.dart';

class SurfaceGap {
  const SurfaceGap({
    required this.surface,
    required this.reason,
    required this.detected,
  });

  final String surface;
  final String reason;
  final int detected;

  Map<String, Object> toJson() => <String, Object>{
    'surface': surface,
    'reason': reason,
    'detected': detected,
  };
}

class CoverageInventory {
  const CoverageInventory({required this.watched, required this.unwatched});

  final List<String> watched;
  final List<SurfaceGap> unwatched;

  bool get isEmpty => watched.isEmpty && unwatched.isEmpty;

  Map<String, Object> toJson() => <String, Object>{
    'watched': watched,
    'unwatched': unwatched.map((gap) => gap.toJson()).toList(),
  };
}

/// Read the positive evidence already held by existing meters. Never throws.
CoverageInventory coverageInventory() {
  if (_safeFlag(() => RuntimeFlags.disabled)) {
    return const CoverageInventory(
      watched: <String>[],
      unwatched: <SurfaceGap>[],
    );
  }

  final watched = <String>[];
  final gaps = <SurfaceGap>[];

  // A correlated tap-to-route navigation is a completed interaction that
  // genuinely crossed the app's screen boundary. Merely installing a
  // NavigatorObserver, or pushing a route, is not evidence of watched work.
  if (_safeCount(() => NavTracker.navCount) > 0) {
    watched.add('request-handling');
  }

  // attemptCount moves only when an outbound lifecycle reaches the existing
  // NetworkSampler, whether through BoosthisHttpOverrides or the hand wrapper.
  if (_safeCount(() => NetworkSampler.getStats()['attemptCount']) > 0) {
    watched.add('outbound-calls');
  }

  watched.sort();
  gaps.sort((a, b) {
    final bySurface = a.surface.compareTo(b.surface);
    return bySurface == 0 ? a.reason.compareTo(b.reason) : bySurface;
  });
  return CoverageInventory(watched: watched, unwatched: gaps);
}

/// Short stable identity used to avoid re-consenting for an unchanged answer.
String coverageFingerprint(CoverageInventory inventory) {
  final watched = List<String>.from(inventory.watched)..sort();
  final gaps = List<SurfaceGap>.from(inventory.unwatched)
    ..sort((a, b) {
      final bySurface = a.surface.compareTo(b.surface);
      return bySurface == 0 ? a.reason.compareTo(b.reason) : bySurface;
    });
  return '${watched.join(',')}|${gaps.map((gap) => '${gap.surface}:${gap.reason}:${gap.detected}').join(',')}';
}

int _safeCount(Object? Function() read) {
  try {
    final value = read();
    if (value is! num || !value.isFinite || value <= 0) return 0;
    return value.floor();
  } catch (_) {
    return 0;
  }
}

bool _safeFlag(bool Function() read) {
  try {
    return read() == true;
  } catch (_) {
    return false;
  }
}
