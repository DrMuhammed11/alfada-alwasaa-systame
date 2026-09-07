import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_events.dart';

/// استثناء خاص عند انتهاء صلاحية الجلسة أو الرمز غير المصرح
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'انتهت الجلسة، يرجى تسجيل الدخول مجددًا']);

  @override
  String toString() => message;
}

/// مدير جلسة المستخدم وحفظ الرمز المميز وتتبع انتهاء الصلاحية
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _token;
  int _consecutive401Count = 0;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// تهيئة الجلسة واسترجاع الرمز المحفوظ
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
  }

  /// حفظ رمز الدخول الجديد
  Future<void> saveToken(String token) async {
    _token = token;
    _consecutive401Count = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// مسح رمز الدخول عند تسجيل الخروج أو انتهاء الجلسة
  Future<void> clearToken() async {
    _token = null;
    _consecutive401Count = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  /// معالجة استجابة 401 — عند تكرارها مرتين يتم تسجيل الخروج التلقائي
  void handleUnauthorizedResponse() {
    if (!isAuthenticated) return;
    _consecutive401Count++;
    debugPrint('HTTP 401 encountered (consecutive: $_consecutive401Count)');
    if (_consecutive401Count >= 2) {
      debugPrint('Session expired: 2 consecutive 401s detected. Auto-logout.');
      _consecutive401Count = 0;
      clearToken();
      AppEvents().triggerSessionExpired('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
    }
  }

  /// إعادة ضبط عداد الـ 401 عند أي استجابة ناجحة
  void resetUnauthorizedCount() {
    _consecutive401Count = 0;
  }
}
