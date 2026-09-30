import 'dart:async';

import '../integration/route_inventory.dart';
import '../observers/pii.dart' show transmitLabelHasPii;
import 'runtime_flags.dart';
import 'safe.dart';

/// Ships a batch of completed measurements, returning how many were accepted.
typedef SampleSubmitter =
    Future<int> Function(List<Map<String, Object?>> samples);

/// The bounded, privacy-gated queue behind the per-request `/samples` channel.
///
/// Flushing is work-gated: an enqueue schedules one deferred send when the
/// 15-second throttle is due, or immediately when a complete batch is waiting.
/// There is no polling timer keeping an otherwise-idle host app awake.
class SampleUploader {
  SampleUploader._();

  /// Locked to the server's `IngestSamplesBody` bounds.
  static const int maxSampleBatch = 100;
  static const int maxBufferedSamples = 500;
  static const int maxSampleRouteLabel = 100;
  static const int maxSampleDurationMs = 600000;
  static const int flushThrottleMs = 15000;
  static const Set<String> allowedRatings = <String>{
    'good',
    'needs-work',
    'poor',
  };

  static SampleSubmitter? _submitter;
  static bool Function() _authorized = () => false;
  static final List<Map<String, Object?>> _buffer = <Map<String, Object?>>[];
  static bool _inFlight = false;
  static bool _flushScheduled = false;
  static int _lastFlushAtMs = 0;
  static bool _automaticFlush = true;

  /// Wire the sender and the SAME effective gate used by snapshot upload.
  static void configure({
    required SampleSubmitter? submitter,
    required bool Function() authorized,
  }) {
    _submitter = submitter;
    _authorized = authorized;
    if (submitter == null) clear();
  }

  static bool get hasSubmitter => _submitter != null;
  static int get bufferLength => _buffer.length;

  /// Retain exactly the closed three-field wire row, or nothing.
  static void enqueue(String routeLabel, num durationMs, String rating) {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      if (_submitter == null || !_authorized()) {
        // A gate that closed after the preceding measurement also erases any
        // rows waiting from the formerly-authorized interval.
        clear();
        return;
      }
      if (!allowedRatings.contains(rating)) return;

      final label = RouteInventory.safeScreenName(
        routeLabel,
        allowMethodPath: true,
      );
      if (label == null || transmitLabelHasPii(label) != null) return;

      var duration = durationMs.isFinite ? durationMs.round() : 0;
      if (duration < 0) duration = 0;
      if (duration > maxSampleDurationMs) duration = maxSampleDurationMs;
      _buffer.add(<String, Object?>{
        'routeLabel': label,
        'durationMs': duration,
        'rating': rating,
      });
      while (_buffer.length > maxBufferedSamples) {
        _buffer.removeAt(0);
      }
      if (_automaticFlush) _maybeScheduleFlush();
    });
  }

  static void _maybeScheduleFlush() {
    if (_flushScheduled || _inFlight || _buffer.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = now - _lastFlushAtMs >= flushThrottleMs;
    final full = _buffer.length >= maxSampleBatch;
    if (!due && !full) return;
    _lastFlushAtMs = now;
    _flushScheduled = true;
    // Timer.run is the same deferred event-loop mechanism used by the kit's
    // uploader timers: capture + HTTP never runs on the measured host stack.
    Timer.run(() {
      _flushScheduled = false;
      unawaited(flush());
    });
  }

  /// Drain and submit one batch. A refused/throwing batch is deliberately lost.
  static Future<int> flush() {
    return Safe.runAsync<int>(0, () async {
      final submitter = _submitter;
      final authorized = !RuntimeFlags.disabled && _authorized();
      if (submitter == null || !authorized || _inFlight || _buffer.isEmpty) {
        if (submitter == null || !authorized) clear();
        return 0;
      }
      _inFlight = true;
      final take = _buffer.length < maxSampleBatch
          ? _buffer.length
          : maxSampleBatch;
      final batch = _buffer.sublist(0, take);
      _buffer.removeRange(0, take);
      try {
        return await submitter(batch);
      } catch (_) {
        return 0;
      } finally {
        _inFlight = false;
        if (_automaticFlush && _buffer.length >= maxSampleBatch) {
          _maybeScheduleFlush();
        }
      }
    });
  }

  static List<Map<String, Object?>> buffered() =>
      List<Map<String, Object?>>.from(_buffer);

  static void clear() {
    _buffer.clear();
  }

  static void resetForTests() {
    _submitter = null;
    _authorized = () => false;
    _buffer.clear();
    _inFlight = false;
    _flushScheduled = false;
    _lastFlushAtMs = 0;
    _automaticFlush = false;
  }
}
