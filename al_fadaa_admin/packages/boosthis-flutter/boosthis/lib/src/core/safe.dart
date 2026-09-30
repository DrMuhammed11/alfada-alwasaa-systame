import 'dart:async';

import 'runtime_flags.dart';

/// Guest-safety helpers. THE rule for every kit: the host application can never
/// crash, slow down, or change behaviour because Boosthis is installed.
///
/// Every public entry point in this kit runs its body through `Safe.run`, so a
/// bug anywhere inside the kit degrades to "no measurement" instead of an
/// exception thrown into the host's UI isolate. Errors are counted and surfaced
/// only through the kit's own debug channel — never re-thrown, never printed to
/// the host's output (except a single dev-only line when BOOSTHIS_DEBUG is on).
///
/// Mirrors `safe.rb` / RN `safe.ts`: only ever wrap Boosthis-OWNED logic, never
/// a host-provided callback — a throw there is the host's own bug and swallowing
/// it would change the host app's behaviour.
class Safe {
  Safe._();

  static const int maxRecent = 20;

  static int _errors = 0;
  static final List<String> _recent = <String>[];

  /// Run [fn], returning [fallback] if it throws for any reason.
  static T run<T>(T fallback, T Function() fn) {
    try {
      return fn();
    } catch (e) {
      note(e);
      return fallback;
    }
  }

  /// Run [fn] for its side effects only. Never throws.
  static void fire(void Function() fn) {
    try {
      fn();
    } catch (e) {
      note(e);
    }
  }

  /// Run an async Boosthis-owned block, returning [fallback] on any throw or
  /// rejection. Never lets a rejection escape into the host UI isolate.
  static Future<T> runAsync<T>(T fallback, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      note(e);
      return fallback;
    }
  }

  /// Fire-and-forget a Boosthis-owned async op, swallowing any rejection (and
  /// any synchronous throw while starting it). Use for `void thing()` chains so
  /// they can never become an unhandled error at the host root.
  static void fireAsync(Future<void> Function() op) {
    try {
      // ignore: unawaited_futures
      Future<void>(op).catchError((Object e) => note(e));
    } catch (e) {
      note(e);
    }
  }

  static void note(Object e) {
    // Type + message only, never a stack trace or interpolated host data:
    // this string can be shown in the in-app bubble.
    var line = '${e.runtimeType}: $e';
    if (line.length > 200) line = line.substring(0, 200);
    _errors += 1;
    _recent.add(line);
    if (_recent.length > maxRecent) _recent.removeAt(0);
    if (RuntimeFlags.debug) {
      // ignore: avoid_print
      print('[boosthis] $line');
    }
  }

  static int get errorCount => _errors;

  /// Oldest-first copy of the recent-errors ring.
  static List<String> get recentErrors => List<String>.from(_recent);

  /// Test seam only.
  static void reset() {
    _errors = 0;
    _recent.clear();
  }
}
