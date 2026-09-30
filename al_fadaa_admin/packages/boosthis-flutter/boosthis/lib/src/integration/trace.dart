// Full-stack trace tag — the Flutter sibling of the RN / Node / Python / Java /
// Go / PHP / Ruby / .NET trace primitives. Byte-for-byte the same contract:
//
//  - header name `x-boosthis-trace`
//  - id format exactly 32 lowercase hex chars, ^[0-9a-f]{32}$
//  - adopt-or-mint sanitize-on-receive: an incoming id is adopted only if it
//    matches the format, otherwise a fresh one is minted (so a caller can never
//    smuggle PII or a header-injection payload through the header)
//  - companion elapsed header `x-boosthis-trace-elapsed`, a bounded
//    non-negative integer chained from each hop's own monotonic delta
//
// Under BOOSTHIS_DISABLED the request wrappers pass straight through and never
// mint or echo a trace id.
//
// PURE DART: `dart:math` only, no Flutter import. A trace id is a CORRELATION
// TAG, not an authenticator, so `Random.secure()` (falling back to the plain
// PRNG when the platform refuses a secure source) is acceptable — a collision
// between two concurrent traces is the only risk, never a security bypass.

import 'dart:math';

import '../core/runtime_flags.dart';
import 'span_scope.dart';

/// Full-stack trace tag primitives. Static-only, mirroring the sibling modules.
class Trace {
  Trace._();

  /// Canonical lowercase header name carried on every instrumented request.
  static const String traceHeader = 'x-boosthis-trace';

  /// A valid trace id is exactly 32 lowercase hex characters (128 bits).
  static final RegExp traceIdRe = RegExp(r'^[0-9a-f]{32}$');

  /// Companion header carrying the relative elapsed-ms offset for the next hop.
  static const String elapsedHeader = 'x-boosthis-trace-elapsed';

  /// A propagated elapsed value is 1-6 digits (0..999999); clamped on receive.
  static final RegExp traceElapsedRe = RegExp(r'^[0-9]{1,6}$');

  /// Upper clamp for a propagated elapsed value (mirrors MAX_SPAN_DURATION_MS).
  static const int maxTraceElapsedMs = 600000;

  static Random? _rng;

  static Random _random() {
    if (_rng != null) return _rng!;
    try {
      _rng = Random.secure();
    } catch (_) {
      _rng = Random();
    }
    return _rng!;
  }

  /// True if the value matches the locked trace-id format exactly.
  static bool isValidTraceId(Object? value) =>
      value is String && traceIdRe.hasMatch(value);

  /// Mint a fresh 32-hex-char trace id (16 random bytes).
  static String newTraceId() {
    final rng = _random();
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      sb.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Adopt-or-mint: return [value] if it is a valid trace id, else mint.
  static String sanitizeTraceId(Object? value) =>
      isValidTraceId(value) ? value as String : newTraceId();

  /// Adopt the incoming trace id from a case-insensitive header map (or mint).
  static String readTraceId(Map<String, Object?>? headers) {
    String? v;
    if (headers != null) {
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == traceHeader) {
          v = entry.value?.toString();
          break;
        }
      }
    }
    return sanitizeTraceId(v);
  }

  /// Sanitize-on-receive for the elapsed chain: bounded int, else 0.
  static int sanitizeTraceElapsed(Object? value) {
    if (value != null && traceElapsedRe.hasMatch(value.toString())) {
      final parsed = int.tryParse(value.toString()) ?? 0;
      return parsed < maxTraceElapsedMs ? parsed : maxTraceElapsedMs;
    }
    return 0;
  }

  /// Build the outbound header map for a request. Pass an existing id to
  /// propagate it (validated first), or omit to mint a fresh trace. A no-op
  /// (empty map) under the kill-switch.
  static Map<String, String> outboundHeaders([String? id]) {
    if (RuntimeFlags.disabled) return <String, String>{};
    final headers = <String, String>{traceHeader: sanitizeTraceId(id)};
    final spanId = SpanScope.currentSpanId();
    if (spanId != null) headers[SpanScope.parentHeader] = spanId;
    return headers;
  }

  /// Milliseconds since epoch (wall clock), matching the sibling now_ms.
  static double nowMs() => DateTime.now().microsecondsSinceEpoch / 1000.0;

  // ---------------------------------------------------------------------
  // Root clock (waterfall offsets)
  //
  // Flutter is a trace ROOT, like RN / Web / Kotlin / Swift and unlike the
  // server kits: nothing upstream hands this process an elapsed base, so the
  // kit OWNS the root clock. The FIRST leg of a trace defines that trace's T0;
  // every later leg on the SAME trace reports `start − T0`. Per trace, never a
  // process-wide epoch — two legs of one action must draw as two
  // distinguishable bars, and a second trace must not inherit the first's age.
  // ---------------------------------------------------------------------

  /// Bounded root-clock table: drop-oldest so a long-lived app cannot grow it.
  static const int _maxTraceRoots = 50;

  /// How many dropped trace ids are remembered, bounded the same way. A screen
  /// firing more parallel actions than the root table holds — or one long
  /// action still open while dozens of quick ones come and go — can push its
  /// OWN trace's T0 out before the next span is recorded. A trace the kit has
  /// FORGOTTEN must not be re-rooted as if it were new: that reports the span
  /// at offset 0, draws it at the left edge of the waterfall, and lets a long
  /// later span out-rank the layer the action really began on and be named the
  /// root — exactly the fault the per-trace clock exists to prevent. So the kit
  /// answers null instead and the caller leaves the span unreported. Past this
  /// many further evictions even that memory is gone.
  static const int _maxForgottenTraces = 50;
  static final Map<String, double> _traceRoots = <String, double>{};
  static final Set<String> _forgottenTraces = <String>{};
  static int _unplaced = 0;

  /// This trace's root instant, registering [now] as T0 the first time the
  /// trace is seen, or null for a trace whose T0 this kit has already dropped.
  /// Mirrors the RN/Web `rootStartFor`.
  static double? rootStartFor(String traceId, double now) {
    final existing = _traceRoots[traceId];
    if (existing != null) return existing;
    if (_forgottenTraces.contains(traceId)) {
      _unplaced += 1;
      return null;
    }
    _traceRoots[traceId] = now;
    while (_traceRoots.length > _maxTraceRoots) {
      final oldest = _traceRoots.keys.first;
      _traceRoots.remove(oldest);
      _forgottenTraces.add(oldest);
      while (_forgottenTraces.length > _maxForgottenTraces) {
        _forgottenTraces.remove(_forgottenTraces.first);
      }
    }
    return now;
  }

  /// Offset from the trace root at which a measurement that STARTED at
  /// [startMs] belongs on the waterfall, or null when this trace's root has
  /// been dropped — the caller then leaves the measurement unreported rather
  /// than placing it at 0. Clamped to `[0, maxTraceElapsedMs]` — a clock that
  /// steps backwards yields 0, not a negative offset, and a very long-running
  /// action saturates at the bound. Sibling of Java `Trace.spanStartOffset` /
  /// Python `span_start_offset`.
  static double? spanStartOffset(String traceId, double startMs) {
    final root = rootStartFor(traceId, startMs);
    if (root == null) return null;
    final offset = startMs - root;
    if (offset.isNaN || offset < 0) return 0.0;
    return offset > maxTraceElapsedMs ? maxTraceElapsedMs.toDouble() : offset;
  }

  /// Drop every root clock (test hook + the `forget()` path).
  static void resetRoots() {
    _traceRoots.clear();
    _forgottenTraces.clear();
    _unplaced = 0;
    SpanScope.resetForTests();
  }

  /// Number of live root clocks — introspection for the bounded-growth test.
  static int rootCount() => _traceRoots.length;

  /// How many measurements this kit refused to place because their trace's
  /// root had been dropped. Introspection for the eviction test, and the count
  /// that keeps the loss from being silent.
  static int unplacedCount() => _unplaced;
}
