// MCP per-tool measurement — the Flutter sibling of the Ruby McpMeasure and the
// Node runtime's mcpMeasure.ts (the canonical cross-runtime source),
// label-for-label with the Java / Go / Python / RN / .NET siblings.
//
// An MCP server is half-visible: the transport times one opaque route, so a
// 40ms tools/list and a 4s tool call look the same. This derives a PER-TOOL
// label so they can be told apart.
//
// CARDINALITY + PII ARE BOUNDED ON PURPOSE. Both the JSON-RPC method and the
// tool name arrive from an UNTRUSTED caller. Methods outside a fixed protocol
// set collapse to mcp.other; tool names outside the developer-registered roster
// collapse to mcp.call.other. Tool ARGUMENTS are never read.
//
// Registering a tool name is developer CODE (not caller input), so mcpTool()
// self-registers its name and registerMcpTools() pre-registers a roster. Both
// are capped and validated.

import '../core/safe.dart';
import '../core/samples.dart';
import '../observers/pii.dart' show transmitLabelHasPii;
import '../integration/trace.dart';

/// MCP per-tool measurement. Static-only.
class McpMeasure {
  McpMeasure._();

  /// Fixed JSON-RPC protocol methods worth timing separately. CLOSED set.
  static const List<String> mcpMethods = <String>[
    'initialize',
    'initialized',
    'ping',
    'tools/list',
    'tools/call',
    'resources/list',
    'resources/read',
    'prompts/list',
    'prompts/get',
    'notifications/initialized',
    'notifications/cancelled',
  ];

  /// Label prefix for tool-call samples; the axis + dashboard group on this.
  static const String mcpCallPrefix = 'mcp.call.';

  /// Suffix marking a FAILED tool call. Closed 2x set.
  static const String mcpErrorSuffix = '.error';

  /// Roster ceiling — even developer code can't mint unbounded labels.
  static const int mcpMaxTools = 64;

  /// Tool names must look like code identifiers: short, no spaces, no PII.
  static final RegExp toolNameRe = RegExp(r'^[A-Za-z0-9_.-]{1,64}$');

  static final Map<String, bool> _registered = <String, bool>{};

  /// Pre-register the MCP tool roster (developer code — a CLOSED set). Invalid
  /// or over-cap names are silently skipped; their calls bucket to
  /// mcp.call.other. A null list is a no-op. Never throws.
  static void registerMcpTools(List<String>? names) {
    Safe.fire(() {
      if (names == null) return;
      for (final n in names) {
        if (_registered.length >= mcpMaxTools) break;
        final ok = _validToolName(n);
        if (ok != null) _registered[ok] = true;
      }
    });
  }

  /// Bounded label for a tool name: registered -> mcp.call.<name>, anything else
  /// -> mcp.call.other. NEVER echoes unregistered caller text.
  static String labelForTool(String? name) {
    final registered = name != null && _registered.containsKey(name);
    if (registered) return '$mcpCallPrefix$name';
    return '${mcpCallPrefix}other';
  }

  /// Derive the bounded sample label for one inbound JSON-RPC message. Returns
  /// null when the value isn't a JSON-RPC-shaped object (so the caller skips
  /// recording). Batch arrays collapse to mcp.batch.
  static String? mcpAutoLabel(Object? msg) {
    if (msg is List) return msg.isEmpty ? null : 'mcp.batch';
    if (msg is! Map) return null;

    final method = msg['method'];
    if (method is! String || method.isEmpty) return null;
    if (!mcpMethods.contains(method)) return 'mcp.other';
    if (method != 'tools/call') {
      return 'mcp.${method.replaceAll('/', '_')}';
    }

    var raw = '';
    final params = msg['params'];
    if (params is Map && params['name'] is String) {
      raw = params['name'] as String;
    }
    return labelForTool(raw);
  }

  /// Record one MCP sample. Failed calls land under a distinct .error label so
  /// per-tool ERROR RATE is visible next to latency. Recording failures are
  /// swallowed (guest-safety).
  static void recordMcpSample(String label, double durationMs, bool isError) {
    Safe.fire(() {
      final name = isError ? '$label$mcpErrorSuffix' : label;
      if (transmitLabelHasPii(name) == null) {
        Samples.record(name, durationMs);
      }
    });
  }

  /// Explicit per-tool wrapper (the stdio path). Wraps a tool handler, self-
  /// registers the name, times the call, and records one MCP sample. A throwing
  /// handler records under <label>.error and RE-THROWS the ORIGINAL error
  /// unchanged. Recording failures are swallowed.
  static Future<T> mcpTool<T>(String name, Future<T> Function() body) async {
    registerMcpTools(<String>[name]);
    final canonical = _validToolName(name);
    final label = labelForTool(canonical);
    final start = Trace.nowMs();
    var failed = false;
    try {
      return await body();
    } catch (_) {
      failed = true;
      rethrow;
    } finally {
      recordMcpSample(label, Trace.nowMs() - start, failed);
    }
  }

  /// Test hook.
  static void resetForTests() {
    _registered.clear();
  }

  /// Validate one developer-supplied tool name. Returns the canonical name or
  /// null when it can't be a label (bad shape / PII-shaped).
  static String? _validToolName(Object? name) {
    if (name is! String) return null;
    final trimmed = name.trim();
    if (!toolNameRe.hasMatch(trimmed)) return null;
    if (transmitLabelHasPii('$mcpCallPrefix$trimmed') != null) return null;
    return trimmed;
  }
}
