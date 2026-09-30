import 'dart:io';
import 'dart:typed_data';

import 'json.dart';
import 'safe.dart';
import 'store.dart';
import 'telemetry.dart';

/// Tamper evidence.
///
/// Every kit is stamped at the edge with a manifest listing each shipped file
/// and its SHA-256, plus a hash over the manifest itself. This class re-computes
/// those hashes locally and reports what it found to the entitlement check, so a
/// kit whose files were edited after install can be told apart from one that was
/// not.
///
/// THE SELF-ENTRY RULE: a manifest can never contain its own hash, so the
/// manifest's entry for itself is EXCLUDED from the file walk — identical to
/// every sibling kit.
///
/// Honest-or-silent: an unstamped checkout (no manifest on disk) reports NOTHING
/// rather than claiming "ok". Absence of evidence is not evidence of integrity.
///
/// FLUTTER REALITY: an AOT app bundle has no readable copy of the kit's own
/// source files, so [kitRoot] usually resolves to null on-device and integrity
/// is silently absent. On the parity harness / MCP binary (a normal Dart
/// process with a filesystem) the manifest CAN be re-hashed, so the code is
/// still ported in full. The host may point the walk at a known root via
/// [setKitRoot].
class Integrity {
  Integrity._();

  static const String manifestFile = 'boosthis-manifest.json';
  static const String statusOk = 'ok';
  static const String statusMismatch = 'mismatch';

  /// Never walk more than this many files, whatever the manifest claims.
  static const int maxFiles = 400;
  static const String key = 'integrity';

  /// A full re-hash once a day is plenty; it is disk work, not free.
  static const int recheckMs = 86400000;

  static String? _kitRoot;

  /// The adapter / MCP binary may declare where the shipped kit lives so the
  /// manifest can be located. Absent on a normal Flutter device build.
  static void setKitRoot(String? root) {
    if (root != null && root.isNotEmpty) _kitRoot = root;
  }

  /// The integrity block for the entitlement check, or null when this install
  /// has no manifest to check against.
  static Map<String, Object?>? status() {
    return Safe.run<Map<String, Object?>?>(null, () {
      final cached = Store.get(key, null);
      if (cached is Map &&
          cached['at'] is int &&
          (Telemetry.nowMs() - (cached['at'] as int)) < recheckMs &&
          cached['status'] is String &&
          cached['manifestHash'] is String) {
        return <String, Object?>{
          'status': cached['status'],
          'manifestHash': cached['manifestHash'],
        };
      }

      final computed = compute();
      if (computed == null) return null;

      Store.set(key, <String, Object?>{
        'status': computed['status'],
        'manifestHash': computed['manifestHash'],
        'at': Telemetry.nowMs(),
      }, durable: true);
      return computed;
    });
  }

  /// Re-hash the shipped files against the manifest.
  static Map<String, Object?>? compute() {
    return Safe.run<Map<String, Object?>?>(null, () {
      final root = kitRoot();
      if (root == null) return null;
      final manifestPath = '$root${Platform.pathSeparator}$manifestFile';
      final mf = File(manifestPath);
      if (!mf.existsSync()) return null;

      final raw = Safe.run<String?>(null, () => mf.readAsStringSync());
      if (raw == null || raw.isEmpty) return null;

      final manifest = Json.decode(raw);
      if (manifest == null) return null;

      final files = manifest['files'];
      final manifestHash = manifest['manifest_sha256'];
      if (files is! List ||
          manifestHash is! String ||
          manifestHash.isEmpty) {
        return null;
      }

      var status = statusOk;
      var seen = 0;
      for (final entry in files) {
        if (entry is! Map) continue;
        final path = entry['path'];
        final expected = entry['sha256'];
        if (path is! String || expected is! String) continue;

        // The manifest cannot contain its own hash — skip the self-entry.
        if (path == manifestFile) continue;

        seen += 1;
        if (seen > maxFiles) break;

        final rel = path.replaceAll(RegExp(r'^/+'), '');
        final full = File('$root${Platform.pathSeparator}$rel');
        if (!full.existsSync()) {
          status = statusMismatch;
          break;
        }
        final actual = _fileSha256(full);
        if (actual == null || !_secureCompare(expected, actual)) {
          status = statusMismatch;
          break;
        }
      }

      return <String, Object?>{'status': status, 'manifestHash': manifestHash};
    });
  }

  /// The kit's own directory, when knowable. On a Flutter device build there is
  /// no readable source tree, so this is null unless the host declared one.
  static String? kitRoot() => _kitRoot;

  static void clear() => Store.delete(key);

  static String? _fileSha256(File f) {
    return Safe.run<String?>(null, () {
      final bytes = f.readAsBytesSync();
      return _sha256Hex(bytes);
    });
  }

  /// Constant-time comparison for two equal-length hex digests.
  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    var res = 0;
    for (var i = 0; i < a.length; i++) {
      res |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return res == 0;
  }

  // ── SHA-256 (pure Dart, zero-dependency) ──────────────────────────────────

  static const List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static String _sha256Hex(List<int> message) {
    var h0 = 0x6a09e667,
        h1 = 0xbb67ae85,
        h2 = 0x3c6ef372,
        h3 = 0xa54ff53a,
        h4 = 0x510e527f,
        h5 = 0x9b05688c,
        h6 = 0x1f83d9ab,
        h7 = 0x5be0cd19;

    final ml = message.length * 8;
    final padded = <int>[...message, 0x80];
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((ml >> (i * 8)) & 0xff);
    }

    final w = Int32List(64);
    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        final j = chunk + i * 4;
        w[i] = (padded[j] << 24) |
            (padded[j + 1] << 16) |
            (padded[j + 2] << 8) |
            padded[j + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^
            ((w[i - 15] & 0xFFFFFFFF) >> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^
            ((w[i - 2] & 0xFFFFFFFF) >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ (~e & g);
        final temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;
        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    return _hex32(h0) + _hex32(h1) + _hex32(h2) + _hex32(h3) +
        _hex32(h4) + _hex32(h5) + _hex32(h6) + _hex32(h7);
  }

  static int _rotr(int v, int bits) =>
      (((v & 0xFFFFFFFF) >> bits) | (v << (32 - bits))) & 0xFFFFFFFF;

  static String _hex32(int v) =>
      (v & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
}
