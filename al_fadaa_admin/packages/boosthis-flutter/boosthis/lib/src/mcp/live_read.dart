// Live per-install READ helpers — the Flutter sibling of the Ruby / .NET
// LiveRead.
//
// This is the READ side of the two-way channel: it lets the Flutter MCP's
// boosthis.snapshot + boosthis.crash_risk tools return an install's REAL
// uploaded picture (full perf snapshot + the "what is likely to crash my app"
// risk feed) instead of the static on-device note — but ONLY when the process
// has been handed read credentials for one specific install.
//
// CREDENTIAL RESOLUTION: an explicit per-call override wins; otherwise env
// BOOSTHIS_INSTALL_ID + BOOSTHIS_READ_TOKEN win, falling back to the persisted
// install id + read token minted by Telemetry.enable. The read token is the
// strictly read-only credential the developer copies into their AI — NEVER the
// delete token. With no creds every reader returns null and the tools serve the
// note.
//
// FAIL-OPEN + FAIL-SOFT: any failure — not configured, kill-switched, offline,
// non-200, bad JSON, oversized, PII trip — yields null so the caller serves the
// note; nothing ever throws to the host. A 404 is SEMANTIC ("nothing uploaded
// yet"), not an error, and the caller surfaces the matching NOTE_*_UNAVAILABLE
// text. Returned rows are re-run through the PII guard and any row that trips it
// is dropped rather than thrown.

import '../core/json.dart';
import '../core/runtime_flags.dart';
import '../core/telemetry.dart';
import '../core/transmit.dart';
import '../observers/pii.dart' show checkNoPii;

/// Live per-install READ helpers. Static-only.
class LiveRead {
  LiveRead._();

  /// ~2MB belt-and-braces cap on any single read (matches the server caps).
  static const int maxReadBytes = 2000000;

  /// Bounds every live read, in milliseconds.
  static const int liveReadTimeoutMs = 5000;

  static const String noteSnapshot =
      'Live full snapshot read from your Boosthis server: the whole meter page '
      'your app last uploaded (per-screen rows, cross-cutting findings, and the '
      'responsiveness/smoothness axes). Numbers + code-defined screen labels '
      'only — never user values or PII.';

  static const String noteSnapshotUnavailable =
      'No live snapshot available. This tool reads your app\'s OWN uploaded '
      'snapshot from the Boosthis server, which needs read credentials '
      '(BOOSTHIS_INSTALL_ID + BOOSTHIS_READ_TOKEN, or a registered install '
      'with a readToken from Telemetry.enable). Without them, use the on-device '
      'tools (session_summary).';

  static const String noteCrashRisk =
      'Potential-crashes risk feed read from your Boosthis server: the crash '
      'classes your app has ALREADY recorded (unhandled zone errors or a '
      'framework error), newest-first, joined with the stability summary from '
      'your latest snapshot. Each crash class carries relatedRules — fetch them '
      'with boosthis.get_rule for the fix. Signatures are code-derived (error '
      'name + redacted frame), never the raw error message, so no user value is '
      'exposed.';

  static const String noteCrashRiskUnavailable =
      'No live crash-risk feed available. This tool reads your app\'s OWN '
      'recorded crash classes from the Boosthis server, which needs read '
      'credentials (BOOSTHIS_INSTALL_ID + BOOSTHIS_READ_TOKEN, or a registered '
      'install with a readToken from Telemetry.enable). Without them, use '
      'boosthis.list_rules to review the crash-prevention rules.';

  /// The rule ids most likely to prevent a generic unhandled error. Every id
  /// here is a flutter-* id that MUST exist in this runtime's own rule book —
  /// a pointer the matcher cannot resolve is worse than no pointer.
  static const List<String> defaultCrashRules = <String>[
    'flutter-unbounded-list-builder',
    'flutter-image-decode-oom',
    'flutter-json-decode-large-payload',
  ];

  static const List<String> workerCrashRules = <String>[
    'flutter-isolate-unbounded-message',
    'flutter-compute-not-idempotent',
  ];

  static const List<String> renderCrashRules = <String>[
    'flutter-rebuild-storm',
    'flutter-expensive-build-method',
    'flutter-image-decode-oom',
  ];

  /// Rules addressing a blocked/overloaded main isolate (the stability axis).
  static const List<String> stabilityRules = <String>[
    'flutter-sync-io-on-ui-isolate',
    'flutter-heavy-work-no-isolate',
    'flutter-http-call-no-timeout',
  ];

  /// Maps a crash KIND to the rule ids most likely to prevent it.
  static Map<String, List<String>> crashKindRules() => <String, List<String>>{
        'uncaught': defaultCrashRules,
        'worker': workerCrashRules,
        'unhandledRejection': workerCrashRules,
        'render': renderCrashRules,
      };

  /// Resolve read credentials for ONE call. Returns null when either the
  /// install id or read token is missing. An explicit override wins; otherwise
  /// env BOOSTHIS_INSTALL_ID + BOOSTHIS_READ_TOKEN win, falling back to the
  /// persisted install id + read token. Never throws.
  static Map<String, String>? resolveLiveCreds(Map<String, String>? override) {
    if (override != null) {
      final id = (override['installId'] ?? '').trim();
      final tok = (override['readToken'] ?? '').trim();
      var base = (override['baseUrl'] ?? '').trim();
      if (base.isEmpty) base = RuntimeFlags.apiBase;
      if (id.isEmpty || tok.isEmpty) return null;
      return <String, String>{
        'installId': id,
        'readToken': tok,
        'baseUrl': _trimRightSlash(base),
      };
    }

    var id = _firstEnv(<String>['BOOSTHIS_INSTALL_ID', 'BOOSTEN_INSTALL_ID']);
    var tok = _firstEnv(<String>['BOOSTHIS_READ_TOKEN', 'BOOSTEN_READ_TOKEN']);
    var base = _firstEnv(<String>[
      'BOOSTHIS_INGEST_URL',
      'BOOSTEN_INGEST_URL',
      'BOOSTHIS_ENDPOINT',
      'BOOSTEN_ENDPOINT',
    ]);
    if (id.isEmpty) id = Telemetry.installId ?? '';
    if (tok.isEmpty) tok = Telemetry.readToken() ?? '';
    if (base.isEmpty) base = RuntimeFlags.apiBase;
    if (id.isEmpty || tok.isEmpty) return null;

    return <String, String>{
      'installId': id,
      'readToken': tok,
      'baseUrl': _trimRightSlash(base),
    };
  }

  /// The whole latest perf snapshot for one install, or null so the caller
  /// serves the note. Re-checked here (defence in depth) and dropped rather than
  /// thrown on a PII trip.
  static Future<Map<String, Object?>?> getLiveSnapshot(
      [Map<String, String>? override]) async {
    try {
      final cfg = resolveLiveCreds(override);
      if (cfg == null) return null;

      final snap = await _fetchJsonMap(
        '${cfg['baseUrl']}/snapshot?installId=${_urlEncode(cfg['installId']!)}',
        cfg['readToken']!,
      );
      if (snap == null) return null;
      if (checkNoPii(snap) != null) return null;

      return <String, Object?>{
        'available': true,
        'source': 'boosthis-server',
        'snapshot': snap,
        'note': noteSnapshot,
      };
    } catch (_) {
      return null; // fail-soft: caller serves the note
    }
  }

  /// The install's already-recorded crash classes + stability summary, with
  /// static rule-id pointers, or null so the caller serves the note.
  static Future<Map<String, Object?>?> getLiveCrashRisk(
      [Map<String, String>? override]) async {
    try {
      final cfg = resolveLiveCreds(override);
      if (cfg == null) return null;

      final data = await _fetchJsonMap(
        '${cfg['baseUrl']}/crashes/risk?installId=${_urlEncode(cfg['installId']!)}',
        cfg['readToken']!,
      );
      if (data == null) return null;

      final kindRules = crashKindRules();
      final crashes = <Map<String, Object?>>[];
      final crashesIn = data['crashes'];
      if (crashesIn is List) {
        for (final item in crashesIn) {
          if (item is! Map) continue;
          var kind = _liveStr(item['kind']);
          if (kind.isEmpty) kind = 'uncaught';
          final related = kindRules[kind] ?? defaultCrashRules;
          final row = <String, Object?>{
            'signature': _liveStr(item['signature']),
            'errorName': _liveStr(item['errorName']),
            'kind': kind,
            'redactedFrame': _liveStr(item['redactedFrame']),
            'countBucket': _liveStr(item['countBucket']),
            'occurrences': _liveNum(item['occurrences']),
            'firstSeenAt': _liveStrOrNull(item['firstSeenAt']),
            'lastSeenAt': _liveStrOrNull(item['lastSeenAt']),
            'relatedRules': related,
          };
          if (checkNoPii(row) == null) crashes.add(row);
        }
      }

      Map<String, Object?>? stability;
      final st = data['stability'];
      if (st is Map && checkNoPii(st) == null) {
        stability = Map<String, Object?>.from(st);
      }

      // Defence in depth over the SERVER-SUPPLIED data only; note/source and
      // the rule-id pointers are our own shipped constants.
      final guarded = <String, Object?>{
        'crashes': crashes,
        'stability': stability,
      };
      if (checkNoPii(guarded) != null) return null;

      return <String, Object?>{
        'available': true,
        'source': 'boosthis-server',
        'crashClasses': _liveNum(data['crashClasses']),
        'totalOccurrences': _liveNum(data['totalOccurrences']),
        'crashes': crashes,
        'stability': stability,
        'stabilityRules': stabilityRules,
        'note': noteCrashRisk,
      };
    } catch (_) {
      return null; // fail-soft: caller serves the note
    }
  }

  // ─── internals ─────────────────────────────────────────────────────────────

  /// GET a JSON object from the server with the read-token bearer. Returns null
  /// on any failure. Honors the kill-switch and screens the URL query through
  /// the PII guard before touching the network. A non-200 (including a semantic
  /// 404) yields null so the caller serves the note.
  static Future<Map<String, Object?>?> _fetchJsonMap(
      String rawUrl, String readToken) async {
    if (RuntimeFlags.disabled) return null;

    // GET rides the shared transport chokepoint (URL guard + kill-switch run
    // inside Transmit). See the assumed-signature note: `Transmit.safeGet(url,
    // {authToken, timeoutMs}) -> TransmitResult` is owned by the transport
    // group. authToken is the bare read token; Transmit adds the Bearer prefix.
    final res = await Transmit.safeGet(
      rawUrl,
      authToken: readToken.isNotEmpty ? readToken : null,
      timeoutMs: liveReadTimeoutMs,
    );
    if (res.status != 200) return null;

    final map = res.body;
    if (map == null) return null;

    // Belt-and-braces size cap on the decoded payload.
    final encoded = Json.encode(map);
    if (encoded == null || encoded.isEmpty || encoded.length > maxReadBytes) {
      return null;
    }
    return map;
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

  static String _trimRightSlash(String s) => s.replaceAll(RegExp(r'/+$'), '');

  static double _liveNum(Object? v) => v is num ? v.toDouble() : 0.0;

  static String _liveStr(Object? v) => v is String ? v : '';

  static String? _liveStrOrNull(Object? v) => v is String ? v : null;

  /// rawurlencode equivalent: encode everything but the RFC 3986 unreserved set.
  static String _urlEncode(String s) => Uri.encodeQueryComponent(s).replaceAll('+', '%20');
}
