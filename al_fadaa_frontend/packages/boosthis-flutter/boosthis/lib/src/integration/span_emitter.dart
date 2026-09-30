// Full-stack trace — span emission (Flutter root layer).
//
// The trace primitives (see `trace.dart`) only PROPAGATE a 32-hex correlation
// id. This lets the Flutter layer emit ONE privacy-safe root span per
// instrumented outbound request so the server can stitch a waterfall
// (flutter -> node -> py) keyed by that id.
//
// A span is a closed six-key wire map, byte-identical to every sibling kit's
// span (SpanEmitter.record / spanEmitter.ts):
//   { traceId, layer:"flutter", routeLabel, durationMs, startOffsetMs, rating }
//
// THE WIRE RULE: a span is always rebuilt as a CLOSED six-key map, never spread
// from an internal object, so a new internal field can never leak onto the
// wire by accident.
//
// PRIVACY-BY-DEFAULT: `enqueueSpan` is a no-op until a submitter is wired. The
// telemetry client only wires the span submitter when the snapshot mirror is
// allowed (full mode, or issues-only after the developer connects an AI), so a
// private app RETAINS nothing span-shaped until sharing is authorized. The
// kill-switch (`BOOSTHIS_DISABLED`) and forget() both stop and clear it.
//
// Everything here is best-effort: span bookkeeping must NEVER change the host
// request's behaviour or crash the app.

import '../core/safe.dart';
import '../core/runtime_flags.dart';
import '../core/score.dart';
import '../observers/pii.dart' show transmitLabelHasPii;
import 'span_scope.dart';
import 'span_work.dart';
import 'trace.dart';
import 'route_inventory.dart';

/// Ships a batch of buffered spans, returning how many were accepted.
typedef SpanSubmitter = Future<int> Function(List<Map<String, Object?>> spans);

/// Full-stack span buffer + emitter for the Flutter root layer.
class SpanEmitter {
  SpanEmitter._();

  /// This kit's layer tag on the wire.
  static const String layer = 'flutter';

  /// The canonical label for an outbound call's root span: `METHOD /outbound`.
  ///
  /// Defined HERE rather than in the adapter so the one word that travels is
  /// code-defined in the package that owns the wire shape. The server reads a
  /// span label as a structural "METHOD /path" or refuses the row outright, so
  /// a bare verb ("GET outbound") is thrown away on arrival — which is exactly
  /// how Flutter traces went missing before 0.1.44. A verb outside the closed
  /// HTTP set does not fit that shape, so its span is dropped on the device by
  /// the screen in [record] rather than uploaded to be refused.
  ///
  /// The path is a CONSTANT: a span never carries a real URL, host or query
  /// string. The host of an outbound call travels on its own sample instead.
  static String outboundLabel(String method) =>
      '${method.trim().toUpperCase()} /outbound';

  /// Server accepts at most 50 spans per batch — the per-call batch cap MUST
  /// stay <= the server maxItems of 50.
  static const int maxSpanBatch = 50;

  /// Hard cap on the in-memory buffer (drop-oldest on overflow) so a burst of
  /// requests between flushes can never grow memory without bound.
  static const int maxBufferedSpans = 50;

  /// `routeLabel` server cap.
  static const int maxSpanRouteLabel = 100;

  /// Duration hard clamp (matches the server `durationMs` 0..600000 bound).
  static const int maxSpanDurationMs = 600000;

  static SpanSubmitter? _submitter;
  static final List<Map<String, Object?>> _buffer = <Map<String, Object?>>[];
  static bool _inFlight = false;

  /// Wire (or clear) the transport that ships buffered spans. Clearing it makes
  /// `enqueueSpan` inert immediately — the privacy-by-default gate.
  static void setSubmitter(SpanSubmitter? fn) {
    _submitter = fn;
  }

  /// True when a submitter is wired (sharing authorized).
  static bool get hasSubmitter => _submitter != null;

  /// Current buffer length (introspection/tests).
  static int get bufferLength => _buffer.length;

  /// The closed 6-key wire map — never more, never fewer.
  static Map<String, Object?> buildWireSpan(
    String traceId,
    String routeLabel,
    int durationMs,
    int startOffsetMs,
    String rating, {
    Object? spanId,
    Object? parentSpanId,
    Object? kind,
    Object? outcome,
  }) {
    final row = <String, Object?>{
      'traceId': traceId,
      'layer': layer,
      'routeLabel': routeLabel,
      'durationMs': durationMs,
      'startOffsetMs': startOffsetMs,
      'rating': rating,
    };
    final own = SpanScope.sanitizeSpanId(spanId);
    if (own != null) row['spanId'] = own;
    final parent = SpanScope.sanitizeSpanId(parentSpanId);
    if (parent != null) row['parentSpanId'] = parent;
    // Optional facts are sanitized here and ADDED ONLY WHEN PRESENT. An
    // unknown value is dropped rather than making the whole batch unsendable,
    // and silence keeps the exact wire shape this kit sent before.
    final workKind = sanitizeWorkKind(kind);
    if (workKind != null) row['kind'] = workKind;
    final workOutcome = sanitizeOutcome(outcome);
    if (workOutcome != null) row['outcome'] = workOutcome;
    return row;
  }

  /// Return a route label accepted by the shared part-name rule.
  static String? spanLabel(String routeLabel) =>
      RouteInventory.safeScreenName(routeLabel, allowMethodPath: true);

  /// Record one root span. Silently drops anything failing the route-label
  /// guard. No-op unless a submitter is wired and the kill-switch is off, so
  /// nothing span-shaped is even RETAINED on a private app.
  static void record(
    String traceId,
    String routeLabel,
    double durationMs, [
    double startOffsetMs = 0.0,
    Object? spanId,
    Object? parentSpanId,
    Object? kind,
    Object? outcome,
  ]) {
    if (_submitter == null || RuntimeFlags.disabled) return;
    Safe.fire(() {
      if (!Trace.isValidTraceId(traceId)) return;
      // The route label is the ONE free-text field on a span, so it is screened
      // here — the last point this kit controls — exactly as every sibling kit
      // does (inside record() in php/ruby/dotnet/rust/elixir, in the transmit
      // filter in node/web/rn/swift, in the middleware in go).
      // transmitLabelHasPii allows the structural "METHOD /path" space that
      // spanLabel() produces and blocks every other whitespace-bearing or
      // PII-shaped label. Screened BEFORE the cap, so a truncated label cannot
      // hide the tail of a UUID from the check.
      //
      // Without this the server refuses the row on ITS label screen: the span
      // is counted as dropped and never stored, which reads on the dashboard
      // as a trace that simply never arrived.
      final label = spanLabel(routeLabel);
      if (label == null || transmitLabelHasPii(label) != null) return;

      final duration = _clampMs(durationMs);
      final offset = _clampMs(startOffsetMs);
      _buffer.add(
        buildWireSpan(
          traceId,
          label,
          duration,
          offset,
          Score.getDurationRating(duration.toDouble()),
          spanId: spanId,
          parentSpanId: parentSpanId,
          kind: kind,
          outcome: outcome,
        ),
      );
      while (_buffer.length > maxBufferedSpans) {
        _buffer.removeAt(0);
      }
    });
  }

  static int _clampMs(double v) {
    var d = v.isFinite ? v.round() : 0;
    if (d < 0) d = 0;
    if (d > maxSpanDurationMs) d = maxSpanDurationMs;
    return d;
  }

  /// Hand up to one batch to the wired submitter and clear it from the buffer.
  /// Guarded against re-entrancy + the kill-switch; swallows any transport
  /// error (returns 0). Never throws into the host.
  static Future<int> flush() async {
    final submitter = _submitter;
    if (submitter == null ||
        RuntimeFlags.disabled ||
        _inFlight ||
        _buffer.isEmpty) {
      return 0;
    }
    _inFlight = true;
    final take = _buffer.length < maxSpanBatch ? _buffer.length : maxSpanBatch;
    final batch = _buffer.sublist(0, take);
    _buffer.removeRange(0, take);
    try {
      return await submitter(batch);
    } catch (_) {
      return 0;
    } finally {
      _inFlight = false;
    }
  }

  /// Remove and return the buffered spans (oldest first) — the PULL side used
  /// by the uploader tick, mirroring Ruby `SpanEmitter.drain`. The buffer is
  /// emptied in one step so a second flush in the same tick cannot ship the
  /// same span twice; a failed batch comes back through [requeue].
  static List<Map<String, Object?>> drain() {
    if (_buffer.isEmpty) return const <Map<String, Object?>>[];
    final batch = List<Map<String, Object?>>.from(_buffer);
    _buffer.clear();
    return batch;
  }

  /// Put a failed batch back at the FRONT (it is older than anything recorded
  /// since), then re-apply the overflow cap so a permanently failing upload can
  /// never grow memory without bound.
  static void requeue(List<Map<String, Object?>> spans) {
    if (spans.isEmpty) return;
    Safe.fire(() {
      _buffer.insertAll(0, spans);
      while (_buffer.length > maxBufferedSpans) {
        _buffer.removeAt(0);
      }
    });
  }

  /// Snapshot copy of the buffer (introspection/tests).
  static List<Map<String, Object?>> buffered() =>
      List<Map<String, Object?>>.from(_buffer);

  /// Drop the in-memory span buffer (called by forget()).
  static void clear() {
    _buffer.clear();
  }

  /// Full reset (tests): drop buffer + submitter.
  static void resetForTests() {
    _submitter = null;
    _buffer.clear();
    _inFlight = false;
  }
}
