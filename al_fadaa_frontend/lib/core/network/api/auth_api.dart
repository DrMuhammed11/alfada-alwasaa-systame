import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../models/user_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../session_manager.dart';

/// عميل عمليات المصادقة وإدارة حساب المستخدم
class AuthApi {
  final AppHttpClient _http = AppHttpClient();
  final SessionManager _session = SessionManager();

  Future<Map<String, dynamic>> login(String email, String password) async {
    _session.resetUnauthorizedCount();
    try {
      // login-v2 يعيد رمز تحديث قابل للتجديد الصامت (لا يوفره /auth/login القديم)
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login-v2'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['accessToken'];
        if (token != null) {
          await _session.saveToken(token, refreshToken: data['refreshToken'] as String?);
        }
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'فشل تسجيل الدخول'};
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم (تأكد من تشغيل backend على منفذ 3000)',
      };
    }
  }

  Future<User?> getMe({Duration timeout = const Duration(seconds: 10)}) async {
    if (!_session.isAuthenticated) return null;
    try {
      final response = await _http.get(Uri.parse(ApiConstants.me), timeout: timeout);
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw Exception('فشل في استرداد بيانات المستخدم (${response.statusCode})');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('getMe exception: $e');
      rethrow;
    }
  }
}
