// The in-app Boosthis bubble — the Flutter port of the sibling kits' bubble
// (PHP / Java / Node / Go / Python / Ruby / .NET / web). DASHBOARD-FIRST: the
// panel opens straight onto the hero score, rating pill and meter rows, pixel-
// parity with the other kits' bubble and the web dashboard — dark theme, orange
// #f97316 primary.
//
// PURE DART, no Flutter import. On a device kit there is no HTML response to
// splice a <script> into, so this file is the pure-Dart STATE + THEME builder:
// it produces the pulse trio, the dashboard-first panel shape (hero + ordered
// meter rows), the server-authority lock overlay, and the frozen theme palette.
// The WIDGET that renders this shape into a floating badge + panel lives in the
// adapter (boosthis_flutter) — a meter's math never lives in the adapter.
//
// Privacy: display-only. The shapes carry ONLY the closed pulse/panel data
// ({score, rating, sampleCount} + the closed meter rows) and never a screen
// label beyond the code-defined axis keys, never a URL, never raw samples.

import '../core/drop_report.dart';
import '../core/safe.dart';
import '../core/samples.dart';
import '../core/score.dart';
import '../core/thresholds.dart';
import '../core/runtime_flags.dart';
import '../core/kill_switch.dart';
import '../core/snapshot.dart';
import '../core/json.dart';
import '../core/project_identity.dart';
import '../core/registration.dart';
import '../core/telemetry.dart';

/// The frozen dark-theme palette — byte-identical to the sibling bubbles' `T`
/// object (orange #f97316 primary), so the Flutter widget paints pixel-parity
/// with the web dashboard and every other kit's bubble.
class BubbleTheme {
  BubbleTheme._();

  static const String bg = '#0b0c10';
  static const String card = '#15171c';
  static const String border = '#262932';
  static const String fg = '#e6e7eb';
  static const String muted = '#8b8f99';
  static const String primary = '#f97316';

  /// Rating colours, byte-identical to the sibling `COLORS` map.
  static const String colorGood = '#4ade80';
  static const String colorNeedsWork = '#fbbf24';
  static const String colorPoor = '#f87171';

  /// Colour for a rating string (good/needs-work/poor), else the muted colour.
  static String colorFor(String? rating) {
    switch (rating) {
      case 'good':
        return colorGood;
      case 'needs-work':
        return colorNeedsWork;
      case 'poor':
        return colorPoor;
      default:
        return muted;
    }
  }
}

/// The in-app bubble — pure-Dart state + theme builder. Static-only.
class Bubble {
  Bubble._();

  static bool Function()? _disabledReaderForTests;
  static bool? Function()? _directiveReaderForTests;

  /// The accepted-terms revision the bubble's first-open gate records/checks.
  /// Byte-equal to the canonical TERMS_VERSION constants in the sibling kits.
  static const String termsVersion = '2026-07-21';

  /// Caption shown on an expected-but-not-yet-measurable axis row.
  static const String panelWarmingCaption = 'warming up';

  // ─── Visibility ────────────────────────────────────────────────────────────

  /// Resolve whether the bubble should be shown (precedence: kill-switch,
  /// BOOSTHIS_BUBBLE, legacy aliases, explicit option, default TRUE). The
  /// default applies in every build mode, including release. Never throws.
  static bool resolveVisibility([bool? option]) {
    // The absolute kill switch fails closed on its own. No later fallback may
    // defeat an entitlement stop merely because reading the flag threw.
    final disabled = Safe.run<bool>(
      true,
      () => (_disabledReaderForTests ?? () => RuntimeFlags.disabled)(),
    );
    if (disabled) return false;

    // Every non-kill-switch failure fails open to the documented visible
    // default. A malformed host environment must not silently remove the UI.
    return Safe.run<bool>(true, () {
      final directive =
          (_directiveReaderForTests ?? () => RuntimeFlags.bubble)();
      if (directive != null) return directive;
      if (RuntimeFlags.noBubble) return false;
      if (RuntimeFlags.forceBubble) return true;
      if (option != null) return option;
      return true;
    });
  }

  /// Inject visibility readers for crash-safety tests only.
  static void setVisibilityReadersForTests({
    bool Function()? disabled,
    bool? Function()? directive,
  }) {
    _disabledReaderForTests = disabled;
    _directiveReaderForTests = directive;
  }

  /// Restore production visibility readers after a test.
  static void resetVisibilityReadersForTests() {
    _disabledReaderForTests = null;
    _directiveReaderForTests = null;
  }

  /// Whether the bubble is enabled for this app: visible, and the kill-switch is
  /// not silently "hidden". Never throws.
  static bool bubbleEnabled([bool? option]) {
    return Safe.run<bool>(false, () {
      if (!resolveVisibility(option)) return false;
      return KillSwitch.visibleStatus() != KillSwitch.hidden;
    });
  }

  // ─── Pulse / percentile ──────────────────────────────────────────────────

  /// The closed pulse shape — one score, one rating, one count. Maps the p95
  /// duration onto 0-100 against the shared TTI band. score/rating are null
  /// until at least one sample exists.
  static Map<String, Object?> pulseShape() {
    var durs = Safe.run<List<int>>(<int>[], Samples.durations);
    final n = durs.length;
    if (n == 0) {
      return <String, Object?>{'score': null, 'rating': null, 'sampleCount': 0};
    }
    final p95 = _percentile(durs, 0.95);
    final score = Score.scoreMetric(
      p95.toDouble(),
      Thresholds.kTtiGood,
      Thresholds.kTtiPoor,
    );
    return <String, Object?>{
      'score': score,
      'rating': Score.getRating(score),
      'sampleCount': n,
    };
  }

  /// The closed pulse JSON string (lock-only when locked). Never throws.
  static String pulseJson() {
    final lock = computePanelLock();
    final shape = lock == null ? pulseShape() : <String, Object?>{'lock': lock};
    return Json.encode(shape) ?? '{"score":null,"rating":null,"sampleCount":0}';
  }

  // ─── Server-authority lock overlay (owner UX) ────────────────────────────

  /// The blocking-lock descriptor served to the panel, or null when access is
  /// active/within-grace. Fails OPEN (null) so a bug here can never brick a
  /// paying app.
  static Map<String, String>? computePanelLock() {
    return Safe.run<Map<String, String>?>(null, () {
      final status = KillSwitch.visibleStatus();
      if (status == KillSwitch.active) return null;
      // Never checked in is NOT a lock: no overlay, so the ordinary panel
      // renders and computePanelNotice()'s "Not registered yet" is what the
      // developer reads. This must sit ABOVE the catch-all at the bottom, which
      // would otherwise blank the whole bubble.
      if (status == KillSwitch.unregistered) return null;

      if (status == KillSwitch.hidden || status == KillSwitch.tampered) {
        return <String, String>{'kind': 'hidden', 'title': '', 'body': ''};
      }
      final detail = KillSwitch.message();
      if (status == KillSwitch.revoked) {
        return <String, String>{
          'kind': 'revoked',
          'title': 'Access revoked',
          'body':
              "This project's Boosthis access was revoked by the account "
              'owner. Contact the owner if you think this is a mistake.',
        };
      }
      if (status == KillSwitch.unpaid) {
        return <String, String>{
          'kind': 'unpaid',
          'title': 'Payment required',
          'body':
              'The Boosthis subscription for this account is unpaid. Ask '
              'the account owner to renew it at boosthis.com to restore access.',
        };
      }
      if (status == KillSwitch.paused) {
        return <String, String>{
          'kind': 'paused',
          'title': 'Boosthis is paused',
          'body': (detail != null && detail.isNotEmpty)
              ? detail
              : 'The owner has paused this app from the Boosthis dashboard. '
                    'Nothing was deleted — press Reconnect there to resume.',
        };
      }
      return <String, String>{'kind': 'hidden', 'title': '', 'body': ''};
    });
  }

  // ─── Panel meter labels + expected axis sets ─────────────────────────────

  /// Display order + labels for the panel's meter rows. Keys/labels track the
  /// snapshot's axis builder and stay byte-identical to the web dashboard's
  /// AXIS_LABELS.
  static Map<String, String> panelAxisLabels() => const <String, String>{
    'responsiveness': 'Responsiveness',
    'resilience': 'Resilience',
    'confidence': 'Confidence',
    'budget': 'On budget',
    'smoothness': 'Smoothness',
    'stability': 'Stability',
    'scroll': 'Scroll',
    'frameFloor': 'Frame floor',
    'frozenFrames': 'Frozen frames',
    'appHang': 'App hang',
    'rasterJank': 'Raster jank',
    'reRenders': 'Rebuilds',
    'imageWeight': 'Image weight',
    'network': 'Network',
    'upstreamCache': 'Upstream cache',
    'routeFailures': 'Route failures',
    'timerHealth': 'Timer health',
    'backgroundWork': 'Background work',
    'liveConnections': 'Live connections',
    'uptimeStability': 'Uptime stability',
    'idle': 'Idle',
    'baseline': 'Baseline',
    'navDeadTime': 'Nav dead time',
    'pressToScreen': 'Press to screen',
    'platformChannels': 'Platform channels',
    'timerLeaks': 'Timer leaks',
    'foregroundResidency': 'Foreground residency',
    'backgroundRecovery': 'Background recovery',
    'dimensionChurn': 'Dimension churn',
    'appearanceChurn': 'Appearance churn',
    'unhandledErrors': 'Unhandled errors',
    'swallowedErrors': 'Swallowed errors',
    'leakWatch': 'Leak Watch',
    'devPosture': 'Dev Posture',
    'crashFree': 'Crash-free',
    // NO 'reliability' row: it scores a SERVER's request outcomes
    // (responses vs error responses). A device kit serves no requests,
    // so this kit never emits it and the panel must not promise it.
    'memoryStability': 'Memory stability',
    'coldStart': 'Cold start',
    'schedulerLatency': 'Scheduler Latency',
    'cpuConsumption': 'CPU consumption',
    'threadFootprint': 'Thread footprint',
    'blockingAsync': 'Blocking async',
    'storageLatency': 'Storage latency',
    'storageFailures': 'Storage Failures',
    'deviceTier': 'Device tier',
    'frustration': 'Frustration',
  };

  // ─── Panel shape (dashboard-first) ─────────────────────────────────────────

  /// The dashboard-first panel shape: the pulse trio plus an ordered list of
  /// meter rows, each projected onto the fixed {key,label,score,rating,caption}
  /// allowlist. Core axes render as pending/measuring… while absent; expected
  /// additive axes render as pending/warming up until they have honest data.
  /// Fail-open: any error degrades to the pulse-only shape.
  static Map<String, Object?> panelShape() {
    final out = pulseShape();
    // Already rendered here so every consumer uses the same fallback rule.
    out['project'] = projectDisplay(getKitProject());
    out['installId'] = Telemetry.installId;

    var axes = Safe.run<Map<String, Object?>>(
      <String, Object?>{},
      () => Snapshot.buildAxes(Samples.all()),
    );

    final rows = <Map<String, Object?>>[];
    final core = panelCoreAxes();

    Safe.fire(() {
      final ordered = <String>[];
      for (final c in core) {
        ordered.add(c);
      }
      for (final key in axes.keys) {
        if (!ordered.contains(key)) ordered.add(key);
      }
      for (final key in ordered) {
        final raw = axes[key];
        final isCore = core.contains(key);
        final axis = raw is Map ? Map<String, Object?>.from(raw) : null;
        final scoreVal = axis == null ? null : axis['score'];
        if (axis == null || scoreVal is! num) {
          // Cold start is measured but NOT rated on this kit (the interval
          // starts at our own start, not at the launch), so it must render as
          // a real reading with its interval named — never as "warming up",
          // which would hide a figure we already have.
          final partial = key == 'coldStart' && axis != null
              ? coldStartCaption(axis)
              : '';
          if (partial.isNotEmpty) {
            rows.add(<String, Object?>{
              'key': key,
              'label': panelLabel(key),
              'score': null,
              'rating': 'pending',
              'caption': partial,
            });
            continue;
          }
          // A RETIRED GRADE is not a warming row. These axes carry a real
          // measurement and will never carry a score, because what they
          // measure is not the app's doing (see
          // docs/decisions/meter-verdicts-that-are-not-about-the-app.md).
          // Left to the generic line below they would say "measuring…" for
          // ever, promising a verdict that is never coming.
          if (axis != null && axis['rating'] == 'not-scored') {
            rows.add(<String, Object?>{
              'key': key,
              'label': panelLabel(key),
              'score': null,
              'rating': 'not-scored',
              'caption': notScoredCaption(key, axis),
            });
            continue;
          }
          final aiBlindSpot = key == 'aiCalls' && axis != null
              ? _aiBlindSpotCaption(axis)
              : '';
          if (aiBlindSpot.isNotEmpty) {
            rows.add(<String, Object?>{
              'key': key,
              'label': panelLabel(key),
              'score': null,
              'rating': 'pending',
              'caption': aiBlindSpot,
            });
            continue;
          }
          if (key == 'pressToScreen' && axis != null) {
            // Counts are observations even before five screens finish.
            rows.add(<String, Object?>{
              'key': key,
              'label': panelLabel(key),
              'score': null,
              'rating': 'pending',
              'caption': 'warming up · ${pressToScreenCaption(axis)}',
            });
            continue;
          }
          if (isCore) {
            rows.add(<String, Object?>{
              'key': key,
              'label': panelLabel(key),
              'score': null,
              'rating': 'pending',
              'caption': 'measuring\u2026',
            });
          }
          continue;
        }
        var score = scoreVal.round();
        if (score < 0) score = 0;
        if (score > 100) score = 100;
        final ratingVal = axis['rating'];
        var rating = ratingVal is String ? ratingVal : null;
        if (rating != Score.good &&
            rating != Score.needsWork &&
            rating != Score.poor) {
          rating = Score.getRating(score);
        }
        final safeKey = key.length > 40 ? key.substring(0, 40) : key;
        rows.add(<String, Object?>{
          'key': safeKey,
          'label': panelLabel(key),
          'score': score,
          'rating': rating,
          'caption': panelCaption(key, axis),
        });
      }
    });

    // Warming-up rows: every expected additive axis with no honest numeric
    // score yet still renders, muted, so a fresh app shows the same meter set
    // here as on the web dashboard.
    Safe.fire(() {
      final rendered = <String, bool>{};
      for (final row in rows) {
        rendered[(row['key'] ?? '').toString()] = true;
      }
      for (final key in panelWarmingAxes()) {
        if (rendered[key] == true) continue;
        // BASELINE can be PRESENT and honest with no score ever coming: every
        // screen's earlier window was too fast to divide by. Left to the
        // generic line it would say "warming up" for ever, which is the
        // steadiness claim this axis is not entitled to make.
        final raw = axes[key];
        final abstains =
            key == 'baseline' &&
            raw is Map<String, Object?> &&
            raw['measurable'] is num &&
            (raw['measurable']! as num).toInt() == 0;
        rows.add(<String, Object?>{
          'key': key,
          'label': panelLabel(key),
          'score': null,
          'rating': 'pending',
          'caption': abstains
              ? baselineNotJudgedCaption(raw as Map<String, Object?>)
              : _panelWarmingCaption(key),
        });
      }
    });

    out['axes'] = rows;

    // A registered-but-silent (or unregistered, or id-rejected) install must
    // never read as connected/normal/awaiting. The key is OMITTED entirely
    // when there is nothing to say.
    final notice = computePanelNotice();
    if (notice != null) {
      final block = <String, Object?>{'kind': notice};
      if (notice == 'uploads-failing') {
        final reason = Telemetry.lastUploadFailure?.reason;
        block['reason'] = reason == UploadFailReason.serverError
            ? 'server-error'
            : reason?.name;
        block['lost'] = Telemetry.droppedUploadCount;
      }
      out['notice'] = block;
    }

    // "Measurements dropped" figure. Like `notice.kind`, this carries ONLY a
    // count + code-defined cause MARKERS — never server text — and the words
    // are literals in the renderer. OMITTED entirely when nothing has been
    // dropped, so a healthy app and an older server look exactly as before.
    final drops = computePanelDrops();
    if (drops != null) out['drops'] = drops;

    return out;
  }

  /// The panel's drop figure, or null when nothing has been dropped. The count
  /// is CUMULATIVE for the life of the process (the size of the hole in the
  /// dashboard; a later clean upload does not erase it). `causes` are the fixed
  /// cause MARKERS in cause order, which the renderer maps to its own literal
  /// text — no server-provided string ever crosses this boundary. Fail-open:
  /// any error yields no figure rather than no panel.
  static Map<String, Object?>? computePanelDrops() {
    return Safe.run<Map<String, Object?>?>(null, () {
      final total = DropReport.droppedRowCount;
      if (total <= 0) return null;
      return <String, Object?>{
        'count': total,
        'causes': DropReport.droppedRowCauses(),
      };
    });
  }

  /// The panel's notice kind, or null when there is nothing to say. Ordered by
  /// how completely each state blocks the developer:
  ///
  ///   install-id-not-uuid  the server rejected the id outright
  ///   not-registered       the kit never registered (no key, or no reach)
  ///   sharing-off          registered, but nothing is being uploaded
  ///
  /// The last one is the quiet failure this notice exists to end. An install
  /// with sharing off still runs, still shows live local meters, and still
  /// looks completely healthy — while the dashboard it is supposed to feed
  /// stays empty. Nothing anywhere told the developer that, so the panel does.
  ///
  /// Fail-open by construction: any error renders the panel with no notice
  /// rather than no panel.
  static String? computePanelNotice() {
    return Safe.run<String?>(null, () {
      // The server rejected the id outright (or the stored id is not a UUID).
      if (Telemetry.registrationStatus == Telemetry.invalidInstallIdMarker ||
          Telemetry.invalidInstallId) {
        return 'install-id-not-uuid';
      }
      Registration.askRegistration();
      final verdict = Registration.verdict;
      if (verdict == RegistrationVerdict.unregistered) return 'not-registered';
      if (verdict == RegistrationVerdict.unknown && !Telemetry.hasCredentials) {
        return 'registration-unknown';
      }
      // A known OFF the kit could not persist is a distinct, louder state than
      // an ordinary "sharing off": the OFF may not survive a relaunch, so the
      // panel says so rather than imply everything is settled. Checked BEFORE
      // the plain sharing-off notice.
      if (Telemetry.sharingOffNotDurable) return 'sharing-off-not-durable';
      // Registered, but full telemetry is off: live local meters, empty
      // dashboard, and until now nothing said so.
      if (!Telemetry.fullTelemetry) return 'sharing-off';
      if (Telemetry.isLastUploadAttemptFailed &&
          Telemetry.lastUploadFailure != null) {
        return 'uploads-failing';
      }
      return null;
    });
  }

  /// The closed panel JSON string (lock-only when locked). Never throws.
  static String panelJson() {
    final lock = computePanelLock();
    final shape = lock == null
        ? panelShape()
        : <String, Object?>{
            'lock': lock,
            'project': projectDisplay(getKitProject()),
          };
    return Json.encode(shape) ?? '{"score":null,"rating":null,"sampleCount":0}';
  }

  // ─── Core + warming axis sets ──────────────────────────────────────────────

  /// The core axes that always render (as pending while absent).
  static List<String> panelCoreAxes() => const <String>[
    'responsiveness',
    'smoothness',
  ];

  /// The additive axes this kit reliably produces once the app has been used a
  /// little, keyed by their WIRE axis keys. Environment/opt-in-gated axes are
  /// deliberately ABSENT: they can be honestly N/A forever and a permanently-
  /// warming row would be a fake meter (platformChannels/timerLeaks are opt-in;
  /// the four GC/heap axes are compiled out of release builds).
  static List<String> panelWarmingAxes() => const <String>[
    'stability',
    'frameFloor',
    'frozenFrames',
    'appHang',
    'rasterJank',
    'network',
    'baseline',
    'navDeadTime',
    'pressToScreen',
    'imageWeight',
    'memoryStability',
    'coldStart',
    'schedulerLatency',
    // CPU/thread are Android-only and deliberately stay out of this warming
    // list; iOS sends a present/not-measurable reason instead.
    'blockingAsync',
    'storageLatency',
    // storageFailures rides the SAME probe as storageLatency, so it warms and
    // resolves on exactly the same tick. Listing one and not the other would
    // leave a panel showing half of a two-part answer.
    'storageFailures',
    'crashFree',
    'unhandledErrors',
    'leakWatch',
    'timerHealth',
    // Memory and collection. Every reading here is one this engine can take
    // and that fills with ordinary use, so the panel warms the same rows the
    // web dashboard does for the same app rather than showing fewer meters.
    'memoryWarnings',
    'peakRss',
    'residentGrowth',
  ];

  static Map<String, String> _warmingGates() => const <String, String>{
    'frameFloor': 'needs 10s of frames',
    'frozenFrames': 'needs some frames',
    'appHang': 'needs some frames',
    'rasterJank': 'needs some frames',
    'coldStart': 'needs the first frame',
    'crashFree': 'needs 5 min',
    'leakWatch': 'needs 5 min',
    'navDeadTime': 'needs 5 navigations',
    'pressToScreen': 'needs 5 joined navigations',
    'schedulerLatency': 'needs 20 ticks',
    'blockingAsync': 'needs 1 min',
    'memoryStability': 'needs 2 samples',
  };

  static String _panelWarmingCaption(String key) {
    final gate = _warmingGates()[key];
    return gate != null ? 'warming up \u00b7 $gate' : panelWarmingCaption;
  }

  // ─── Labels + captions ─────────────────────────────────────────────────────

  /// Human label for a panel axis: the fixed label when known, else a humanized
  /// camelCase key (never dropped).
  static String panelLabel(String key) {
    final labels = panelAxisLabels();
    if (labels.containsKey(key)) return labels[key]!;
    final words = key.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
      (m) => ' ',
    );
    if (words.isEmpty) return words;
    return words[0].toUpperCase() + words.substring(1);
  }

  /// The words for an unrated cold-start reading: the figure AND the interval
  /// it covers, so a partial measurement is never read as a whole start-up.
  /// Empty when the axis carries no figure (then the row warms up as usual).
  ///
  /// Same sentence the server writes for this kit's `measuredTo` code, so the
  /// in-app panel and the web dashboard cannot disagree about what was
  /// measured. See docs/cold-start-boundary-contract.md.
  static String coldStartCaption(Map<String, Object?> axis) {
    return Safe.run<String>('', () {
      final ms = axis['startupMs'];
      if (ms is! num) return '';
      final secs = ms / 1000;
      final shown = secs >= 10
          ? '${secs.round()}s'
          : '${secs.toStringAsFixed(1)}s';
      return 'first frame $shown after Boosthis started \u00b7 '
          'the app was already starting before that';
    });
  }

  /// Wording for a baseline reading that compared nothing: every screen with
  /// enough samples had an earlier window too fast (sub-millisecond) to divide
  /// by. Same phrase the sibling kits use, so one product speaks one way — and
  /// never "measuring…", which promises a reading that is not coming.
  static String baselineNotJudgedCaption(Map<String, Object?> axis) {
    final raw = axis['unscoredRoutes'];
    final skipped = raw is num ? raw.toInt() : 0;
    return 'not judged \u00b7 $skipped screen${skipped == 1 ? '' : 's'} '
        'too fast to compare';
  }

  /// Words for a reading that is published but never graded: the measurement
  /// itself, then the reason there is no verdict. Never "measuring…", which
  /// would promise a score that is not coming, and never an empty row.
  static String notScoredCaption(String key, Map<String, Object?> axis) {
    return Safe.run<String>('not graded', () {
      num? n(Object? v) => v is num && v.isFinite ? v : null;
      switch (key) {
        case 'foregroundResidency':
          final pct = n(axis['foregroundPct']);
          final min = n(axis['activeMin']);
          if (pct == null || min == null) return 'not graded';
          return '${min.round()} min in front \u00b7 $pct% of session \u00b7 '
              'not graded (the person decides this, not the app)';
        case 'dimensionChurn':
        case 'appearanceChurn':
          final perHour = n(axis['perHour']);
          final count = n(axis['count']);
          if (perHour == null || count == null) return 'not graded';
          final what = key == 'dimensionChurn' ? 'size changes' : 'theme changes';
          return '$perHour/hr $what \u00b7 ${count.round()} total \u00b7 '
              'not graded (the person decides this, not the app)';
        case 'memoryWarnings':
          final count = n(axis['count']);
          final windowMin = n(axis['windowMin']);
          if (count == null || windowMin == null) return 'not graded';
          return '${count.round()} warning${count == 1 ? '' : 's'} in '
              '$windowMin min \u00b7 not graded (the OS decides this, '
              'largely on how much memory the device has)';
        default:
          return 'not graded';
      }
    });
  }

  /// Honest numeric caption for one axis. Prefers the axis's own caption; else a
  /// bare score. Display-only; never routes, URLs, or raw samples.
  static String panelCaption(String key, Map<String, Object?> axis) {
    return Safe.run<String>('', () {
      if (key == 'pressToScreen') return pressToScreenCaption(axis);
      final cap = axis['caption'];
      if (cap is String && cap.trim().isNotEmpty) return cap;
      final score = axis['score'];
      if (score is num) {
        final blindSpot = key == 'aiCalls' ? _aiBlindSpotCaption(axis) : '';
        return blindSpot.isEmpty
            ? '${score.round()}'
            : '${score.round()} · $blindSpot';
      }
      return '';
    });
  }

  /// Show the whole interval and each reason a press missed the reading, so the
  /// panel cannot present only the quick survivors as a healthy navigation.
  static String pressToScreenCaption(Map<String, Object?> axis) {
    return Safe.run<String>('', () {
      final whole = axis['p75Ms'];
      final dead = axis['deadP75Ms'];
      final settle = axis['settleP75Ms'];
      final past = axis['unjoinedPastBound'];
      final none = axis['unjoinedNoScreen'];
      final untimed = axis['unjoinedNoTiming'];
      final bound = axis['boundMs'];
      final navs = axis['navCount'];
      final wait = whole is num && dead is num && settle is num
          ? '${whole.round()}ms total · ${dead.round()}ms to mount · '
              '${settle.round()}ms to settle · '
          : '';
      return '$wait${navs is num ? navs.round() : 0} joined · '
          '${past is num ? past.round() : 0} past '
          '${bound is num ? bound.round() : 0}ms bound · '
          '${none is num ? none.round() : 0} no screen · '
          '${untimed is num ? untimed.round() : 0} presses whose screen had no reading to time';
    });
  }

  static String _aiBlindSpotCaption(Map<String, Object?> axis) {
    final raw = axis['unwatchedClients'];
    if (raw is! num || !raw.isFinite || raw <= 0) return '';
    final count = raw.floor();
    return '$count HTTP client${count == 1 ? '' : 's'} not watched';
  }

  // ─── Percentile ────────────────────────────────────────────────────────────

  /// The p'th percentile of a list of durations, byte-identical floor index
  /// policy to the sibling bubbles (idx = floor(len * p), clamped).
  static int _percentile(List<int> values, double p) {
    final len = values.length;
    if (len == 0) return 0;
    final sorted = List<int>.from(values)..sort();
    var idx = (len * p).toInt();
    if (idx > len - 1) idx = len - 1;
    return sorted[idx];
  }
}
