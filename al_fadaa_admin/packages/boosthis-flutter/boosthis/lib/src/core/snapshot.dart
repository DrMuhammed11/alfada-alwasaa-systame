import 'build_identity.dart';
import 'device_facts.dart';
import 'json.dart';
import 'kit_version.dart';
import 'runtime_flags.dart';
import 'safe.dart';
import 'samples.dart';
import 'score.dart';
import 'store.dart';
import 'telemetry.dart';
import 'thresholds.dart';
import '../integration/ai_calls.dart';
import '../integration/route_inventory.dart';

/// The perf snapshot: what this app looks like right now, as a closed payload on
/// exactly the top-level fields the server's ingest accepts.
///
/// Screen-bearing by definition, so it only moves when full telemetry is on —
/// the owner's own opt-in, or the server directive learned at consent.
/// BOOSTHIS_DISABLED and forget() always win (the Uploader enforces that gate).
///
/// IDENTITY: the payload carries BOTH the runtime tag `runtime: "flutter"` AND
/// the real device `platform` handed in by the adapter ("ios"/"android"/…). The
/// runtime is never used as a platform value.
///
/// The additive meter collectors (rasterJank, platformChannels, timerLeaks,
/// smoothness, frameFloor, lifecycle axes, …) live in sibling ownership groups.
/// They register through [addAxisContributor] so this file assembles the
/// payload without importing them; a missing contributor is simply absent from
/// the axes (fail-open), exactly like an axis that has not warmed up.
class Snapshot {
  Snapshot._();

  /// A p99 at or below this is not a tail worth acting on.
  static const int resilienceTailFloorMs = 50;
  /// Below this count a p99 is just the slowest of a handful.
  static const int resilienceMinTailSamples = 20;
  /// A median below capture resolution is unmeasured, not small.
  static const int resilienceMinMedianMs = 1;

  /// Steady-state re-upload interval once the first-run turbo ramp is done.
  static const int snapshotFlushMs = 60000;

  /// BOOSTHIS_TURBO=0 (and only that exact value) opts an install OUT of the
  /// first-run ramp, falling back to the steady 60s cadence from boot.
  static const String turboEnvVar = 'BOOSTHIS_TURBO';
  static const String turboOff = '0';

  /// Route rows carry this prefix in every runtime, so live-data tools match.
  static const String screenPrefix = 'screen:';
  static const int maxSnapshotRows = 100;
  static const int maxSnapshotFindings = 20;

  /// A route slower than this at p95 is worth calling out.
  static const int slowApiP95Ms = 1000;

  static const String keyLastUpload = 'snapshot_last_upload';
  static const String keyStartedAt = 'started_at';

  /// Axis contributors wired by the meters/observers groups. Each receives the
  /// axes map (to add to) and the current samples list.
  static final List<
          void Function(Map<String, Object?> axes,
              List<Map<String, Object?>> samples)>
      _axisContributors = [];

  /// Findings contributors (cross-cutting live detectors), wired by observers.
  static final List<List<Map<String, Object?>> Function()>
      _findingContributors = [];

  static void addAxisContributor(
    void Function(Map<String, Object?> axes,
            List<Map<String, Object?>> samples)
        fn,
  ) {
    _axisContributors.add(fn);
  }

  static void addFindingContributor(
      List<Map<String, Object?>> Function() fn) {
    _findingContributors.add(fn);
  }

  /// Test seam: drop all wired contributors.
  static void resetContributorsForTests() {
    _axisContributors.clear();
    _findingContributors.clear();
  }

  static bool turboDisabled() {
    final v = RuntimeFlags.env(turboEnvVar);
    return v != null && v.trim() == turboOff;
  }

  /// Delay (ms) until the NEXT upload, based purely on how long this install
  /// has been running:
  ///   age < 30s  -> 10s
  ///   age < 90s  -> 20s
  ///   age < 180s -> 40s
  ///   otherwise  -> the steady 60s
  ///
  /// FROZEN across all kits (strict `<` boundaries). Age-driven on purpose: a
  /// skipped or empty upload must not burn a ramp step.
  static int nextSnapshotDelayMs(int sessionAgeMs) {
    if (turboDisabled()) return snapshotFlushMs;
    if (sessionAgeMs < 30000) return 10000;
    if (sessionAgeMs < 90000) return 20000;
    if (sessionAgeMs < 180000) return 40000;
    return snapshotFlushMs;
  }

  /// When this install first ran in this scope.
  static int startedAtMs() {
    final v = Store.get(keyStartedAt, null);
    if (v is int) return v;
    final now = Telemetry.nowMs();
    Store.set(keyStartedAt, now, durable: true);
    return now;
  }

  static int sessionAgeMs() {
    final d = Telemetry.nowMs() - startedAtMs();
    return d < 0 ? 0 : d;
  }

  /// True when the cadence says another upload is due.
  static bool uploadDue() {
    final v = Store.get(keyLastUpload, 0);
    final last = v is int ? v : 0;
    if (last == 0) return true;
    return (Telemetry.nowMs() - last) >= nextSnapshotDelayMs(sessionAgeMs());
  }

  static void markUploaded() =>
      Store.set(keyLastUpload, Telemetry.nowMs(), durable: true);

  /// Is there anything worth uploading? An empty snapshot is never shipped.
  static bool worthUploading() => Samples.count() > 0 || AiCalls.hasEvidence;

  /// Build the current privacy-safe snapshot as a closed map on the EXACT
  /// allowlisted top-level fields the server accepts. Pure: reads stored
  /// samples and meter state, performs no network I/O.
  static Map<String, Object?> capturePerfSnapshot() {
    return Safe.run<Map<String, Object?>>(<String, Object?>{}, () {
      final samples = Samples.all();
      final rows = buildRows(samples);

      final snap = <String, Object?>{
        'capturedAt': Telemetry.nowMs(),
        'runtimeVersion': RUNTIME_VERSION,
        // Identity: the runtime tag AND the real device platform, distinct.
        'runtime': Telemetry.runtime,
        'platform': Telemetry.platform,
        'startedAt': startedAtMs(),
        'totalEvents': samples.length,
        'rows': rows,
      };

      final crossCutting = buildCrossCutting(rows);
      for (final contributor in _findingContributors) {
        final findings = Safe.run<List<Map<String, Object?>>>(
            <Map<String, Object?>>[], contributor);
        for (final f in findings) {
          if (crossCutting.length >= maxSnapshotFindings) break;
          crossCutting.add(f);
        }
      }
      snap['crossCutting'] = crossCutting;
      snap['axes'] = Json.objectOrEmpty(buildAxes(samples));

      final build = BuildIdentity.buildInfo();
      if (build != null) snap['build'] = build;

      // What this phone platform was OBSERVED to allow. Pure read of counters
      // the lifecycle callback and the upload loop already maintain — no
      // platform channel, no I/O, nothing that could touch the UI isolate.
      // Omitted entirely when nothing has been observed: a block naming a
      // platform and no fact is not an observation.
      final deviceFacts = readDeviceFactsBlock();
      if (deviceFacts != null) snap[kDeviceFactsKey] = deviceFacts;

      // The app's WHOLE screen list, as its own router describes it — so the
      // map can draw screens nobody has opened, marked "not seen", rather
      // than only the ones a session happened to reach. Always present once
      // the kit has the feature, even when the answer is "nothing was handed
      // over": a missing block means a kit too old to know the question.
      final routeList = RouteInventory.routeListForSnapshot();
      if (routeList != null) snap['routeList'] = routeList;

      return snap;
    });
  }

  /// One row per route: count, p50, p95, max and the most recent duration.
  /// First-seen order is preserved before the busiest-first sort.
  static List<Map<String, Object?>> buildRows(
      List<Map<String, Object?>> samples) {
    final order = <String>[];
    final byRoute = <String, List<int>>{};
    for (final s in samples) {
      final route = '${s['route']}';
      final d = s['durationMs'] is int ? s['durationMs'] as int : 0;
      final list = byRoute.putIfAbsent(route, () {
        order.add(route);
        return <int>[];
      });
      list.add(d);
    }

    final rows = <Map<String, Object?>>[];
    for (final route in order) {
      final durations = byRoute[route]!;
      final max = durations.reduce((a, b) => a > b ? a : b);
      rows.add(<String, Object?>{
        'key': screenPrefix + route,
        'count': durations.length,
        'p50': Samples.percentile(durations, 0.5).round(),
        'p95': Samples.percentile(durations, 0.95).round(),
        'max': max,
        'last': durations[durations.length - 1],
      });
    }

    // Busiest routes first (stable), so the cap keeps what matters.
    final indexed = <MapEntry<int, Map<String, Object?>>>[];
    for (var i = 0; i < rows.length; i++) {
      indexed.add(MapEntry(i, rows[i]));
    }
    indexed.sort((a, b) {
      final ca = a.value['count'] as int;
      final cb = b.value['count'] as int;
      final byCount = cb.compareTo(ca);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
    final sorted = indexed.map((e) => e.value).toList();
    return sorted.length > maxSnapshotRows
        ? sorted.sublist(0, maxSnapshotRows)
        : sorted;
  }

  /// Cross-cutting findings: routes whose p95 is over the slow-API line.
  static List<Map<String, Object?>> buildCrossCutting(
      List<Map<String, Object?>> rows) {
    final out = <Map<String, Object?>>[];
    for (final row in rows) {
      final p95 = row['p95'] is int ? row['p95'] as int : 0;
      if (p95 >= slowApiP95Ms) {
        out.add(<String, Object?>{
          'kind': 'slow-api',
          'name': row['key'],
          'p95': p95,
          'count': row['count'],
        });
      }
      if (out.length >= maxSnapshotFindings) break;
    }
    return out;
  }

  /// Every axis this runtime can honestly report right now. Each gates itself
  /// and is simply absent while it is still warming up.
  static Map<String, Object?> buildAxes(List<Map<String, Object?>> samples) {
    final axes = <String, Object?>{};
    final durations = samples
        .map((s) => s['durationMs'] is int ? s['durationMs'] as int : 0)
        .toList();

    // Core responsiveness — the only axis that maps to the Speed score. Gated
    // on the frozen kMinSamplesForAxes = 5.
    if (durations.length >= 5) {
      final p75 = Samples.percentile(durations, 0.75);
      final score = Score.scoreMetric(p75, Thresholds.kTtiGood, Thresholds.kTtiPoor);
      axes['responsiveness'] = <String, Object?>{
        'score': score,
        'rating': Score.getRating(score),
        'p75Ms': p75.round(),
        'count': durations.length,
      };

      if (durations.length >= resilienceMinTailSamples) {
        final p50 = Samples.percentile(durations, 0.5);
        final p99 = Samples.percentile(durations, 0.99);

        // Tail contract: tiny fast tails and zero medians gave false verdicts.
        if (p99 <= resilienceTailFloorMs) {
          final tailRatio =
              p50 >= resilienceMinMedianMs ? p99 / p50 : null;
          axes['resilience'] = <String, Object?>{
            'score': 100,
            'rating': Score.good,
            'tailRatio': tailRatio == null
                ? null
                : (tailRatio * 10).round() / 10.0,
            'p50Ms': p50.round(),
            'p99Ms': p99.round(),
            'sampleCount': durations.length,
          };
        } else if (p50 < resilienceMinMedianMs) {
          axes['resilience'] = <String, Object?>{
            'score': null,
            'rating': 'pending',
            'tailRatio': null,
            'p50Ms': p50.round(),
            'p99Ms': p99.round(),
            'sampleCount': durations.length,
          };
        } else {
          final tailRatio = p99 / p50;
          final resScore = Score.scoreMetric(tailRatio, 2.0, 10.0);
          axes['resilience'] = <String, Object?>{
            'score': resScore,
            'rating': Score.getRating(resScore),
            'tailRatio': (tailRatio * 10).round() / 10.0,
            'p50Ms': p50.round(),
            'p99Ms': p99.round(),
            'sampleCount': durations.length,
          };
        }
      }
    }

    final aiCalls = AiCalls.buildAxis();
    if (aiCalls != null) axes['aiCalls'] = aiCalls;

    // Additive axes contributed by the meters/observers groups.
    for (final contributor in _axisContributors) {
      Safe.fire(() => contributor(axes, samples));
    }

    // patchLag rides here for the same reason it does in every sibling kit:
    // it is not a sampled meter, it is a fact about the build that is running.
    // Absent (never zero, never pending) when no build stamp is known — a
    // Flutter binary cannot discover its own build time, so this appears only
    // when the app passed --dart-define=BOOSTHIS_BUILD_TIME_MS (or the adapter
    // called setBuildInfo). ADDITIVE + display-only: never feeds Speed.
    final patchLag = BuildIdentity.readPatchLag();
    if (patchLag != null) axes['patchLag'] = patchLag;

    return axes;
  }
}
