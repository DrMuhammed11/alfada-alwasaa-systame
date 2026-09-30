/// Extra infrastructure meters (Flutter) — the honest-absence file.
///
/// Where the Ruby kit's ExtraMeters could port GC/heap/allocation/thread axes
/// from MRI's `GC.stat` and `Thread.list`, a Flutter app in a RELEASE build
/// CANNOT. The Dart VM's allocation profile and GC events are only reachable
/// over the VM Service, which is compiled OUT of release builds (the same
/// verdict Hermes forced on the React Native kit). So there is no honest source
/// here for:
///   - gcPressure     (share of wall time in GC) — VM Service only. Cannot know.
///   - heapGrowth     (live-slot slope)          — VM Service only. Cannot know.
///   - allocationRate (objects/s)                — VM Service only. Cannot know.
///   - isolate-level scheduling beyond the main isolate's own event loop — the
///     kit cannot see into isolates the host spawned. Cannot know.
///
/// PER THE CONTRACT, a "cannot-know" axis MUST NOT appear as a warming tile that
/// warms forever. The honest whole-process memory signal a device kit CAN read
/// (`ProcessInfo.currentRss` trend) is owned by `runtime_vitals.dart`
/// (residentGrowth) — the correct home for it, and the substitute the ceiling
/// note names. Restating it here under a second key would violate House Rule 5
/// (one signal, one key, one collector).
///
/// This file therefore EMITS NOTHING. It exists so the meters group carries the
/// same structural part every sibling kit carries (see PORT_CONTRACT §Parts),
/// while being explicit — in code and comment — that Flutter has no honest
/// extra-meter axis of its own. [addExtraMeters] is a guest-safe no-op; it is
/// wired into the snapshot path exactly where the Ruby sibling's is, so the
/// call site does not have to special-case Flutter.
///
/// ADDITIVE + display-only + GUEST-SAFE, like the rest of the kit.
library;

import '../core/runtime_flags.dart';
import '../core/safe.dart';

/// Extra-meters collector (static, one per isolate).
class ExtraMeters {
  ExtraMeters._();

  /// Record ONE runtime-health sample. No honest release-build source exists on
  /// Flutter (see the file header), so this is deliberately a no-op — never a
  /// fabricated sample. Kept for structural parity with the sibling collectors'
  /// per-boundary `sample()` call so the wiring is identical.
  static void sample() {
    // Intentionally empty: nothing measurable without the VM Service.
  }

  /// Attach every currently-available extra meter to [axes]. Flutter has none
  /// in a release build (GC/heap need the VM Service, which is compiled out),
  /// so this adds NOTHING — an honest absence, not a warming tile. Guest-safe.
  static void addExtraMeters(Map<String, Object?> axes) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      // No axes: every candidate signal (gcPressure / heapGrowth /
      // allocationRate) requires the VM Service, which release builds strip.
      // residentGrowth (the honest substitute) lives in RuntimeVitals.
    });
  }
}
