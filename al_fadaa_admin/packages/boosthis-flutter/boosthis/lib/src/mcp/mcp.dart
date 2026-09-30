// Boosthis as a local stdio MCP server (JSON-RPC 2.0, newline-delimited) for
// Flutter / Dart projects — the Flutter sibling of boosthis-ruby's mcp.rb, the
// PHP Mcp.php, Java Mcp.java, Go mcp.go, Node mcp.ts, and boosthis-py's mcp.py.
// Same protocol version, the same {content:[{type:"text",text:...}]} result
// envelope, and the same initialize / tools/list / tools/call handling, so any
// MCP client (Replit AI, Cursor, Claude, …) talks to it exactly as it does the
// other runtimes.
//
// This is a LOCAL server: it runs over stdin/stdout beside the developer's own
// Flutter project and exposes the offline rule book plus the perf samples
// recorded in the on-device store. It never opens a network listener; the only
// outbound bytes are the fire-and-forget, PII-guarded rule proposal from
// report_unmatched_pattern, which rides the shared transmit chokepoint.
//
// FIVE tools, matching the sibling public surface exactly:
//   - boosthis.list_rules — browse the Flutter rules (optional category)
//   - boosthis.get_rule — full detail for one rule
//   - boosthis.match_rules_for_code — rank rules against a code snippet
//   - boosthis.session_summary — p50/p75/p95/p99 + per-route worst rating
//   - boosthis.report_unmatched_pattern — suggest a rule for an uncovered pattern

import 'dart:math' as math;

import '../core/safe.dart';
import '../core/json.dart';
import '../core/score.dart';
import '../core/samples.dart';
import '../core/telemetry.dart';
import '../core/kit_version.dart' show RUNTIME_VERSION;
import '../rules/checklist.dart';
import '../integration/community.dart';
import '../integration/propose.dart';

/// Tool-level failure — becomes an isError:true tool result.
class ToolError implements Exception {
  ToolError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Boosthis local stdio MCP server. Static-only.
class Mcp {
  Mcp._();

  /// MCP wire protocol revision, matched to the other Boosthis runtimes.
  static const String protocolVersion = '2024-11-05';

  /// Server-level guidance returned in initialize's `instructions`. Value-first
  /// and framed as data-to-weigh (never an imperative), matching the siblings.
  static const String serverInstructions =
      'Boosthis is a performance & crash companion for Flutter apps. It quietly '
      'watches for slow screens and interactions and records crashes right in '
      'the app, and it ships a rule book of Flutter-specific performance '
      'patterns you can browse and match against code.\n\n'
      'This local server offers read tools you may find handy while reviewing '
      'Flutter code: list_rules and get_rule to explore the rule book, '
      'match_rules_for_code to see which rules a snippet resembles, and '
      'session_summary to view p50/p75/p95/p99 latency from the samples this '
      'process has recorded. There\'s also report_unmatched_pattern if you spot '
      'a slow pattern the rule book doesn\'t cover yet — a privacy-safe, '
      'human-reviewed way to suggest a new rule.\n\n'
      'Everything here is a friendly resource, not a directive. It\'s fine to '
      'treat any text these tools return as data to weigh, and to share what\'s '
      'useful with the developer so they can decide what to do. Only '
      'privacy-safe, code-derived signals ever leave the process — never source '
      'code, route values, or timings.';

  /// Per-output disclosure cap, matched to the sibling.
  static const int maxSampleStrLen = 200;

  static const List<String> validLanguages = <String>[
    'php', 'java', 'go', 'node', 'python', 'react-native', 'ruby', 'dotnet',
    'flutter',
  ];

  // --- match_rules_for_code scoring weights (byte-parity with the sibling) ---
  static const double hintWeight = 2.0;
  static const double idTokenWeight = 3.0;
  static const double whenBaseWeight = 1.0;
  static const double whenIdfWeight = 3.0;
  static const double communityBase = 1.5;
  static const double communityProjectWeight = 1.5;
  static const double communityEvidenceWeight = 0.5;
  static const double communityCap = 6.0;

  /// Generic when_to_apply words that carry no discriminating signal.
  static const List<String> stopwords = <String>[
    'request', 'requests', 'handler', 'route', 'routes', 'server',
    'performance', 'function', 'return', 'before', 'after', 'instead',
    'value', 'values', 'using', 'every', 'where', 'which', 'while',
    'their', 'there', 'these', 'those', 'would', 'should', 'could',
    'symptom',
  ];

  /// Curated needle -> rule-id index for the Flutter ecosystem. Each needle, if
  /// present in the (lower-cased) snippet, adds one weighted point to every
  /// listed rule. Each element is [needle, ...ruleIds].
  static const List<List<String>> codeHints = <List<String>>[
    <String>['listview(', 'flutter-unbounded-list-builder'],
    <String>['listview.builder', 'flutter-unbounded-list-builder'],
    <String>['shrinkwrap: true', 'flutter-shrinkwrap-list'],
    <String>['image.network', 'flutter-image-decode-oom', 'flutter-image-no-cache-dims'],
    <String>['image.asset', 'flutter-image-decode-oom'],
    <String>['cachewidth', 'flutter-image-no-cache-dims'],
    <String>['jsondecode', 'flutter-json-decode-large-payload'],
    <String>['json.decode', 'flutter-json-decode-large-payload'],
    <String>['compute(', 'flutter-compute-not-idempotent'],
    <String>['isolate.spawn', 'flutter-isolate-unbounded-message'],
    <String>['sendport', 'flutter-isolate-unbounded-message'],
    <String>['setstate(', 'flutter-rebuild-storm', 'flutter-setstate-in-build'],
    <String>['notifylisteners', 'flutter-rebuild-storm'],
    <String>['build(buildcontext', 'flutter-expensive-build-method'],
    <String>['mediaquery.of', 'flutter-mediaquery-rebuild'],
    <String>['opacity(', 'flutter-opacity-saves-layer', 'flutter-raster-jank'],
    <String>['cliprrect', 'flutter-clip-saves-layer'],
    <String>['savelayer', 'flutter-raster-jank'],
    <String>['http.get', 'flutter-http-call-no-timeout', 'flutter-no-http-connection-reuse'],
    <String>['http.post', 'flutter-http-call-no-timeout'],
    <String>['dio(', 'flutter-http-call-no-timeout', 'flutter-no-http-connection-reuse'],
    <String>['.timeout(', 'flutter-http-call-no-timeout'],
    <String>['file(', 'flutter-sync-io-on-ui-isolate'],
    <String>['readasstringsync', 'flutter-sync-io-on-ui-isolate'],
    <String>['sharedpreferences', 'flutter-sync-io-on-ui-isolate'],
    <String>['timer(', 'flutter-timer-not-cancelled'],
    <String>['timer.periodic', 'flutter-timer-not-cancelled'],
    <String>['streamsubscription', 'flutter-stream-not-cancelled'],
    <String>['addlistener', 'flutter-listener-not-removed'],
    <String>['animationcontroller', 'flutter-controller-not-disposed'],
    <String>['dispose()', 'flutter-controller-not-disposed'],
    <String>['future.wait', 'flutter-unawaited-future'],
    <String>['methodchannel', 'flutter-platform-channel-chatty'],
    <String>['navigator.push', 'flutter-heavy-route-transition'],
    <String>['rebuild', 'flutter-rebuild-storm'],
  ];

  // --- circuit summary thresholds (byte-parity with every sibling) ---
  static const int circuitLoopMinHits = 8;
  static const int circuitLoopWindowMs = 30000;
  static const int circuitLoopMaxMedianGapMs = 2000;
  static const int circuitBurstWindowMs = 1000;
  static const int circuitBurstMin = 6;
  static const int circuitMaxLoopSuspects = 5;

  /// Prompt-injection markers neutralised in sample-derived strings.
  static const List<String> injectionMarkers = <String>[
    '<|im_start|>', '<|im_end|>', '<|system|>', '<|user|>',
    '<|assistant|>', '<|endoftext|>', '###system', '###instruction',
  ];

  static Map<String, int>? _wordDf;

  // -------------------------------------------------------------------
  // Stdio loop.
  // -------------------------------------------------------------------

  /// Runs the local stdio MCP server: reads newline-delimited JSON-RPC requests
  /// from [readLine] (returns null at EOF), dispatches each, and writes
  /// newline-delimited responses via [writeOut]. Notifications never reply. A
  /// malformed line yields a proper JSON-RPC error rather than tearing down the
  /// loop. Returns cleanly at EOF.
  static Future<void> run(
    Future<String?> Function() readLine,
    void Function(String) writeOut,
  ) async {
    try {
      while (true) {
        final line = await readLine();
        if (line == null) break;
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final resp = handleLine(trimmed);
        if (resp == null) continue;
        writeOut('$resp\n');
      }
    } catch (_) {
      // A transport-level failure ends the loop cleanly; the kit never throws
      // to the host process.
    }
  }

  // -------------------------------------------------------------------
  // JSON-RPC 2.0 envelope.
  // -------------------------------------------------------------------

  /// Parses and dispatches a single request line. Returns the response JSON to
  /// write, or null when nothing should be written (notifications). Public so
  /// tests can drive the protocol without a real pipe.
  static String? handleLine(String line) {
    final probe = _safeJsonObject(line);
    if (identical(probe, _parseError)) {
      return _rpcError(null, -32700, 'Parse error');
    }
    if (probe is! Map) return _rpcError(null, -32600, 'Invalid Request');

    final m = probe;
    if (m['jsonrpc'] != '2.0') {
      return _rpcError(null, -32600, "Invalid Request: jsonrpc must be '2.0'");
    }

    final hasId = m.containsKey('id');
    final id = hasId ? m['id'] : null;
    if (hasId && id != null && id is! String && id is! int && id is! double) {
      return _rpcError(
          null, -32600, 'Invalid Request: id must be string, number, or null');
    }

    final method = m['method'];
    if (method is! String) {
      return _rpcError(
          hasId ? id : null, -32600, 'Invalid Request: missing method');
    }

    return _dispatch(method, m, id, !hasId);
  }

  /// Executes one tool by name, returning its JSON-serializable result or
  /// throwing a [ToolError]. Public for tests.
  static Object? callTool(String name, Map<String, Object?> args) {
    switch (name) {
      case 'boosthis.list_rules':
        return _toolListRules(args);
      case 'boosthis.get_rule':
        return _toolGetRule(args);
      case 'boosthis.match_rules_for_code':
        final code = args['code'] is String ? args['code'] as String : '';
        return <String, Object?>{'matches': matchRulesForCode(code)};
      case 'boosthis.session_summary':
        return sessionSummary();
      case 'boosthis.report_unmatched_pattern':
        return _toolReportUnmatchedPattern(args);
      default:
        throw ToolError('unknown tool: $name');
    }
  }

  // -------------------------------------------------------------------
  // Tool catalogue (tools/list).
  // -------------------------------------------------------------------

  static List<Map<String, Object?>> toolCatalogue() {
    final tools = <Map<String, Object?>>[];

    final cat = _prop('string', 'Optional category filter.');
    cat['enum'] = <String>['case-study', 'industry', 'operational'];
    tools.add(_tool(
      'boosthis.list_rules',
      'Browse the Flutter performance rules — useful when reviewing widget or '
          'screen code or before pulling one up in detail. Optionally narrow to '
          'a category (case-study, industry, or operational).',
      <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{'category': cat},
      },
    ));

    tools.add(_tool(
      'boosthis.get_rule',
      'Look up the full detail for one Flutter rule — its title, when it tends '
          'to apply, evidence references, and category. Handy once list_rules or '
          'match_rules_for_code points you at a candidate. The prescriptive fix '
          'lives server-side and is served separately.',
      <String, Object?>{
        'type': 'object',
        'required': <String>['id'],
        'properties': <String, Object?>{
          'id': _prop('string',
              "Rule id, e.g. 'flutter-unbounded-list-builder' or 'flutter-http-call-no-timeout'."),
        },
      },
    ));

    tools.add(_tool(
      'boosthis.match_rules_for_code',
      'Rank the Flutter rules against a code snippet using a curated keyword '
          'index plus each rule\'s when-to-apply text. Returns up to 8 candidates '
          'worth reviewing — suggestions to weigh against each rule\'s '
          'when_to_apply, not definitive findings.',
      <String, Object?>{
        'type': 'object',
        'required': <String>['code'],
        'properties': <String, Object?>{'code': _prop('string', null)},
      },
    ));

    tools.add(_tool(
      'boosthis.session_summary',
      'See p50/p75/p95/p99 latency plus per-route worst rating from the samples '
          'the Boosthis instrument wrapper has recorded in this process. Comes '
          'back empty when no samples have been collected yet (for example, when '
          'this server runs on its own rather than in-process) — that\'s '
          'expected, not an error.',
      <String, Object?>{'type': 'object', 'properties': <String, Object?>{}},
    ));

    final lang = _prop('string', null);
    lang['enum'] = <String>[
      'flutter', 'ruby', 'php', 'java', 'go', 'node', 'python', 'react-native',
      'dotnet',
    ];
    final repCat =
        _prop('string', 'Optional: coarse performance category for the pattern.');
    repCat['enum'] = <String>[
      'startup', 'navigation', 'interaction', 'rendering', 'network', 'data',
      'memory', 'other',
    ];
    tools.add(_tool(
      'boosthis.report_unmatched_pattern',
      'Share a slow pattern you\'ve noticed that no current Flutter rule covers. '
          'The privacy-safe signal is reviewed by humans to help author new '
          'rules. Best with a generic description of the shape — for example "a '
          'setState called on every animation frame" — rather than the '
          'developer\'s literal code or anything identifying.',
      <String, Object?>{
        'type': 'object',
        'required': <String>['pattern', 'language'],
        'properties': <String, Object?>{
          'pattern': _prop('string', 'Short, generic description of the pattern.'),
          'language': lang,
          'observed_ms':
              _prop('integer', 'Optional: measured latency in ms for context.'),
          'category': repCat,
          'proposed_rule_id': _prop(
              'string', "Optional draft: a kebab-case id for the rule you'd propose."),
          'proposed_title': _prop(
              'string', 'Optional draft: a short human title for the proposed rule.'),
          'proposed_when_to_apply': _prop('string',
              'Optional draft: when this rule should fire (generic, no user code).'),
          'proposed_fix_template': _prop('string',
              'Optional draft: the fix guidance you\'d suggest (generic, no user code).'),
        },
      },
    ));

    return tools;
  }

  // -------------------------------------------------------------------
  // session_summary.
  // -------------------------------------------------------------------

  static Map<String, Object?> sessionSummary() {
    final samples = Samples.all();
    final summary = _buildSummary(samples);
    summary['circuit'] = _buildCircuit(samples);
    return sanitizeMcpValue(summary) as Map<String, Object?>;
  }

  // -------------------------------------------------------------------
  // match_rules_for_code.
  // -------------------------------------------------------------------

  static List<Map<String, Object?>> matchRulesForCode(String code) {
    final lower = code.toLowerCase();
    Community.refreshCommunityCacheIfStale();
    final community = _communityByRule();
    final codeWords = _wordSetFrom(code, RegExp(r'[a-z][a-z0-9]{3,}'));
    final df = _wordDocFreq();

    final hintScore = <String, double>{};
    for (final h in codeHints) {
      final needle = h[0];
      if (!lower.contains(needle)) continue;
      for (var i = 1; i < h.length; i++) {
        hintScore[h[i]] = (hintScore[h[i]] ?? 0.0) + hintWeight;
      }
    }

    final scored = <Map<String, Object?>>[];
    for (final r in Checklist.all()) {
      final id = r.id;
      var relevance = hintScore[id] ?? 0.0;

      for (final tok in id.split('-')) {
        if (tok.length >= 4 && codeWords.containsKey(tok)) {
          relevance += idTokenWeight;
        }
      }

      for (final w in _distinctiveWords(r.whenToApply).keys) {
        if (!codeWords.containsKey(w)) continue;
        final freq = math.max(1, df[w] ?? 1);
        relevance += whenBaseWeight + whenIdfWeight / freq;
      }

      if (relevance <= 0) continue;

      var score = relevance;
      var projects = 0;
      final c = community[id];
      if (c != null) {
        score += _communityBoost(c);
        projects = c['projects'] as int;
      }
      scored.add(<String, Object?>{
        'id': id,
        'score': score,
        'projects': projects,
        'categoryRank': _categoryRank(r.category),
        'evidenceCount': r.evidence.length,
      });
    }

    scored.sort((a, b) {
      var cmp = (b['score'] as double).compareTo(a['score'] as double);
      if (cmp == 0) cmp = (b['projects'] as int).compareTo(a['projects'] as int);
      if (cmp == 0) {
        cmp = (a['categoryRank'] as int).compareTo(b['categoryRank'] as int);
      }
      if (cmp == 0) {
        cmp = (b['evidenceCount'] as int).compareTo(a['evidenceCount'] as int);
      }
      if (cmp == 0) cmp = (a['id'] as String).compareTo(b['id'] as String);
      return cmp;
    });

    final out = <Map<String, Object?>>[];
    for (final s in scored) {
      if (out.length >= 8) break;
      final r = Checklist.findById(s['id'] as String);
      if (r == null) continue;
      final m = <String, Object?>{
        'id': r.id,
        'title': r.title,
        'category': r.category,
        'match_score': ((s['score'] as double) * 100).round() / 100.0,
        'when_to_apply': r.whenToApply,
      };
      final c = community[s['id']];
      if (c != null) {
        m['community_proven'] = true;
        m['community_projects'] = c['projects'];
        m['community_evidence'] = c['evidence'];
        var circ = List<Object?>.from(c['circumstances'] as List);
        if (circ.length > 3) circ = circ.sublist(0, 3);
        m['community_circumstances'] = circ;
      }
      out.add(m);
    }
    return out;
  }

  // -------------------------------------------------------------------
  // Sanitization.
  // -------------------------------------------------------------------

  /// Recursively sanitize every string (and map key) in a sample-derived value.
  static Object? sanitizeMcpValue(Object? value) {
    if (value is String) return sanitizeMcpString(value);
    if (value is List) return value.map(sanitizeMcpValue).toList();
    if (value is Map) {
      final out = <String, Object?>{};
      value.forEach((k, v) {
        out[sanitizeMcpString(k.toString())] = sanitizeMcpValue(v);
      });
      return out;
    }
    return value;
  }

  /// Prompt-injection sanitization for sample-derived strings: caps length,
  /// strips C0/C1 control characters (keeping \n and \t), neutralises common
  /// role-injection markers, and escapes angle brackets. Public for tests.
  static String sanitizeMcpString(String value) {
    var s = value;
    for (final marker in injectionMarkers) {
      final lowerMarker = marker.toLowerCase();
      while (true) {
        final idx = s.toLowerCase().indexOf(lowerMarker);
        if (idx < 0) break;
        s = s.substring(0, idx) + '[redacted]' + s.substring(idx + marker.length);
      }
    }
    final buf = StringBuffer();
    for (final ch in s.runes) {
      if (ch == 0x0A || ch == 0x09) {
        buf.writeCharCode(ch);
        continue;
      }
      if (ch >= 0x20 && !(ch >= 0x7F && ch <= 0x9F)) {
        buf.writeCharCode(ch);
      }
    }
    var cleaned = buf.toString().replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    if (cleaned.length > maxSampleStrLen) {
      cleaned = '${cleaned.substring(0, maxSampleStrLen)}\u2026[truncated]';
    }
    return cleaned;
  }

  // -------------------------------------------------------------------
  // Dispatch.
  // -------------------------------------------------------------------

  static const Object _parseError = Object();

  static String? _dispatch(
      String method, Map m, Object? id, bool isNotification) {
    switch (method) {
      case 'initialize':
        if (isNotification) return null;
        return _rpcResult(id, <String, Object?>{
          'protocolVersion': protocolVersion,
          'capabilities': <String, Object?>{
            'tools': <String, Object?>{},
            'resources': <String, Object?>{},
          },
          'serverInfo': <String, Object?>{
            'name': 'boosthis-flutter',
            'version': RUNTIME_VERSION,
          },
          'instructions': serverInstructions,
        });
      case 'notifications/initialized':
        return null;
      case 'tools/list':
        if (isNotification) return null;
        return _rpcResult(id, <String, Object?>{'tools': toolCatalogue()});
      case 'tools/call':
        if (isNotification) return null;
        final parsed = _parseCallParams(m['params']);
        Object? result;
        try {
          result = callTool(parsed[0] as String, parsed[1] as Map<String, Object?>);
        } on ToolError catch (e) {
          return _rpcResult(id, <String, Object?>{
            'isError': true,
            'content': <Object?>[
              <String, Object?>{'type': 'text', 'text': 'tool failed: ${e.message}'}
            ],
          });
        }
        return _rpcResult(id, _toolResult(result));
      case 'resources/list':
        if (isNotification) return null;
        return _rpcResult(id, <String, Object?>{'resources': <Object?>[]});
      case 'ping':
        if (isNotification) return null;
        return _rpcResult(id, <String, Object?>{});
      default:
        if (isNotification) return null;
        return _rpcError(id, -32601, 'method not found: $method');
    }
  }

  static Object _safeJsonObject(String line) {
    final parsed = Json.decode(line);
    if (parsed == null) return _parseError;
    return parsed;
  }

  static String _rpcResult(Object? id, Map<String, Object?> result) {
    final out = Json.encode(<String, Object?>{
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });
    return out ??
        (Json.encode(<String, Object?>{
              'jsonrpc': '2.0',
              'id': null,
              'error': <String, Object?>{'code': -32603, 'message': 'internal error'},
            }) ??
            '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"internal error"}}');
  }

  static String _rpcError(Object? id, int code, String message) {
    final out = Json.encode(<String, Object?>{
      'jsonrpc': '2.0',
      'id': id,
      'error': <String, Object?>{'code': code, 'message': message},
    });
    return out ??
        '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"internal error"}}';
  }

  static List<Object?> _parseCallParams(Object? params) {
    var name = '';
    var args = <String, Object?>{};
    if (params is Map) {
      if (params['name'] is String) name = params['name'] as String;
      if (params['arguments'] is Map) {
        args = Map<String, Object?>.from(params['arguments'] as Map);
      }
    }
    return <Object?>[name, args];
  }

  static Map<String, Object?> _toolResult(Object? payload) {
    final text = Json.encode(payload) ?? 'null';
    return <String, Object?>{
      'content': <Object?>[
        <String, Object?>{'type': 'text', 'text': text}
      ],
    };
  }

  static Map<String, Object?> _prop(String type, String? description) {
    final m = <String, Object?>{'type': type};
    if (description != null) m['description'] = description;
    return m;
  }

  static Map<String, Object?> _tool(
      String name, String description, Map<String, Object?> inputSchema) {
    return <String, Object?>{
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }

  // -------------------------------------------------------------------
  // Tool bodies.
  // -------------------------------------------------------------------

  static Map<String, Object?> _toolListRules(Map<String, Object?> args) {
    var rules = Checklist.all();
    if (args.containsKey('category') && args['category'] != null) {
      final cv = args['category'];
      if (cv is! String ||
          !<String>['case-study', 'industry', 'operational'].contains(cv)) {
        throw ToolError(
            "category must be one of 'case-study', 'industry', 'operational'");
      }
      rules = rules.where((r) => r.category == cv).toList();
    }
    final out = rules
        .map((r) => <String, Object?>{
              'id': r.id,
              'title': r.title,
              'category': r.category,
              'languages': r.languages,
            })
        .toList();
    return <String, Object?>{'count': rules.length, 'rules': out};
  }

  static Map<String, Object?> _toolGetRule(Map<String, Object?> args) {
    final id = _optStr(args, 'id');
    final rule = Checklist.findById(id);
    if (rule == null) throw ToolError('unknown rule id: $id');
    return <String, Object?>{
      'id': rule.id,
      'title': rule.title,
      'when_to_apply': rule.whenToApply,
      'evidence': rule.evidence,
      'category': rule.category,
      'languages': rule.languages,
    };
  }

  static Map<String, Object?> _toolReportUnmatchedPattern(
      Map<String, Object?> args) {
    var pattern = _requireStr(args, 'pattern');
    pattern = _truncatePattern(pattern, 500);
    final language = _requireStr(args, 'language');
    if (!validLanguages.contains(language)) {
      throw ToolError(
          "language must be one of 'flutter', 'ruby', 'php', 'java', 'go', 'node', 'python', 'react-native'");
    }
    final observed = _optInt(args, 'observed_ms');
    _dispatchProposal(
      pattern,
      language,
      observed[1] as bool ? (observed[0] as int).toDouble() : 0.0,
      observed[1] as bool,
      _optStr(args, 'category'),
      _optStr(args, 'proposed_rule_id'),
      _optStr(args, 'proposed_title'),
      _optStr(args, 'proposed_when_to_apply'),
      _optStr(args, 'proposed_fix_template'),
    );
    return <String, Object?>{'ok': true, 'stored_at_ms': Telemetry.nowMs()};
  }

  static void _dispatchProposal(
    String pattern,
    String language,
    double observedMs,
    bool hasObserved,
    String category,
    String proposedRuleId,
    String proposedTitle,
    String proposedWhenToApply,
    String proposedFixTemplate,
  ) {
    Safe.fire(() {
      final draft = <String, Object?>{
        'proposedRuleId': proposedRuleId,
        'title': proposedTitle,
        'whenToApply': proposedWhenToApply,
        'fixTemplate': proposedFixTemplate,
      };
      Propose.reportUnmatchedPattern(
          pattern, language, observedMs, hasObserved, category, draft);
    });
  }

  static String _truncatePattern(String s, int max) {
    final out = Propose.truncateRunes(s, max);
    return out;
  }

  // -------------------------------------------------------------------
  // Argument coercion helpers.
  // -------------------------------------------------------------------

  static String _requireStr(Map<String, Object?> args, String key) {
    final v = args[key];
    if (v is! String || v.trim().isEmpty) {
      throw ToolError("missing or empty '$key'");
    }
    return v.trim();
  }

  static String _optStr(Map<String, Object?> args, String key) {
    final v = args[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : '';
  }

  /// Accept a true integer or a numeric string. Returns [value, present?].
  static List<Object?> _optInt(Map<String, Object?> args, String key) {
    if (!args.containsKey(key) || args[key] == null) {
      return <Object?>[0, false];
    }
    final v = args[key];
    if (v is int) return <Object?>[v, true];
    if (v is double) {
      if (v.isNaN || v.isInfinite || v != v.floorToDouble()) {
        throw ToolError("'$key' must be an integer");
      }
      return <Object?>[v.toInt(), true];
    }
    if (v is String) {
      final s = v.trim();
      if (!RegExp(r'^-?\d+$').hasMatch(s)) {
        throw ToolError("'$key' must be an integer");
      }
      return <Object?>[int.parse(s), true];
    }
    throw ToolError("'$key' must be an integer");
  }

  // -------------------------------------------------------------------
  // session_summary internals.
  // -------------------------------------------------------------------

  static int _ratingOrder(String r) {
    switch (r) {
      case 'good':
        return 0;
      case 'needs-work':
        return 1;
      case 'poor':
        return 2;
      default:
        return 0;
    }
  }

  static Map<String, Object?> _buildSummary(List<Map<String, Object?>> samples) {
    if (samples.isEmpty) {
      return <String, Object?>{
        'total': 0, 'good': 0, 'needsWork': 0, 'poor': 0,
        'p50_ms': null, 'p75_ms': null, 'p95_ms': null, 'p99_ms': null,
        'byRoute': <String, Object?>{},
      };
    }

    final durations = <int>[];
    var good = 0, needsWork = 0, poor = 0;
    final byRoute = <String, Map<String, Object?>>{};
    for (final s in samples) {
      final ms = (s['durationMs'] as num?)?.toInt() ?? 0;
      final rating = Score.getDurationRating(ms.toDouble());
      durations.add(ms);
      if (rating == 'poor') {
        poor++;
      } else if (rating == 'needs-work') {
        needsWork++;
      } else {
        good++;
      }
      final route = (s['route'] ?? '').toString();
      final r = byRoute.putIfAbsent(
          route,
          () => <String, Object?>{
                'count': 0,
                'max_ms': 0,
                'worst_rating': 'good',
              });
      r['count'] = (r['count'] as int) + 1;
      if (ms > (r['max_ms'] as int)) r['max_ms'] = ms;
      if (_ratingOrder(rating) > _ratingOrder(r['worst_rating'] as String)) {
        r['worst_rating'] = rating;
      }
    }
    durations.sort();

    return <String, Object?>{
      'total': samples.length,
      'good': good,
      'needsWork': needsWork,
      'poor': poor,
      'p50_ms': _pct(durations, 0.50),
      'p75_ms': _pct(durations, 0.75),
      'p95_ms': _pct(durations, 0.95),
      'p99_ms': _pct(durations, 0.99),
      'byRoute': byRoute,
    };
  }

  static int _pct(List<int> sorted, double p) {
    final n = sorted.length;
    if (n == 0) return 0;
    var idx = (n * p).toInt();
    if (idx > n - 1) idx = n - 1;
    return sorted[idx];
  }

  static int _circuitMedian(List<int> sorted) {
    final n = sorted.length;
    if (n == 0) return 0;
    final mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2.0).round();
  }

  /// Circuit summary — LOOP SUSPECTS + FAN-OUT BURST over the same samples.
  static Map<String, Object?> _buildCircuit(List<Map<String, Object?>> samples) {
    final out = <String, Object?>{
      'loop_suspects': <Object?>[],
      'burst_max_1s': 0,
      'burst_route_count': 0,
      'related_rules': <Object?>[],
    };
    if (samples.isEmpty) return out;

    var loopSuspects = <Map<String, Object?>>[];
    final relatedRules = <String>[];

    final byRoute = <String, List<int>>{};
    for (final s in samples) {
      final route = (s['route'] ?? '').toString();
      final at = (s['at'] as num?)?.toInt() ?? 0;
      byRoute.putIfAbsent(route, () => <int>[]).add(at);
    }

    byRoute.forEach((route, tsRaw) {
      final ts = List<int>.from(tsRaw)..sort();
      if (ts.length < circuitLoopMinHits) return;

      var bestStart = 0, bestCount = 0, lo = 0;
      for (var hi = 0; hi < ts.length; hi++) {
        while (ts[hi] - ts[lo] > circuitLoopWindowMs) {
          lo++;
        }
        final count = hi - lo + 1;
        if (count > bestCount) {
          bestCount = count;
          bestStart = lo;
        }
      }
      if (bestCount < circuitLoopMinHits) return;

      final windowTs = ts.sublist(bestStart, bestStart + bestCount);
      final gaps = <int>[];
      for (var i = 1; i < windowTs.length; i++) {
        gaps.add(windowTs[i] - windowTs[i - 1]);
      }
      gaps.sort();
      final medianGap = _circuitMedian(gaps);
      if (medianGap > circuitLoopMaxMedianGapMs) return;

      final windowSpanMs = windowTs.last - windowTs.first;
      final windowS = math.max(1, (windowSpanMs / 1000.0).round());
      loopSuspects.add(<String, Object?>{
        'route': route,
        'hits': bestCount,
        'window_s': windowS,
        'median_gap_ms': medianGap,
      });
    });
    loopSuspects.sort((a, b) => (b['hits'] as int).compareTo(a['hits'] as int));
    if (loopSuspects.length > circuitMaxLoopSuspects) {
      loopSuspects = loopSuspects.sublist(0, circuitMaxLoopSuspects);
    }
    out['loop_suspects'] = loopSuspects;

    final all = List<Map<String, Object?>>.from(samples)
      ..sort((a, b) => ((a['at'] as num?)?.toInt() ?? 0)
          .compareTo((b['at'] as num?)?.toInt() ?? 0));
    var burstMax = 0, burstLo = 0, burstHi = 0, lo2 = 0;
    for (var hi = 0; hi < all.length; hi++) {
      while (((all[hi]['at'] as num?)?.toInt() ?? 0) -
              ((all[lo2]['at'] as num?)?.toInt() ?? 0) >
          circuitBurstWindowMs) {
        lo2++;
      }
      final count = hi - lo2 + 1;
      if (count > burstMax) {
        burstMax = count;
        burstLo = lo2;
        burstHi = hi;
      }
    }
    out['burst_max_1s'] = burstMax;
    if (burstMax > 0) {
      final routes = <String, bool>{};
      for (var i = burstLo; i <= burstHi; i++) {
        routes[(all[i]['route'] ?? '').toString()] = true;
      }
      out['burst_route_count'] = routes.length;
    }

    if (loopSuspects.isNotEmpty) relatedRules.add('flutter-retry-redirect-loop');
    if (burstMax >= circuitBurstMin) relatedRules.add('flutter-fanout-overload');
    out['related_rules'] = relatedRules;

    return out;
  }

  // -------------------------------------------------------------------
  // match_rules_for_code internals.
  // -------------------------------------------------------------------

  static int _categoryRank(String category) {
    switch (category) {
      case 'case-study':
        return 0;
      case 'industry':
        return 1;
      case 'operational':
        return 2;
      default:
        return 99;
    }
  }

  static Map<String, bool> _wordSetFrom(String text, RegExp re) {
    final out = <String, bool>{};
    for (final m in re.allMatches(text.toLowerCase())) {
      out[m.group(0)!] = true;
    }
    return out;
  }

  static Map<String, bool> _distinctiveWords(String text) {
    final out = <String, bool>{};
    for (final w in _wordSetFrom(text, RegExp(r'[a-z][a-z0-9]{4,}')).keys) {
      if (!stopwords.contains(w)) out[w] = true;
    }
    return out;
  }

  static Map<String, int> _wordDocFreq() {
    return _wordDf ??= () {
      final df = <String, int>{};
      for (final r in Checklist.all()) {
        for (final w in _distinctiveWords(r.whenToApply).keys) {
          df[w] = (df[w] ?? 0) + 1;
        }
      }
      return df;
    }();
  }

  static double _communityBoost(Map<String, Object?> c) {
    final projects = (c['projects'] as num).toDouble();
    final evidence = (c['evidence'] as num).toDouble();
    final boost = communityBase +
        communityProjectWeight * (math.log(1 + projects) / math.log(2)) +
        communityEvidenceWeight * (math.log(1 + evidence) / math.log(2));
    return math.min(boost, communityCap);
  }

  static Map<String, Map<String, Object?>> _communityByRule() {
    final out = <String, Map<String, Object?>>{};
    for (final r in Community.readCommunityCache()) {
      if (r is! Map) continue;
      final ruleId = r['ruleId'] is String ? r['ruleId'] as String : '';
      if (ruleId.isEmpty) continue;
      final entry = out.putIfAbsent(
          ruleId,
          () => <String, Object?>{
                'projects': 0,
                'evidence': 0,
                'circumstances': <Object?>[],
              });
      final p = _numericInt(r['projects']);
      if (p > (entry['projects'] as int)) entry['projects'] = p;
      entry['evidence'] = (entry['evidence'] as int) + _numericInt(r['evidence']);
      final sev = r['severityBucket'] is String ? r['severityBucket'] as String : '';
      final ct = r['countBucket'] is String ? r['countBucket'] as String : '';
      final desc = _describeCircumstance(sev, ct);
      final circ = entry['circumstances'] as List<Object?>;
      if (!circ.contains(desc)) circ.add(desc);
    }
    return out;
  }

  static int _numericInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String && RegExp(r'^-?\d+$').hasMatch(v.trim())) {
      return int.parse(v.trim());
    }
    return 0;
  }

  static String _describeCircumstance(String sev, String ct) {
    final s = sev.isEmpty ? 'any severity' : '$sev severity';
    final c = ct.isEmpty ? 'any volume' : '$ct occurrences';
    return '$s \u00b7 $c';
  }

  /// Test hook.
  static void resetForTests() {
    _wordDf = null;
  }
}
