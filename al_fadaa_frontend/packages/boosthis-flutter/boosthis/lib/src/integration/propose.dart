// Learning-loop WRITE client — the Flutter sibling of the Ruby / .NET Propose.
//
// When the developer's own AI reports a slow pattern that no shipped rule covers
// (boosthis.report_unmatched_pattern), this forwards a privacy-safe PROPOSAL to
// the maintainer's review queue (POST /rules/propose). The maintainer approves
// or rejects it by hand — nothing here ever ships a rule.
//
// TWO privacy tiers, decided by the SERVER:
//  - TIER A (always): a demand signal only — runtime, a coarse category,
//    severity + timing buckets, a NON-reversible sha256 of the pattern, and an
//    occurrence count. No free text, no code, no identifiers.
//  - TIER B (only when the app proves control of a connected install): also the
//    raw pattern text and any AI-drafted rule (id/title/whenToApply/fix). Proof
//    is the install's read token in the X-Boosthis-Install-* headers.
//
// The payload rides the shared PII guard before any send; BOOSTHIS_DISABLED
// silences it; it is entirely fail-open — every error is swallowed so a
// best-effort proposal can never block or break the tool the developer's AI
// called. The public method returns a Future that never throws.

import 'dart:convert';
import 'dart:typed_data';

import '../core/thresholds.dart';
import '../core/runtime_flags.dart';
import '../core/telemetry.dart';
import '../core/transmit.dart';
import '../observers/pii.dart' show checkNoPii, assertNoPii;
import 'community.dart';

/// Learning-loop WRITE client. Static-only.
class Propose {
  Propose._();

  static const List<String> categories = <String>[
    'startup',
    'navigation',
    'interaction',
    'rendering',
    'network',
    'data',
    'memory',
    'other',
  ];

  static final RegExp ruleIdRe = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final RegExp wsRe = RegExp(r'\s+');

  /// Bounds the proposal POST, matching Community's timeout.
  static const int timeoutMs = 5000;

  /// Lowercase-hex sha256 of a UTF-8 string. Pure Dart (zero deps): the kit
  /// cannot pull package:crypto, so SHA-256 is implemented inline in
  /// [_Sha256]. Byte-identical output to every sibling's sha256_hex.
  static String sha256Hex(String s) => _Sha256.hexOfBytes(utf8.encode(s));

  /// The non-reversible dedup + distinct-project counting key: sha256 of the
  /// whitespace-normalized, lower-cased pattern (64 lowercase hex chars).
  static String patternSignature(String pattern) {
    final norm = pattern.toLowerCase().replaceAll(wsRe, ' ').trim();
    return sha256Hex(norm);
  }

  /// Maps the tool's `language` enum to the wire `runtime` enum, defaulting to
  /// THIS runtime — "flutter", the same tag Telemetry and the snapshot send.
  ///
  /// The shared server does not know that tag until this kit is wired up
  /// server-side. Being rejected as an unknown runtime is the correct failure:
  /// borrowing a sibling's tag would silently file this kit's reports under
  /// another runtime's corpus, which is worse than an error.
  static String runtimeFromLanguage(String? language) {
    switch (language) {
      case 'node':
        return 'node';
      case 'python':
        return 'py';
      case 'react-native':
        return 'rn';
      case 'go':
        return 'go';
      case 'java':
        return 'java';
      case 'php':
        return 'php';
      case 'ruby':
        return 'ruby';
      case 'dotnet':
        return 'dotnet';
      case 'flutter':
        return 'flutter';
      default:
        return 'flutter';
    }
  }

  /// Buckets the observed latency against the shared TTI band. Absent or
  /// non-finite input degrades to "warn" (an unmatched pattern is, by nature, a
  /// suspected problem).
  static String timingBucketFor(double observedMs, bool present) {
    if (!present || !observedMs.isFinite) return 'warn';
    if (observedMs <= Thresholds.kTtiGood) return 'good';
    if (observedMs >= Thresholds.kTtiPoor) return 'poor';
    return 'warn';
  }

  /// Maps the timing bucket to a severity bucket.
  static String severityForTiming(String timing) {
    switch (timing) {
      case 'poor':
        return 'high';
      case 'warn':
        return 'med';
      default:
        return 'low';
    }
  }

  /// Clamps a free category to the 8-value enum, else "other".
  static String normalizeCategory(String? category) =>
      category != null && categories.contains(category) ? category : 'other';

  /// Caps a string to [max] code points (never splitting a surrogate pair).
  static String truncateRunes(String? s, int max) {
    if (s == null || max <= 0) return '';
    final runes = s.runes.toList();
    if (runes.length <= max) return s;
    return String.fromCharCodes(runes.take(max));
  }

  /// Includes a tier-B free-text field ONLY if present and it passes the shared
  /// PII guard. Dropping a PII-tripping field (rather than aborting) keeps the
  /// tier-A demand signal alive. Truncate first, then guard.
  static String cleanText(String? value, int maxLen) {
    final trimmed = truncateRunes(value, maxLen);
    if (trimmed.isEmpty) return '';
    if (checkNoPii(trimmed) != null) return '';
    return trimmed;
  }

  /// Fire-and-forget a rule PROPOSAL to the maintainer's review queue. Fully
  /// fail-open: never blocks the caller in any way that can throw, and never
  /// throws. A no-op when there is no invite key or under BOOSTHIS_DISABLED.
  ///
  /// [draft] is an optional { proposedRuleId, title, whenToApply, fixTemplate }.
  static Future<void> reportUnmatchedPattern(
    String pattern,
    String language,
    double observedMs,
    bool observedPresent,
    String? category, [
    Map<String, Object?> draft = const <String, Object?>{},
  ]) async {
    try {
      await _proposeUnmatchedPattern(
        pattern,
        language,
        observedMs,
        observedPresent,
        category,
        draft,
      );
    } catch (_) {
      // Fully fail-open: a best-effort proposal never blocks or breaks the
      // tool the developer's AI called.
    }
  }

  static Future<void> _proposeUnmatchedPattern(
    String pattern,
    String language,
    double observedMs,
    bool observedPresent,
    String? category,
    Map<String, Object?> draft,
  ) async {
    final key = Telemetry.effectiveProjectKey ?? '';
    // Gate: a proposal requires an invite key (the distributable fix scope).
    // Without one this is an unregistered install — stay fully on-device.
    if (key.isEmpty) return;
    if (RuntimeFlags.disabled) return;

    final timingBucket = timingBucketFor(observedMs, observedPresent);
    final body = <String, Object?>{
      'runtime': runtimeFromLanguage(language),
      'category': normalizeCategory(category),
      'severityBucket': severityForTiming(timingBucket),
      'timingBucket': timingBucket,
      'signature': patternSignature(pattern),
      'occurrences': 1,
    };

    // TIER B: only when we can prove control of a connected install. The sibling
    // kits carry the install proof in X-Boosthis-Install-* HEADERS; the Flutter
    // Transmit chokepoint only sends a Bearer authToken + JSON body, so the proof
    // rides the body via safeTransmitTrustedPayload (which exists to carry
    // server-issued credentials the field-name PII guard would otherwise reject).
    // See the honesty note in the final report — this is a WIRE divergence the
    // server must accept for the Flutter runtime.
    final creds = _installCreds();
    final trusted = creds != null;
    if (creds != null) {
      body['installId'] = creds[0];
      body['installToken'] = creds[1];
      final rawPattern = cleanText(pattern, 2000);
      if (rawPattern.isNotEmpty) body['pattern'] = rawPattern;
      final candidate =
          truncateRunes(draft['proposedRuleId'] as String? ?? '', 80);
      if (candidate.isNotEmpty && ruleIdRe.hasMatch(candidate)) {
        body['proposedRuleId'] = candidate;
      }
      final title = cleanText(draft['title'] as String? ?? '', 160);
      if (title.isNotEmpty) body['title'] = title;
      final whenToApply = cleanText(draft['whenToApply'] as String? ?? '', 2000);
      if (whenToApply.isNotEmpty) body['whenToApply'] = whenToApply;
      final fixTemplate = cleanText(draft['fixTemplate'] as String? ?? '', 8000);
      if (fixTemplate.isNotEmpty) body['fixTemplate'] = fixTemplate;
    }

    final url = '${Community.endpointBase()}/rules/propose';
    if (trusted) {
      // Trusted path: install proof in the body legitimately trips the
      // field-name guard, so use the trusted-payload chokepoint. The URL query
      // is still scanned and BOOSTHIS_DISABLED still honoured inside Transmit.
      await Transmit.safeTransmitTrustedPayload(
        url,
        body,
        authToken: key,
        timeoutMs: timeoutMs,
      );
    } else {
      // Tier A: a pure demand signal — passes the full shared PII guard.
      assertNoPii(body);
      await Transmit.safeTransmit(
        url,
        body,
        authToken: key,
        timeoutMs: timeoutMs,
      );
    }
  }

  static String _firstEnv(List<String> names) {
    for (final n in names) {
      final v = RuntimeFlags.env(n);
      if (v == null) continue;
      final t = v.trim();
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  /// The install id + read token that prove control of a connected install.
  /// Returns null unless both are present.
  static List<String>? _installCreds() {
    final id = _firstEnv(<String>['BOOSTHIS_INSTALL_ID', 'BOOSTEN_INSTALL_ID']);
    final tok = _firstEnv(<String>['BOOSTHIS_READ_TOKEN', 'BOOSTEN_READ_TOKEN']);
    if (id.isEmpty || tok.isEmpty) return null;
    return <String>[id, tok];
  }
}

/// Self-contained SHA-256 (FIPS 180-4). Pure Dart, zero dependencies — the
/// `boosthis` package may not depend on package:crypto. Produces the standard
/// lowercase-hex digest, byte-identical to the sibling kits' sha256.
class _Sha256 {
  _Sha256._();

  static const List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static const int _mask = 0xffffffff;

  static int _rotr(int x, int n) =>
      ((x >> n) | (x << (32 - n))) & _mask;

  static String hexOfBytes(List<int> message) {
    final h = <int>[
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];

    // Pre-processing: append 0x80, pad to 56 mod 64, append 64-bit length.
    final ml = message.length * 8;
    final bytes = <int>[...message, 0x80];
    while (bytes.length % 64 != 56) {
      bytes.add(0);
    }
    for (var i = 7; i >= 0; i--) {
      bytes.add((ml >> (i * 8)) & 0xff);
    }

    final w = Int32List(64);
    for (var chunk = 0; chunk < bytes.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        final j = chunk + i * 4;
        w[i] = ((bytes[j] << 24) |
                (bytes[j + 1] << 16) |
                (bytes[j + 2] << 8) |
                bytes[j + 3]) &
            _mask;
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15] & _mask, 7) ^
            _rotr(w[i - 15] & _mask, 18) ^
            ((w[i - 15] & _mask) >> 3);
        final s1 = _rotr(w[i - 2] & _mask, 17) ^
            _rotr(w[i - 2] & _mask, 19) ^
            ((w[i - 2] & _mask) >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask;
      }

      var a = h[0], b = h[1], c = h[2], d = h[3];
      var e = h[4], f = h[5], g = h[6], hh = h[7];

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & _mask) & g);
        final t1 = (hh + s1 + ch + _k[i] + (w[i] & _mask)) & _mask;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final t2 = (s0 + maj) & _mask;
        hh = g;
        g = f;
        f = e;
        e = (d + t1) & _mask;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & _mask;
      }

      h[0] = (h[0] + a) & _mask;
      h[1] = (h[1] + b) & _mask;
      h[2] = (h[2] + c) & _mask;
      h[3] = (h[3] + d) & _mask;
      h[4] = (h[4] + e) & _mask;
      h[5] = (h[5] + f) & _mask;
      h[6] = (h[6] + g) & _mask;
      h[7] = (h[7] + hh) & _mask;
    }

    final sb = StringBuffer();
    for (final v in h) {
      sb.write((v & _mask).toRadixString(16).padLeft(8, '0'));
    }
    return sb.toString();
  }
}
