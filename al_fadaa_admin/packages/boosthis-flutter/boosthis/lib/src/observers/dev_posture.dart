/// Boosthis: Dev Posture axis source (Flutter).
///
/// The additive "Dev Posture" meter reports whether a live app is still wearing
/// its development clothes. It reports EXPOSURE, never safety: a clean tile
/// means "none of the development settings we can read were on", never "you are
/// production-hardened".
///
/// READ ONCE AT STARTUP (freeze-at-init, like the cold-start contract): the
/// adapter hands in a one-shot snapshot of the compile-time posture facts
/// (kDebugMode / kProfileMode / kReleaseMode / debugPaintSizeEnabled
/// equivalents) the FIRST time the meters read this axis. The result is cached
/// and the SAME frozen object is returned on every later snapshot even if the
/// facts change afterwards. A test seam resets/overrides it.
///
/// PER-RUNTIME READABLE CHECKS (Flutter):
///   • debugFlag     — kDebugMode is true (a debug build shipped). ALWAYS
///                     present (the constant is always readable).
///   • profilingOpen — kProfileMode is true (a profile build shipped, i.e. the
///                     profiler/timeline is attachable). Present when the
///                     adapter supplies it.
///   • verboseErrors — debugPaintSizeEnabled is true (debug paint overlays on).
///                     Present when the adapter supplies it.
///   sourceMaps is NOT readable on Flutter → its flag is OMITTED.
///
/// WIRE OBJECT (numbers + rating/caption strings only — NEVER an env value,
/// path, URL, or config string):
///   { score, rating, caption, findings, checks, measurable,
///     debugFlag?, verboseErrors?, sourceMaps?, profilingOpen? }
///
/// Each flag is present ONLY when this runtime actually performed that check
/// (value 1 = the development setting is ON; 0 = read and off). An unreadable
/// check's flag is OMITTED entirely — absence means "we did not look".
///
/// ADDITIVE / display-only: NEVER feeds the Speed score.
library;

/// Rating band strings (shared across kits). Kept local so this axis does not
/// depend on the meters group — devPosture computes its own rating.
const String _ratingGood = 'good';
const String _ratingNeedsWork = 'needs-work';
const String _ratingPoor = 'poor';

/// The four flag identifiers, in the fixed order the caption lists them.
const List<String> _flagOrder = <String>[
  'debugFlag',
  'verboseErrors',
  'sourceMaps',
  'profilingOpen',
];

/// Setting NAMES used in the caption — never an env var value or flag string.
const Map<String, String> _flagPhrase = <String, String>{
  'debugFlag': 'debug mode on',
  'verboseErrors': 'verbose error pages on',
  'sourceMaps': 'source maps served',
  'profilingOpen': 'profiling port open',
};

/// The compile-time posture facts the adapter reads once and passes in. Each
/// field is nullable: null means "this runtime could not read that check", so
/// the corresponding wire flag is OMITTED entirely.
class DevPostureFacts {
  /// kDebugMode — a debug build shipped. Always readable, so never null.
  final bool debugMode;

  /// kProfileMode — a profile build shipped (profiler attachable). null when
  /// the adapter did not read it.
  final bool? profileMode;

  /// debugPaintSizeEnabled — debug paint overlays on. null when not read.
  final bool? debugPaintSizeEnabled;

  const DevPostureFacts({
    required this.debugMode,
    this.profileMode,
    this.debugPaintSizeEnabled,
  });
}

/// The frozen, read-once result as a closed JSON map. `null` until the first
/// read populates it.
Map<String, Object?>? _frozen;

/// Assemble the wire object from the flags that were actually read. Applies the
/// shared devPosture scoring/rating/caption contract deterministically:
///   • rating: debugFlag===1 → poor; else findings>0 → needs-work; else good.
///   • score: 100, −60 if debugFlag===1, −20 per OTHER finding, clamp 0..100.
///   • caption: good → "none of the {checks} development settings we can read
///     were on"; otherwise the ON findings joined by ", ".
Map<String, Object?> assembleDevPosture(Map<String, int> flags) {
  var checks = 0;
  var findings = 0;
  final onPhrases = <String>[];
  final debugOn = flags['debugFlag'] == 1;

  for (final key in _flagOrder) {
    final v = flags[key];
    if (v == null) continue;
    checks += 1;
    if (v == 1) {
      findings += 1;
      onPhrases.add(_flagPhrase[key]!);
    }
  }

  var score = 100;
  if (debugOn) score -= 60;
  for (final key in _flagOrder) {
    if (key == 'debugFlag') continue;
    if (flags[key] == 1) score -= 20;
  }
  if (score < 0) score = 0;
  if (score > 100) score = 100;

  final rating = debugOn
      ? _ratingPoor
      : findings > 0
          ? _ratingNeedsWork
          : _ratingGood;

  final caption = findings == 0
      ? 'none of the $checks development settings we can read were on'
      : onPhrases.join(', ');

  final out = <String, Object?>{
    'score': score,
    'rating': rating,
    'caption': caption,
    'findings': findings,
    'checks': checks,
    'measurable': 1,
  };
  // Emit each flag ONLY when it was read (present in `flags`).
  for (final key in _flagOrder) {
    final v = flags[key];
    if (v != null) out[key] = v;
  }
  return out;
}

Map<String, Object?> _computeFrozen(DevPostureFacts facts) {
  final flags = <String, int>{};
  // debugFlag is always readable (the adapter always supplies kDebugMode).
  flags['debugFlag'] = facts.debugMode ? 1 : 0;
  // profilingOpen ← kProfileMode, present only when the adapter read it.
  if (facts.profileMode != null) {
    flags['profilingOpen'] = facts.profileMode! ? 1 : 0;
  }
  // verboseErrors ← debugPaintSizeEnabled, present only when read.
  if (facts.debugPaintSizeEnabled != null) {
    flags['verboseErrors'] = facts.debugPaintSizeEnabled! ? 1 : 0;
  }
  // sourceMaps is not readable on Flutter → never added → omitted.
  return assembleDevPosture(flags);
}

/// The Dev Posture axis. Freeze-at-init: the first call evaluates the checks
/// from [facts] and caches the reading; every later call returns the SAME
/// frozen object even if the facts change afterwards. Never throws.
///
/// Flutter always has at least one readable check (kDebugMode is always
/// supplied), so this always emits — it never returns null.
Map<String, Object?> readDevPosture(DevPostureFacts facts) {
  if (_frozen == null) {
    try {
      _frozen = _computeFrozen(facts);
    } catch (_) {
      // Even on a catastrophic failure the debug read is trivially safe; fall
      // back to a debug-off, single-check clean reading rather than crash.
      _frozen = assembleDevPosture(<String, int>{'debugFlag': 0});
    }
  }
  return _frozen!;
}

/// Test seam — reset the frozen result so the next read re-evaluates (and,
/// optionally, override the frozen reading with explicit flags to test
/// bands/omission without manipulating the real posture facts).
void resetDevPostureForTests([Map<String, int>? override]) {
  _frozen = override != null ? assembleDevPosture(override) : null;
}

/// Test seam — force a fresh evaluation and return the reading (bypasses the
/// freeze so a test can assert what the live checks produced).
Map<String, Object?> readDevPostureForTests(DevPostureFacts facts) {
  _frozen = null;
  return readDevPosture(facts);
}
