/// Boosthis host-suspend sensor (Flutter) — port of the shared cross-runtime
/// sensor (Ruby's suspend_sensor.rb, PHP's SuspendSensor.php, Go's
/// suspend_sensor.go, Node's suspendSensor.ts, .NET's SuspendSensor.cs).
///
/// On a device, the OS SUSPENDS the app when it is backgrounded (or the process
/// is frozen for battery): `Timer`s fire tens of seconds late and the first
/// frames after a resume pay the wake cost. A suspend-poisonable meter (frame
/// floor / worst freeze / scheduler latency) would otherwise record those gaps
/// as terrifying reds even though no user-facing work was ever stalled. This is
/// the shared detector such meters consult so they can DISCOUNT — never hide —
/// readings attributable to a suspend.
///
/// The detection rule and wire numbers are FROZEN across every runtime and are
/// copied byte-for-byte from the Ruby sibling:
///   - An activity boundary arriving after a gap >= [suspendGapMs] (10s) with
///     no activity in between is a WAKE — the idle gap before it is where a
///     suspend can have happened.
///   - For [suspendWakeWindowMs] (60s) after a wake, samples reflect resume
///     cost, not the app's own steady-state code, so a suspend-poisonable meter
///     discounts any reading whose timestamp falls inside that window.
///
/// PRIVACY. Timestamps and counts only; nothing here sees a route/URL/customer
/// string. The ONLY fields that reach the wire are `suspendDiscounts` and
/// `suspendWorstMs` (the server's closed shape allowlists exactly those two).
/// This class exposes the two numbers; the poisonable meter attaches them.
///
/// GUEST-SAFETY. Wired onto the EXISTING activity boundary (the lifecycle /
/// frame path the adapter already drives), never a new timer or poller. All
/// work runs through Safe/Store, so a bug degrades to "no discount".
library;

import '../core/runtime_flags.dart';
import '../core/safe.dart';
import '../core/store.dart';
import '../core/telemetry.dart';

/// The host-suspend sensor. Static (one per isolate), mirroring the sibling
/// module shape.
class SuspendSensor {
  SuspendSensor._();

  // ── Shared constants (byte-parity with every runtime) ──────────────────────

  /// An idle gap at/above this (ms) is long enough for the host to have
  /// suspended the app; the wake after it opens a discount window.
  /// (Ruby SUSPEND_GAP_MS.)
  static const int suspendGapMs = 10000;

  /// How long (ms) after a wake samples are attributed to resume cost rather
  /// than the app's own code. (Ruby SUSPEND_WAKE_WINDOW_MS.)
  static const int suspendWakeWindowMs = 60000;

  /// Bounds the retained wake-window ring so a long-lived install on a flaky
  /// host can never grow it unbounded. (Ruby SUSPEND_MAX_WAKE_WINDOWS.)
  static const int suspendMaxWakeWindows = 256;

  // ── Cross-request state keys (identical strings to the Ruby sibling) ────────
  static const String _keyLastActivity = 'suspend.lastActivityMs';
  static const String _keyWakeCount = 'suspend.wakeCount';
  static const String _keyWakeWindows = 'suspend.wakeWindows';
  static const String _keyWorstMs = 'suspend.worstMs';

  /// Observe one activity boundary. Detects a wake after a suspicious idle gap
  /// and, when found, opens a discount window and returns the gap in ms;
  /// returns 0 when this arrival was not a wake. No-op (returns 0) under the
  /// kill-switch. Never throws. Mirrors Ruby `note_request_boundary`.
  static int noteBoundary() {
    if (RuntimeFlags.disabled) return 0;
    return Safe.run(0, () {
      final now = Telemetry.nowMs();
      final last = _asInt(Store.get(_keyLastActivity, 0));

      var gap = 0;
      if (last > 0) {
        final delta = now - last;
        if (delta >= suspendGapMs) {
          gap = delta;
          _openWakeWindow(now);
        }
      }
      Store.set(_keyLastActivity, now);
      return gap;
    });
  }

  /// True when [tsMs] falls inside any recorded post-wake window (resume-cost
  /// territory). A suspend-poisonable meter calls this per sample and discounts
  /// the ones that return true. Pure read over the bounded ring. Mirrors Ruby
  /// `in_wake_window?`.
  static bool inWakeWindow(int tsMs) {
    if (RuntimeFlags.disabled) return false;
    return Safe.run(false, () {
      final windows = Store.get(_keyWakeWindows, const <Object?>[]);
      if (windows is! List) return false;
      for (final w in windows) {
        if (w is! List || w.length < 2) continue;
        final start = _asInt(w[0]);
        final finish = _asInt(w[1]);
        if (tsMs >= start && tsMs <= finish) return true;
      }
      return false;
    });
  }

  /// Record that a reading of [ms] was discounted because it fell in a wake
  /// window, keeping the worst such reading. No-op under the kill-switch or for
  /// a non-positive reading. Never throws. Mirrors Ruby `note_discounted_reading`.
  static void noteDiscountedReading(int ms) {
    if (RuntimeFlags.disabled || ms <= 0) return;
    Safe.fire(() {
      Store.update(_keyWorstMs, (cur) {
        final c = _asInt(cur);
        return ms > c ? ms : c;
      });
    });
  }

  /// How many suspend-suspicious wakes have been seen this session. Ships as
  /// the wire field `suspendDiscounts` (allowlisted) — attached by the
  /// poisonable meter only when > 0. Mirrors Ruby `discount_count`.
  static int discountCount() {
    if (RuntimeFlags.disabled) return 0;
    return Safe.run(0, () => _asInt(Store.get(_keyWakeCount, 0)));
  }

  /// Worst discounted reading (ms) seen inside a wake window this session, or 0
  /// when none. Ships as the wire field `suspendWorstMs` (allowlisted) —
  /// attached by the poisonable meter only when > 0. Mirrors Ruby `worst_ms`.
  static int worstMs() {
    if (RuntimeFlags.disabled) return 0;
    return Safe.run(0, () => _asInt(Store.get(_keyWorstMs, 0)));
  }

  /// Wipe all sensor state (wired into forget() / the parity harness).
  /// Idempotent. Mirrors Ruby `clear`.
  static void clear() {
    Safe.fire(() {
      Store.delete(_keyLastActivity);
      Store.delete(_keyWakeCount);
      Store.delete(_keyWakeWindows);
      Store.delete(_keyWorstMs);
    });
  }

  /// Record the newly-opened post-wake window and bump the wake count under the
  /// same read-modify-write path. Mirrors Ruby `open_wake_window`.
  static void _openWakeWindow(int now) {
    Store.update(_keyWakeCount, (cur) => _asInt(cur) + 1);
    Store.update(_keyWakeWindows, (cur) {
      final windows = <Object?>[];
      if (cur is List) windows.addAll(cur);
      windows.add(<Object?>[now, now + suspendWakeWindowMs]);
      // Bound the ring: drop the oldest windows first.
      final overflow = windows.length - suspendMaxWakeWindows;
      if (overflow > 0) windows.removeRange(0, overflow);
      return windows;
    });
  }

  /// Coerce a Store-decoded value (JSON numbers can arrive as int or double)
  /// into an int; anything non-numeric reads as 0.
  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return 0;
  }
}
