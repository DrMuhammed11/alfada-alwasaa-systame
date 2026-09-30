/// Boosthis: candidate rules (Flutter kit).
///
/// A "candidate rule" is a recurring problem signature the kit has observed but
/// which does NOT map to any rule in the existing rule book. When the same kind
/// of finding fires repeatedly, that is a strong signal there is a real,
/// generalisable pattern worth turning into a named rule everybody gets.
///
/// This is the Flutter copy of the contract every kit follows
/// (`docs/kit-problem-reporting-contract.md`). The thresholds, the buckets, the
/// signature shape and the wire payload keys are byte-identical to the Node,
/// React Native, Python, browser and Swift siblings, because a signature that
/// spells itself differently can never group with the same problem found in
/// another language.
///
/// PRIVACY. A finding is reduced to `<kind>:<severityBucket>:<countBucket>` and
/// nothing else. The finding's own `name` — a bare outbound hostname, a fixed
/// label — is used LOCALLY only, for the recurrence hint. It never enters the
/// signature and it never leaves the device. There is no URL, no path, no
/// value and no code on this channel.
///
/// AN APP KIT'S TWO CONSTRAINTS, both answered here:
///   * Nothing runs on the UI isolate's frame path. Every caller of [ingest] is
///     the uploader's background tick; the accumulator itself only touches the
///     store and hands the network work to the registered submitters.
///   * The store must survive a process the operating system suspends or kills
///     between two sightings of the same problem, so the candidate set and the
///     severity baselines are DURABLE [Store] writes. The polling-dedupe key is
///     deliberately NOT durable: a relaunch is a genuinely new observation.
///
/// GUEST SAFETY: every entry point runs inside [Safe], so a bug here degrades
/// to silence instead of surfacing in the host app.
library;

import '../core/runtime_flags.dart' show RuntimeFlags;
import '../core/safe.dart' show Safe;
import '../core/store.dart' show Store;
import '../core/telemetry.dart' show Telemetry;
import 'problem_kinds.dart' show isProblemKind;

/// Sends one batch and returns how many rows the server accepted.
typedef CandidateSubmitter = Future<int> Function(
  List<Map<String, Object?>> rows,
);

class CandidateRules {
  CandidateRules._();

  /// Durable store keys. Shared spelling with the sibling kits.
  static const String keyCandidates = 'candidate-rules-v1';
  static const String keyBaselines = 'rule-baselines-v1';

  /// Cap the persisted set so a busy app cannot grow the kit's own state
  /// without limit.
  static const int maxCandidates = 100;

  /// One occurrence is an anecdote; the claim being made is "recurring".
  static const int minOccurrencesToSurface = 2;

  /// Never ship more than this many rows in one call — the same batch cap
  /// every other kit applies.
  static const int maxPerCall = 50;

  static CandidateSubmitter? _candidateSubmitter;
  static CandidateSubmitter? _resolutionSubmitter;
  static String? _lastIngestKey;

  /// Register the auto-submitter for recurring problems. Pass null to clear
  /// (erasure), which is what stops anything leaving the device.
  static void setCandidateSubmitter(CandidateSubmitter? submitter) {
    _candidateSubmitter = submitter;
  }

  /// Register the auto-submitter for fix outcomes. Pass null to clear.
  static void setResolutionSubmitter(CandidateSubmitter? submitter) {
    _resolutionSubmitter = submitter;
  }

  // ── Buckets and the signature ───────────────────────────────────────────

  static String bucketSeverity(double p95) {
    if (p95 <= 100) return 'low';
    if (p95 <= 500) return 'med';
    return 'high';
  }

  static String bucketCount(int count) {
    if (count < 3) return '<3';
    if (count < 10) return '<10';
    if (count < 50) return '<50';
    return '50+';
  }

  static const Map<String, int> _sevRank = <String, int>{
    'low': 0,
    'med': 1,
    'high': 2,
  };

  static String _severityToRating(String sev) {
    if (sev == 'high') return 'poor';
    if (sev == 'med') return 'needs-work';
    return 'good';
  }

  static String _kindOf(Map<String, Object?> finding) {
    final v = finding['kind'];
    return v is String ? v : '';
  }

  static double _p95Of(Map<String, Object?> finding) {
    final v = finding['p95'];
    return v is num ? v.toDouble() : 0;
  }

  static int _countOf(Map<String, Object?> finding) {
    final v = finding['count'];
    return v is num ? v.toInt() : 0;
  }

  static int _intOf(Object? value) => value is num ? value.toInt() : 0;

  /// Build the privacy-safe signature. The finding's `name` is intentionally
  /// dropped: only the kind, the severity bucket and the count bucket are
  /// persisted and uploaded.
  static String signatureFor(Map<String, Object?> finding) {
    final sev = bucketSeverity(_p95Of(finding));
    final ct = bucketCount(_countOf(finding));
    return '${_kindOf(finding)}:$sev:$ct';
  }

  /// Cheap stable hash used purely as a storage key. No crypto dependency and
  /// no privacy risk: the input is already the signature, which carries no
  /// user values.
  static String safeHashId(String input) {
    var h = 5381;
    for (final unit in input.codeUnits) {
      h = ((h * 33) ^ unit) & 0xffffffff;
    }
    return 'cr_${h.toRadixString(36)}';
  }

  // ── The persisted set ───────────────────────────────────────────────────

  /// Read the persisted candidate set. Safe — returns [] on any error.
  static List<Map<String, Object?>> list() {
    if (RuntimeFlags.disabled) return <Map<String, Object?>>[];
    return Safe.run<List<Map<String, Object?>>>(<Map<String, Object?>>[], () {
      final raw = Store.get(keyCandidates, <Object?>[]);
      if (raw is! List) return <Map<String, Object?>>[];
      final out = <Map<String, Object?>>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final row = Map<String, Object?>.from(entry);
        if (row['id'] is! String) continue;
        if (row['signature'] is! String) continue;
        if (row['occurrences'] is! num) continue;
        out.add(row);
      }
      return out;
    });
  }

  static void _writeAll(List<Map<String, Object?>> rows) {
    Safe.fire(() {
      final trimmed =
          rows.length > maxCandidates ? rows.sublist(0, maxCandidates) : rows;
      Store.set(keyCandidates, trimmed, durable: true);
    });
  }

  /// Filter to candidates that have hit the minimum recurrence threshold.
  static List<Map<String, Object?>> surfaceable(
    List<Map<String, Object?>> all,
  ) {
    return all
        .where((c) => _intOf(c['occurrences']) >= minOccurrencesToSurface)
        .toList();
  }

  // ── Fix-resolution baselines ────────────────────────────────────────────

  static Map<String, String> _readBaselines() {
    return Safe.run<Map<String, String>>(<String, String>{}, () {
      final raw = Store.get(keyBaselines, <String, Object?>{});
      if (raw is! Map) return <String, String>{};
      final out = <String, String>{};
      raw.forEach((k, v) {
        if (k is! String || v is! String) return;
        if (v == 'low' || v == 'med' || v == 'high') out[k] = v;
      });
      return out;
    });
  }

  static void _writeBaselines(Map<String, String> baselines) {
    Safe.fire(() => Store.set(keyBaselines, baselines, durable: true));
  }

  // ── Ingest ──────────────────────────────────────────────────────────────

  static String _fingerprint(List<Map<String, Object?>> findings) {
    final parts = findings
        .map((f) =>
            '${_kindOf(f)}|${f['name'] is String ? f['name'] : ''}'
            '|${_p95Of(f).round()}|${_countOf(f)}')
        .toList()
      ..sort();
    return parts.join('\n');
  }

  /// Ingest the latest detector findings: increment counts for known
  /// signatures, create new candidates for unseen ones, persist, then upload
  /// anything that just crossed the local recurrence threshold and any fix
  /// outcome the baselines now prove.
  ///
  /// Polling-safe: consecutive calls with an identical finding set are one
  /// observation, so recurrence measures how often the PROBLEM happens rather
  /// than how often the kit looks.
  ///
  /// Returns the surfaceable candidates after the pass.
  static Future<List<Map<String, Object?>>> ingest(
    List<Map<String, Object?>> observed,
  ) async {
    if (RuntimeFlags.disabled) return <Map<String, Object?>>[];
    return Safe.runAsync<List<Map<String, Object?>>>(
      <Map<String, Object?>>[],
      () async {
        // Only the shared vocabulary travels. An off-list kind is DROPPED
        // rather than accumulated: a spelling no other language uses could
        // never group with the same problem found elsewhere.
        final findings =
            observed.where((f) => isProblemKind(_kindOf(f))).toList();
        if (findings.isEmpty) return surfaceable(list());

        final key = _fingerprint(findings);
        if (key == _lastIngestKey) return surfaceable(list());
        _lastIngestKey = key;

        final now = Telemetry.nowMs();
        final byId = <String, Map<String, Object?>>{};
        final order = <String>[];
        for (final row in list()) {
          final id = row['id'];
          if (id is! String) continue;
          if (!byId.containsKey(id)) order.add(id);
          byId[id] = row;
        }

        for (final f in findings) {
          final sig = signatureFor(f);
          final id = safeHashId(sig);
          final prev = byId[id];
          if (prev != null) {
            prev['lastSeenAt'] = now;
            prev['occurrences'] = _intOf(prev['occurrences']) + 1;
          } else {
            order.add(id);
            byId[id] = <String, Object?>{
              'id': id,
              'signature': sig,
              'kind': _kindOf(f),
              'severityBucket': bucketSeverity(_p95Of(f)),
              'firstSeenAt': now,
              'lastSeenAt': now,
              'occurrences': 1,
              'exampleHint': f['hint'] is String ? f['hint'] : '',
              'status': 'new',
            };
          }
        }

        // Most-recently-seen first, capped on write.
        final merged = order
            .map((id) => byId[id])
            .whereType<Map<String, Object?>>()
            .toList()
          ..sort((a, b) =>
              _intOf(b['lastSeenAt']).compareTo(_intOf(a['lastSeenAt'])));
        _writeAll(merged);

        await _submitResolutions(findings);
        final after = await _submitCandidates(merged);
        return surfaceable(after);
      },
    );
  }

  /// Compare each kind's current worst severity against the worst ever
  /// recorded. A strict improvement means a fix landed. The stored baseline is
  /// lowered ONLY after the server accepts, so a transient network failure
  /// retries on the next pass instead of losing the improvement.
  static Future<void> _submitResolutions(
    List<Map<String, Object?>> findings,
  ) async {
    final baselines = _readBaselines();
    var changed = false;
    final currentWorst = <String, String>{};
    final currentCount = <String, int>{};
    for (final f in findings) {
      final kind = _kindOf(f);
      final sev = bucketSeverity(_p95Of(f));
      final prev = currentWorst[kind];
      if (prev == null || (_sevRank[sev] ?? 0) > (_sevRank[prev] ?? 0)) {
        currentWorst[kind] = sev;
      }
      final seen = currentCount[kind] ?? 0;
      final now = _countOf(f);
      currentCount[kind] = now > seen ? now : seen;
    }

    final resolved = <Map<String, Object?>>[];
    currentWorst.forEach((kind, sev) {
      final worst = baselines[kind];
      if (worst != null && (_sevRank[sev] ?? 0) < (_sevRank[worst] ?? 0)) {
        resolved.add(<String, Object?>{
          'ruleId': kind,
          'kind': kind,
          'beforeRating': _severityToRating(worst),
          'afterRating': _severityToRating(sev),
          'occurrences': 1,
          // The circumstances BEFORE the fix, so the community matcher can
          // weight a proven fix toward similar projects.
          'severityBucket': worst,
          'countBucket': bucketCount(currentCount[kind] ?? 0),
        });
      } else if (worst == null ||
          (_sevRank[sev] ?? 0) > (_sevRank[worst] ?? 0)) {
        // New or worsened — raise the worst-ever baseline immediately.
        baselines[kind] = sev;
        changed = true;
      }
    });

    final submitter = _resolutionSubmitter;
    if (resolved.isNotEmpty && submitter != null) {
      final batch = resolved.length > maxPerCall
          ? resolved.sublist(0, maxPerCall)
          : resolved;
      final accepted = await submitter(batch);
      if (accepted > 0) {
        for (final row in batch.take(accepted)) {
          final kind = row['ruleId'];
          if (kind is! String) continue;
          final now = currentWorst[kind];
          if (now == null) continue;
          baselines[kind] = now;
          changed = true;
        }
      }
    }
    if (changed) _writeBaselines(baselines);
  }

  /// Auto-submit: any surfaceable candidate still `new` is a signature that
  /// just crossed the local threshold. Returns the set as it now stands.
  static Future<List<Map<String, Object?>>> _submitCandidates(
    List<Map<String, Object?>> merged,
  ) async {
    final submitter = _candidateSubmitter;
    if (submitter == null) return merged;
    final toSubmit =
        surfaceable(merged).where((c) => c['status'] == 'new').toList();
    if (toSubmit.isEmpty) return merged;

    final capped =
        toSubmit.length > maxPerCall ? toSubmit.sublist(0, maxPerCall) : toSubmit;
    final payload = capped.map((row) {
      final sig = row['signature'] is String ? row['signature'] as String : '';
      final parts = sig.split(':');
      return <String, Object?>{
        'signature': sig,
        'kind': row['kind'] is String ? row['kind'] : '',
        'severityBucket':
            row['severityBucket'] is String ? row['severityBucket'] : '',
        'countBucket': parts.length > 2 ? parts[2] : '<3',
        'occurrences': _intOf(row['occurrences']),
      };
    }).toList();

    final accepted = await submitter(payload);
    if (accepted <= 0) {
      // Best-effort. The candidate stays `new`, so the next observation
      // retries automatically.
      return merged;
    }
    final submittedIds = <String>{};
    for (final row in capped.take(accepted)) {
      final id = row['id'];
      if (id is String) submittedIds.add(id);
    }
    // Re-read: another flush may have written while the upload was in flight,
    // and clobbering that write would resurrect an already submitted
    // candidate.
    final latest = list();
    final base = latest.isEmpty ? merged : latest;
    for (final row in base) {
      final id = row['id'];
      if (id is String && submittedIds.contains(id)) row['status'] = 'submitted';
    }
    _writeAll(base);
    return base;
  }

  // ── Erasure and lifecycle ───────────────────────────────────────────────

  /// Wipe the candidates AND the severity baselines, and drop the in-memory
  /// dedupe key. Wired into `forget()`, so nothing Boosthis-shaped survives
  /// erasure on the device.
  static void clearAll() {
    Safe.fire(() {
      Store.delete(keyCandidates);
      Store.delete(keyBaselines);
    });
    _lastIngestKey = null;
  }

  /// The host app is going to the background. Nothing is left in flight — the
  /// uploader's timer is what gets cancelled — but the polling-dedupe key is
  /// dropped so the first pass after a resume counts as a genuinely new
  /// observation rather than being folded into the last one before the
  /// suspend.
  static void onSuspend() {
    _lastIngestKey = null;
  }

  /// Test seam: forget the submitters and the dedupe key. The durable store is
  /// left alone; a test that wants it gone calls [clearAll].
  static void resetForTests() {
    _candidateSubmitter = null;
    _resolutionSubmitter = null;
    _lastIngestKey = null;
  }
}
