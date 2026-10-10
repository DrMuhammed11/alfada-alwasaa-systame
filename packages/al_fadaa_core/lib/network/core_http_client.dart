import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'core_session_manager.dart';

/// عميل شبكة HTTP الموحد لتطبيقات الفضاء الواسع
/// يدير الترويسات والمصادقة وإعادة المحاولة التلقائية عند انتهاء الرمز (Silent Refresh)
class CoreHttpClient {
  static final CoreHttpClient _instance = CoreHttpClient._internal();
  factory CoreHttpClient() => _instance;
  CoreHttpClient._internal();

  final CoreSessionManager _sessionManager = CoreSessionManager();

  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
    };
    final token = _sessionManager.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _inspectResponse(
    http.Response response, [
    Future<http.Response> Function()? repeat,
  ]) async {
    if (response.statusCode == 401) {
      final refreshed = await _sessionManager.tryRefresh();
      if (refreshed) {
        if (repeat != null) {
          final retried = await repeat();
          if (retried.statusCode != 401) {
            _sessionManager.resetUnauthorizedCount();
            return retried;
          }
        } else {
          _sessionManager.resetUnauthorizedCount();
          return response;
        }
      }
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      _sessionManager.resetUnauthorizedCount();
    }
    return response;
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final combined = {...defaultHeaders, if (headers != null) ...headers};
    try {
      final response = await http.get(url, headers: combined);
      return await _inspectResponse(response, () => http.get(url, headers: defaultHeaders));
    } catch (e) {
      debugPrint('[CoreHttpClient] GET error on $url: $e');
      rethrow;
    }
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final combined = {...defaultHeaders, if (headers != null) ...headers};
    try {
      final encodedBody = (body is Map || body is List) ? jsonEncode(body) : body;
      final response = await http.post(url, headers: combined, body: encodedBody, encoding: encoding);
      return await _inspectResponse(response, () => http.post(url, headers: defaultHeaders, body: encodedBody, encoding: encoding));
    } catch (e) {
      debugPrint('[CoreHttpClient] POST error on $url: $e');
      rethrow;
    }
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final combined = {...defaultHeaders, if (headers != null) ...headers};
    try {
      final encodedBody = (body is Map || body is List) ? jsonEncode(body) : body;
      final response = await http.put(url, headers: combined, body: encodedBody, encoding: encoding);
      return await _inspectResponse(response, () => http.put(url, headers: defaultHeaders, body: encodedBody, encoding: encoding));
    } catch (e) {
      debugPrint('[CoreHttpClient] PUT error on $url: $e');
      rethrow;
    }
  }

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final combined = {...defaultHeaders, if (headers != null) ...headers};
    try {
      final encodedBody = (body is Map || body is List) ? jsonEncode(body) : body;
      final response = await http.patch(url, headers: combined, body: encodedBody, encoding: encoding);
      return await _inspectResponse(response, () => http.patch(url, headers: defaultHeaders, body: encodedBody, encoding: encoding));
    } catch (e) {
      debugPrint('[CoreHttpClient] PATCH error on $url: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final combined = {...defaultHeaders, if (headers != null) ...headers};
    try {
      final encodedBody = (body is Map || body is List) ? jsonEncode(body) : body;
      final response = await http.delete(url, headers: combined, body: encodedBody, encoding: encoding);
      return await _inspectResponse(response, () => http.delete(url, headers: defaultHeaders, body: encodedBody, encoding: encoding));
    } catch (e) {
      debugPrint('[CoreHttpClient] DELETE error on $url: $e');
      rethrow;
    }
  }
}
