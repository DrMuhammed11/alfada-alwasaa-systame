import 'dart:async';

import 'build_identity.dart';
import 'activation_notice.dart';
import 'integrity.dart';
import 'kill_switch.dart';
import 'kit_version.dart';
import 'runtime_flags.dart';
import 'project_identity.dart';
import 'safe.dart';
import 'sample_uploader.dart';
import 'samples.dart';
import 'score.dart';
import 'snapshot.dart';
import 'store.dart';
import 'telemetry.dart';
import 'uploader.dart';
import '../integration/span_emitter.dart';
import '../integration/span_scope.dart';
import '../integration/trace.dart';
import '../observers/candidate_rules.dart';
import '../observers/crash_reporter.dart' show flushCrashes, setCrashSubmitter;

/// The public facade of the Flutter kit — the pure-Dart surface the thin
/// `boosthis_flutter` adapter drives, and the only thing a developer touches
/// directly for a manual integration.
///
/// Every method is crash-contained via [Safe]: if any of it fails, the host app
/// carries on exactly as if Boosthis were not installed. Nothing here blocks the
/// UI isolate — registration, entitlement checks and uploads all run off the
/// hot path.
///
/// ONBOARDING CONTRACT: [enable] REQUIRES an `installId` (a UUID). The kit never
/// invents one.
class Kit {
  Kit._();

  /// The runtime tag on the wire.
  static const String runtime = Telemetry.runtime;

  /// The kit's own version.
  static const String version = RUNTIME_VERSION;

  /// Configure host-supplied context BEFORE starting. The adapter calls this
  /// with the device platform ("ios"/"android"/"macos"/"windows"/"web") and the
  /// app's own documents/support directory (used for scope hashing + state).
  /// Optional build metadata powers the patchLag axis.
  static void configure({
    String? platform,
    String? appDocumentsPath,
    int? buildTimeMs,
    String? buildCommit,
    String? kitRoot,
  }) {
    Safe.fire(() {
      if (platform != null) Telemetry.setPlatform(platform);
      if (appDocumentsPath != null) Store.setHostAppPath(appDocumentsPath);
      if (buildTimeMs != null || buildCommit != null) {
        BuildIdentity.setBuildInfo(
          buildTimeMs: buildTimeMs,
          buildCommit: buildCommit,
        );
      }
      if (kitRoot != null) Integrity.setKitRoot(kitRoot);
    });
  }

  /// Turn the kit on and start the background uploader. REQUIRES [installId].
  /// Safe to call more than once — the expensive parts are gated on stored
  /// state. Returns true when the kit is now enabled.
  static bool start({
    required String installId,
    String? appName,
    String? projectKey,
    bool? shareMeterWithAI,
    // PRE-CONTACT quiet opt-out (parity with the RN kit's `issuesOnly`): stay
    // on issue signatures only until the server answers. Never a veto once the
    // server speaks. See phone-kit-sharing-posture.md.
    bool? issuesOnly,
    String? platform,
    String? appDocumentsPath,
  }) {
    return Safe.run<bool>(false, () {
      if (RuntimeFlags.disabled) return false;
      if (platform != null || appDocumentsPath != null) {
        configure(platform: platform, appDocumentsPath: appDocumentsPath);
      }
      final ok = Telemetry.enable(
        installId: installId,
        appName: appName,
        projectKey: projectKey,
        shareMeterWithAI: shareMeterWithAI,
        issuesOnly: issuesOnly,
      );
      if (ok) {
        // Join the two halves of the span channel: the emitter buffers, the
        // uploader ships. Wiring the submitter is ALSO the retention gate —
        // SpanEmitter.record() drops everything while it is null, so a kit
        // that was never started never even holds a span in memory.
        SpanEmitter.setSubmitter(Uploader.postSpans);
        SampleUploader.configure(
          submitter: Uploader.postSamples,
          authorized: Uploader.canUpload,
        );
        Telemetry.setFullTelemetryListener((sharing) {
          SampleUploader.configure(
            submitter: sharing ? Uploader.postSamples : null,
            authorized: Uploader.canUpload,
          );
        });
        Uploader.setSpanSource(
          drain: SpanEmitter.drain,
          requeue: SpanEmitter.requeue,
        );
        // Begin the bounded first-confirmation ladder at launch. A fresh install
        // has no credential yet, so those early steps cost no request; the
        // post-registration edge below restarts an exhausted ladder.
        KillSwitch.chaseFirstActivation();
        // Off the hot path, in order: register with the server (mints this
        // install's tokens — nothing can authenticate an upload without them),
        // then the entitlement check. The uploader will not send anything
        // until that check answers `active`.
        Safe.fireAsync(() async {
          final hadCredentials = Telemetry.hasCredentials;
          final registered = await Telemetry.ensureRegistered(
            projectKey: projectKey,
            explicit: true,
          );
          // Registration can finish after the launch chase has exhausted all
          // five credential-less steps. Restart it the moment a credential is
          // minted so this install does not wait for the ordinary heartbeat.
          if (registered && !hadCredentials && Telemetry.hasCredentials) {
            KillSwitch.chaseFirstActivation();
          }
          await consent();
          KillSwitch.chaseFirstActivation();
        });
        // Problem reporting: the accumulator holds the recurring signatures,
        // the uploader owns the wire. Registered here so a kit that never
        // starts can never send, and cleared by forget(). Idempotent — a
        // second start replaces the same two closures. See
        // docs/kit-problem-reporting-contract.md.
        CandidateRules.setCandidateSubmitter(Uploader.postCandidates);
        CandidateRules.setResolutionSubmitter(Uploader.postResolutions);
        // Crash reports ride the same always-on channel. Without this join the
        // reporter captures, redacts and PERSISTS crashes that nothing ever
        // sends — a file that grows on the device while the project page reads
        // "no crashes". Flush once here as well: the reporter is installed
        // before this line, so its own restore-and-flush found no submitter.
        setCrashSubmitter(Uploader.postCrashes);
        flushCrashes();
        Uploader.start();
      }
      return ok;
    });
  }

  /// Alias kept for onboarding symmetry with the sibling kits' explicit
  /// `enableTelemetry`. Identical behaviour to [start].
  static bool enable({
    required String installId,
    String? appName,
    String? projectKey,
    bool? shareMeterWithAI,
    bool? issuesOnly,
  }) {
    return start(
      installId: installId,
      appName: appName,
      projectKey: projectKey,
      shareMeterWithAI: shareMeterWithAI,
      issuesOnly: issuesOnly,
    );
  }

  /// Run the entitlement check-in (gate 1). Returns the server's status string,
  /// or null when it could not be reached. Never throws.
  static Future<String?> consent({bool force = false}) async {
    return Safe.runAsync<String?>(null, () {
      final integrity = Integrity.status();
      return KillSwitch.check(integrity: integrity, force: force);
    });
  }

  /// Record one completed measurement — the only way the perf axes learn
  /// anything from a manual integration.
  static void trackPerf(String label, num durationMs) {
    Safe.fire(() => Samples.record(label, durationMs));
  }

  /// Is the kit measuring right now? Both gates must be open.
  static bool get enabled => Telemetry.enabled && KillSwitch.isActive();

  /// The picture the kit would upload right now, for local inspection.
  static Map<String, Object?> snapshot() {
    return Safe.run<Map<String, Object?>>(
      <String, Object?>{},
      Snapshot.capturePerfSnapshot,
    );
  }

  /// A plain answer to "is this working?" — the same facts the MCP
  /// connection-status tool reports. Every field is observed, never assumed.
  static Map<String, Object?> status() {
    return Safe.run<Map<String, Object?>>(<String, Object?>{}, () {
      final id = Telemetry.installId;
      return <String, Object?>{
        'runtime': Telemetry.runtime,
        'platform': Telemetry.platform,
        'kitVersion': RUNTIME_VERSION,
        // Already-rendered display text: consumers never invent a fallback.
        'projectDisplay': projectDisplay(getKitProject()),
        'registered': Telemetry.registered,
        'installIdKnown': id != null,
        'hasProjectKey': Telemetry.stored()['projectKey'] != null,
        'projectKey': Telemetry.stored()['projectKey'],
        'projectKeySource': Telemetry.stored()['projectKeySource'],
        'entitlement': KillSwitch.visibleStatus(),
        'fullTelemetry': Telemetry.fullTelemetry,
        'issuesEnabled': Telemetry.issuesEnabled,
        'sampleCount': Samples.count(),
        'storeWritable': Store.writable(),
        'storeBackend': Store.backend(),
        'hasCredentials': Telemetry.hasCredentials,
        'registrationStatus': Telemetry.registrationStatus,
        'inactiveNotice': Telemetry.inactiveNoticeBody,
        'disabledByEnv': RuntimeFlags.disabled,
      };
    });
  }

  /// Rate a single duration against the shared band — a convenience for the
  /// adapter's per-screen tiles. Byte-identical to every sibling edge.
  static String ratingFor(num ms) => Score.getDurationRating(ms);

  /// Erase this install: hand the delete token back to the server and clear
  /// every local file the kit wrote. After this the kit is silent until it is
  /// started again.
  static Future<bool> forget() async {
    return Safe.runAsync<bool>(false, () async {
      Uploader.stop();
      SampleUploader.configure(submitter: null, authorized: Uploader.canUpload);
      Telemetry.setFullTelemetryListener(null);
      ActivationNotice.stop();
      KillSwitch.stopActivationChase();
      // Problem reporting stops FIRST-class: clear the senders so no in-flight
      // pass can still reach the wire, then wipe the recurring signatures and
      // the severity baselines. Nothing Boosthis-shaped is left on the device.
      CandidateRules.setCandidateSubmitter(null);
      CandidateRules.setResolutionSubmitter(null);
      CandidateRules.clearAll();
      setCrashSubmitter(null);
      SpanEmitter.setSubmitter(null);
      SpanEmitter.clear();
      Trace.resetRoots();
      SpanScope.resetForTests();
      return Telemetry.forget();
    });
  }

  /// Send everything pending right now instead of waiting for the cadence.
  static Future<void> flushNow() async {
    await Safe.runAsync<void>(null, () async {
      if (Telemetry.fullTelemetry) {
        await SampleUploader.flush();
        await Uploader.flushSpans();
        await Uploader.uploadSnapshot();
      }
    });
  }
}
