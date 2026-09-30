/// BoosthisProfiler — opt-in widget rebuild-storm meter.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. Imports `package:flutter`; NOT compiled
/// or analysed by this workspace's meter-parity harness. See
/// `../../../PORT_CONTRACT.md`.
///
/// `debugProfileBuildsEnabled` is debug-only, so the release-build reRenders
/// meter is this opt-in wrapper — the exact same deal as RN's render Profiler.
/// Wrap a screen (or any subtree) and give it a stable `id`:
///
///     BoosthisProfiler(
///       id: 'Feed',
///       child: FeedScreen(),
///     )
///
/// It counts how often its subtree rebuilds and forwards the count + a stable
/// id to the pure package's reRenders collector. Recording it makes the axis
/// leave its release-build "not measurable" state. NO rebuild-storm math here.
///
/// The recording is done in a post-frame callback (after the host's own build
/// has committed) and is fully guarded, so it can never crash the host during
/// the build/commit phase — mirroring the RN Profiler's onRender safety note.
library;

import 'package:boosthis/boosthis.dart' as boosthis;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Wrap a subtree to feed the pure package's reRenders axis. Opt-in.
class BoosthisProfiler extends StatefulWidget {
  const BoosthisProfiler({super.key, required this.id, required this.child});

  /// Stable label for this subtree — by convention the screen name. Never a
  /// user-derived string (it may reach the wire as a route/screen label).
  final String id;

  /// The subtree whose rebuilds are counted.
  final Widget child;

  @override
  State<BoosthisProfiler> createState() => _BoosthisProfilerState();
}

class _BoosthisProfilerState extends State<BoosthisProfiler> {
  @override
  Widget build(BuildContext context) {
    // `build` runs during the commit phase, OUTSIDE any error boundary, so a
    // throw here could crash the host. We do NOT wrap `child` in a guard that
    // would swallow the HOST's own build errors and change its behaviour; we
    // only defer Boosthis's own recording to a post-frame callback and guard
    // that. Recording after commit also avoids re-entrancy with the frame
    // timings callback.
    _scheduleRecord();
    return widget.child;
  }

  void _scheduleRecord() {
    try {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        try {
          boosthis.Boosthis.recordReRender(id: widget.id);
        } catch (_) {
          /* perf bookkeeping must never crash the host app */
        }
      });
    } catch (_) {
      /* scheduling failed — drop the sample rather than throw */
    }
  }
}
