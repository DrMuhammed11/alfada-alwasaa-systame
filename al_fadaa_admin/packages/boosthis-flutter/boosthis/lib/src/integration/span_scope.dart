// Active-span scope — the half of full-stack causality that answers which call
// is open right now.
//
// A trace id correlates hops into one user action; it cannot say which hop
// caused which. `spanId` is this call's own identity and `parentSpanId` is the
// call that caused it.
//
// ADOPT-OR-DROP, never adopt-or-mint. A bad trace id may safely start a new
// trace, but minting a replacement parent would fabricate a call that never
// existed. A malformed or missing parent is therefore absent.
//
// CONCURRENCY HONESTY. The ambient scope is synchronous only. `runInSpan`
// closes its frame when the callback returns, including when that return value
// is a Future. Holding a process-wide scope across an await could falsely make
// two concurrent calls parent and child. A wrong parent is worse than no
// parent: a flat trace is visibly flat, while a wrong tree reads as truth.
//
// PRIVACY CONTRACT: a span id is exactly 16 lowercase hex characters. Pure hex
// cannot match the PII guard's value patterns, and `spanId`, `parentSpanId`, and
// `x-boosthis-trace-parent` tokenize cleanly. The id is random, ephemeral, and
// never derived from user data.
//
// Like a trace id, a span id must NEVER appear in a route or screen label.

import 'dart:math';

/// One call's identity and the identity of the call that caused it.
class SpanHandle {
  const SpanHandle({
    required this.spanId,
    required this.parentSpanId,
    this.traceId,
  });

  final String spanId;
  final String? parentSpanId;
  final String? traceId;
}

class _SpanFrame {
  const _SpanFrame(this.spanId, this.traceId);

  final String spanId;
  final String? traceId;
}

/// The action a call belongs to and the leg of it that is open.
class ActionContext {
  const ActionContext({required this.traceId, required this.spanId});

  final String traceId;
  final String spanId;
}

const Object _ambientParent = Object();

/// Static active-span primitives, matching the Flutter kit's [Trace] idiom.
class SpanScope {
  SpanScope._();

  /// Companion header carrying the caller's span id to the next hop.
  static const String parentHeader = 'x-boosthis-trace-parent';

  /// A valid span id is exactly 16 lowercase hex characters (64 random bits).
  static final RegExp spanIdRe = RegExp(r'^[0-9a-f]{16}$');
  static final RegExp _traceIdRe = RegExp(r'^[0-9a-f]{32}$');

  /// The ambient scope silently stops deepening past this bound.
  static const int maxActiveSpans = 32;

  static final List<_SpanFrame> _active = <_SpanFrame>[];
  static Random? _rng;

  static Random _random() {
    if (_rng != null) return _rng!;
    try {
      _rng = Random.secure();
    } catch (_) {
      // This is a correlation tag, not an authenticator. The same fallback as
      // Trace is acceptable: weaker randomness only risks a local collision.
      _rng = Random();
    }
    return _rng!;
  }

  static bool isValidSpanId(Object? value) =>
      value is String && spanIdRe.hasMatch(value);

  /// Mint eight random bytes rendered as 16 lowercase hexadecimal characters.
  static String newSpanId() {
    final rng = _random();
    final out = StringBuffer();
    for (var i = 0; i < 8; i++) {
      out.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  /// Adopt a valid identity unchanged; drop every other value.
  static String? sanitizeSpanId(Object? value) =>
      isValidSpanId(value) ? value as String : null;

  /// Normalize a raw header (an Iterable uses its first value), then adopt/drop.
  static String? adoptParentSpanId(Object? headerValue) {
    try {
      final raw = headerValue is Iterable
          ? (headerValue.isEmpty ? null : headerValue.first)
          : headerValue;
      return sanitizeSpanId(raw);
    } catch (_) {
      return null;
    }
  }

  static String? currentSpanId() =>
      _active.isEmpty ? null : _active.last.spanId;

  /// The innermost open call that knows which ACTION it belongs to, or null.
  ///
  /// The scope is synchronous by design, so work resumed after an await usually
  /// has no frame. Naming an action then would mean guessing; absence honestly
  /// reads as "no action recorded".
  static ActionContext? currentAction() {
    for (var i = _active.length - 1; i >= 0; i--) {
      final frame = _active[i];
      if (frame.traceId != null) {
        return ActionContext(traceId: frame.traceId!, spanId: frame.spanId);
      }
    }
    return null;
  }

  /// Mint a span. Omit [parentSpanId] to use the ambient caller; explicitly pass
  /// null to make a root. [traceId] is retained only when it has the locked
  /// 32-hex action shape. Merely beginning a span does not make it ambient.
  static SpanHandle beginSpan([
    Object? parentSpanId = _ambientParent,
    Object? traceId,
  ]) {
    final parent = identical(parentSpanId, _ambientParent)
        ? currentSpanId()
        : sanitizeSpanId(parentSpanId);
    final action = traceId is String && _traceIdRe.hasMatch(traceId)
        ? traceId
        : null;
    return SpanHandle(
      spanId: newSpanId(),
      parentSpanId: parent,
      traceId: action,
    );
  }

  /// Mint a span in [traceId] while preserving the ambient caller.
  static SpanHandle beginSpanInTrace(Object? traceId) =>
      beginSpan(_ambientParent, traceId);

  /// Run [fn] in a synchronous scope and remove this frame by identity.
  static T runInSpan<T>(SpanHandle span, T Function() fn) {
    _SpanFrame? frame;
    if (_active.length < maxActiveSpans) {
      frame = _SpanFrame(span.spanId, span.traceId);
      _active.add(frame);
    }
    try {
      return fn();
    } finally {
      if (frame != null) {
        _active.removeWhere((candidate) => identical(candidate, frame));
      }
    }
  }

  /// Test seam: number of currently active synchronous frames.
  static int activeCount() => _active.length;

  /// Test seam: clear every active frame.
  static void resetForTests() => _active.clear();
}
