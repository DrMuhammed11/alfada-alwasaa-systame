import 'dart:io' show Platform;

import 'runtime_flags.dart';
import 'safe.dart';
import 'score.dart';
import 'telemetry.dart';

/// What this build IS: the runtime it runs on and, when the host wires it, how
/// old the running bundle is.
///
/// Everything here is honest-or-absent. A component the kit cannot read is left
/// out of the payload entirely — never guessed, never defaulted to a plausible
/// value. That is what makes the exposure-window / patch-lag meter worth
/// anything.
///
/// FLUTTER REALITY: a pure-Dart process cannot read a lockfile mtime or a build
/// stamp on its own (the app is an AOT bundle; `pubspec.lock` is not shipped).
/// So there is NO auto patchLag. The ADAPTER may hand in a build time / commit
/// (from the app's own build metadata) via [setBuildInfo]; only then does the
/// build object — and, given a build time, the patchLag axis — appear.
class BuildIdentity {
  BuildIdentity._();

  // Shared cross-runtime rating bands (days since the build was cut).
  static const int patchLagGoodDays = 7;
  static const int patchLagNeedsWorkDays = 30;

  /// The age (days) at which the score reaches 0.
  static const int patchLagScaleDays = 60;
  static const int msPerDay = 86400000;

  static int? _buildTimeMs;
  static String? _buildCommit;
  static bool _readDefines = false;

  /// A Flutter binary cannot discover its own build time, so the only honest
  /// source is one the BUILD supplies. Read once, lazily, from the compile-time
  /// defines the install guide documents:
  ///
  ///     flutter build apk --dart-define=BOOSTHIS_BUILD_TIME_MS=$(date +%s000) \
  ///                       --dart-define=BOOSTHIS_BUILD_COMMIT=$(git rev-parse HEAD)
  ///
  /// Absent them the axis stays absent — never a zero, never a warming tile.
  static void _loadDefinesOnce() {
    if (_readDefines) return;
    _readDefines = true;
    final ms = RuntimeFlags.env('BOOSTHIS_BUILD_TIME_MS');
    final commit = RuntimeFlags.env('BOOSTHIS_BUILD_COMMIT');
    setBuildInfo(
      buildTimeMs: ms == null ? null : int.tryParse(ms.trim()),
      buildCommit: commit,
    );
  }

  /// The adapter wires the running bundle's build time (epoch ms) and/or commit
  /// SHA from the app's own build metadata. A non-finite or future build time
  /// is dropped (honest absence). A commit must be 7–40 lowercase hex.
  static void setBuildInfo({int? buildTimeMs, String? buildCommit}) {
    if (buildTimeMs != null && buildTimeMs > 0 &&
        buildTimeMs <= Telemetry.nowMs()) {
      _buildTimeMs = buildTimeMs;
    }
    if (buildCommit != null) {
      final c = buildCommit.toLowerCase();
      if (RegExp(r'^[0-9a-f]{7,40}$').hasMatch(c)) _buildCommit = c;
    }
  }

  /// Best-effort OS name — one of dart:io's `Platform.operatingSystem` values
  /// ("android", "ios", "macos", "windows", "linux", "fuchsia"). The wire
  /// `platform` on the snapshot comes from the adapter (Telemetry.platform),
  /// not from here; this is diagnostic context only.
  static String? operatingSystem() {
    return Safe.run<String?>(null, () {
      final os = Platform.operatingSystem;
      return os.isEmpty ? null : os;
    });
  }

  /// The Dart runtime version string, when readable.
  static String? dartVersion() {
    return Safe.run<String?>(null, () {
      final v = Platform.version;
      return v.isEmpty ? null : v;
    });
  }

  /// The build block for the snapshot: emitted only when at least one component
  /// is genuinely known.
  static Map<String, Object?>? buildInfo() {
    return Safe.run<Map<String, Object?>?>(null, () {
      final info = <String, Object?>{};
      info['runtimeName'] = 'flutter';
      final dv = dartVersion();
      if (dv != null) info['runtimeVersion'] = dv;
      final os = operatingSystem();
      if (os != null) info['os'] = os;
      _loadDefinesOnce();
      if (_buildCommit != null) info['commit'] = _buildCommit;
      if (_buildTimeMs != null) info['buildTimeMs'] = _buildTimeMs;
      return info.isEmpty ? null : info;
    });
  }

  /// The patchLag axis — how long this deployment has been running the code it
  /// was built with. Emitted ONLY when the adapter supplied a build time
  /// (null = honest absence, never a fake or forever-warming axis).
  ///
  /// ADDITIVE + display-only: NEVER feeds the Speed score.
  static Map<String, Object?>? readPatchLag() {
    return Safe.run<Map<String, Object?>?>(null, () {
      _loadDefinesOnce();
      final buildTimeMs = _buildTimeMs;
      if (buildTimeMs == null) return null;

      var ageMs = Telemetry.nowMs() - buildTimeMs;
      if (ageMs < 0) ageMs = 0;
      final ageDays = ageMs / msPerDay;
      final String rating;
      if (ageDays < patchLagGoodDays) {
        rating = Score.good;
      } else if (ageDays < patchLagNeedsWorkDays) {
        rating = Score.needsWork;
      } else {
        rating = Score.poor;
      }
      var raw = 100 - ((ageDays / patchLagScaleDays) * 100);
      if (raw < 0.0) raw = 0.0;
      if (raw > 100.0) raw = 100.0;
      return <String, Object?>{
        'score': raw.round(),
        'rating': rating,
        'buildAgeMs': ageMs,
        'buildTimeMs': buildTimeMs,
        // Caption reports build AGE ONLY — never implies patched/safe.
        'caption': 'build ~${ageDays.toInt()}d old',
      };
    });
  }
}
