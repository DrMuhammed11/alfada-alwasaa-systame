/// Host Load — the kernel's one-minute runnable-task average per CPU.
///
/// Android and Linux expose this through `/proc/loadavg`; platforms without
/// that source omit the axis. The kernel average is not reported during the
/// first minute of device uptime, because it still describes boot.
library;

import 'dart:io' show File, Platform;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

const double kSystemLoadGood = 0.7;
const double kSystemLoadPoor = 2.0;
const double kSystemLoadMinUptimeSeconds = 60.0;
const int kSystemLoadScopeCode = 4;

Map<String, Object?>? computeSystemLoad({
  required double load,
  required int cpus,
  required double uptimeSeconds,
}) {
  if (!load.isFinite || load < 0 || cpus < 1) return null;
  if (!uptimeSeconds.isFinite || uptimeSeconds < kSystemLoadMinUptimeSeconds) {
    return null;
  }
  final loadPerCpu = load / cpus;
  final score = linearScore(loadPerCpu, kSystemLoadGood, kSystemLoadPoor);
  return <String, Object?>{
    'score': score,
    'rating': ratingFor(score),
    'loadPerCpu': (loadPerCpu * 1000).round() / 1000,
    'load': (load * 1000).round() / 1000,
    'cpus': cpus,
    'scopeCode': kSystemLoadScopeCode,
    'caption': '1-minute load per CPU',
  };
}

/// Read `/proc/loadavg` and `/proc/uptime`. Missing sources are absence, never
/// zero and never a platform guess.
Map<String, Object?>? readSystemLoad() {
  try {
    final loadFile = File('/proc/loadavg');
    final uptimeFile = File('/proc/uptime');
    if (!loadFile.existsSync() || !uptimeFile.existsSync()) return null;
    final loadParts = loadFile.readAsStringSync().trim().split(RegExp(r'\s+'));
    final uptimeParts = uptimeFile.readAsStringSync().trim().split(
      RegExp(r'\s+'),
    );
    if (loadParts.isEmpty || uptimeParts.isEmpty) return null;
    final load = double.tryParse(loadParts.first);
    final uptime = double.tryParse(uptimeParts.first);
    if (load == null || uptime == null) return null;
    return computeSystemLoad(
      load: load,
      cpus: Platform.numberOfProcessors,
      uptimeSeconds: uptime,
    );
  } catch (_) {
    return null;
  }
}
