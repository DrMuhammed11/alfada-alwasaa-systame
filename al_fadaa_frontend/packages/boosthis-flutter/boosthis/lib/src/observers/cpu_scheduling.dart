/// Processor, thread, and scheduling readings available to a pure-Dart
/// Flutter kit. Android process facts come from one read apiece of procfs.
/// iOS keeps the readings present but explicitly unmeasurable: reaching
/// task_info/task_threads would require the native side this kit does not have.
library;

import 'dart:io' show File, Platform;
import 'dart:math' as math;

import '../meters/meter_axes.dart' show linearScore, ratingFor;

const double kCpuConsumptionGoodPct = 70;
const double kCpuConsumptionPoorPct = 100;
const int kCpuConsumptionMinSamples = 3;
const int kCpuConsumptionMinSpanMs = 1000;

/// Linux exposes utime/stime in USER_HZ ticks. The procfs ABI uses 100 USER_HZ
/// ticks per second on Android, independent of the device's timer frequency.
const int kAndroidUserHz = 100;

const double kThreadGrowthGoodPerMin = 0.5;
const double kThreadGrowthPoorPerMin = 5;
const int kThreadFootprintMinSamples = 12;
const int kThreadFootprintMinSpanMs = 60000;
const int kThreadFootprintStartupExclusionMs = 60000;
const int kThreadFootprintRingCap = 240;

const int kBlockingAsyncThresholdMs = 100;
const double kBlockingAsyncGoodPerMin = 0.5;
const double kBlockingAsyncPoorPerMin = 10;
const int kBlockingAsyncMinWindowMs = 60000;

class _CpuAnchor {
  const _CpuAnchor(this.atMs, this.ticks);
  final int atMs;
  final int ticks;
}

class _ThreadPoint {
  const _ThreadPoint(this.atMs, this.threads);
  final int atMs;
  final int threads;
}

_CpuAnchor? _cpuAnchor;
int _cpuSampleCount = 0;
Map<String, Object?>? _cpuConsumption;
final List<_ThreadPoint> _threadSamples = <_ThreadPoint>[];
Map<String, Object?>? _threadReading;
int? _samplerStartedAtMs;
bool _sampleInFlight = false;

int _blockingStartedAtMs = 0;
int _blockingCount = 0;
int _blockingWorstMs = 0;

Map<String, Object?> _notMeasurable(String reason) => <String, Object?>{
      'present': true,
      'measurable': 0,
      'reason': reason,
    };

/// Called by the scheduler-latency timer which the kit already owns. No timer
/// is created here. The reads are asynchronous so opening procfs never blocks
/// the UI isolate, and overlapping ticks are discarded.
Future<void> sampleCpuScheduling(int monotonicMs) async {
  if (!Platform.isAndroid || _sampleInFlight) return;
  _sampleInFlight = true;
  try {
    final stat = await File('/proc/self/stat').readAsString();
    _recordCpuStat(monotonicMs, stat);
    final status = await File('/proc/self/status').readAsString();
    _recordThreadStatus(monotonicMs, status);
  } catch (_) {
    // procfs can disappear during process teardown. No sample is preferable to
    // a fabricated zero, and a later timer tick may try again.
  } finally {
    _sampleInFlight = false;
  }
}

/// Record the same timer's lateness for blockingAsync.
void noteCpuSchedulingTick(int monotonicMs, int latenessMs) {
  if (_blockingStartedAtMs == 0) _blockingStartedAtMs = monotonicMs;
  if (latenessMs >= kBlockingAsyncThresholdMs) {
    _blockingCount += 1;
    if (latenessMs > _blockingWorstMs) _blockingWorstMs = latenessMs;
  }
}

void _recordCpuStat(int atMs, String stat) {
  // comm is parenthesised and may itself contain spaces or parentheses. Split
  // only after its final ')' so fields 14/15 remain positions 11/12 here.
  final close = stat.lastIndexOf(')');
  if (close < 0 || close + 2 >= stat.length) return;
  final fields = stat.substring(close + 2).trim().split(RegExp(r'\s+'));
  if (fields.length <= 12) return;
  final utime = int.tryParse(fields[11]);
  final stime = int.tryParse(fields[12]);
  if (utime == null || stime == null || utime < 0 || stime < 0) return;
  recordCpuTicksForTests(atMs, utime + stime);
}

void _recordThreadStatus(int atMs, String status) {
  final match = RegExp(r'^Threads:\s*(\d+)\s*$', multiLine: true)
      .firstMatch(status);
  final threads = match == null ? null : int.tryParse(match.group(1)!);
  if (threads == null || threads <= 0) return;
  recordThreadCountForTests(atMs, threads);
}

/// cpuConsumption: Android's cumulative utime+stime, anchored and differenced.
Map<String, Object?>? readCpuConsumption() {
  if (!Platform.isAndroid) {
    return _notMeasurable(
      '/proc/self/stat is unavailable and pure Dart has no task_info CPU-time API',
    );
  }
  return _cpuConsumption;
}

/// threadFootprint: one Threads: read, never a /proc/self/task walk.
Map<String, Object?>? readThreadFootprint() {
  if (!Platform.isAndroid) {
    return _notMeasurable(
      '/proc/self/status is unavailable and pure Dart has no task_threads API',
    );
  }
  return _threadReading;
}

/// blockingAsync: count of late callbacks from the already-running timer.
Map<String, Object?>? readBlockingAsync(int monotonicMs) {
  if (_blockingStartedAtMs == 0) return null;
  final spanMs = monotonicMs - _blockingStartedAtMs;
  if (spanMs < kBlockingAsyncMinWindowMs) return null;
  final perMin = _blockingCount / (spanMs / 60000);
  final score = linearScore(
    perMin,
    kBlockingAsyncGoodPerMin,
    kBlockingAsyncPoorPerMin,
  );
  return <String, Object?>{
    'score': score,
    'rating': ratingFor(score),
    'count': _blockingCount,
    'perMin': _r1(perMin),
    'worstMs': _blockingWorstMs,
    'windowMin': _r1(spanMs / 60000),
  };
}

/// Deterministic seams also used by the proc parsers.
void recordCpuTicksForTests(int atMs, int ticks) {
  final current = _CpuAnchor(atMs, ticks);
  final anchor = _cpuAnchor;
  if (anchor == null || ticks < anchor.ticks || atMs <= anchor.atMs) {
    _cpuAnchor = current;
    _cpuSampleCount = 1;
    _cpuConsumption = null;
    return;
  }
  _cpuSampleCount += 1;
  final spanMs = atMs - anchor.atMs;
  if (_cpuSampleCount < kCpuConsumptionMinSamples ||
      spanMs < kCpuConsumptionMinSpanMs) {
    _cpuConsumption = null;
    return;
  }
  final deltaTicks = ticks - anchor.ticks;
  final cpuPct = deltaTicks * 100000 / (kAndroidUserHz * spanMs);
  final score = linearScore(
    cpuPct,
    kCpuConsumptionGoodPct,
    kCpuConsumptionPoorPct,
  );
  _cpuConsumption = <String, Object?>{
    'score': score,
    'rating': ratingFor(score),
    'cpuPct': _r1(cpuPct),
    'sampleCount': _cpuSampleCount,
    'windowSec': _r1(spanMs / 1000),
  };
}

void recordThreadCountForTests(int atMs, int threads) {
  _samplerStartedAtMs ??= atMs;
  _threadSamples.add(_ThreadPoint(atMs, threads));
  while (_threadSamples.length > kThreadFootprintRingCap) {
    _threadSamples.removeAt(0);
  }
  final cutoff = _samplerStartedAtMs! + kThreadFootprintStartupExclusionMs;
  final judged = _threadSamples.where((p) => p.atMs >= cutoff).toList();
  if (judged.length < kThreadFootprintMinSamples) {
    _threadReading = null;
    return;
  }
  final spanMs = judged.last.atMs - judged.first.atMs;
  if (spanMs < kThreadFootprintMinSpanMs) {
    _threadReading = null;
    return;
  }
  final fit = _threadSlopeAndSe(judged);
  final growth = fit[0];
  final se = fit[1];
  final abstain = growth.abs() <= se;
  final score = abstain
      ? null
      : linearScore(
          math.max(0, growth),
          kThreadGrowthGoodPerMin,
          kThreadGrowthPoorPerMin,
        );
  _threadReading = <String, Object?>{
    if (score != null) 'score': score,
    'rating': abstain ? 'not-scored' : ratingFor(score!),
    'threads': threads,
    'peakThreads': judged.map((p) => p.threads).reduce(math.max),
    'growthPerMin': _r1(growth),
    'sampleCount': judged.length,
    'windowMin': _r1(spanMs / 60000),
  };
}

List<double> _threadSlopeAndSe(List<_ThreadPoint> points) {
  final t0 = points.first.atMs;
  final xs = points.map((p) => (p.atMs - t0) / 60000).toList();
  final ys = points.map((p) => p.threads.toDouble()).toList();
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = ys.reduce((a, b) => a + b) / ys.length;
  var sxx = 0.0, sxy = 0.0;
  for (var i = 0; i < xs.length; i++) {
    sxx += (xs[i] - mx) * (xs[i] - mx);
    sxy += (xs[i] - mx) * (ys[i] - my);
  }
  final slope = sxx == 0 ? 0.0 : sxy / sxx;
  var residual = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final predicted = my + slope * (xs[i] - mx);
    residual += (ys[i] - predicted) * (ys[i] - predicted);
  }
  final se = points.length > 2 && sxx > 0
      ? math.sqrt(residual / (points.length - 2) / sxx)
      : 0.0;
  return <double>[slope, se];
}

Object _r1(num value) {
  final rounded = (value * 10).round() / 10.0;
  return rounded == rounded.roundToDouble() ? rounded.toInt() : rounded;
}

class CpuSchedulingInternals {
  static Map<String, Object?>? get cpuReading => _cpuConsumption;
  static Map<String, Object?>? get threadReading => _threadReading;

  static void cpu(int atMs, int ticks) => recordCpuTicksForTests(atMs, ticks);
  static void threads(int atMs, int count) =>
      recordThreadCountForTests(atMs, count);
  static void tick(int atMs, int latenessMs) =>
      noteCpuSchedulingTick(atMs, latenessMs);
  static Map<String, Object?>? blocking(int atMs) =>
      readBlockingAsync(atMs);

  static void reset() {
    resetCpuScheduling();
  }
}

void resetCpuScheduling() {
  _cpuAnchor = null;
  _cpuSampleCount = 0;
  _cpuConsumption = null;
  _threadSamples.clear();
  _threadReading = null;
  _samplerStartedAtMs = null;
  _sampleInFlight = false;
  _blockingStartedAtMs = 0;
  _blockingCount = 0;
  _blockingWorstMs = 0;
}