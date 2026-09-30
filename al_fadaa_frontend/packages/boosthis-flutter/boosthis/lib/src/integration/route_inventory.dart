/// Ask the app's router for the whole screen list — Flutter side.
///
/// The map can only draw screens somebody has opened. A Flutter app already
/// holds the whole list somewhere: a `MaterialApp`'s `routes` table names
/// every screen it can push, and a `GoRouter`'s configuration names every
/// route registered on it and every route nested under it, whether or not
/// anyone has been there. This module asks for that configuration, so the map
/// can show the app's whole shape with the screens nobody has reached marked
/// as not seen.
///
/// **What a live navigator cannot answer.** The `Navigator`'s running stack —
/// the routes currently pushed — is deliberately NOT used here. It is the
/// screens somebody opened, which is precisely what the map already has. A
/// stack assembled at run time (`onGenerateRoute` building destinations on
/// demand, a `Navigator` handed a `pages` list) declares nothing up front, so
/// nothing is carried from it and the answer is `unsupported`.
///
/// Three rules, the same as every other kit:
///
/// * **Ask, never read.** This reads the route configuration the developer
///   handed over. It does not read source, walk the app directory, or parse a
///   bundle.
/// * **Nothing rather than a guess.** A configuration we do not recognise —
///   and a source that cannot prove it holds the WHOLE tree — loses the whole
///   read. A half list drawn as a whole map is a lie the reader cannot see.
/// * **A quiet screen is "not seen", never "dead".** Nothing here judges a
///   screen for being unvisited.
///
/// The labels are the strings this kit files its screen rows under, because
/// the map joins the two by label. The navigator observer records
/// `route.settings.name`, which for a `MaterialApp.routes` table is the table
/// KEY, and for a `GoRouter` page is `state.name ?? state.path` — so a route
/// is listed under its declared name where it has one and its declared path
/// pattern where it does not.
library;

import '../core/safe.dart';
import '../core/telemetry.dart';
import '../observers/pii.dart' show routeLabelHasPii;

// BOOSTHIS_PART_NAME_V1 — one bound and one refusal rule for every part label.
const int kMaxPartName = 100;

/// Router families this kit can ask. The server holds the same closed list;
/// a name added here and not there is refused on arrival.
const List<String> kFlutterRouteSourceWords = <String>[
  'flutter-routes',
  'go-router',
];

/// How many entries may travel. A larger app still reports its `total`, so a
/// reader says "at least this many" rather than believing the cap.
const int kMaxRouteListEntries = 200;

/// One read of a handed-over route configuration: a status word, the router
/// family it came from (when one was recognised), and the screen names.
class RouterRead {
  const RouterRead(this.status, {this.source, this.labels = const <String>[]});

  /// 'read' | 'unsupported' | 'unreadable' — never 'off', which is the
  /// report's own answer when the whole feature is switched off.
  final String status;
  final String? source;
  final List<String> labels;
}

/// The app's whole screen list, as its own router describes it.
class RouteInventory {
  RouteInventory._();

  static Object? _handle;
  static bool _enabled = true;
  static List<String> _declared = const <String>[];
  static final Set<String> _warnedPartNameRefusals = <String>{};
  static int refusedPartNameCount = 0;

  /// Hand the kit your route configuration so it can list the app's screens
  /// itself.
  ///
  /// A reference assignment and nothing else — nothing is walked here, so this
  /// costs the app nothing at start-up and never sits in front of the first
  /// screen. The walk happens when a snapshot asks for one.
  ///
  /// What answers: a `MaterialApp`/`CupertinoApp` `routes` table (a
  /// `Map<String, WidgetBuilder>`), a `GoRouter`, or a bare list of its
  /// routes. The adapter's `BoosthisNavigatorObserver` takes the same handle
  /// and passes it here, so an app that already installs the observer adds one
  /// argument rather than a second call.
  static void registerRouteTable(Object? handle) {
    Safe.fire(() {
      _handle = handle;
    });
  }

  /// Declare screens by hand — for the parts of an app whose destinations are
  /// built at run time, where no configuration can be asked. These ride the
  /// list marked `declared`, and a screen that is both declared and read from
  /// the router is marked `both`.
  static void declareScreens(List<String> names) {
    Safe.fire(() {
      final cleaned = <String>[];
      for (final raw in names) {
        final label = safeScreenName(raw, warnOnRefusal: true);
        if (label != null && !cleaned.contains(label)) cleaned.add(label);
      }
      _declared = cleaned;
    });
  }

  /// Switch the whole screen list off. Switched off, the block still travels
  /// saying `off`, so the server can tell a developer who turned it off from a
  /// kit too old to have it.
  static void setRouteListEnabled(bool on) {
    _enabled = on;
  }

  static bool routeListEnabled() => _enabled;

  /// Test seam: forget the handed-over configuration and the declared list.
  static void resetForTests() {
    _handle = null;
    _enabled = true;
    _declared = const <String>[];
    _warnedPartNameRefusals.clear();
    refusedPartNameCount = 0;
  }

  // ── Labels ─────────────────────────────────────────────────────────────

  /// One screen name, made safe to travel — or null.
  ///
  /// A screen name is code, not user data: the developer's own word, kept as
  /// written. What is refused is anything that stopped looking like one — a
  /// name carrying an id means a RESOLVED route was handed over rather than a
  /// registration, and that is dropped rather than redacted into something
  /// that would read as a screen.
  static String? safeScreenName(
    Object? raw, {
    bool allowMethodPath = false,
    bool warnOnRefusal = false,
  }) {
    try {
      if (raw is! String) {
        refusedPartNameCount += 1;
        if (warnOnRefusal) _warnPartNameRefusal('not-string');
        return null;
      }
      final text = raw.trim();
      if (text.length > kMaxPartName) {
        refusedPartNameCount += 1;
        if (warnOnRefusal) _warnPartNameRefusal('too-long');
        return null;
      }
      if (text.isEmpty) {
        refusedPartNameCount += 1;
        if (warnOnRefusal) _warnPartNameRefusal('empty');
        return null;
      }
      if (!allowMethodPath && routeLabelHasPii(text) != null) {
        refusedPartNameCount += 1;
        if (warnOnRefusal) _warnPartNameRefusal('privacy');
        return null;
      }
      return text;
    } catch (_) {
      refusedPartNameCount += 1;
      if (warnOnRefusal) _warnPartNameRefusal('unreadable');
      return null;
    }
  }

  static void _warnPartNameRefusal(String reason) {
    if (!_warnedPartNameRefusals.add(reason)) return;
    final detail = reason == 'too-long'
        ? 'its length exceeds the $kMaxPartName-character rule'
        : reason == 'privacy'
        ? 'it contains a value-like pattern'
        : 'it is not a non-empty string';
    Telemetry.warnLine(
      '[boosthis] Part name refused because $detail. '
      'Use a non-empty, code-defined route or screen pattern of '
      '$kMaxPartName characters or fewer (for example, /users/:id).',
    );
  }

  // ── Reading a route configuration ──────────────────────────────────────

  /// Read every screen a handed-over route configuration registers.
  ///
  /// 'read'        — a configuration that names the WHOLE registered tree.
  /// 'unsupported' — nothing here could be asked: no configuration was handed
  ///                 over, or what was handed over declares nothing up front
  ///                 (a stack assembled at run time).
  /// 'unreadable'  — a configuration we recognised, in a shape we did not.
  static RouterRead readRouteTable(Object? handle) {
    if (handle == null) return const RouterRead('unsupported');
    try {
      if (handle is Map) {
        final labels = <String>[];
        for (final key in handle.keys) {
          // A non-string key is not a route table: refuse the whole read
          // rather than list the part of it we happened to understand.
          if (key is! String) {
            return const RouterRead('unreadable', source: 'flutter-routes');
          }
          final label = safeScreenName(key);
          if (label != null && !labels.contains(label)) labels.add(label);
        }
        return RouterRead('read', source: 'flutter-routes', labels: labels);
      }
      final routes = _routerRoutes(handle);
      if (routes == null) return const RouterRead('unsupported');
      final labels = <String>[];
      if (!_walkRoutes(routes, labels, 0)) {
        return const RouterRead('unreadable', source: 'go-router');
      }
      return RouterRead('read', source: 'go-router', labels: labels);
    } catch (_) {
      // Never into the host app.
      return const RouterRead('unreadable');
    }
  }

  /// Find the route list on whatever was handed over.
  ///
  /// null means there is no configuration here to read — which includes a
  /// live `Navigator` or a router whose destinations are built on demand,
  /// deliberately.
  static List<Object?>? _routerRoutes(Object handle) {
    if (handle is List) return handle;
    final dynamic h = handle;
    // GoRouter.configuration.routes — the whole registered tree.
    try {
      final dynamic configuration = h.configuration;
      if (configuration != null) {
        final dynamic routes = configuration.routes;
        if (routes is List) return routes;
      }
    } catch (_) {
      // Not a router shaped like this one; try the plainer shape below.
    }
    try {
      final dynamic routes = h.routes;
      if (routes is List) return routes;
    } catch (_) {
      // Nothing here answers to a route list at all.
    }
    return null;
  }

  /// Walk a route list and every route nested inside it.
  ///
  /// Each entry is asked for its `name`, its `path` and its nested `routes`.
  /// A shell route has children and no path of its own, which is read exactly
  /// that way: its children are walked and the shell itself is not a screen.
  /// An entry that answers to NONE of the three is a shape we do not
  /// understand, and it loses the whole read.
  static bool _walkRoutes(List<Object?> routes, List<String> out, int depth) {
    if (depth > 10) return false;
    for (final route in routes) {
      if (route == null) return false;
      final dynamic r = route;
      String? name;
      String? path;
      List<Object?>? nested;
      try {
        final dynamic v = r.name;
        if (v is String) name = v;
      } catch (_) {
        // A route family without names; its path still answers.
      }
      try {
        final dynamic v = r.path;
        if (v is String) path = v;
      } catch (_) {
        // A shell route has no path of its own.
      }
      try {
        final dynamic v = r.routes;
        if (v is List) nested = v;
      } catch (_) {
        // A leaf route need not answer to nested routes.
      }
      if (name == null && path == null && nested == null) return false;
      // The page a router builds is named `state.name ?? state.path`, so the
      // list is built the same way and the two join by label.
      final raw = name ?? path;
      if (raw != null) {
        final label = safeScreenName(raw);
        if (label != null && !out.contains(label)) out.add(label);
      }
      if (nested != null && !_walkRoutes(nested, out, depth + 1)) return false;
    }
    return true;
  }

  // ── The merged answer ──────────────────────────────────────────────────

  /// The whole screen list: what the router said, merged with what the
  /// developer declared through [declareScreens], each entry saying where it
  /// came from. Neither list overwrites the other — a screen in both is
  /// marked `both`.
  static Map<String, Object?> routeListReport({List<String>? declared}) {
    if (!routeListEnabled()) {
      return <String, Object?>{
        'status': 'off',
        'entries': <Map<String, Object?>>[],
        'total': 0,
      };
    }
    final read = readRouteTable(_handle);
    final origin = <String, String>{};
    for (final label in read.labels) {
      if (!origin.containsKey(label)) origin[label] = 'framework';
    }
    for (final raw in declared ?? _declared) {
      final label = safeScreenName(raw);
      if (label == null) continue;
      origin[label] = origin.containsKey(label) ? 'both' : 'declared';
    }
    final all = origin.keys.toList()..sort();
    final entries = <Map<String, Object?>>[];
    for (final label in all) {
      if (entries.length >= kMaxRouteListEntries) break;
      entries.add(<String, Object?>{'label': label, 'from': origin[label]});
    }
    final report = <String, Object?>{
      'status': read.status,
      'entries': entries,
      'total': all.length,
    };
    if (read.source != null) report['source'] = read.source;
    return report;
  }

  /// The block a snapshot carries.
  ///
  /// A kit that HAS this feature always says something, even when the answer
  /// is "nothing was handed over": that is `unsupported`, an answer the page
  /// can word. Carrying nothing at all is reserved for a kit too old to know
  /// the question — which is a different fact, and the only way the server can
  /// tell the two apart. The single exception is a throw, where the honest
  /// answer is that this kit could not produce a block at all.
  static Map<String, Object?>? routeListForSnapshot() {
    try {
      return routeListReport();
    } catch (_) {
      return null;
    }
  }
}
