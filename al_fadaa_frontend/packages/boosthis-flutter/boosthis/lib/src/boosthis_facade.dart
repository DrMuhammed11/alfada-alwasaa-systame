/// Boosthis — the static facade the thin Flutter adapter drives.
///
/// The `boosthis_flutter` adapter turns Flutter engine callbacks into plain
/// pure-Dart facts and hands them to exactly this surface: `Boosthis.boot(...)`,
/// `Boosthis.run(...)`, and the `record*` entry points. This file is glue only:
/// it MECHANICALLY delegates to the real modules (Kit, FlutterMeters,
/// NavTracker, the observers, Bubble, …) — the meter MATH never lives here.
///
/// GUEST-SAFE (frozen): every method wraps its body in [Safe.run]/[Safe.fire]
/// (async paths in [Safe.runAsync]) and can never throw into the host UI
/// isolate, no matter what garbage a caller passes.
library;

import 'dart:async';

import 'core/build_identity.dart';
import 'core/device_facts.dart';
import 'core/kit.dart';
import 'core/project_identity.dart';
import 'core/runtime_flags.dart';
import 'core/safe.dart';
import 'core/telemetry.dart';
import 'integration/bubble.dart';
import 'integration/instrument.dart';
import 'integration/nav_tracker.dart';
import 'integration/network_sampler.dart';
import 'integration/trace.dart' show Trace;
import 'integration/ai_calls.dart';
import 'integration/ai_providers.dart';
import 'integration/zone_timers.dart';
import 'meters/device_tier.dart';
import 'meters/flutter_meters.dart';
import 'meters/meter_axes.dart';
import 'meters/runtime_vitals.dart';
import 'meters/request_error_timer.dart';
import 'observers/candidate_rules.dart';
import 'observers/cold_start.dart';
import 'observers/cpu_scheduling.dart';
import 'observers/crash_reporter.dart';
import 'observers/dev_posture.dart';
import 'observers/image_weight.dart';
import 'observers/leak_watch.dart';
import 'observers/lifecycle_axes.dart';
import 'observers/memory_meters.dart';
import 'observers/system_load.dart';
import 'observers/platform_channels.dart';
import 'observers/scheduler_latency.dart';
import 'observers/storage_latency.dart';
import 'observers/swallowed_errors.dart';
import 'observers/timer_leaks.dart';
import 'observers/unhandled_errors.dart';
import 'core/snapshot.dart';

/// The static facade. All members are static; state lives in the real modules.
class Boosthis {
  Boosthis._();

  static bool _booted = false;
  static bool _bubbleEnabled = true;

  /// Broadcast stream the bubble subscribes to for repaints. The facade owns
  /// it; a light tick is emitted after each recorded fact so the pill/panel can
  /// re-read [bubbleState]. Never carries data — just a repaint signal.
  static final StreamController<void> _bubbleTicks =
      StreamController<void>.broadcast(sync: false);

  /// A repaint signal stream for the adapter's bubble widget.
  static Stream<void> get bubbleChanges => _bubbleTicks.stream;

  // ── Boot ────────────────────────────────────────────────────────────────

  /// Start the kit from the adapter. [installId] is REQUIRED (Flutter follows
  /// the RN/web/node rule — an id is never auto-generated). [runtime] is the
  /// wire tag ("flutter"); [platform] is the REAL device platform. Idempotent,
  /// guest-safe, never throws.
  static void boot({
    required String installId,
    String runtime = 'flutter',
    String? apiBase,
    String? appName,
    String? inviteKey,
    bool? showBubble,
    String? stateDir,
    String? platform,
    // PRE-CONTACT quiet opt-out (parity with the RN kit's `issuesOnly`): stay
    // on issue signatures only until the server answers. Forwarded UNCHANGED to
    // Kit.start; never a veto once the server speaks. See
    // phone-kit-sharing-posture.md.
    bool? issuesOnly,
    Map<String, Object?>? posture,
    Map<String, Object?>? deviceTier,
    Iterable<Object?>? aiEndpoints,
    String? appOrigin,
  }) {
    Safe.fire(() {
      if (_booted) return;
      _booted = true;

      // Cold-start reference point. The host calls start() from main(), so
      // first-frame minus this instant is a tight LOWER BOUND on the true
      // cold start (it excludes only pre-main engine bring-up).
      markKitStart(DateTime.now().millisecondsSinceEpoch);

      // Host-supplied context first (endpoint + platform + state scope dir).
      // apiBase must land BEFORE Kit.start: the entitlement check fires from
      // inside start(), and an ignored argument would silently talk to the
      // hosted service instead of the endpoint the host asked for.
      if (apiBase != null) RuntimeFlags.setApiBase(apiBase);
      setDeclaredAiEndpoints(aiEndpoints);
      AiCalls.setAppOrigin(appOrigin);
      AiCalls.armObservation();
      Kit.configure(platform: platform, appDocumentsPath: stateDir);

      // Freeze the one-shot dev-posture read from the compile-time facts.
      if (posture != null) {
        Safe.fire(() {
          readDevPosture(
            DevPostureFacts(
              debugMode: posture['debugMode'] == true,
              profileMode: posture['profileMode'] == true,
              debugPaintSizeEnabled: posture['debugPaintSizeEnabled'] == true,
            ),
          );
        });
      }

      // The device tier is CPU-derived inside device_tier from
      // Platform.numberOfProcessors already; the adapter's processor-count hint
      // is accepted for API symmetry but needs no extra wiring here.

      _bubbleEnabled = Bubble.resolveVisibility(showBubble);

      // Install the observer groups that need explicit wiring before they
      // report anything (each is a no-op until wired, so this flips them on).
      Safe.fire(installLifecycleTracking);
      Safe.fire(installSwallowedErrorTracking);
      Safe.fire(installUnhandledErrorTracking);
      Safe.fire(installTimerLeakTracking);
      Safe.fire(installSchedulerLatencyTracking);
      Safe.fire(() => installCrashReporter(detailed: false));

      // Let the Zone timer tracker attribute leaks to the current route.
      ZoneTimers.currentRouteResolver = () => NavTracker.currentRoute;

      _wireAxisContributors();

      // Turn the kit on (entitlement check + uploader ramp run off the hot
      // path inside Kit.start). inviteKey rides as the project key.
      Kit.start(
        installId: installId,
        appName: appName,
        projectKey: inviteKey,
        issuesOnly: issuesOnly,
      );
    });
  }

  /// Wire every meter/observer group's axis into the snapshot builder exactly
  /// once. Each contributor is Safe-wrapped by the snapshot, so a missing or
  /// throwing one is simply absent (fail-open), never a crash.
  static bool _contributorsWired = false;
  static void _wireAxisContributors() {
    if (_contributorsWired) return;
    _contributorsWired = true;

    Snapshot.addAxisContributor((axes, samples) {
      FlutterMeters.addFrameAxes(axes);
    });
    Snapshot.addAxisContributor((axes, samples) {
      RuntimeVitals.addVitals(axes);
    });
    Snapshot.addAxisContributor((axes, samples) {
      _put(axes, 'deviceTier', deviceTierAxis());
      _put(axes, 'imageWeight', readImageWeight());
      _put(axes, 'memoryStability', readMemoryStability());
      final peakRss = readPeakRss();
      if (peakRss != null) axes['peakRss'] = peakRss;
      _put(axes, 'schedulerLatency', readSchedulerLatency());
      final cpuConsumption = readCpuConsumption();
      if (cpuConsumption != null) axes['cpuConsumption'] = cpuConsumption;
      final threadFootprint = readThreadFootprint();
      if (threadFootprint != null) axes['threadFootprint'] = threadFootprint;
      final schedulerClockMs =
          SchedulerLatencyInternals.monotonicElapsedMs;
      final blockingAsync = readBlockingAsync(schedulerClockMs);
      if (blockingAsync != null) axes['blockingAsync'] = blockingAsync;
      _put(axes, 'timerLeaks', readTimerLeaks());
      _put(axes, 'swallowedErrors', readSwallowedErrors());
      _put(axes, 'leakWatch', readLeakWatch());
      _put(
        axes,
        'devPosture',
        readDevPosture(const DevPostureFacts(debugMode: false)),
      );
      _put(axes, 'foregroundResidency', readForegroundResidency());
      _put(axes, 'backgroundRecovery', readBackgroundRecovery());
      _put(axes, 'dimensionChurn', readDimensionChurn());
      _put(axes, 'appearanceChurn', readAppearanceChurn());
      _put(axes, 'memoryWarnings', readMemoryWarnings());
      _put(axes, 'navDeadTime', NavTracker.readNavDeadTime());
      // Pending join counts still have to travel: _put removes null-score
      // axes, which would hide precisely the slow presses this axis explains.
      axes['pressToScreen'] = NavTracker.readPressToScreen();
      final fg = foregroundActiveMs();
      _put(axes, 'unhandledErrors', readUnhandledErrors(fg));
      final upstreamCache = readUpstreamCache();
      if (upstreamCache != null) axes['upstreamCache'] = upstreamCache;
      final routeFailures = readRouteFailures();
      if (routeFailures != null) axes['routeFailures'] = routeFailures;
      axes['timerHealth'] = readTimerHealth();
      axes['backgroundWork'] = readBackgroundWorkUnavailable();
      axes['liveConnections'] = readLiveConnectionsUnavailable();
      axes['uptimeStability'] = readUptimeStabilityUnavailable();
      axes['idle'] = readIdleUnavailable();

      // coldStart / crashFree / storageLatency - the three axes the in-app
      // panel has always listed. Each stays OMITTED until it has honest data
      // (first frame / 5-minute window / 5 probe samples), so a warming tile
      // is a real gate rather than a broken promise.
      _put(axes, 'coldStart', readColdStart());
      _put(axes, 'crashFree', readCrashFree());
      // storageLatency is attached DIRECTLY rather than through _put, for the
      // same reason platformChannels is: when there is no writable state dir
      // the observer returns a self-explaining {present, measurable: 0, reason}
      // object, and _put's honesty gate would drop it - leaving the tile
      // warming forever on a device that can never produce a reading. A null
      // (still collecting samples) is still omitted.
      final storage = readStorageLatency();
      if (storage != null) axes['storageLatency'] = storage;
      // storageFailures — the SAME observation point as storageLatency, kept
      // separate because a slow store and a failing store are different
      // problems (docs/local-store-reading-contract.md). Attached directly for
      // the same reason its sibling is: the no-store case is a self-explaining
      // {present, measurable: 0, reason} object that _put's honesty gate would
      // drop, leaving a tile warming forever on a device with nowhere to write.
      final storageFails = readStorageFailures();
      if (storageFails != null) axes['storageFailures'] = storageFails;
      final systemLoad = readSystemLoad();
      if (systemLoad != null) axes['systemLoad'] = systemLoad;
      final net = NetworkSampler.getStats();
      _put(axes, 'network', computeNetworkScore(_networkStatsFrom(net)));

      // patchLag — mandatory on every kit. Emitted ONLY when the adapter wired
      // a build time (readPatchLag returns null = honest absence otherwise);
      // its scored shape passes _put's honesty gate. Same key/shape/gate as the
      // Ruby & .NET kits.
      _put(axes, 'patchLag', BuildIdentity.readPatchLag());

      // platformChannels — a NEW Flutter axis, OPT-IN. Unlike every other axis
      // it is attached DIRECTLY (never through _put), because the contract
      // requires it to upload even when NOT measurable: a self-explaining
      // {present:true, measurable:0, reason:...} tile beats warming forever.
      axes['platformChannels'] = readPlatformChannels();

      // budget / baseline / frameFloor — the last three axes the port contract
      // and the in-app panel promise. The MATH has always been here and unit
      // tested; nothing ever handed it the live rings, so three tiles warmed
      // forever on every Flutter project. Each still returns null until its own
      // gate is met (20 samples on one route / 6 samples on one route / 3
      // completed 10s frame windows), so _put keeps a genuinely-not-ready tile
      // warming rather than inventing a zero.
      final routes = _routeSeriesFrom(samples);
      _put(axes, 'budget', computeBudget(routes));
      _put(axes, 'baseline', computeBaselineScore(routes));
      _put(
        axes,
        'frameFloor',
        computeFrameFloor(FlutterMeters.frameSpans(), Telemetry.nowMs()),
      );
    });
  }

  /// Group the measurement ring into per-route ordered durations — the shape
  /// the route-based axes consume. The ring is already oldest-first and that
  /// order is preserved per route, which is what lets those axes compare a
  /// route's FIRST samples against its LATEST. Route labels never leave this
  /// method: they are the grouping key and nothing more.
  static List<RouteSeries> _routeSeriesFrom(
    List<Map<String, Object?>> samples,
  ) {
    return Safe.run<List<RouteSeries>>(<RouteSeries>[], () {
      final byRoute = <String, List<int>>{};
      for (final s in samples) {
        final route = s['route'];
        final duration = s['durationMs'];
        if (route is! String || duration is! num) continue;
        (byRoute[route] ??= <int>[]).add(duration.round());
      }
      return byRoute.values.map((d) => RouteSeries(d)).toList();
    });
  }

  /// Add an axis only when it is a real, non-pending map — an absent axis stays
  /// absent (never emitted as a zero), matching the frozen warming contract.
  static void _put(Map<String, Object?> axes, String key, Object? axis) {
    if (axis is! Map) return;
    final m = Map<String, Object?>.from(axis);
    // A pending axis (null score, or an explicit measurable:0 sentinel) is not
    // yet honest data — leave it out entirely.
    if (m['score'] == null &&
        m['measurable'] != 1 &&
        m['tier'] == null &&
        m['rating'] != 'not-scored') {
      return;
    }
    axes[key] = m;
  }

  static NetworkStats _networkStatsFrom(Map<String, Object?> s) {
    int i(Object? v) => v is int ? v : (v is num ? v.round() : 0);
    return NetworkStats(
      attemptCount: i(s['attemptCount']),
      completedCount: i(s['completedCount']),
      failedCount: i(s['failedCount']),
      timeoutCount: i(s['timeoutCount']),
      stallCount: i(s['stallCount']),
      durations: <int>[i(s['p75Ms'])],
      worstMs: i(s['worstMs']),
    );
  }

  // ── Zone runner ───────────────────────────────────────────────────────────

  /// Run the host [body] inside the pure package's counting Zone (timer leaks +
  /// unhandled async errors). Never throws from the kit path; if the runner
  /// itself fails the caller (adapter) still runs [body] directly.
  static void run(void Function() body) {
    ZoneTimers.run<void>(
      body,
      onError: (Object e, StackTrace s) {
        Safe.fire(() {
          noteUnhandledError();
          capture(e, s, crashKindUnhandledRejection);
        });
      },
    );
  }

  // ── Frame pipeline ──────────────────────────────────────────────────────

  /// One engine `FrameTiming`, in microseconds, from the adapter's
  /// `addTimingsCallback` bridge. Guest-safe.
  static void recordFrame({
    required int buildMicros,
    required int rasterMicros,
    required int totalMicros,
    int vsyncOverheadMicros = 0,
  }) {
    Safe.fire(() {
      FlutterMeters.recordFrame(
        FrameSample(
          buildMicros: buildMicros,
          rasterMicros: rasterMicros,
          vsyncOverheadMicros: vsyncOverheadMicros,
          totalSpanMicros: totalMicros,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      // Phone windows advance only while foregrounded. A minute in a pocket is
      // not a minute over which a Dart Timer failed to behave.
      sampleTimerHealth(foregroundActiveMs());
      // A frame is also how a screen ARRIVES. If a route push is still waiting
      // to be drawn, this frame closes it and files the one measurement this
      // kit's unit of work produces — without this line an app wired exactly as
      // the install guide describes registers, uploads snapshots and reports
      // every meter, while never sending a single timing.
      Instrument.screenDrawn();
      _tick();
    });
  }

  /// Cold-start probe: the first frame rasterized. Latched once - later
  /// frames never overwrite it, because the FIRST frame is the cold start.
  static void markFirstFrame() {
    Safe.fire(() {
      markFirstFrameAt(DateTime.now().millisecondsSinceEpoch);
      _tick();
    });
  }

  /// Take one storage-latency probe sample. The pure package never schedules
  /// its own timers, so the adapter calls this on a slow cadence. Async and
  /// guest-safe: the probe swallows its own failures and never reaches the
  /// host, and an unwritable state dir becomes a self-explaining tile rather
  /// than a permanently warming one.
  static void sampleStorageProbe() {
    Safe.fire(() => unawaited(sampleStorage()));
  }

  // ── Errors (monitor-only — the adapter always delegates afterwards) ────────

  /// A `FlutterError.onError` detail. RECORD ONLY; the adapter delegates to the
  /// host's previous handler. Guest-safe.
  static void recordFlutterError({
    String? summary,
    String? library,
    bool silent = false,
    String? stack,
  }) {
    Safe.fire(() {
      noteUnhandledError();
      if (summary != null) noteSwallowedError(summary);
      // The details' own stack, when the adapter has one: without it every
      // framework error redacts to "<unknown>" and all of them collapse into a
      // single signature that names no code.
      capture(summary, _asStack(stack), crashKindUncaught);
      _tick();
    });
  }

  /// A `PlatformDispatcher.onError` pair. RECORD ONLY. Guest-safe.
  static void recordPlatformError({String? error, String? stack}) {
    Safe.fire(() {
      noteUnhandledError();
      capture(error, _asStack(stack), crashKindUnhandledRejection);
      _tick();
    });
  }

  /// Chained `debugPrint` volume for the leak-watch axis. Only the LENGTH ever
  /// reaches the kit — never the message text (PII contract). Guest-safe.
  static void recordLogLine({int length = 0}) {
    Safe.fire(() {
      if (length <= 0) return;
      noteSwallowedError();
    });
  }

  // ── Lifecycle / metrics / brightness ──────────────────────────────────────

  /// A `didChangeAppLifecycleState`. [state] is `AppLifecycleState.name`
  /// ("resumed"/"paused"/"inactive"/"detached"/"hidden"). Guest-safe.
  static void recordLifecycle(String state) {
    Safe.fire(() {
      final active = state == 'resumed';
      noteLifecycleState(active);
      // The same transition, read for a different question: not "was this
      // measurement taken while the app slept?" but "what did the platform
      // let the app DO while it slept?" — the phone's half of the record of
      // what a platform allows. See core/device_facts.dart.
      noteDeviceLifecycle(active);
      if (!active) {
        // The app is going away and may not come back as this process.
        // Nothing is left in flight — the uploader's timer is what stops — but
        // the reporting accumulator's polling-dedupe key is dropped so the
        // first pass after a resume counts as a genuinely new sighting rather
        // than being folded into the last one before the suspend.
        CandidateRules.onSuspend();
      }
      _tick();
    });
  }

  /// A `didChangeMetrics` reading (physical pixels). Counts a dimension churn
  /// event; raw sizes are never retained. Guest-safe.
  static void recordMetrics({
    double widthPx = 0,
    double heightPx = 0,
    double devicePixelRatio = 1.0,
  }) {
    Safe.fire(noteDimensionChange);
  }

  /// A `didChangePlatformBrightness`. Counts an appearance churn event; the
  /// brightness value itself is never retained. Guest-safe.
  static void recordBrightness(String name) {
    Safe.fire(noteAppearanceChange);
  }

  /// A `didHaveMemoryPressure`. Samples the memory meters. Guest-safe.
  static void recordMemoryPressure() {
    Safe.fire(() {
      sampleMemory();
      noteMemoryWarning();
      // The same event, read as a fact about the PLATFORM rather than about
      // this app: an OS that warns before killing gives an app a chance to
      // release memory, and code written for this platform needs to know
      // whether that chance exists. Positive-only — see device_facts.dart.
      noteLowMemoryWarning();
    });
  }

  /// Who made this handset, if the host app already knows (a device-info
  /// plugin, say). Optional and dropped unless it is one of a closed list of
  /// manufacturers: several Android vendors ship their own process killers
  /// and genuinely change whether backgrounded work runs, so a fact observed
  /// on one of them is filed apart from the OS's own behaviour. Guest-safe.
  static void recordDeviceVendor(String? manufacturer) {
    setDeviceVendor(manufacturer);
  }

  /// Which Apple device this is, if the host app already knows.
  ///
  /// `dart:io` reports `ios` for an iPad, and iPadOS is a different platform
  /// with different background rules — an iPad's answer filed under iOS is a
  /// wrong answer rather than an imprecise one. So on Apple hardware this kit
  /// reports nothing at all until the app says which device it is running on;
  /// one call at startup (from `device_info_plus`, say) is what lets an iPhone
  /// or iPad contribute what it observes. `iosMajor` and `androidApi` are
  /// optional overrides for the numbers the kit already reads off the OS's own
  /// version string; pass them only if you have better ones. Guest-safe.
  static void recordDeviceIdentity({
    bool? isPad,
    int? iosMajor,
    int? androidApi,
  }) {
    Safe.fire(() {
      setDeviceIdentity(
        isPad: isPad,
        iosMajor: iosMajor,
        androidApi: androidApi,
      );
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// A route transition from the adapter's NavigatorObserver. Only the
  /// templated route NAME is ever used — never RouteSettings.arguments.
  /// Guest-safe.
  static void recordNav({
    required String action,
    String? route,
    String? previousRoute,
  }) {
    Safe.fire(() {
      final now = Trace.nowMs();
      switch (action) {
        case 'push':
          if (route != null) {
            NavTracker.pushRoute(route, now);
            Instrument.screenMountStarted(route);
          }
          break;
        case 'pop':
        case 'remove':
          NavTracker.popRoute();
          // A route that went away before it was ever drawn is not a screen
          // anyone waited for: forget it rather than charging the next frame
          // with a wait for a screen nobody saw. A route removed from beneath
          // the pending one leaves it alone.
          Instrument.forgetScreenIfPending(route);
          break;
        case 'replace':
          if (route != null) {
            NavTracker.replaceRoute(route, now);
            Instrument.screenMountStarted(route);
          }
          break;
      }
      _tick();
    });
  }

  // ── Re-render profiler ──────────────────────────────────────────────────

  /// A subtree rebuild from `BoosthisProfiler`. [id] is a stable, code-defined
  /// screen label — never user-derived. Guest-safe.
  static void recordReRender({required String id}) {
    Safe.fire(() {
      // reRenders is a display-only axis; a rebuild note doubles as a
      // dimension-free appearance signal for the additive meters.
      // The count is coordinate-free and label-only.
      noteAppearanceChange();
    });
  }

  // ── Outbound network ──────────────────────────────────────────────────────

  /// One outbound request lifecycle from the chained HttpOverrides. Only a
  /// coarse duration + a stalled flag reach the sampler — never the URL, host,
  /// headers, body or status. Guest-safe.
  static void recordOutbound({
    String? host,
    int durationMs = 0,
    bool stalled = false,
  }) {
    Safe.fire(() {
      final d = durationMs.isFinite && durationMs > 0 ? durationMs : 0;
      NetworkSampler.record(
        durationMs: d.toDouble(),
        outcome: stalled ? NetworkOutcome.stall : NetworkOutcome.ok,
      );
      _tick();
    });
  }

  /// Classify one request at the adapter's actual send boundary. The address is
  /// used only by the in-process classifier and is never retained or emitted.
  static AiCallHandle? recordOutboundSent({
    required String host,
    required String method,
    required String path,
  }) {
    return Safe.run<AiCallHandle?>(null, () {
      return AiCalls.sent(host: host, method: method, path: path);
    });
  }

  /// Register the adapter's identity check for its chained HttpOverrides.
  /// The callback and override identity remain in process; only a count can
  /// enter the aiCalls axis.
  static void setHttpOverridesCurrentProbe(bool Function()? probe) {
    Safe.fire(() {
      AiCalls.setHttpOverridesCurrentProbe(probe);
    });
  }

  /// Close the numbers-only AI call handle when the response or error arrives.
  static void recordOutboundFinished(
    AiCallHandle? call, {
    int durationMs = 0,
    bool failed = false,
  }) {
    Safe.fire(() {
      AiCalls.finished(call, durationMs: durationMs, failed: failed);
    });
  }

  /// Record the cache verdict stamped on a reply the app received.
  static void recordUpstreamCacheReply(
    String? Function(String name) readHeader,
  ) {
    Safe.fire(() => noteUpstreamCacheReply(readHeader));
  }

  /// Attribute an outbound completion to the screen active when it was sent.
  static void recordRouteOutboundResult({
    required String? route,
    required bool failed,
  }) {
    Safe.fire(() => noteRouteOutboundResult(route, failed: failed));
  }

  static String? get currentRoute => NavTracker.currentRoute;

  // ── Image cache ──────────────────────────────────────────────────────────

  /// A periodic `PaintingBinding.instance.imageCache` reading for the
  /// imageWeight axis. Guest-safe.
  static void recordImageCache({
    int currentSizeBytes = 0,
    int liveImageCount = 0,
    int currentSize = 0,
    int maximumSizeBytes = 0,
  }) {
    Safe.fire(() {
      recordCacheSample(currentSizeBytes, liveImageCount);
    });
  }

  // ── Bubble ────────────────────────────────────────────────────────────────

  /// The current bubble state the adapter paints: a label, an optional score
  /// string, and the axis tiles. Never throws; returns an empty-ish map on any
  /// failure. The adapter interprets nothing — it renders what is here.
  static Map<String, Object?> bubbleState() {
    // Resolve this before building the display shape so every return path,
    // including Safe.run's fallback, carries the answer the Flutter widget
    // consumes. The resolver independently fail-closes the absolute kill switch.
    final visible = Safe.run<bool>(
      false,
      () => _bubbleEnabled && Bubble.bubbleEnabled(),
    );
    return Safe.run<Map<String, Object?>>(
      <String, Object?>{
        'visible': visible,
        'label': 'Boosthis',
        'project': PROJECT_UNKNOWN_TEXT,
        'score': null,
        'tiles': const <Object?>[],
      },
      () {
        if (!visible) {
          return <String, Object?>{
            'visible': false,
            'label': 'Boosthis',
            'project': PROJECT_UNKNOWN_TEXT,
            'score': null,
            'tiles': const <Object?>[],
          };
        }
        final panel = Bubble.panelShape();
        final scoreVal = panel['score'];
        final rawAxes = panel['axes'];
        final tiles = <Object?>[];
        if (rawAxes is List) {
          for (final row in rawAxes) {
            if (row is! Map) continue;
            final score = row['score'];
            tiles.add(<String, Object?>{
              'key': row['key'],
              'label': row['label'],
              'value': score is num ? score.toString() : null,
              'present': score is num,
            });
          }
        }
        final state = <String, Object?>{
          'visible': true,
          'label': 'Boosthis',
          'project': panel['project'] is String
              ? panel['project']
              : PROJECT_UNKNOWN_TEXT,
          'installId': panel['installId'],
          'score': scoreVal is num ? scoreVal.toString() : null,
          'tiles': tiles,
        };
        // A registered-but-silent (or unregistered, or id-rejected) install must
        // say so in the panel — otherwise a healthy-looking bubble hides a
        // dashboard that stays empty forever. The adapter renders whatever kind
        // is here; the copy is code-defined and carries no server text.
        final notice = panel['notice'];
        if (notice is Map && notice['kind'] is String) {
          state['notice'] = notice['kind'];
          if (notice['reason'] is String) {
            state['uploadFailReason'] = notice['reason'];
          }
          if (notice['lost'] is num) {
            state['uploadsLost'] = notice['lost'];
          }
        }
        // The "Measurements dropped" figure, when there is one. Like the notice,
        // this carries only a count + code-defined cause markers; the adapter
        // maps the markers to its own literal words and shows nothing at all when
        // the key is absent.
        final drops = panel['drops'];
        if (drops is Map && drops['count'] is num) {
          final causes = drops['causes'];
          state['drops'] = <String, Object?>{
            'count': drops['count'],
            'causes': causes is List
                ? causes.whereType<String>().toList()
                : const <String>[],
          };
        }
        return state;
      },
    );
  }

  /// Test seam for exercising the adapter's state-to-widget visibility
  /// contract without booting uploader/background work.
  static void setBubbleOptionForTests(bool? option) {
    _bubbleEnabled = Bubble.resolveVisibility(option);
  }

  // ── Internals ────────────────────────────────────────────────────────────

  static void _tick() {
    Safe.fire(() {
      if (_bubbleTicks.hasListener) _bubbleTicks.add(null);
    });
  }

  static StackTrace? _asStack(String? s) {
    if (s == null || s.isEmpty) return null;
    return StackTrace.fromString(s);
  }
}
