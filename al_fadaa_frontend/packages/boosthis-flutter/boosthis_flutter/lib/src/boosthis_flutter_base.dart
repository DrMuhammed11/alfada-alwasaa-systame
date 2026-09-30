/// BoosthisFlutter — the adapter's start/run surface.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. Imports `package:flutter`; NOT compiled
/// or analysed by this workspace's meter-parity harness (Dart SDK only). See
/// `../../../PORT_CONTRACT.md`.
///
/// This file is a THIN, MECHANICAL binding. It does no meter math. Its whole
/// job is:
///   1. ensure a WidgetsFlutterBinding exists,
///   2. register a frame-timings callback that hands each FrameTiming to the
///      pure package as a FrameSample record,
///   3. chain FlutterError.onError and PlatformDispatcher.onError — RECORD then
///      ALWAYS delegate to the previous handler (monitor-only, never suppress),
///   4. wrap debugPrint (chained) so the pure leak-watch sees log volume,
///   5. add a WidgetsBindingObserver for lifecycle / metrics / brightness,
///   6. read PaintingBinding.instance.imageCache periodically for imageWeight,
///   7. supply compile-time posture facts + the app documents dir for the
///      state scope,
///   8. offer BoosthisFlutter.run(() => runApp(...)) which runs the host inside
///      the pure package's Zone spec (timerLeaks + unhandled async errors).
///
/// EVERY callback body is wrapped in try/catch that can never throw into the
/// host. The pure package additionally guards each entry point with Safe.run;
/// the double guard here is deliberate — a Flutter callback runs outside any
/// error boundary and a throw would reach the host's root.
library;

import 'dart:async';
import 'dart:io' show Directory, Platform;
import 'dart:ui' as ui;

import 'package:boosthis/boosthis.dart' as boosthis;
import 'package:flutter/foundation.dart';
// `debugPaintSizeEnabled` (read once for devPosture) lives in the rendering
// library and is NOT re-exported by widgets.dart — without this import the
// adapter does not compile in a host app.
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The single entry point a Flutter host calls.
///
/// All members are static; there is no state here — state lives in the pure
/// package. This class only installs bindings.
abstract final class BoosthisFlutter {
  BoosthisFlutter._();

  static bool _started = false;
  static WidgetsBindingObserver? _observer;
  static Timer? _imageCacheTimer;
  static Timer? _storageProbeTimer;
  static DebugPrintCallback? _previousDebugPrint;
  static FlutterExceptionHandler? _previousFlutterOnError;
  static ui.ErrorCallback? _previousPlatformOnError;

  /// Start the kit. Safe to call more than once (subsequent calls are no-ops).
  ///
  /// [installId] is REQUIRED — Flutter follows the RN/web/node rule that
  /// telemetry needs an explicit install id and one is never auto-generated.
  /// [apiBase] overrides the endpoint; when null the pure package reads
  /// BOOSTHIS_API_BASE (via --dart-define first, then Platform.environment).
  ///
  /// The whole body is crash-contained: a failure while wiring the kit can
  /// never propagate into the host's `main()`.
  static void start({
    required String installId,
    String? apiBase,
    String? appName,
    String? inviteKey,
    bool? showBubble,
    // PRE-CONTACT quiet opt-out (parity with the RN kit's `issuesOnly`): stay
    // on issue signatures only until the server answers. Forwarded UNCHANGED to
    // Boosthis.boot; never a veto once the server speaks. See
    // phone-kit-sharing-posture.md.
    bool? issuesOnly,
    Iterable<Object?>? aiEndpoints,
    String? appOrigin,
  }) {
    boosthis.StartAnnounce.beginStartAnnouncement();
    try {
      _announceStart(inviteKey, showBubble);
    } finally {
      boosthis.StartAnnounce.flushHeldRefusals();
    }
    if (_started) return;
    _started = true;

    // Nothing below may throw into the host. One outer guard plus per-step
    // guards so a single failed step cannot abort the rest of the wiring.
    try {
      // (1) Ensure the binding exists. Idempotent; returns the live binding.
      WidgetsFlutterBinding.ensureInitialized();

      // (7) Compile-time posture facts + state-scope directory. Hand these to
      // the pure package's boot; it decides the state dir per the contract
      // (BOOSTHIS_STATE_DIR env, else this dir, else a temp dir).
      final String? documentsDir = _documentsDirSafe();

      boosthis.Boosthis.boot(
        installId: installId,
        runtime: 'flutter',
        apiBase: apiBase,
        appName: appName,
        inviteKey: inviteKey,
        showBubble: showBubble,
        issuesOnly: issuesOnly,
        aiEndpoints: aiEndpoints,
        appOrigin: appOrigin,
        stateDir: documentsDir,
        platform: _platformName(),
        posture: <String, Object?>{
          // Frozen one-shot devPosture read — pure package labels them.
          'debugMode': kDebugMode,
          'profileMode': kProfileMode,
          'releaseMode': kReleaseMode,
          'debugPaintSizeEnabled': debugPaintSizeEnabled,
        },
        deviceTier: <String, Object?>{
          'numberOfProcessors': _numberOfProcessorsSafe(),
        },
      );

      // (2) Frame timings — the strongest device signal. Each FrameTiming is
      // forwarded to the pure package as a FrameSample. NO jank math here.
      _installFrameTimingsCallback();

      // (3) Error handlers — record then ALWAYS delegate (monitor-only).
      _installErrorHandlers();

      // (4) debugPrint wrap (chained) for leak watch.
      _installDebugPrintHook();

      // (5) Lifecycle / metrics / brightness observer.
      _installLifecycleObserver();

      // (6) Periodic imageCache read for imageWeight.
      _installImageCacheSampler();

      // Cold start: first-frame callback → kit-start→first-frame span (pure
      // Dart cannot see the launch, so the span is partial and stays unrated).
      _installColdStartProbe();

      _installStorageProbeSampler();
    } catch (err, stack) {
      _swallow('start', err, stack);
    }
  }

  static void _announceStart(String? inviteKey, bool? showBubble) {
    try {
      final key =
          boosthis.ProjectKeyResolver.resolve(code: inviteKey).key;
      final boosthis.BadgeState badge;
      if (boosthis.RuntimeFlags.disabled) {
        badge = boosthis.BadgeState.switchedOff;
      } else if (!boosthis.Bubble.resolveVisibility(showBubble)) {
        badge = boosthis.BadgeState.hiddenBySetting;
      } else {
        badge = boosthis.BadgeState.visible;
      }
      boosthis.StartAnnounce.announceKitStart(key, badge);
    } catch (_) {
      boosthis.StartAnnounce.announceKitStart(
          inviteKey, boosthis.BadgeState.visible);
    }
  }

  /// Run the host app inside the pure package's Zone spec so timer leaks and
  /// unhandled async errors are captured. Delegates the Zone spec creation to
  /// the pure package (no zone math here).
  ///
  ///     BoosthisFlutter.run(() => runApp(const MyApp()));
  static void run(void Function() body) {
    try {
      boosthis.Boosthis.run(body);
    } catch (err, stack) {
      // If the pure package's runner itself failed to install, still run the
      // host body directly so the app boots regardless of the kit.
      _swallow('run', err, stack);
      body();
    }
  }

  // ── (2) Frame timings ────────────────────────────────────────────────────

  static void _installFrameTimingsCallback() {
    try {
      SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        // Callback fires on the engine's cadence, outside any error boundary.
        try {
          for (final FrameTiming t in timings) {
            // Hand raw microsecond durations to the pure package. It decides
            // build-vs-raster attribution, jank buckets and windowing. We only
            // read the FrameTiming fields the engine gives us.
            boosthis.Boosthis.recordFrame(
              buildMicros: t.buildDuration.inMicroseconds,
              rasterMicros: t.rasterDuration.inMicroseconds,
              totalMicros: t.totalSpan.inMicroseconds,
              vsyncOverheadMicros: t.vsyncOverhead.inMicroseconds,
            );
          }
        } catch (err, stack) {
          _swallow('frameTimings', err, stack);
        }
      });
    } catch (err, stack) {
      _swallow('installFrameTimings', err, stack);
    }
  }

  // ── (3) Error handlers — monitor only, always delegate ─────────────────────

  static void _installErrorHandlers() {
    try {
      _previousFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        // Record first, then ALWAYS delegate to the host's previous handler.
        try {
          boosthis.Boosthis.recordFlutterError(
            summary: details.exceptionAsString(),
            library: details.library,
            silent: details.silent,
            stack: details.stack?.toString(),
          );
        } catch (err, stack) {
          _swallow('flutterOnError', err, stack);
        }
        final FlutterExceptionHandler? prev = _previousFlutterOnError;
        if (prev != null) {
          prev(details);
        } else {
          // Preserve default framework behaviour when there was no handler.
          FlutterError.presentError(details);
        }
      };
    } catch (err, stack) {
      _swallow('installFlutterOnError', err, stack);
    }

    try {
      _previousPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        try {
          boosthis.Boosthis.recordPlatformError(
            error: error.toString(),
            stack: stack.toString(),
          );
        } catch (err, s) {
          _swallow('platformOnError', err, s);
        }
        final ui.ErrorCallback? prev = _previousPlatformOnError;
        // Delegate: if the host had a handler, honour its return value; else
        // report as handled=false so the framework's default path still runs.
        if (prev != null) return prev(error, stack);
        return false;
      };
    } catch (err, stack) {
      _swallow('installPlatformOnError', err, stack);
    }
  }

  // ── (4) debugPrint wrap (chained) ──────────────────────────────────────────

  static void _installDebugPrintHook() {
    try {
      _previousDebugPrint = debugPrint;
      final DebugPrintCallback prev = _previousDebugPrint!;
      debugPrint = (String? message, {int? wrapWidth}) {
        // Record log volume for leak watch, then ALWAYS delegate. Never inspect
        // or transmit the message text (it may carry app data — PII contract).
        try {
          boosthis.Boosthis.recordLogLine(length: message?.length ?? 0);
        } catch (err, stack) {
          _swallow('debugPrint', err, stack);
        }
        prev(message, wrapWidth: wrapWidth);
      };
    } catch (err, stack) {
      _swallow('installDebugPrint', err, stack);
    }
  }

  // ── (5) Lifecycle / metrics / brightness observer ──────────────────────────

  static void _installLifecycleObserver() {
    try {
      final _BoosthisLifecycleObserver obs = _BoosthisLifecycleObserver();
      _observer = obs;
      WidgetsBinding.instance.addObserver(obs);
    } catch (err, stack) {
      _swallow('installLifecycleObserver', err, stack);
    }
  }

  // ── (6) imageCache sampler ──────────────────────────────────────────────────

  static void _installImageCacheSampler() {
    try {
      // Read on a slow cadence; the pure package windows/rates it. 5s matches
      // the sibling image-weight cadence — cheap O(1) reads.
      _imageCacheTimer = Timer.periodic(const Duration(seconds: 5), (Timer _) {
        try {
          final ImageCache cache = PaintingBinding.instance.imageCache;
          boosthis.Boosthis.recordImageCache(
            currentSizeBytes: cache.currentSizeBytes,
            liveImageCount: cache.liveImageCount,
            currentSize: cache.currentSize,
            maximumSizeBytes: cache.maximumSizeBytes,
          );
        } catch (err, stack) {
          _swallow('imageCacheSample', err, stack);
        }
      });
    } catch (err, stack) {
      _swallow('installImageCacheSampler', err, stack);
    }
  }

  // ── (7) storage-latency probe ───────────────────────────────────────────────

  static void _installStorageProbeSampler() {
    try {
      // Slow cadence on purpose: each sample is a real write/read/delete round
      // trip in the kit's own state dir. 30s reaches the 5-sample honesty gate
      // in about two and a half minutes while staying far below anything that
      // could show up as IO pressure in the host app.
      _storageProbeTimer =
          Timer.periodic(const Duration(seconds: 30), (Timer _) {
        try {
          boosthis.Boosthis.sampleStorageProbe();
        } catch (err, stack) {
          _swallow('storageProbeSample', err, stack);
        }
      });
    } catch (err, stack) {
      _swallow('installStorageProbeSampler', err, stack);
    }
  }

  // ── Cold start probe ────────────────────────────────────────────────────────

  static void _installColdStartProbe() {
    try {
      // First frame rasterized → real cold-start measurement (better than a
      // JS-bundle proxy). The pure package latches the value; we only mark it.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        try {
          boosthis.Boosthis.markFirstFrame();
        } catch (err, stack) {
          _swallow('markFirstFrame', err, stack);
        }
      });
    } catch (err, stack) {
      _swallow('installColdStartProbe', err, stack);
    }
  }

  // ── Posture / device helpers (guarded dart:io) ──────────────────────────────

  static String? _documentsDirSafe() {
    // The adapter cannot depend on path_provider (that would pull a plugin);
    // instead it hands the pure package a best-effort dir and the pure package
    // applies the BOOSTHIS_STATE_DIR override / temp-dir fallback. Using the
    // current dir is a safe, filesystem-guarded default here.
    try {
      return Directory.current.path;
    } catch (_) {
      return null;
    }
  }

  static String _platformName() {
    // Real device platform — never invent "flutter" as a platform value.
    try {
      if (kIsWeb) return 'web';
    } catch (_) {
      // kIsWeb is a const; guard defensively regardless.
    }
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
      if (Platform.isFuchsia) return 'fuchsia';
    } catch (_) {
      // No dart:io platform (e.g. web) — fall through.
    }
    return 'unknown';
  }

  static int? _numberOfProcessorsSafe() {
    try {
      return Platform.numberOfProcessors;
    } catch (_) {
      return null;
    }
  }

  // ── Crash containment ─────────────────────────────────────────────────────

  static void _swallow(String scope, Object err, StackTrace stack) {
    // Never rethrow into the host. In debug, surface once to the console so a
    // kit bug is visible to the developer; never transmit or persist here.
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrintSynchronously(
        '[boosthis] suppressed error in $scope — Boosthis failed soft so the '
        'host app keeps running: $err',
      );
    }
  }
}

/// Lifecycle / metrics / brightness observer. Every override forwards a plain
/// fact to the pure package and can never throw into the framework.
class _BoosthisLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      boosthis.Boosthis.recordLifecycle(state.name);
    } catch (_) {
      /* never throw into the framework */
    }
  }

  @override
  void didChangeMetrics() {
    try {
      final ui.FlutterView? view =
          WidgetsBinding.instance.platformDispatcher.implicitView;
      if (view != null) {
        final ui.Size size = view.physicalSize;
        boosthis.Boosthis.recordMetrics(
          widthPx: size.width,
          heightPx: size.height,
          devicePixelRatio: view.devicePixelRatio,
        );
      }
    } catch (_) {
      /* never throw into the framework */
    }
  }

  @override
  void didChangePlatformBrightness() {
    try {
      final ui.Brightness b =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      boosthis.Boosthis.recordBrightness(b.name);
    } catch (_) {
      /* never throw into the framework */
    }
  }

  @override
  void didHaveMemoryPressure() {
    try {
      boosthis.Boosthis.recordMemoryPressure();
    } catch (_) {
      /* never throw into the framework */
    }
  }
}
