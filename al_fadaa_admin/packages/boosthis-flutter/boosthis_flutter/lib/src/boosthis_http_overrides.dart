/// BoosthisHttpOverrides — opt-in outbound network sampling.
///
/// REQUIRES A FLUTTER SDK TO COMPILE. Imports `package:flutter` (foundation)
/// and `dart:io`; NOT compiled or analysed by this workspace's meter-parity
/// harness. See `../../../PORT_CONTRACT.md`.
///
/// Install it CHAINED so a host `HttpOverrides.global` is never clobbered:
///
///     BoosthisHttpOverrides.install();
///
/// It wraps `dart:io` `HttpClient` request lifecycles and reports, per request,
/// only counts and durations to the pure package's network sampler — never the
/// URL, headers, body, query string or status body. Instrumented-outbound-only,
/// exactly like every other kit. This covers `dart:io`/`http` clients; a Dio
/// interceptor is a separate opt-in in the pure package.
///
/// Every hook is guarded so a failure inside the kit can never break the host's
/// outbound HTTP.
library;

import 'dart:convert' show Encoding;
import 'dart:io';

import 'package:boosthis/boosthis.dart' as boosthis;

/// A chained `HttpOverrides` that samples outbound request timing.
class BoosthisHttpOverrides extends HttpOverrides {
  BoosthisHttpOverrides._(this._previous);

  final HttpOverrides? _previous;

  static bool _installed = false;
  static BoosthisHttpOverrides? _instance;

  /// Install chained over the current global. Idempotent.
  static void install() {
    try {
      if (_installed) return;
      _installed = true;
      final instance = BoosthisHttpOverrides._(HttpOverrides.current);
      _instance = instance;
      HttpOverrides.global = instance;
      boosthis.Boosthis.setHttpOverridesCurrentProbe(
        () => identical(HttpOverrides.current, _instance),
      );
    } catch (_) {
      /* never break the host's networking */
    }
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Delegate client creation to the previous override (or the platform
    // default) so we never change how the host's client is built, then wrap it.
    HttpClient inner;
    try {
      inner =
          _previous?.createHttpClient(context) ??
          super.createHttpClient(context);
    } catch (_) {
      // If our chaining fails, fall back to the framework default so the host
      // still gets a working client.
      return super.createHttpClient(context);
    }
    try {
      return _BoosthisHttpClient(inner);
    } catch (_) {
      return inner;
    }
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    try {
      final HttpOverrides? prev = _previous;
      if (prev != null) return prev.findProxyFromEnvironment(url, environment);
    } catch (_) {
      /* fall through to default */
    }
    return super.findProxyFromEnvironment(url, environment);
  }
}

/// Thin wrapper that times request→response and reports counts/durations only.
/// It forwards every method verbatim to the inner client; only [openUrl] adds a
/// timing hook (all HttpClient.get/post/etc. funnel through openUrl).
class _BoosthisHttpClient implements HttpClient {
  _BoosthisHttpClient(this._inner);

  final HttpClient _inner;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    final Stopwatch sw = Stopwatch()..start();
    // Mint at the synchronous call site so the parent is the scope open NOW,
    // never a scope that happens to be open after this Future resolves.
    final boosthis.SpanHandle? span = boosthis.RuntimeFlags.disabled
        ? null
        : boosthis.SpanScope.beginSpan();
    final double startedAt = boosthis.Trace.nowMs();
    return _inner.openUrl(method, url).then((HttpClientRequest req) {
      // The request is opened; timing completes when the response closes. We
      // hook the response's drain via .done — but the simplest privacy-safe
      // signal is the round trip to first response, recorded on close below.
      return _BoosthisHttpClientRequest(
        req,
        sw,
        method.toUpperCase(),
        startedAt,
        span,
      );
    });
  }

  // Everything else is a verbatim forward. HttpClient.get/getUrl/post/... are
  // implemented on top of openUrl, so instrumenting openUrl is enough.

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('get', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('post', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('put', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('delete', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('patch', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('head', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);

  // ── Pass-through configuration surface ──────────────────────────────────────

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _inner.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _inner.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set keyLog(void Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

/// Wraps an [HttpClientRequest] only to observe when its response arrives. It
/// forwards every member to the inner request; it overrides [close] to record
/// the round-trip duration once the response is available.
class _BoosthisHttpClientRequest implements HttpClientRequest {
  _BoosthisHttpClientRequest(
    this._inner,
    this._sw,
    this._method,
    this._startedAt,
    this._span,
  );

  final HttpClientRequest _inner;
  final Stopwatch _sw;
  final String _method;
  final double _startedAt;
  final boosthis.SpanHandle? _span;
  bool _recorded = false;
  String? _routeAtSend;
  boosthis.AiCallHandle? _aiCall;
  String? _traceId;
  double? _startOffsetMs;

  void _attachTraceHeaders() {
    final span = _span;
    if (span == null) return;
    try {
      final existingValues = _inner.headers[boosthis.Trace.traceHeader];
      final existing = existingValues == null || existingValues.isEmpty
          ? null
          : existingValues.first;
      final traceId = boosthis.Trace.sanitizeTraceId(existing);

      // Flutter is a trace root and owns all three values. Strip every
      // caller-supplied spelling before attaching the sanitized trace, this
      // call's elapsed offset, and this call's own id as the next-hop parent.
      _inner.headers.removeAll(boosthis.Trace.traceHeader);
      _inner.headers.removeAll(boosthis.Trace.elapsedHeader);
      _inner.headers.removeAll(boosthis.SpanScope.parentHeader);
      _inner.headers.set(boosthis.Trace.traceHeader, traceId);
      _inner.headers.set(boosthis.SpanScope.parentHeader, span.spanId);

      final offset = boosthis.Trace.spanStartOffset(traceId, _startedAt);
      _traceId = traceId;
      _startOffsetMs = offset;
      if (offset != null) {
        _inner.headers.set(
          boosthis.Trace.elapsedHeader,
          offset.round().toString(),
        );
      }
    } catch (_) {
      // Header propagation is instrumentation and must never block the request.
    }
  }

  void _record({required bool stalled, int? statusCode}) {
    if (_recorded) return;
    _recorded = true;
    try {
      _sw.stop();
      // Privacy-safe: host + duration + stalled flag ONLY. Never the full URL,
      // status body, headers or query string. The pure package templates/keeps
      // only what its network sampler allows.
      boosthis.Boosthis.recordOutbound(
        host: _inner.uri.host,
        durationMs: _sw.elapsedMilliseconds,
        stalled: stalled,
      );
      final traceId = _traceId;
      final offset = _startOffsetMs;
      final span = _span;
      if (boosthis.Telemetry.fullTelemetry &&
          traceId != null &&
          offset != null &&
          span != null) {
        boosthis.SpanEmitter.record(
          traceId,
          boosthis.SpanEmitter.outboundLabel(_method),
          _sw.elapsedMilliseconds.toDouble(),
          offset,
          span.spanId,
          span.parentSpanId,
          'http',
          boosthis.outcomeForStatus(statusCode, stalled),
        );
      }
    } catch (_) {
      /* sampling must never break the host's request */
    }
  }

  @override
  Future<HttpClientResponse> close() {
    _attachTraceHeaders();
    _routeAtSend = boosthis.Boosthis.currentRoute;
    // close(), not openUrl(), is the point dart:io actually sends the request.
    _aiCall = boosthis.Boosthis.recordOutboundSent(
      host: _inner.uri.host,
      method: _method,
      path: _inner.uri.path,
    );
    return _inner.close().then(
      (HttpClientResponse resp) {
        boosthis.Boosthis.recordUpstreamCacheReply((String name) {
          final values = resp.headers[name];
          return values == null || values.isEmpty ? null : values.first;
        });
        boosthis.Boosthis.recordRouteOutboundResult(
          route: _routeAtSend,
          failed: resp.statusCode >= 400,
        );
        boosthis.Boosthis.recordOutboundFinished(
          _aiCall,
          durationMs: _sw.elapsedMilliseconds,
          failed: resp.statusCode >= 400,
        );
        _record(stalled: false, statusCode: resp.statusCode);
        return resp;
      },
      onError: (Object e) {
        boosthis.Boosthis.recordRouteOutboundResult(
          route: _routeAtSend,
          failed: true,
        );
        boosthis.Boosthis.recordOutboundFinished(
          _aiCall,
          durationMs: _sw.elapsedMilliseconds,
          failed: true,
        );
        _record(stalled: true);
        // Rethrow so the host sees the real error unchanged.
        throw e;
      },
    );
  }

  @override
  Future<HttpClientResponse> get done => _inner.done;

  // ── Verbatim forwards ──────────────────────────────────────────────────────

  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) => _inner.write(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _inner.writeln(object);
}
