// Scheduler / Zone plumbing — the counting Zone that FEEDS the `timerLeaks`
// axis owned by observers/timer_leaks.dart.
//
// Flutter-only, pure Dart. `Boosthis.run(body)` runs the host's app body inside
// a custom Zone whose ZoneSpecification intercepts `createTimer` and
// `createPeriodicTimer` (and their cancellation / one-shot firing). Every timer
// is tagged with the route that was on top of the nav stack when it was created.
// When that route is later retired (popped), any timer it created that is STILL
// alive is a leak — reported to the axis via noteRouteRetired().
//
// SEPARATION OF CONCERNS: the AXIS math + counters live in
// observers/timer_leaks.dart; this file is ONLY the Zone plumbing that installs
// tracking and calls that module's note* hooks:
//   installTimerLeakTracking() — once, when the Zone is installed;
//   noteTimerCreated()         — on createTimer / createPeriodicTimer;
//   noteTimerCancelled()       — on Timer.cancel() or a one-shot firing;
//   noteRouteRetired(surviving, survivingPeriodic:) — on route retire.
// The route→timers bookkeeping needed to compute "surviving under this route"
// is this file's job (the Zone is the only place that sees each timer).
//
// GUEST-SAFETY: the Zone delegates every operation to the parent Zone
// unchanged; the kit only OBSERVES. `runZonedGuarded` chains to the host's own
// error handler and never suppresses. Timer callbacks run exactly as the host
// scheduled them — the counting bookkeeping is wrapped so a throw inside it can
// never change the host's timer behaviour.

import 'dart:async';

import '../observers/timer_leaks.dart';
import '../meters/request_error_timer.dart';

/// One tracked timer created inside the Boosthis Zone.
class _TrackedTimer {
  _TrackedTimer(this.route, this.periodic);

  /// The nav-stack route label that owned the timer at creation time (or null).
  final String? route;

  /// True for a periodic timer (createPeriodicTimer).
  final bool periodic;

  /// Still alive (not cancelled and, for one-shot timers, not yet fired).
  bool alive = true;
}

/// The counting Zone factory + route-retire bookkeeping. Static-only.
class ZoneTimers {
  ZoneTimers._();

  /// Resolves the current top-of-stack route label at timer-creation time.
  /// Wired to NavTracker.currentRoute by the kit; injectable so this file
  /// carries no import cycle with nav_tracker.
  static String? Function()? currentRouteResolver;

  /// Every timer still tracked (removed when cancelled / fired). Bounded so a
  /// long-lived app can't grow this without bound: the oldest DEAD entries are
  /// dropped first; if all are alive the oldest is dropped (it can no longer be
  /// attributed to a retiring route, which is the honest degradation).
  static const int _maxTracked = 4000;
  static final List<_TrackedTimer> _tracked = <_TrackedTimer>[];

  static bool _installed = false;

  /// Run [body] inside the counting Zone. Any uncaught async error is handed to
  /// [onError] if provided, else forwarded to the parent Zone's handler — never
  /// suppressed. Installs timer-leak tracking on first call.
  static R? run<R>(R Function() body,
      {void Function(Object, StackTrace)? onError}) {
    if (!_installed) {
      _installed = true;
      installTimerLeakTracking();
    }

    final spec = ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        final tracked = _track(periodic: false);
        return _CancelObservingTimer(parent.createTimer(zone, duration, () {
          // A one-shot timer that fires is no longer a leak candidate.
          _retire(tracked);
          f();
        }), tracked);
      },
      createPeriodicTimer: (self, parent, zone, duration, f) {
        final tracked = _track(periodic: true);
        return _CancelObservingTimer(
          parent.createPeriodicTimer(zone, duration, f),
          tracked,
        );
      },
    );

    final parent = Zone.current;
    return runZonedGuarded<R>(
      body,
      (error, stack) {
        if (onError != null) {
          onError(error, stack);
        } else {
          parent.handleUncaughtError(error, stack);
        }
      },
      zoneSpecification: spec,
    );
  }

  static _TrackedTimer _track({required bool periodic}) {
    String? route;
    try {
      route = currentRouteResolver?.call();
    } catch (_) {
      route = null;
    }
    final t = _TrackedTimer(route, periodic);
    _tracked.add(t);
    _trim();
    // Tell the axis a timer is now live.
    noteTimerCreated();
    noteHealthTimerCreated();
    return t;
  }

  /// A tracked timer became inactive (cancelled or one-shot fired). Idempotent —
  /// only the first retirement decrements the live count.
  static void _retire(_TrackedTimer t) {
    if (!t.alive) return;
    t.alive = false;
    noteTimerCancelled();
    noteHealthTimerRetired();
  }

  /// Called by NavTracker when a route is popped: reports how many timers this
  /// route created that are STILL alive (leaks) to the axis, then forgets them.
  static void onRouteRetired(String route) {
    var surviving = 0;
    var survivingPeriodic = 0;
    final keep = <_TrackedTimer>[];
    for (final t in _tracked) {
      if (t.route == route) {
        if (t.alive) {
          surviving++;
          if (t.periodic) survivingPeriodic++;
          // A leaked timer is still ticking; stop attributing it to a route
          // (its route is gone) but it remains live for the live-count. We do
          // NOT mark it dead — it genuinely is still alive.
          keep.add(_TrackedTimer(null, t.periodic)..alive = t.alive);
        }
        // dead timers under this route are simply dropped
      } else {
        keep.add(t);
      }
    }
    _tracked
      ..clear()
      ..addAll(keep);
    noteRouteRetired(surviving, survivingPeriodic: survivingPeriodic);
  }

  static void _trim() {
    if (_tracked.length <= _maxTracked) return;
    // Drop oldest DEAD entries first.
    _tracked.removeWhere((t) => !t.alive && _tracked.length > _maxTracked);
    while (_tracked.length > _maxTracked) {
      _tracked.removeAt(0);
    }
  }

  /// Reset Zone-side bookkeeping (forget() hook + tests). Does NOT reset the
  /// axis counters (that's resetTimerLeaks()); the kit resets both.
  static void reset() {
    _tracked.clear();
    _installed = false;
  }
}

/// A Timer wrapper that observes cancellation so a cancelled periodic timer
/// stops counting toward leaks. Delegates every member to the wrapped Timer.
class _CancelObservingTimer implements Timer {
  _CancelObservingTimer(this._inner, this._tracked);

  final Timer _inner;
  final _TrackedTimer _tracked;

  @override
  void cancel() {
    ZoneTimers._retire(_tracked);
    _inner.cancel();
  }

  @override
  bool get isActive => _inner.isActive;

  @override
  int get tick => _inner.tick;
}
