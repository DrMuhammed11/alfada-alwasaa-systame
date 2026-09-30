import 'dart:async';

import 'device_facts.dart';
import 'drop_report.dart';
import 'kill_switch.dart';
import 'kit_version.dart';
import 'runtime_flags.dart';
import 'safe.dart';
import 'sample_uploader.dart';
import 'snapshot.dart';
import 'telemetry.dart';
import 'transmit.dart';
import '../integration/span_scope.dart';
import '../observers/candidate_rules.dart';
import '../observers/crash_reporter.dart' show kMaxBatch;
import '../observers/live_detectors.dart' show collectDetectorFindings;

/// The outbound side of the screen-bearing channels: perf snapshots (and, when
/// a span source is wired by the observers group, trace spans).
///
/// Everything here runs off the host's frame path and NEVER blocks the UI
/// isolate — the tick is a background [Timer], and every network error is
/// swallowed. Everything here is gated on full telemetry: a project that has
/// not turned sharing on uploads nothing, ever.
///
/// CADENCE (frozen across all kits): a flat 60s steady-state tick, with the
/// first-run turbo ramp 10/20/40/60s applied by [Snapshot.nextSnapshotDelayMs].
/// The uploader wakes on a short fixed interval and asks the cadence whether an
/// upload is due, so the ramp is honoured without a self-adjusting timer that
/// could drift.
class Uploader {
  Uploader._();

  /// Never ship more than this many spans in one call. MUST stay <= the
  /// server's ingest bound (`spans` maxItems = 50): a larger batch is rejected
  /// wholesale with a 400, so raising the emitter's buffer cap without this
  /// would silently stop every waterfall from landing.
  static const int maxSpansPerCall = 50;

  /// How often the background loop wakes to check the cadence. Short enough
  /// that the 10s first-run ramp step is respected, cheap enough to ignore.
  static const int tickIntervalMs = 5000;

  static Timer? _timer;

  /// Span source, wired by the observers group's SpanEmitter. Drains and
  /// returns buffered spans (newest kept); [requeue] puts a failed batch back.
  static List<Map<String, Object?>> Function()? _drainSpans;
  static void Function(List<Map<String, Object?>> spans)? _requeueSpans;

  static void setSpanSource({
    required List<Map<String, Object?>> Function() drain,
    required void Function(List<Map<String, Object?>> spans) requeue,
  }) {
    _drainSpans = drain;
    _requeueSpans = requeue;
  }

  /// Start the background upload loop. Idempotent. Never throws.
  static void start() {
    Safe.fire(() {
      if (_timer != null) return;
      _timer = Timer.periodic(
        const Duration(milliseconds: tickIntervalMs),
        (_) => _tick(),
      );
    });
  }

  static void stop() {
    Safe.fire(() {
      _timer?.cancel();
      _timer = null;
    });
  }

  static void _tick() {
    Safe.fireAsync(() async {
      // This tick was already scheduled, for the uploader's own reasons. Its
      // arrival is the positive half of "do armed timers keep firing in the
      // background?"; the next one's due time is what makes a tick that
      // never arrived tellable from one that was never armed.
      noteTimerFired();
      noteTimerArmed(Telemetry.nowMs() + tickIntervalMs);
      // Lazy re-consent: until the server has minted this install's tokens
      // there is nothing to authenticate an upload with, so every flush tick
      // knocks first (rate-limited to one attempt per hour inside).
      final hadCredentials = Telemetry.hasCredentials;
      final registered = await Telemetry.ensureRegistered();
      if (registered && !hadCredentials && Telemetry.hasCredentials) {
        KillSwitch.chaseFirstActivation();
      }
      await Telemetry.maybeRefreshCoverage();
      // Ordinary heartbeat handoff. checkDue() makes this network-free until
      // the six-hour entitlement cadence is due.
      await KillSwitch.check();
      await flushSpans();
      await flushSnapshotIfDue();
      await flushProblemReports();
    });
  }

  /// Accumulate whatever the live detectors currently see and report anything
  /// that has now recurred often enough to be worth another project knowing
  /// about. Runs on the uploader's background tick, never the frame path.
  ///
  /// Deliberately NOT behind [canUpload]: this channel is always-on for a
  /// registered install (`docs/kit-problem-reporting-contract.md` §5), so it is
  /// gated on the kill switch and the consent answer only — a hashed signature
  /// carries nothing screen-bearing for the detail-share directive to be about.
  /// The accumulator still runs when the gate is shut: an app that registers
  /// later must be able to report a problem it has been watching recur, and
  /// nothing leaves the device until the gate opens.
  static Future<void> flushProblemReports() async {
    await Safe.runAsync<void>(null, () async {
      if (RuntimeFlags.disabled) return;
      final findings = Safe.run<List<Map<String, Object?>>>(
        <Map<String, Object?>>[],
        collectDetectorFindings,
      );
      if (findings.isEmpty) return;
      await CandidateRules.ingest(findings);
    });
  }

  /// Send one batch of recurring-problem signatures. Returns how many rows the
  /// server accepted. Registered as [CandidateRules]' submitter by [Kit.start],
  /// and cleared by `Kit.forget`.
  static Future<int> postCandidates(List<Map<String, Object?>> rows) async {
    return Safe.runAsync<int>(0, () async {
      if (rows.isEmpty) return 0;
      if (!_canReport()) return 0;
      // Lazy consent: knock once, then re-read our own state — an erasure may
      // have landed while the knock was in flight.
      if (Telemetry.deleteToken == null) await Telemetry.ensureRegistered();
      if (!_canReport()) return 0;
      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) return 0;

      final batch = rows.length > CandidateRules.maxPerCall
          ? rows.sublist(0, CandidateRules.maxPerCall)
          : rows;
      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/candidates',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'signatures': batch,
          },
          authToken: token,
          timeoutMs: 5000,
        );
      } catch (_) {
        Telemetry.noteUploadRejected(UploadFailReason.unreachable, 0);
        return 0;
      }
      return _accepted(res, batch.length);
    });
  }

  /// Send one batch of fix outcomes. Same gates, same shape.
  static Future<int> postResolutions(List<Map<String, Object?>> rows) async {
    return Safe.runAsync<int>(0, () async {
      if (rows.isEmpty) return 0;
      if (!_canReport()) return 0;
      if (Telemetry.deleteToken == null) await Telemetry.ensureRegistered();
      if (!_canReport()) return 0;
      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) return 0;

      final batch = rows.length > CandidateRules.maxPerCall
          ? rows.sublist(0, CandidateRules.maxPerCall)
          : rows;
      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/resolutions',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'resolutions': batch,
          },
          authToken: token,
          timeoutMs: 5000,
        );
      } catch (_) {
        Telemetry.noteUploadRejected(UploadFailReason.unreachable, 0);
        return 0;
      }
      return _accepted(res, batch.length);
    });
  }

  /// Send one batch of scrubbed crash fingerprints. Always-on for a registered
  /// app — the same gates as the two problem-reporting channels above, never
  /// the sampling ones. Returns how many reports the server accepted; the
  /// reporter clears its unsent counters for exactly that many. Registered as
  /// the crash reporter's submitter by [Kit.start], cleared by `Kit.forget`.
  static Future<int> postCrashes(List<Map<String, Object?>> rows) async {
    return Safe.runAsync<int>(0, () async {
      if (rows.isEmpty) return 0;
      if (!_canReport()) return 0;
      // Lazy consent: knock once, then re-read our own state — an erasure may
      // have landed while the knock was in flight.
      if (Telemetry.deleteToken == null) await Telemetry.ensureRegistered();
      if (!_canReport()) return 0;
      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) return 0;

      final batch =
          rows.length > kMaxBatch ? rows.sublist(0, kMaxBatch) : rows;
      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/crashes',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'crashes': batch,
          },
          authToken: token,
          timeoutMs: 5000,
        );
      } catch (_) {
        Telemetry.noteUploadRejected(UploadFailReason.unreachable, 0);
        return 0;
      }
      return _accepted(res, batch.length);
    });
  }

  /// Ship one already-drained measurement batch. Refused rows are never
  /// requeued; an unreachable server must not grow memory in a host app.
  static Future<int> postSamples(List<Map<String, Object?>> samples) async {
    return Safe.runAsync<int>(0, () async {
      if (samples.isEmpty || !canUpload()) return 0;
      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) return 0;
      final batch = samples.length > SampleUploader.maxSampleBatch
          ? samples.sublist(0, SampleUploader.maxSampleBatch)
          : samples;
      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/samples',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'samples': batch,
          },
          authToken: token,
          timeoutMs: 5000,
        );
      } catch (_) {
        Telemetry.noteUploadRejected(
          UploadFailReason.unreachable,
          batch.length,
        );
        return 0;
      }
      return _accepted(res, batch.length);
    });
  }

  static int _accepted(TransmitResult res, int rows) {
    final status = res.status;
    if (status >= 200 && status < 300) {
      Telemetry.noteUploadAccepted();
      DropReport.noteServerDrops(res.body);
      return rows;
    }
    Telemetry.noteUploadRejected(_failureReason(status), 0);
    return 0;
  }

  /// Send buffered spans, newest first, when both gates allow.
  static Future<bool> flushSpans() async {
    return Safe.runAsync<bool>(false, () async {
      if (!canUpload()) return false;
      final drain = _drainSpans;
      if (drain == null) return false;

      final spans = drain();
      if (spans.isEmpty) return false;
      return await postSpans(spans) > 0;
    });
  }

  /// Ship ONE batch of already-drained spans. Shared by the uploader tick and
  /// by the emitter's own push path, so there is exactly one place that knows
  /// the /spans wire — and exactly one requeue rule. Returns the number of
  /// spans the server accepted (0 on any failure). Never throws.
  static Future<int> postSpans(List<Map<String, Object?>> spans) async {
    final sent = await Safe.runAsync<int>(0, () async {
      if (spans.isEmpty) return 0;
      var batch = spans;
      if (batch.length > maxSpansPerCall) {
        // Keep the newest; the oldest are the least useful.
        batch = batch.sublist(batch.length - maxSpansPerCall);
      }
      // Rebuild every closed row at the final wire door. Parent identities are
      // adopt-or-drop and optional: malformed/absent values are omitted rather
      // than sent as null or allowed to fabricate causality.
      batch = batch.map(_wireSpan).toList(growable: false);

      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) {
        _requeueSpans?.call(spans);
        return 0;
      }

      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/spans',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'spans': batch,
          },
          authToken: token,
          timeoutMs: 5000,
        );
      } catch (_) {
        Telemetry.noteUploadRejected(
          UploadFailReason.unreachable,
          batch.length,
        );
        _requeueSpans?.call(spans);
        return 0;
      }
      final status = res.status;
      if (status >= 200 && status < 300) {
        Telemetry.noteUploadAccepted();
        // A 202 is not unqualified success: the server may have stored fewer
        // rows than we sent. The reply body is already decoded and in hand, so
        // reading its honesty fields adds no request-path cost and, guarded
        // inside DropReport, can never fail this upload. A reply without the
        // fields reports nothing.
        DropReport.noteServerDrops(res.body);
        return batch.length;
      }
      Telemetry.noteUploadRejected(_failureReason(status), batch.length);

      // A semantic 404 means this install is gone; there is nothing to requeue.
      if (status != 404) _requeueSpans?.call(spans);
      return 0;
    });
    return sent;
  }

  static Map<String, Object?> _wireSpan(Map<String, Object?> span) {
    final row = <String, Object?>{
      'traceId': span['traceId'],
      'layer': span['layer'],
      'routeLabel': span['routeLabel'],
      'durationMs': span['durationMs'],
      'startOffsetMs': span['startOffsetMs'],
      'rating': span['rating'],
    };
    final spanId = SpanScope.sanitizeSpanId(span['spanId']);
    if (spanId != null) row['spanId'] = spanId;
    final parentSpanId = SpanScope.sanitizeSpanId(span['parentSpanId']);
    if (parentSpanId != null) row['parentSpanId'] = parentSpanId;
    return row;
  }

  /// Upload a perf snapshot when the cadence says one is due and there is
  /// something in it. An empty snapshot from a just-installed app is skipped.
  static Future<bool> flushSnapshotIfDue() async {
    return Safe.runAsync<bool>(false, () async {
      if (!canUpload()) return false;
      if (!Snapshot.uploadDue() || !Snapshot.worthUploading()) return false;
      return uploadSnapshot();
    });
  }

  /// Force one snapshot upload regardless of CADENCE — never regardless of the
  /// gates: a project that has not turned sharing on has no force path.
  static Future<bool> uploadSnapshot() async {
    return Safe.runAsync<bool>(false, () async {
      if (!canUpload()) return false;

      final id = Telemetry.installId;
      final token = Telemetry.deleteToken;
      if (id == null || token == null) return false;

      final snapshot = Snapshot.capturePerfSnapshot();
      // This upload is happening anyway. Watching whether the platform lets
      // it FINISH once the app is backgrounded is the whole of the "does
      // pending work run?" observation — nothing is started, delayed or
      // retried to answer it. See device_facts.dart.
      final int work = noteWorkPending();
      late final TransmitResult res;
      try {
        res = await Transmit.safeTransmit(
          '${RuntimeFlags.apiBase}/snapshots',
          <String, Object?>{
            'installId': id,
            'packageVersion': RUNTIME_VERSION,
            'snapshot': snapshot,
          },
          authToken: token,
          timeoutMs: 8000,
        );
      } catch (_) {
        noteWorkSettled(work);
        Telemetry.noteUploadRejected(UploadFailReason.unreachable, 1);
        return false;
      }
      // Settled either way: the question is whether the platform let the work
      // FINISH, not whether the server liked the answer.
      noteWorkSettled(work);
      final status = res.status;
      if (status >= 200 && status < 300) {
        Telemetry.noteUploadAccepted();
        // Stamp the cadence only on a real acceptance, so a failing server does
        // not silently stretch the interval.
        Snapshot.markUploaded();
        // Same honesty read as the /spans path: the body is already in hand, so
        // recording any dropped rows costs nothing and cannot fail the upload.
        DropReport.noteServerDrops(res.body);
        return true;
      }
      Telemetry.noteUploadRejected(_failureReason(status), 1);
      return false;
    });
  }

  /// Both gates, in order: entitlement first, then the sharing switch.
  static bool canUpload() {
    if (RuntimeFlags.disabled) return false;
    if (!KillSwitch.isActive()) return false;
    if (!Telemetry.registered || Telemetry.disconnected) return false;
    return Telemetry.fullTelemetry;
  }

  /// The reporting channel's gates, in the order the contract fixes them: kill
  /// switch, then the consent answer. Registration is what the consent
  /// round-trip mints, so holding the delete token IS the consent answer — and
  /// `forget()` clearing it is what stops reporting for good.
  ///
  /// The detail-share directive is deliberately absent: that gate exists for
  /// screen-bearing data, and a hashed signature carries none.
  static bool _canReport() {
    if (RuntimeFlags.disabled) return false;
    if (!KillSwitch.isActive()) return false;
    if (!Telemetry.registered || Telemetry.disconnected) return false;
    return true;
  }

  static UploadFailReason _failureReason(int status) {
    if (status == 0) return UploadFailReason.unreachable;
    if (status == 401 || status == 403) return UploadFailReason.unauthorized;
    if (status >= 500) return UploadFailReason.serverError;
    return UploadFailReason.rejected;
  }
}
