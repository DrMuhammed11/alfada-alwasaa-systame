// The community rule cache — the Flutter sibling of the Ruby / .NET Community.
//
// The checklist ships with the kit, but real projects keep finding patterns the
// shipped rules do not cover. The server serves those learned rules from
// GET /rules/community, and this keeps a local copy so the checklist and the MCP
// tools work at full strength without a network round trip on every call.
//
// FAILS OPEN, ALWAYS. A cold cache, an unreachable server, a bad key, a
// malformed answer — every one means "carry on with the shipped rules". The
// community layer can only ever ADD to what the kit already knows.

import '../core/store.dart';
import '../core/json.dart';
import '../core/runtime_flags.dart';
import '../core/telemetry.dart';
import '../core/transmit.dart';

/// The community rule cache. Static-only.
class Community {
  Community._();

  /// A cached copy is good for six hours.
  static const int cacheTtlMs = 21600000;
  static const int timeoutMs = 5000;

  /// Refuse an oversized answer rather than parsing it.
  static const int maxBytes = 1000000;

  static const String key = 'community_rules';

  static bool _refreshDisabled = false;

  static String endpointBase() => RuntimeFlags.apiBase;

  /// The cached rules, or an empty list when nothing is cached yet.
  static List<Object?> readCommunityCache() {
    final rec = Store.get(key, const <String, Object?>{});
    if (rec is! Map) return <Object?>[];
    final rules = rec['rules'];
    return rules is List ? List<Object?>.from(rules) : <Object?>[];
  }

  static int? cacheAgeMs() {
    final rec = Store.get(key, const <String, Object?>{});
    final at = rec is Map ? rec['fetchedAt'] : null;
    if (at is int) {
      final age = Telemetry.nowMs() - at;
      return age < 0 ? 0 : age;
    }
    return null;
  }

  static bool stale() {
    final age = cacheAgeMs();
    return age == null || age >= cacheTtlMs;
  }

  /// Refresh the cache when it has aged out. Cheap and safe to call from any
  /// path: it returns immediately unless a refresh is genuinely due. Never
  /// throws, never blocks the caller on the result.
  static Future<void> refreshCommunityCacheIfStale() async {
    if (_refreshDisabled || RuntimeFlags.disabled) return;
    if (!stale()) return;

    try {
      // Stamp the attempt BEFORE the call so a server that is down cannot turn
      // every call into a retry.
      Store.update(key, const <String, Object?>{}, (cur) {
        final rec = cur is Map
            ? Map<String, Object?>.from(cur)
            : <String, Object?>{};
        rec['attemptedAt'] = Telemetry.nowMs();
        return rec;
      });

      // GET /rules/community rides the shared transport chokepoint. See the
      // assumed-signature note: `Transmit.safeGet(url, {authToken, timeoutMs})
      // -> TransmitResult` is owned by the transport group.
      final res = await Transmit.safeGet(
        '${endpointBase()}/rules/community?runtime=${Telemetry.runtime}',
        authToken: Telemetry.effectiveProjectKey,
        timeoutMs: timeoutMs,
      );
      final body = res.body;
      if (res.status != 200 || body == null) return;

      final rules = body['rules'];
      if (rules is! List) return;

      final encoded = Json.encode(rules);
      if (encoded == null || encoded.length > maxBytes) return;

      Store.set(key, <String, Object?>{
        'rules': List<Object?>.from(rules),
        'fetchedAt': Telemetry.nowMs(),
      });
    } catch (_) {
      // Fail open — a cold/failed refresh means "carry on with shipped rules".
    }
  }

  /// Test seam — keeps the suite off the network.
  static void setRefreshDisabledForTesting(bool disabled) {
    _refreshDisabled = disabled;
  }

  static void clear() {
    Store.delete(key);
  }
}
