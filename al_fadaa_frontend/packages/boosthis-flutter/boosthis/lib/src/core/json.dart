import 'dart:convert' as convert;

import 'safe.dart';

/// JSON helpers with the kit's encoding contract baked in.
///
/// Two things matter for cross-runtime parity:
///  - an empty axes/rows container must serialize as `{}` / `[]` exactly as the
///    other kits do, so a map is never guessed at;
///  - a value that cannot be encoded must not blow up the host — [encode]
///    returns null rather than throwing.
class Json {
  Json._();

  /// Encode, returning null (never throwing) when the value cannot be encoded.
  static String? encode(Object? value) {
    return Safe.run<String?>(null, () => convert.jsonEncode(value));
  }

  /// Decode to a `Map<String, Object?>`, returning null on any error or when
  /// the top-level value is not an object.
  static Map<String, Object?>? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return Safe.run<Map<String, Object?>?>(null, () {
      final out = convert.jsonDecode(raw);
      return out is Map<String, Object?>
          ? out
          : (out is Map ? Map<String, Object?>.from(out) : null);
    });
  }

  /// Decode ANY top-level JSON value (object, array, or scalar) — used by the
  /// durable store, whose values are not always objects. Returns null on error.
  static Object? decodeAny(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return Safe.run<Object?>(null, () => convert.jsonDecode(raw));
  }

  /// Force a value to encode as a JSON OBJECT even when empty. The wire
  /// contract says `axes` is a map — an empty container must serialize as `{}`,
  /// not `[]`, or server validation fails.
  static Map<String, Object?> objectOrEmpty(Object? map) {
    if (map is Map<String, Object?>) return map;
    if (map is Map) return Map<String, Object?>.from(map);
    return <String, Object?>{};
  }
}
