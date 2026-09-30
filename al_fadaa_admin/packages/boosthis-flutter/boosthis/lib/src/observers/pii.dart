/// PII denylist + guard (Flutter kit).
///
/// A verbatim-in-SEMANTICS port of the server's guard, the RN kit's
/// `no-pii.ts` and the Ruby kit's `pii.rb`. Inspects BOTH field names AND
/// string values. `assertNoPii` throws before any outbound send if a payload
/// trips the denylist or a value pattern.
///
/// PARITY WARNING: the denylist, the allowlist, every regex and the ORDER of
/// the checks stay byte-identical to the server's pii.ts and every sibling
/// kit. Drift does not fail loudly — it silently drops whole uploads on one
/// side of the wire. INCLUDING the narrowly-scoped structural method-path
/// space exception (`GET /path` labels skip ONLY the space heuristic).
library;

import 'pii_detected_error.dart';
import '../integration/route_inventory.dart';

/// Canonical set of field names that must never appear in a transmitted
/// payload. Same entries, same order as every sibling kit's PII_DENYLIST.
const List<String> kPiiDenylist = <String>[
  // identity
  'email', 'mail', 'username', 'userid', 'user_id', 'uid',
  'firstname', 'first_name', 'lastname', 'last_name',
  'fullname', 'full_name', 'phone', 'mobile', 'tel',
  'ssn', 'nationalid', 'national_id', 'taxid', 'tax_id',
  'dob', 'birthdate', 'birthday',
  // account/auth secrets
  'password', 'passwd', 'secret',
  'apikey', 'api_key', 'token', 'auth', 'authorization',
  'session', 'cookie', 'bearer', 'jwt',
  'creditcard', 'credit_card', 'cardnumber', 'card_number', 'cvv',
  'iban', 'swift', 'routingnumber', 'routing_number',
  // device-as-identity
  'deviceid', 'device_id', 'advertisingid', 'advertising_id',
  'idfa', 'idfv', 'macaddress', 'mac_address', 'imei',
  // network identity
  'ipaddress', 'ip_address', 'ip', 'ipv4', 'ipv6',
  'useragent', 'user_agent',
  // location
  'latitude', 'longitude', 'lat', 'lng', 'lon', 'geohash',
  'address', 'street', 'city', 'zipcode', 'zip_code',
  'postalcode', 'postal_code',
  // free-form content (high-risk for incidental PII)
  'message', 'content', 'body', 'text', 'comment', 'note',
  'value', 'input', 'query', 'search',
];

/// Allowlist of keys that look like denylisted ones but are explicitly safe
/// (code-defined metadata). Kept in lock-step with the sibling kits.
const Set<String> _allowlist = <String>{
  'screen', 'screenname', 'screen_name',
  'appversion', 'app_version',
  'osversion', 'os_version',
  'osname', 'os_name',
  'findingid', 'finding_id',
  'ruleid', 'rule_id',
  'score', 'rating', 'perception',
  // Per-process correlation token used by the production sampler. Generated
  // as s_<timestamp>_<random>, never a user/auth session id. Without this the
  // denied fragment `session` tokenizes out of sessionId and blocks every
  // sample. sessionKey / sessionToken stay denied via the tokenizer.
  'sessionid', 'session_id',
  // Snapshot axis keys whose names collide with a denied fragment via the
  // pass-2 substring check (…Contention contains `content`). Code-defined
  // axis identifiers, never user content; values are still screened.
  'gilcontention', 'lockcontention',
  'monitorcontention', 'monitor_contention',
  'lock_contention',
  'threadcontention', 'thread_contention',
  // leakWatch per-category COUNTERS whose camelCase names embed denied
  // fragments (`secret` in secretCount). Integers only — the field NAMES are
  // allowlisted.
  'secretcount', 'stackcount', 'piicount',
  // cookieExposure axis KEY itself collides with the denied `cookie`
  // fragment via the pass-2 substring check. Counts-only sub-object.
  'cookieexposure',
  // The BUILD-MAP KEY on a crash frame. An obfuscated release Flutter stack is
  // a list of raw addresses, and the split-debug-info file that could name them
  // is keyed on the ELF GNU build id plus an offset — so the frame carries
  // both, or it stays unreadable for ever. Decided by the build, never by a
  // person: a lowercase-hex build id and an integer offset already relative to
  // the image (an absolute address never leaves the device). Clean against
  // today's denylist and listed so a future denylist term cannot silently strip
  // them; the VALUES are still screened. Carried only by the three kits that
  // emit them (Swift, Kotlin, Flutter) and the server's ingest.
  'buildid', 'build_id', 'offset',
};

final RegExp _emailRe = RegExp(
  r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
);

/// The kit's canonical email regex, re-exported (never duplicated) so the
/// leakWatch collector reuses this exact pattern for its pii category.
final RegExp piiEmailRe = _emailRe;

final RegExp _ipv4Re = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');
final RegExp _ipv6FullRe = RegExp(
  r'^[0-9a-f]{1,4}(?::[0-9a-f]{1,4}){7}$',
  caseSensitive: false,
);
final RegExp _ipv6HexOnlyRe = RegExp(r'^[0-9a-f:]+$', caseSensitive: false);
final RegExp _ipv6CandidateRe = RegExp(
  r'[0-9a-f:]{4,45}',
  caseSensitive: false,
);
final RegExp _jwtRe = RegExp(
  r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
);
final RegExp _bearerRe = RegExp(r'bearer\s+\S{8,}', caseSensitive: false);
final RegExp _phoneRe = RegExp(
  r'(?<![0-9a-fA-F])(?:\+\d{1,3}[\s\-.])?\(?\d{3}\)?[\s\-.]\d{3}[\s\-.]\d{4}(?![0-9a-fA-F])',
);

/// UUID v4/v5 and similar hyphen-grouped hex identifiers. Applied only to
/// specific high-risk fields (route labels), never the general walk, because
/// install IDs are also UUID-shaped.
final RegExp routeLabelUuidRe = RegExp(
  r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  caseSensitive: false,
);

/// Long unbroken numeric runs (6+ digits) that look like opaque identifiers in
/// route labels. Scoped to routeLabel checks.
final RegExp routeLabelNumericRe = RegExp(r'\b\d{6,}\b');

final RegExp _labelHasSpaceRe = RegExp(r'\s');

// Structural exception: a canonical "METHOD /path" span label is exempted ONLY
// from the space heuristic; every later PII check still runs. Fully anchored
// (closed method set, exactly one space, path has no further whitespace) —
// mirrors HTTP_METHOD_PATH_RE / STRUCTURAL_METHOD_PATH_RE in the sibling kits.
final RegExp _httpMethodPathRe = RegExp(
  r'^(?:GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS|TRACE|CONNECT) /\S*$',
);

String _normalize(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

List<String> _tokenize(String name) {
  var s = name
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (m) => '${m[1]} ${m[2]}',
      );
  return s
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .where((t) => t.isNotEmpty)
      .map((t) => t.toLowerCase())
      .toList();
}

bool _looksLikeIpv6(String val) {
  if (val.length < 3) return false;
  if (_ipv6FullRe.hasMatch(val)) return true;
  if (!val.contains('::')) return false;
  if (!_ipv6HexOnlyRe.hasMatch(val)) return false;
  if (val.indexOf('::') != val.lastIndexOf('::')) return false;
  final groups = val.split(':').where((g) => g.isNotEmpty).length;
  return groups >= 1 && groups <= 7;
}

bool _containsEmbeddedIpv6(String val) {
  for (final m in _ipv6CandidateRe.allMatches(val)) {
    if (_looksLikeIpv6(m.group(0)!)) return true;
  }
  return false;
}

/// Returns the denied denylist entry a field NAME trips, or null when clean.
String? findDeniedFragment(String name) {
  final norm = _normalize(name);
  if (_allowlist.contains(norm)) return null;
  final tokens = _tokenize(name);
  // Pass 1: exact normalized match + per-token match.
  for (final denied in kPiiDenylist) {
    final dNorm = _normalize(denied);
    if (norm == dNorm) return denied;
    for (final tok in tokens) {
      if (tok == dNorm) return denied;
    }
  }
  // Pass 2: concatenated-fragment containment for entries >= 5 chars.
  for (final denied in kPiiDenylist) {
    final dNorm = _normalize(denied);
    if (dNorm.length < 5) continue;
    if (norm.contains(dNorm)) return denied;
  }
  return null;
}

/// Returns a fragment tag if the string VALUE looks like PII, else null.
String? findDeniedValue(String val) {
  if (val.length < 5) return null;
  if (_emailRe.hasMatch(val)) return '~email';
  if (_jwtRe.hasMatch(val)) return '~jwt';
  if (_bearerRe.hasMatch(val)) return '~bearer';
  if (_ipv4Re.hasMatch(val)) return '~ipv4';
  if (_containsEmbeddedIpv6(val)) return '~ipv6';
  if (_phoneRe.hasMatch(val)) return '~phone';
  return null;
}

/// Returns the matched tag if a route/screen label contains a high-risk PII
/// pattern (UUID or long numeric id), or has whitespace (always user content).
String? routeLabelHasPii(String label) {
  if (_labelHasSpaceRe.hasMatch(label)) return '~space-separated-label';
  final existing = findDeniedValue(label);
  if (existing != null) return existing;
  if (routeLabelUuidRe.hasMatch(label)) return '~uuid';
  if (routeLabelNumericRe.hasMatch(label)) return '~numeric-id';
  return null;
}

/// Transmit-time span-label check. Allows the structural "METHOD /path" space
/// (from spanLabel()); blocks every other whitespace-bearing label.
String? transmitLabelHasPii(String label) {
  if (_labelHasSpaceRe.hasMatch(label) && !_httpMethodPathRe.hasMatch(label)) {
    return '~space-separated-label';
  }
  final existing = findDeniedValue(label);
  if (existing != null) return existing;
  if (routeLabelUuidRe.hasMatch(label)) return '~uuid';
  if (routeLabelNumericRe.hasMatch(label)) return '~numeric-id';
  return null;
}

/// Return a safe route or screen label, or null when it must be refused.
/// Length is checked by the kit's one part-name normalizer before privacy.
String? sanitizeRouteLabel(String label) =>
    RouteInventory.safeScreenName(label);

PiiDetectedError? _walk(Object? payload, String path, Set<Object> seen) {
  if (payload is String) {
    final denied = findDeniedValue(payload);
    if (denied != null) {
      final fieldName = path.contains('.')
          ? path.substring(path.lastIndexOf('.') + 1)
          : path;
      return PiiDetectedError(path, fieldName, denied);
    }
    return null;
  }
  if (payload == null) return null;
  if (payload is num || payload is bool) return null;
  if (seen.contains(payload)) return null;
  if (payload is Iterable) {
    seen.add(payload);
    var i = 0;
    for (final item in payload) {
      final inner = _walk(item, '$path[$i]', seen);
      if (inner != null) return inner;
      i += 1;
    }
    return null;
  }
  if (payload is Map) {
    seen.add(payload);
    for (final entry in payload.entries) {
      final key = entry.key.toString();
      final childPath = '$path.$key';
      final matched = findDeniedFragment(key);
      if (matched != null) return PiiDetectedError(childPath, key, matched);
      final inner = _walk(entry.value, childPath, seen);
      if (inner != null) return inner;
    }
    return null;
  }
  return null;
}

/// Returns null if clean, or the offending error object if PII was detected.
PiiDetectedError? checkNoPii(Object? payload) =>
    _walk(payload, r'$', <Object>{});

/// Throws [PiiDetectedError] if the payload contains any PII.
void assertNoPii(Object? payload) {
  final hit = checkNoPii(payload);
  if (hit != null) throw hit;
}
