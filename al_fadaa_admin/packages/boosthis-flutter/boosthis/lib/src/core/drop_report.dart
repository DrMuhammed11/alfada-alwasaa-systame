import 'safe.dart';
import 'telemetry.dart';

/// "The server stored fewer rows than this app sent" — said inside the app.
///
/// WHY THIS EXISTS. The upload endpoints answer 202 and then discard individual
/// rows they cannot store: a route label the shared privacy guard refuses, a
/// span past the per-trace cap, a snapshot entry whose name is rejected. Until
/// now the kit read that 202 as unqualified success, so a developer whose every
/// route label was being thrown away saw a healthy app, no output, and a
/// dashboard that was quietly missing data. The only way to find out was to read
/// the database by hand — which is exactly what cost real debugging time during
/// the Flutter live smoke.
///
/// CONTRACT (identical in every kit — change it in one, change it in
/// all):
///   - Read `dropped` and `droppedByCause` from an upload reply. Their ABSENCE
///     (older server, non-JSON body, unreadable body) means "nothing to report":
///     no warning, no crash, no guessing.
///   - Warn EXACTLY ONCE per process per cause on the host's error stream,
///     naming the cause and the fix. Never once per request, never behind a
///     debug flag — this exists for the developer who does not yet suspect the
///     kit, the same reason the "stayed inactive" line is ungated. It goes
///     through the very same stderr sink as that line ([Telemetry.warnLine]).
///   - Keep a cumulative count + the causes seen, so the kit's own panel can
///     show the size of the hole in the same words the web page uses.
///   - Nothing here may ever fail an upload or reach the host's request path:
///     every entry point is self-guarded and the reply body is already in hand.
///   - Nothing is uploaded. The warning is local output only.
class DropReport {
  DropReport._();

  /// The cause keys this kit knows, in the fixed order used everywhere the
  /// causes are listed. Any cause key NOT in this set is counted in the total
  /// and named nowhere — the kit never invents an explanation for something it
  /// cannot read.
  static const List<String> causeKeys = <String>[
    'labelRejected',
    'traceCapReached',
    'snapshotEntryFiltered',
  ];

  /// Short cause text — the same words the project's web page uses, so the
  /// in-app view and the dashboard never tell two different stories.
  static const Map<String, String> causeText = <String, String>{
    'labelRejected': 'route names the privacy guard refused',
    'traceCapReached': 'spans past the 20-span limit',
    'snapshotEntryFiltered': 'snapshot entries the privacy guard refused',
  };

  /// What the developer changes to stop it. Second sentence of the warning.
  static const Map<String, String> causeFix = <String, String>{
    'labelRejected': 'Name routes in code, the way GET /orders is written.',
    'traceCapReached':
        'A trace keeps its first 20 spans \u2014 measure fewer steps per '
            'request, or split a very long trace.',
    'snapshotEntryFiltered':
        'Name screens in code, never from what a person typed or an id.',
  };

  // ─── Process-local state ───────────────────────────────────────────────────
  //
  // Cumulative for the life of the process: it is the size of the hole in the
  // dashboard, so a later clean upload does not erase it.

  static int _droppedRows = 0;
  static final Set<String> _seenCauses = <String>{};
  static final Set<String> _warnedCauses = <String>{};

  /// How many rows the server has refused since this process started.
  static int get droppedRowCount => _droppedRows;

  /// The causes seen so far, in the fixed cause order. Empty when nothing has
  /// been dropped.
  static List<String> droppedRowCauses() =>
      causeKeys.where(_seenCauses.contains).toList();

  /// The panel figure: `"6 \u2014 route names the privacy guard refused; spans
  /// past the 20-span limit"`. Empty string when nothing has been dropped, so a
  /// healthy app shows nothing at all.
  static String summaryText() {
    if (_droppedRows <= 0) return '';
    final causes = droppedRowCauses().map((c) => causeText[c]!).toList();
    if (causes.isEmpty) return '$_droppedRows';
    return '$_droppedRows \u2014 ${causes.join('; ')}';
  }

  static int _finiteCount(Object? v) {
    if (v is! num) return 0;
    if (!v.isFinite || v <= 0) return 0;
    return v.floor();
  }

  /// Record what one upload reply said, and warn once per cause.
  ///
  /// Safe to call with anything: a reply without the fields, a non-map, null.
  /// Only a body that actually reports a positive `dropped` changes any state or
  /// prints anything. Never throws — telling someone about a dropped row must
  /// never break an upload.
  static void noteServerDrops(Map<String, Object?>? body) {
    Safe.fire(() {
      if (body == null) return;
      final total = _finiteCount(body['dropped']);
      if (total <= 0) return;
      _droppedRows += total;
      final raw = body['droppedByCause'];
      if (raw is! Map) return;
      for (final cause in causeKeys) {
        if (_finiteCount(raw[cause]) <= 0) continue;
        _seenCauses.add(cause);
        _warnCauseOnce(cause, _finiteCount(raw[cause]));
      }
    });
  }

  /// Emit the one-shot line for a cause, ungated, never repeated. Goes through
  /// the SAME stderr sink as the "stayed inactive" line, so it inherits that
  /// line's crash-safety and a test can capture both the same way.
  static void _warnCauseOnce(String cause, int count) {
    if (_warnedCauses.contains(cause)) return;
    _warnedCauses.add(cause);
    Telemetry.warnLine(
      '[boosthis] Boosthis dropped $count of the measurements this app sent: '
      '${causeText[cause]}. ${causeFix[cause]}',
    );
  }

  /// Test seam — forget every drop and every warn-once latch. Called from
  /// [Telemetry.resetForTests] alongside the existing one-shot reset.
  static void resetForTests() {
    _droppedRows = 0;
    _seenCauses.clear();
    _warnedCauses.clear();
  }
}
