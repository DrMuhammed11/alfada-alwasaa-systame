import '../core/runtime_flags.dart';
import '../core/safe.dart';
import '../core/score.dart';
import 'ai_providers.dart';

const List<String> aiShapedPaths = <String>[
  '/v1/chat/completions',
  '/v1/completions',
  '/v1/responses',
  '/v1/embeddings',
  '/v1/messages',
  '/api/generate',
  '/api/chat',
  '/api/embeddings',
  '/generate_stream',
];

/// Opaque, numbers-only state for one classified call in flight.
class AiCallHandle {
  AiCallHandle._(this.providerCode);

  final int providerCode;
  bool _finished = false;
}

/// Counts AI calls observed at the adapter's actual send boundary.
class AiCalls {
  AiCalls._();

  static const int minSamplesForAxis = 5;
  static const int maxDurations = 200;

  static int _callCount = 0;
  static int _completedCount = 0;
  static int _failCount = 0;
  static int _declaredCalls = 0;
  static int _unclassifiedCalls = 0;
  static final Set<int> _providers = <int>{};
  static final Map<int, int> _callsByProvider = <int, int>{};
  static final List<int> _durations = <int>[];
  static String _appOriginHost = '';
  static bool _observationArmed = false;
  static bool Function()? _httpOverridesCurrentProbe;

  /// Arm the outbound observation claim when the kit starts. Merely importing
  /// the package is not evidence that the process was inspected.
  static void armObservation() {
    if (RuntimeFlags.disabled) return;
    Safe.fire(() {
      _observationArmed = true;
    });
  }

  /// Let the Flutter adapter prove whether its chained HttpOverrides remains
  /// the process's current funnel. The callback is read only while building an
  /// axis and is always fail-closed, so host networking cannot be disturbed.
  static void setHttpOverridesCurrentProbe(bool Function()? probe) {
    Safe.fire(() {
      _httpOverridesCurrentProbe = probe;
    });
  }

  /// Test seam for the enumerable Flutter fact: whether the one dart:io HTTP
  /// client funnel watched by this kit is still current.
  static void setHttpOverridesCurrentForTests(bool? current) {
    setHttpOverridesCurrentProbe(current == null ? null : () => current);
  }

  /// Flutter has no runtime package registry. dart:io HttpClient,
  /// package:http's IOClient, and Dio's default adapter share one enumerable
  /// funnel: the process's current HttpOverrides. Report only whether that
  /// funnel can bypass this kit, never a client or package name.
  static int? unwatchedClientCount() {
    if (RuntimeFlags.disabled || !_observationArmed) return null;
    final current = Safe.run<bool>(
      false,
      () => _httpOverridesCurrentProbe?.call() == true,
    );
    return current ? 0 : 1;
  }

  /// Name the app server this phone calls so its server-side observation is
  /// never counted a second time here. The address remains in process.
  static void setAppOrigin(Object? origin) {
    _appOriginHost = Safe.run<String>('', () {
      if (origin is! String || origin.trim().isEmpty) return '';
      final raw = origin.trim().toLowerCase();
      final parsed = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
      return parsed?.host.toLowerCase() ?? '';
    });
  }

  /// Classify immediately before the underlying transport is sent.
  ///
  /// Host, method and path are compared on this stack and never retained.
  static AiCallHandle? sent({
    required String host,
    required String method,
    required String path,
  }) {
    if (RuntimeFlags.disabled) return null;
    return Safe.run<AiCallHandle?>(null, () {
      final h = host.toLowerCase();
      if (h.isEmpty || h == _appOriginHost || _isBoosthisHost(h)) return null;
      final provider = aiProviderCodeOrDeclared(h);
      if (provider == 0) {
        if (method.toUpperCase() == 'POST' && _isAiShaped(path)) {
          _unclassifiedCalls++;
        }
        return null;
      }
      _callCount++;
      _providers.add(provider);
      _callsByProvider[provider] = (_callsByProvider[provider] ?? 0) + 1;
      if (provider == declaredProviderCode) _declaredCalls++;
      return AiCallHandle._(provider);
    });
  }

  /// Complete a classified call without retaining any request metadata.
  static void finished(
    AiCallHandle? call, {
    required int durationMs,
    bool failed = false,
  }) {
    if (call == null || call._finished || RuntimeFlags.disabled) return;
    Safe.fire(() {
      call._finished = true;
      _completedCount++;
      var duration = durationMs;
      if (duration < 0) duration = 0;
      if (duration > 120000) duration = 120000;
      _durations.add(duration);
      if (_durations.length > maxDurations) _durations.removeAt(0);
      if (failed) _failCount++;
    });
  }

  static bool _isAiShaped(String raw) {
    var path = raw.split('?').first.toLowerCase();
    path = path.replaceAll(RegExp(r'/+$'), '');
    return path.isNotEmpty && aiShapedPaths.contains(path);
  }

  static bool _isBoosthisHost(String host) {
    final own = Uri.tryParse(RuntimeFlags.apiBase)?.host.toLowerCase() ?? '';
    return own.isNotEmpty && host == own;
  }

  static int _percentile(List<int> values, double p) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    var index = (p * sorted.length).ceil() - 1;
    if (index < 0) index = 0;
    if (index >= sorted.length) index = sorted.length - 1;
    return sorted[index];
  }

  /// The closed aiCalls wire shape, or null when there is no evidence.
  static Map<String, Object?>? buildAxis() {
    if (RuntimeFlags.disabled) return null;
    final unwatchedClients = unwatchedClientCount();
    if (_callCount == 0 &&
        _unclassifiedCalls == 0 &&
        (unwatchedClients == null || unwatchedClients == 0)) {
      return null;
    }

    var topProvider = 0;
    var topCalls = 0;
    _callsByProvider.forEach((provider, calls) {
      if (calls > topCalls) {
        topProvider = provider;
        topCalls = calls;
      }
    });

    final axis = <String, Object?>{'rating': 'pending', 'measurable': 0};
    if (unwatchedClients != null) {
      axis['unwatchedClients'] = unwatchedClients;
    }
    if (_callCount > 0) {
      axis['callCount'] = _callCount;
      axis['providerCount'] = _providers.length;
      axis['topProvider'] = topProvider;
      axis['failCount'] = _failCount;
    }
    if (_declaredCalls > 0) axis['declaredCalls'] = _declaredCalls;
    if (_unclassifiedCalls > 0) {
      axis['unclassifiedCalls'] = _unclassifiedCalls;
    }

    // An in-flight call has no outcome yet. Keep the count visible, but never
    // score an unfinished denominator as if it were a success.
    if (_callCount < minSamplesForAxis || _completedCount != _callCount) {
      return axis;
    }

    final failPct = (_failCount / _callCount) * 100;
    final score = Score.scoreMetric(failPct, 0, 10);
    axis['score'] = score;
    axis['rating'] = Score.getRating(score);
    axis['measurable'] = 1;
    if (_durations.isNotEmpty) {
      axis['p75Ms'] = _percentile(_durations, 0.75);
      axis['worstMs'] = _durations.reduce((a, b) => a > b ? a : b);
    }
    return axis;
  }

  static Map<String, Object?> getStats() =>
      Map<String, Object?>.from(buildAxis() ?? const <String, Object?>{});

  static bool get hasEvidence {
    if (_callCount > 0 || _unclassifiedCalls > 0) return true;
    return (unwatchedClientCount() ?? 0) > 0;
  }

  static void clear() {
    _callCount = 0;
    _completedCount = 0;
    _failCount = 0;
    _declaredCalls = 0;
    _unclassifiedCalls = 0;
    _providers.clear();
    _callsByProvider.clear();
    _durations.clear();
    _appOriginHost = '';
    _observationArmed = false;
    _httpOverridesCurrentProbe = null;
  }
}
