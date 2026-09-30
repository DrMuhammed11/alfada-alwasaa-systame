import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'json.dart';
import 'kit_version.dart';
import 'runtime_flags.dart';
import 'safe.dart';

/// The decoded result of a send: HTTP status + JSON-decoded body (or null).
class TransmitResult {
  const TransmitResult(this.status, this.body);
  final int status;
  final Map<String, Object?>? body;
}

/// HTTP transport. Every byte the kit sends leaves through here, and every send
/// passes the no-PII guard FIRST — payload body, then URL query — in the same
/// order as the other runtimes.
///
/// Best effort by contract: a failed send is a dropped measurement, NEVER an
/// error thrown into the host. There is no retry storm — one attempt, a short
/// bounded timeout via `HttpClient.connectionTimeout` + a wrapping
/// `Future.timeout`, and the caller decides whether to keep the batch.
///
/// ONE shared `HttpClient` for the process lifetime (never one per call — a
/// client-per-call leaks sockets under load); each send passes its own timeout.
class Transmit {
  Transmit._();

  static HttpClient? _client;

  /// Test seam: swap the wire for a recorder. The recorder receives
  /// (method, url, headers, timeoutMs, body) and returns a [TransmitResult].
  static Future<TransmitResult> Function(
    String method,
    String url,
    Map<String, String> headers,
    int timeoutMs,
    String? body,
  )? _sender;

  static String userAgent() => 'boosthis-flutter/$RUNTIME_VERSION';

  /// The no-PII payload guard. The Pii group wires the real `assertNoPii` via
  /// [setPayloadGuard]; it must THROW when the payload carries PII, so the
  /// network call is never made. Until wired the default is a no-op, but the
  /// kit never enables telemetry without the guard group present.
  static void Function(Object? payload) _payloadGuard = (_) {};

  /// The no-PII URL guard. Wired by the Pii group; throws on a PII-shaped query.
  static void Function(String url) _urlGuard = (_) {};

  static void setPayloadGuard(void Function(Object? payload) guard) {
    _payloadGuard = guard;
  }

  static void setUrlGuard(void Function(String url) guard) {
    _urlGuard = guard;
  }

  static void setSenderForTests(
    Future<TransmitResult> Function(
      String method,
      String url,
      Map<String, String> headers,
      int timeoutMs,
      String? body,
    )? fn,
  ) {
    _sender = fn;
  }

  /// Guarded POST: assert no PII in the payload and the URL, honour
  /// BOOSTHIS_DISABLED (synthetic 204), then send. Never throws into the host —
  /// a transport failure returns `{status: 0}`; only the PII guard may throw,
  /// and that is a developer-facing bug, contained by the caller's Safe.run.
  static Future<TransmitResult> safeTransmit(
    String url,
    Object? payload, {
    String? authToken,
    int timeoutMs = 5000,
    Map<String, String>? headers,
  }) async {
    // The PII guard runs unconditionally — inert mode silences outbound
    // traffic, it does NOT relax the privacy contract.
    _payloadGuard(payload);
    _urlGuard(url);
    if (RuntimeFlags.disabled) {
      return const TransmitResult(204, null);
    }
    return _post(url, payload, authToken, timeoutMs, headers);
  }

  /// Variant that skips ONLY the payload-body PII check for a payload whose
  /// body legitimately carries a server-issued credential the field-name guard
  /// would otherwise reject (the deleteToken on POST /installs/forget). The URL
  /// query is still scanned and BOOSTHIS_DISABLED is still honoured.
  static Future<TransmitResult> safeTransmitTrustedPayload(
    String url,
    Object? payload, {
    String? authToken,
    int timeoutMs = 5000,
  }) async {
    _urlGuard(url);
    if (RuntimeFlags.disabled) {
      return const TransmitResult(204, null);
    }
    return _post(url, payload, authToken, timeoutMs);
  }

  /// Read-only GET for the live-data channels (connection status, community
  /// lookups). No body, so no payload PII check; the URL query IS still scanned
  /// and BOOSTHIS_DISABLED is still honoured (returns 204, no request made).
  static Future<TransmitResult> safeGet(
    String url, {
    String? authToken,
    int timeoutMs = 5000,
  }) async {
    _urlGuard(url);
    if (RuntimeFlags.disabled) {
      return const TransmitResult(204, null);
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': userAgent(),
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    final raw = await _send('GET', url, null, headers, timeoutMs);
    return TransmitResult(raw.status, Json.decode(raw.body));
  }

  static Future<TransmitResult> _post(
    String url,
    Object? payload,
    String? authToken,
    int timeoutMs, [
    Map<String, String>? extraHeaders,
  ]) async {
    final body = Json.encode(payload);
    if (body == null) return const TransmitResult(0, null);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': userAgent(),
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (extraHeaders != null) {
      extraHeaders.forEach((k, v) {
        if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
      });
    }

    final raw = await _send('POST', url, body, headers, timeoutMs);
    return TransmitResult(raw.status, Json.decode(raw.body));
  }

  static Future<_RawResponse> _send(
    String method,
    String url,
    String? body,
    Map<String, String> headers,
    int timeoutMs,
  ) async {
    final sender = _sender;
    if (sender != null) {
      final r = await sender(method, url, headers, timeoutMs, body);
      return _RawResponse(r.status, Json.encode(r.body) ?? '');
    }
    return Safe.runAsync<_RawResponse>(
      const _RawResponse(0, ''),
      () => _sendHttp(method, url, body, headers, timeoutMs),
    );
  }

  static Future<_RawResponse> _sendHttp(
    String method,
    String url,
    String? body,
    Map<String, String> headers,
    int timeoutMs,
  ) async {
    final client = _client ??= HttpClient();
    // Bounded connect timeout (never longer than 3s), matching the siblings.
    final connectMs = timeoutMs < 3000 ? timeoutMs : 3000;
    client.connectionTimeout = Duration(milliseconds: connectMs);

    final uri = Uri.parse(url);
    final fut = () async {
      final req = await client.openUrl(method, uri);
      headers.forEach(req.headers.set);
      if (body != null) {
        req.add(convert.utf8.encode(body));
      }
      final resp = await req.close();
      final text = await resp.transform(convert.utf8.decoder).join();
      return _RawResponse(resp.statusCode, text);
    }();

    // Overall bound: even a hung read must never block a background flush
    // forever. On timeout we return a dropped-measurement result.
    return fut.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () => const _RawResponse(0, ''),
    );
  }
}

class _RawResponse {
  const _RawResponse(this.status, this.body);
  final int status;
  final String body;
}
