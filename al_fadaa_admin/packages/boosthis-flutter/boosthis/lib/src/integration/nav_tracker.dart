// Navigation tracker — pure-Dart route stack + navigation timing axes.
//
// Driven by the adapter's NavigatorObserver (which lives in the boosthis_flutter
// package and calls into this pure module on didPush/didPop/didReplace). This
// file holds NO Flutter import: the observer translates Route callbacks into the
// plain `recordNavTap` / `recordScreenMountStart` / `pushRoute` / `popRoute`
// calls below.
//
// navDeadTime — the Flutter sibling of the RN navDeadTime axis. It measures the
// "dead time" between a user's tap and the destination screen's mount STARTING:
// the gap where nothing visibly happens. A tap timestamp is correlated with the
// NEXT route push that starts within 15s of it, and the p75 gap is scored.
// Thresholds on p75: good <= 200, poor >= 1000. Pending until >= 5 navigations.
// pressToScreen holds that press until the destination's OWN screen arrival
// sample completes. It measures press → usable, not the sum of two percentiles.
// The two legs are percentiles over the same completed navigations.
//
// HONESTY / INVARIANTS (byte-identical to the RN axis):
//   - NEVER feeds the composite Speed score. Display-only, additive.
//   - OMIT WHILE WARMING: readNavDeadTime() is pending until >= 5 navs.
//   - NUMERIC-ONLY on the wire: { score, rating, p75Ms, navCount }. No caption.
//   - Bands: linearScore(p75Ms, good=200, poor=1000).
//
// GUEST-SAFETY: recorders are plain best-effort counters; a throw can never
// reach the host. No host globals wrapped, no timers.

import '../core/safe.dart';
import '../meters/meter_axes.dart' show linearScore, ratingFor;
import 'zone_timers.dart';

/// Route stack + navigation dead-time axis. Static-only.
class NavTracker {
  NavTracker._();

  /// Dead-time score bands (ms). <=200ms feels immediate (100); >=1s reads as a
  /// dead tap (0). Byte-identical to the RN NAV_DEAD_TIME_THRESHOLDS.
  static const int navDeadTimeGood = 200;
  static const int navDeadTimePoor = 1000;
  /// A whole wait of three seconds is already the complaint this axis measures.
  static const int pressToScreenGood = 1000;
  static const int pressToScreenPoor = 3000;

  /// A route push is attributed to a tap only if it starts within this window
  /// after the tap — beyond it, the push isn't this tap's navigation.
  static const int navCorrelationMs = 15000;

  /// Navigations needed before the axis leaves "pending".
  static const int navDeadTimeMinNavs = 5;

  /// Bounded ring of per-nav dead-time gaps.
  static const int navRingCap = 300;

  /// The most recent tap timestamp still eligible to correlate with a mount.
  /// Consumed (set null) once a mount correlates, so one tap yields at most one
  /// nav.
  static double? _lastTapAt;

  /// Per-nav dead-time gaps (ms).
  static final List<double> _gaps = <double>[];
  static final List<({double dead, double whole})> _joined = [];
  static double? _openPressAt;
  static double? _openMountAt;
  static int _unjoinedPastBound = 0;
  static int _unjoinedNoScreen = 0;
  static int _unjoinedNoTiming = 0;

  /// Pure-Dart route stack of code-defined labels (never a raw path/URL). The
  /// adapter's NavigatorObserver keeps this in sync with the app's Navigator.
  static final List<String> _stack = <String>[];

  // ─── Route stack (driven by NavigatorObserver) ────────────────────────────

  /// Push a route label onto the stack AND treat it as a screen-mount start for
  /// the dead-time correlation. Best-effort, never throws.
  static void pushRoute(String label, double now) {
    Safe.fire(() {
      _stack.add(label);
      _recordScreenMountStart(now);
    });
  }

  /// Pop the top route label off the stack. Best-effort, never throws. Retiring
  /// a route hands the Zone-timer tracker a chance to count any timers created
  /// under it that are still alive (the `timerLeaks` axis).
  static void popRoute() {
    Safe.fire(() {
      if (_stack.isEmpty) return;
      final retired = _stack.removeLast();
      ZoneTimers.onRouteRetired(retired);
    });
  }

  /// Replace the top route label (didReplace). Best-effort, never throws.
  static void replaceRoute(String label, double now) {
    Safe.fire(() {
      if (_stack.isNotEmpty) {
        _stack[_stack.length - 1] = label;
      } else {
        _stack.add(label);
      }
      _recordScreenMountStart(now);
    });
  }

  /// The current top-of-stack route label, or null when empty.
  static String? get currentRoute => _stack.isEmpty ? null : _stack.last;

  /// Depth of the route stack.
  static int get depth => _stack.length;

  // ─── navDeadTime axis ──────────────────────────────────────────────────────

  /// Record a tap timestamp (from the fid/interaction sampler). The next route
  /// push within the bound will correlate to it. Best-effort, never throws.
  static void recordNavTap(double now) {
    Safe.fire(() {
      // A second press before any mount means the first never reached a screen.
      if (_lastTapAt != null) _unjoinedNoScreen++;
      _lastTapAt = now;
    });
  }

  /// Record the START of a screen mount (route push). If a tap is pending within
  /// the correlation window, bank the gap as one navigation and consume the tap.
  static void recordScreenMountStart(double now) {
    Safe.fire(() => _recordScreenMountStart(now));
  }

  static void _recordScreenMountStart(double now) {
    // A new mount supersedes the previous destination, even if it has no press.
    forgetPendingScreenPress();
    if (_lastTapAt == null) return;
    final tapAt = _lastTapAt!;
    final gap = now - tapAt;
    // Consume the tap regardless — a mount that arrives ends this tap's
    // candidacy either way (a later, unrelated mount must not reuse it).
    _lastTapAt = null;
    if (gap < 0) {
      _unjoinedNoScreen++;
      return;
    }
    if (gap > navCorrelationMs) {
      _unjoinedPastBound++;
      return;
    }
    _gaps.add(gap);
    if (_gaps.length > navRingCap) {
      _gaps.removeRange(0, _gaps.length - navRingCap);
    }
    // Dead time is banked now; the whole waits for THIS screen's sample.
    _openPressAt = tapAt;
    _openMountAt = now;
  }

  /// This destination's own per-screen reading completed at [now].
  /// Called with that reading's completion clock, not a second clock read.
  /// Best-effort, never throws.
  static void recordScreenUsable(double now) {
    Safe.fire(() {
      final pressAt = _openPressAt;
      final mountAt = _openMountAt;
      if (pressAt == null || mountAt == null) {
        forgetPendingScreenPress();
        return;
      }
      final whole = now - pressAt;
      final dead = mountAt - pressAt;
      if (!whole.isFinite || !dead.isFinite ||
          whole < 0 || dead < 0 || whole < dead) {
        // A backwards clock cannot give this screen a usable interval, but
        // its joined press must still be visible as one we could not time.
        forgetPendingScreenPress();
        return;
      }
      _joined.add((dead: dead, whole: whole));
      // Clear only after banking the reading; a completed screen must not be
      // mistaken for one abandoned before its sample arrived.
      _clearPendingScreenPress();
      if (_joined.length > navRingCap) {
        _joined.removeRange(0, _joined.length - navRingCap);
      }
    });
  }

  /// An abandoned screen must not lend its press to a later screen's frame.
  /// Best-effort, never throws.
  static void forgetPendingScreenPress() {
    Safe.fire(() {
      // The mount was joined, but its own reading never arrived. Count it
      // once even if several cleanup paths attempt to forget this screen.
      if (_openPressAt != null) _unjoinedNoTiming++;
      _clearPendingScreenPress();
    });
  }

  static void _clearPendingScreenPress() {
    _openPressAt = null;
    _openMountAt = null;
  }

  /// Nearest-rank p75 of an unordered list (does not mutate). 0 when empty.
  /// Byte-identical index policy to the RN navDeadTime p75.
  static double _p75(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    var idx = (0.75 * sorted.length).ceil() - 1;
    if (idx < 0) idx = 0;
    if (idx > sorted.length - 1) idx = sorted.length - 1;
    return sorted[idx];
  }

  /// The Navigation Dead Time axis, or a pending reading while warming up (<5
  /// navs). Pure read — never mutates state, never throws. Numbers-only wire
  /// shape: { score, rating, p75Ms, navCount }.
  static Map<String, Object?> readNavDeadTime() {
    return Safe.run<Map<String, Object?>>(
      <String, Object?>{
        'score': null,
        'rating': 'pending',
        'p75Ms': null,
        'navCount': 0,
      },
      () {
        final navCount = _gaps.length;
        if (navCount < navDeadTimeMinNavs) {
          return <String, Object?>{
            'score': null,
            'rating': 'pending',
            'p75Ms': null,
            'navCount': navCount,
          };
        }
        final gap = _p75(_gaps);
        final score = linearScore(
          gap,
          navDeadTimeGood.toDouble(),
          navDeadTimePoor.toDouble(),
        );
        return <String, Object?>{
          'score': score,
          'rating': ratingFor(score),
          'p75Ms': gap.round(),
          'navCount': navCount,
        };
      },
    );
  }

  /// Whole press → usable and both legs over the SAME joined navigations.
  /// Counts ride even while pending: slow and screenless presses cannot vanish
  /// merely because there are not yet five complete readings.
  static Map<String, Object?> readPressToScreen() {
    final pending = <String, Object?>{
      'score': null,
      'rating': 'pending',
      'p75Ms': null,
      'navCount': 0,
      'deadP75Ms': null,
      'settleP75Ms': null,
      'unjoinedPastBound': _unjoinedPastBound,
      'unjoinedNoScreen': _unjoinedNoScreen,
      'unjoinedNoTiming': _unjoinedNoTiming,
      'boundMs': navCorrelationMs,
    };
    return Safe.run<Map<String, Object?>>(pending, () {
      final navCount = _joined.length;
      final base = <String, Object?>{
        ...pending,
        'navCount': navCount,
        'unjoinedPastBound': _unjoinedPastBound,
        'unjoinedNoScreen': _unjoinedNoScreen,
        'unjoinedNoTiming': _unjoinedNoTiming,
      };
      if (navCount < navDeadTimeMinNavs) return base;
      final whole = _p75(_joined.map((n) => n.whole).toList());
      final score = linearScore(whole, pressToScreenGood, pressToScreenPoor);
      return <String, Object?>{
        ...base,
        'score': score,
        'rating': ratingFor(score),
        'p75Ms': whole.round(),
        'deadP75Ms': _p75(_joined.map((n) => n.dead).toList()).round(),
        'settleP75Ms':
            _p75(_joined.map((n) => n.whole - n.dead).toList()).round(),
      };
    });
  }

  /// True while a tap is pending correlation (introspection/tests).
  static bool get hasPendingTap => _lastTapAt != null;

  /// Correlated navigation count so far (introspection/tests).
  static int get navCount => _gaps.length;

  /// Reset all state (forget() hook + tests). Idempotent.
  static void reset() {
    Safe.fire(() {
      _lastTapAt = null;
      _gaps.clear();
      _joined.clear();
      // Forgetting the install clears observations; it is not another
      // abandoned navigation to add to the counts being erased.
      _clearPendingScreenPress();
      _unjoinedPastBound = 0;
      _unjoinedNoScreen = 0;
      _unjoinedNoTiming = 0;
      _stack.clear();
    });
  }
}
