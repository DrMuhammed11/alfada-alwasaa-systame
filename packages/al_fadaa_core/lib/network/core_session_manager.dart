import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// مدير الجلسات الموحد — يحفظ ويدير رموز المصادقة والمستخدم الحالي
class CoreSessionManager {
  static final CoreSessionManager _instance = CoreSessionManager._internal();
  factory CoreSessionManager() => _instance;
  CoreSessionManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _userData;
  int _unauthorizedCounter = 0;

  final ValueNotifier<bool> isAuthenticatedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> forceLogoutNotifier = ValueNotifier<bool>(false);

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// تهيئة الجلسة عند إقلاع التطبيق
  Future<void> init() async {
    try {
      _token = await _storage.read(key: 'jwt_token');
      _refreshToken = await _storage.read(key: 'refresh_token');

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _userData = jsonDecode(userJson) as Map<String, dynamic>;
      }

      isAuthenticatedNotifier.value = isAuthenticated;
    } catch (e) {
      debugPrint('[CoreSessionManager] Failed to read stored session: $e');
    }
  }

  /// حفظ بيانات الجلسة بعد تسجيل الدخول الناجح
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? user,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _userData = user;
    _unauthorizedCounter = 0;

    await _storage.write(key: 'jwt_token', value: token);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user));
    }

    isAuthenticatedNotifier.value = true;
    forceLogoutNotifier.value = false;
  }

  /// مسح الجلسة بالكامل (تسجيل الخروج)
  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _userData = null;
    _unauthorizedCounter = 0;

    try {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('[CoreSessionManager] Error clearing storage: $e');
    }

    isAuthenticatedNotifier.value = false;
    forceLogoutNotifier.value = true;
  }

  void resetUnauthorizedCount() {
    _unauthorizedCounter = 0;
  }

  /// محاولة التجديد التلقائي للتوكن عند استقبال 401
  Future<bool> tryRefresh() async {
    final currentRefresh = _refreshToken;
    if (currentRefresh == null || currentRefresh.isEmpty) {
      _unauthorizedCounter++;
      if (_unauthorizedCounter >= 3) {
        await clearSession();
      }
      return false;
    }

    try {
      final url = Uri.parse(CoreApiConstants.refresh);
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': currentRefresh}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newToken = data['accessToken'] ?? data['token'];
        final newRefresh = data['refreshToken'] ?? currentRefresh;

        if (newToken != null) {
          _token = newToken;
          _refreshToken = newRefresh;
          await _storage.write(key: 'jwt_token', value: newToken);
          await _storage.write(key: 'refresh_token', value: newRefresh);
          _unauthorizedCounter = 0;
          return true;
        }
      }
    } catch (e) {
      debugPrint('[CoreSessionManager] Token refresh failed: $e');
    }

    _unauthorizedCounter++;
    if (_unauthorizedCounter >= 3) {
      await clearSession();
    }
    return false;
  }
}
