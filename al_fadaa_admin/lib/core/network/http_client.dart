import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class AdminHttpClient {
  static final AdminHttpClient _instance = AdminHttpClient._internal();
  factory AdminHttpClient() => _instance;
  AdminHttpClient._internal();

  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = SessionManager().token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<http.Response> get(Uri uri, {Duration? timeout}) async {
    final response = await _client
        .get(uri, headers: _buildHeaders())
        .timeout(timeout ?? const Duration(seconds: 15));
    _check401(response);
    return response;
  }

  Future<http.Response> post(Uri uri, {Object? body, Duration? timeout}) async {
    final encoded = body is String ? body : (body != null ? jsonEncode(body) : null);
    final response = await _client
        .post(uri, headers: _buildHeaders(), body: encoded)
        .timeout(timeout ?? const Duration(seconds: 15));
    _check401(response);
    return response;
  }

  Future<http.Response> patch(Uri uri, {Object? body, Duration? timeout}) async {
    final encoded = body is String ? body : (body != null ? jsonEncode(body) : null);
    final response = await _client
        .patch(uri, headers: _buildHeaders(), body: encoded)
        .timeout(timeout ?? const Duration(seconds: 15));
    _check401(response);
    return response;
  }

  Future<http.Response> delete(Uri uri, {Duration? timeout}) async {
    final response = await _client
        .delete(uri, headers: _buildHeaders())
        .timeout(timeout ?? const Duration(seconds: 15));
    _check401(response);
    return response;
  }

  void _check401(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint('Admin 401 Unauthorized received');
      SessionManager().clearSession();
      throw UnauthorizedException();
    }
  }
}
