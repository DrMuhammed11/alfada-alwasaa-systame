import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

/// عميل شبكة HTTP موحد يدير الترويسات والمصادقة وإعادة المحاولة التلقائية
class AppHttpClient {
  static final AppHttpClient _instance = AppHttpClient._internal();
  factory AppHttpClient() => _instance;
  AppHttpClient._internal();

  final SessionManager _sessionManager = SessionManager();

  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _sessionManager.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// فحص الاستجابة وتتبع انتهاء الجلسة
  http.Response _inspectResponse(http.Response response) {
    if (response.statusCode == 401) {
      _sessionManager.handleUnauthorizedResponse();
    } else {
      _sessionManager.resetUnauthorizedCount();
    }
    return response;
  }

  /// تنفيذ طلب مع محاولة إعادة واحدة عند انتهاء المهلة أو كود 503
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() action, {
    String description = 'HTTP Request',
  }) async {
    try {
      final res = await action();
      if (res.statusCode == 503) {
        debugPrint('503 Service Unavailable on $description -> Retrying once in 1s...');
        await Future.delayed(const Duration(seconds: 1));
        return _inspectResponse(await action());
      }
      return _inspectResponse(res);
    } on TimeoutException {
      debugPrint('Timeout on $description -> Retrying once in 1s...');
      await Future.delayed(const Duration(seconds: 1));
      final retryRes = await action();
      return _inspectResponse(retryRes);
    } catch (e) {
      debugPrint('$description error: $e');
      rethrow;
    }
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeWithRetry(
      () => http.get(uri, headers: headers ?? defaultHeaders).timeout(timeout),
      description: 'GET ${uri.path}',
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeWithRetry(
      () => http.post(uri, headers: headers ?? defaultHeaders, body: body).timeout(timeout),
      description: 'POST ${uri.path}',
    );
  }

  Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeWithRetry(
      () => http.patch(uri, headers: headers ?? defaultHeaders, body: body).timeout(timeout),
      description: 'PATCH ${uri.path}',
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeWithRetry(
      () => http.delete(uri, headers: headers ?? defaultHeaders).timeout(timeout),
      description: 'DELETE ${uri.path}',
    );
  }

  Future<http.Response> sendMultipart(
    http.MultipartRequest request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final token = _sessionManager.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return _inspectResponse(response);
  }
}
