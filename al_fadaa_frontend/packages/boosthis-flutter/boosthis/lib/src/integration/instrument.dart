// The measurement API — the one place the host app calls to hand Boosthis a
// beginning and an end for a screen, an interaction, or a traced leg of work.
//
// A device kit has no request/response cycle like the server kits, so the three
// verbs are the RN device analogues: trackScreen (a route/screen came up),
// trackInteraction (a tap/gesture handler ran) and trackSpan (a measured leg of
// work, e.g. an instrumented outbound call). Each wrapper:
//   - is crash-contained via Safe.run / Safe.fire — a throw in the kit can never
//     reach the host, and the host's own body is re-thrown UNCHANGED;
//   - records a PII-guarded, code-defined LABEL only (never a raw path/URL);
//   - times the body with the wall clock and records one Sample;
//   - feeds the additive navigation axes via NavTracker without ever touching
//     the composite speed score.
//
// Spans only move with full telemetry + a wired submitter, mirroring the sibling
// gate in SpanEmitter: nothing span-shaped is retained on a private app.

import '../core/safe.dart';
import '../core/runtime_flags.dart';
import '../core/samples.dart';
import '../core/telemetry.dart';
import 'nav_tracker.dart';
import 'route_inventory.dart';
import 'span_emitter.dart';
import 'span_scope.dart';
import 'trace.dart';

/// The measurement API. Static-only, guest-safe.
class Instrument {
  Instrument._();

  /// How long after a screen starts mounting its next frame may still be read
  /// as that screen arriving. Past this the app was backgrounded, or the route
  /// was abandoned before it ever drew, and the gap is not a measurement of
  /// anything: the wait is dropped rather than filed as a very slow screen.
  static const double screenArrivalCapMs = 10000;

  /// The screen waiting to be drawn, and the instant it started mounting.
  /// A newer push overwrites an older one: frames arrive every few
  /// milliseconds, so a second push before the first drew means the first
  /// screen was never the one the person ended up looking at.
  static String? _mountingScreen;
  static double? _mountingSince;

  /// Note that a screen/route became visible. Called by the adapter's
  /// NavigatorObserver AND available for a manual host call. Records the mount
  /// start (for navDeadTime correlation), pushes the route label, and starts
  /// this screen's arrival timing. Never throws.
  static void trackScreen(String screen) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      final label = RouteInventory.safeScreenName(screen, warnOnRefusal: true);
      if (label == null) return;
      final now = Trace.nowMs();
      NavTracker.pushRoute(label, now);
      screenMountStarted(label);
    });
  }

  /// A screen/route started mounting. Called by the adapter's NavigatorObserver
  /// (through the facade) on push and replace. The next frame the engine draws
  /// closes it and records ONE sample — this kit's unit of work is a screen
  /// arriving, the device sibling of a server kit's request. Never throws.
  static void screenMountStarted(String screen) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      final label = RouteInventory.safeScreenName(screen, warnOnRefusal: true);
      if (label == null) {
        NavTracker.forgetPendingScreenPress();
        return;
      }
      _mountingScreen = label;
      // Its OWN clock read, deliberately NOT the navigation stamp taken a
      // moment earlier. The work in between — naming the route and pushing it
      // onto the stack — is the kit's own, and charging it to the screen's
      // wait made a leftover frame report (one the engine had already
      // finished before the push) look like a real arrival.
      _mountingSince = Trace.nowMs();
    });
  }

  /// A frame report that reaches us sooner than this after a route was pushed
  /// describes a frame that finished BEFORE the push. The engine hands us
  /// COMPLETED frames, in batches, and the fastest display any device runs at
  /// still needs about eight milliseconds to produce one — so a report this
  /// prompt is a leftover, not the new screen. It is skipped and the screen
  /// stays armed, rather than filing a near-zero wait nobody waited.
  static const double staleFrameReportMs = 4;

  /// A gap this long between frame reports means the app STOPPED drawing: an
  /// idle app produces no frames. A screen still waiting when drawing resumes
  /// cannot be measured by the frame that resumed it — whatever drew that
  /// screen happened during the silence, unreported. Such a screen is dropped
  /// rather than charged with the whole idle stretch.
  static const double frameStreamGapMs = 400;

  static double? _lastFrameReport;

  /// The engine reported a finished frame (from the adapter's frame-timing
  /// bridge). If a screen is waiting to be drawn, the first report that could
  /// plausibly BE that screen closes it into one sample and disarms, so the
  /// frames that follow measure nothing. Never throws.
  static void screenDrawn() {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      final now = Trace.nowMs();
      final previousReport = _lastFrameReport;
      _lastFrameReport = now;
      final label = _mountingScreen;
      final since = _mountingSince;
      if (label == null || since == null) return;
      final waited = now - since;
      // Too soon to be this screen's frame: leave it armed for the next report.
      if (waited >= 0 && waited < staleFrameReportMs) return;
      _mountingScreen = null;
      _mountingSince = null;
      if (waited < 0 || waited > screenArrivalCapMs) {
        NavTracker.forgetPendingScreenPress();
        return;
      }
      // The app stopped drawing in between, so this frame is the app waking up,
      // not the screen arriving. Nothing honest can be said about the wait.
      if (previousReport != null &&
          waited > frameStreamGapMs &&
          now - previousReport > frameStreamGapMs) {
        NavTracker.forgetPendingScreenPress();
        return;
      }
      _recordSample(label, waited, false);
      // This same `now` completed the screen's own reading. A second clock
      // read here would make the two readings disagree about when it was ready.
      NavTracker.recordScreenUsable(now);
    });
  }

  /// A route went away. If it is the screen still waiting to be drawn, forget
  /// it: nobody ever saw it, so the next frame must not be charged with its
  /// wait. A different route leaving (Flutter can remove one underneath the
  /// current screen) leaves the pending screen alone. A departure with no name
  /// cannot be told apart, so it forgets — losing a measurement beats
  /// inventing one. Never throws.
  static void forgetScreenIfPending(String? route) {
    Safe.fire(() {
      if (_mountingScreen == null) return;
      if (route != null && route != _mountingScreen) return;
      _mountingScreen = null;
      _mountingSince = null;
      NavTracker.forgetPendingScreenPress();
    });
  }

  /// True while a screen is still waiting for its frame (introspection/tests).
  static bool get hasMountingScreen => _mountingScreen != null;

  /// Forget any half-timed screen (forget() hook + tests). Idempotent.
  static void resetScreenTiming() {
    Safe.fire(() {
      _mountingScreen = null;
      _mountingSince = null;
      NavTracker.forgetPendingScreenPress();
    });
  }

  /// Note that a screen/route went away (adapter didPop). Never throws.
  static void leaveScreen() {
    if (RuntimeFlags.disabled) return;
    Safe.fire(NavTracker.popRoute);
  }

  /// Record a user tap/interaction timestamp so the NEXT screen mount can be
  /// correlated for navDeadTime. Called by the adapter's gesture observer or a
  /// manual host call. Never throws.
  static void trackInteraction() {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() => NavTracker.recordNavTap(Trace.nowMs()));
  }

  /// Time a synchronous [body], record one Sample under [label], and return the
  /// body's value. A throw in [body] is re-thrown UNCHANGED after the sample is
  /// recorded; a throw in the KIT is swallowed. Never blocks; never throws from
  /// the kit path.
  static T measure<T>(String label, T Function() body) {
    if (RuntimeFlags.disabled) return body();
    final start = Trace.nowMs();
    var threw = false;
    try {
      return body();
    } catch (_) {
      threw = true;
      rethrow;
    } finally {
      Safe.fire(() => _recordSample(label, Trace.nowMs() - start, threw));
    }
  }

  /// Time an async [body], record one Sample under [label], and return the
  /// body's value. Same re-throw contract as [measure]. The kit path uses
  /// try/finally so it can never block the UI isolate on IO.
  static Future<T> measureAsync<T>(
    String label,
    Future<T> Function() body,
  ) async {
    if (RuntimeFlags.disabled) return body();
    final start = Trace.nowMs();
    var threw = false;
    try {
      return await body();
    } catch (_) {
      threw = true;
      rethrow;
    } finally {
      Safe.fire(() => _recordSample(label, Trace.nowMs() - start, threw));
    }
  }

  /// Emit one root span for a measured leg of work under [routeLabel] (e.g. an
  /// instrumented outbound call). Spans only move with full telemetry + a wired
  /// submitter. [traceId] adopts-or-mints. Never throws.
  ///
  /// [startOffsetMs] is where this leg sits on the trace's waterfall. Omit it
  /// and the kit derives it: the leg ended now and ran for [durationMs], so it
  /// started [durationMs] ago, measured against THIS TRACE's root clock. Pass
  /// it only for a leg the app timed itself and is placing by hand — a constant
  /// would stack every leg of one action at the left edge.
  ///
  /// A derived offset can come back unknown, when the app had more traces alive
  /// at once than the root table holds and THIS trace's T0 was dropped. The leg
  /// is then left unreported rather than drawn at the left edge, where it could
  /// out-rank the layer the action really began on. See [Trace.unplacedCount].
  static void trackSpan(
    String routeLabel,
    double durationMs, {
    String? traceId,
    double? startOffsetMs,
  }) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      if (!Telemetry.fullTelemetry) return;
      final safeRouteLabel = RouteInventory.safeScreenName(
        routeLabel,
        allowMethodPath: true,
        warnOnRefusal: true,
      );
      if (safeRouteLabel == null) return;
      final id = Trace.sanitizeTraceId(traceId);
      final offset =
          startOffsetMs ??
          Trace.spanStartOffset(
            id,
            Trace.nowMs() - (durationMs > 0 ? durationMs : 0.0),
          );
      // This trace's root was dropped, so there is no honest place for the leg
      // on the waterfall. Every trace-ROOT kit leaves it out rather than
      // reporting 0.
      if (offset == null) return;
      final span = SpanScope.beginSpanInTrace(id);
      SpanEmitter.record(
        id,
        safeRouteLabel,
        durationMs,
        offset,
        span.spanId,
        span.parentSpanId,
      );
    });
  }

  static void _recordSample(String label, double durationMs, bool threw) {
    final safe = RouteInventory.safeScreenName(label, warnOnRefusal: true);
    if (safe == null) return;
    final d = durationMs < 0 ? 0.0 : durationMs;
    Samples.record(safe, d);
  }
}
