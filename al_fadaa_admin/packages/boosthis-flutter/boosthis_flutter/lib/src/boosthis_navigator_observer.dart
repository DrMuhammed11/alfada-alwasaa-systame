/// BoosthisNavigatorObserver — opt-in navigation timing.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. Imports `package:flutter`; NOT compiled
/// or analysed by this workspace's meter-parity harness. See
/// `../../../PORT_CONTRACT.md`.
///
/// Add it to your `MaterialApp` (or `CupertinoApp` / `Navigator`):
///
///     MaterialApp(
///       navigatorObservers: [BoosthisNavigatorObserver()],
///       ...
///     )
///
/// It forwards route transitions to the pure package's nav tracker (nav dead
/// time, screens, per-screen attribution). It records only the route's
/// templated NAME — never arguments (which may carry user data / ids). Every
/// override is wrapped so it can never throw into the framework's navigation.
library;

import 'package:boosthis/boosthis.dart' as boosthis;
import 'package:flutter/widgets.dart';

/// Feeds route pushes/pops/replaces to the pure package's nav tracker.
class BoosthisNavigatorObserver extends NavigatorObserver {
  /// Optionally hand over the app's route configuration at the same time as
  /// the observer, so the map can draw the screens nobody opened as well as
  /// the ones this session reached:
  ///
  ///     MaterialApp(
  ///       routes: appRoutes,
  ///       navigatorObservers: [BoosthisNavigatorObserver(routes: appRoutes)],
  ///     )
  ///
  /// or, with go_router:
  ///
  ///     GoRouter(
  ///       routes: appRoutes,
  ///       observers: [BoosthisNavigatorObserver(routes: router)],
  ///     )
  ///
  /// Nothing is walked here — the reference is kept and read when a snapshot
  /// is built. A `routes` of null leaves the kit saying it was handed no
  /// configuration, which is what the map then reports.
  BoosthisNavigatorObserver({Object? routes}) {
    if (routes != null) {
      try {
        boosthis.RouteInventory.registerRouteTable(routes);
      } catch (_) {
        /* a hand-off must never break the host app */
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('push', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('pop', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record('replace', newRoute, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record('remove', route, previousRoute);
    super.didRemove(route, previousRoute);
  }

  void _record(String action, Route<dynamic>? route, Route<dynamic>? previous) {
    try {
      boosthis.Boosthis.recordNav(
        action: action,
        // Templated route name only — never RouteSettings.arguments.
        route: _label(route),
        previousRoute: _label(previous),
      );
    } catch (_) {
      /* nav bookkeeping must never crash the host's navigation */
    }
  }

  static String? _label(Route<dynamic>? route) {
    try {
      return route?.settings.name;
    } catch (_) {
      return null;
    }
  }
}
