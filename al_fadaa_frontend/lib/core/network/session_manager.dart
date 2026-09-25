import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'app_events.dart';

/// استثناء خاص عند انتهاء صلاحية الجلسة أو الرمز غير المصرح
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'انتهت الجلسة، يرجى تسجيل الدخول مجددًا']);

  @override
  String toString() => message;
}

/// مدير الجلسة — التوكنات في التخزين الآمن المشفر (لا SharedPreferences نصية)
/// مع تجديد صامت برمز التحديث قبل اللجوء لتسجيل الخروج التلقائي.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  int _consecutive401Count = 0;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// تجديد متزامن مشترك — كل 401s المتزامنة تنتظر نفس عملية التجديد
  Completer<bool>? _refreshCompleter;

  /// تهيئة الجلسة واسترجاع الرموز المحفوظة
  Future<void> init() async {
    try {
      _token = await _secure.read(key: _kToken);
      _refreshToken = await _secure.read(key: _kRefresh);
    } catch (e) {
      debugPrint('Error initializing secure storage: $e');
    }
  }

  /// حفظ زوج الرموز (الوصول + التحديث إن وُجد)
  Future<void> saveToken(String token, {String? refreshToken}) async {
    _token = token;
    _consecutive401Count = 0;
    if (refreshToken != null && refreshToken.isNotEmpty) _refreshToken = refreshToken;
    try {
      await _secure.write(key: _kToken, value: token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secure.write(key: _kRefresh, value: refreshToken);
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// مسح الجلسة عند الخروج أو انتهائها النهائي
  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    _consecutive401Count = 0;
    try {
      await _secure.delete(key: _kToken);
      await _secure.delete(key: _kRefresh);
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  /// محاولة تجديد رمز الوصول برمز التحديث — تجديد واحد مشترك للطلبات المتزامنة
  Future<bool> tryRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    _doRefresh().whenComplete(() {
      _refreshCompleter = null;
    });
    return completer.future;
  }

  Future<void> _doRefresh() async {
    final completer = _refreshCompleter;
    if (completer == null) return;
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.refresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccess = body['accessToken'] as String?;
        final newRefresh = body['refreshToken'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await saveToken(newAccess, refreshToken: newRefresh);
          if (!completer.isCompleted) completer.complete(true);
          return;
        }
      }
      // رمز التحديث مرفوض (مبطل/منتهي/سرقة محتملة) — إنهاء الجلسة نهائيًا
      if (!completer.isCompleted) completer.complete(false);
    } catch (e) {
      debugPrint('Session refresh error: $e');
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  /// معالجة 401 النهائي بعد فشل التجديد — تكرار مرتين يؤدي لخروج تلقائي
  void handleUnauthorizedResponse() {
    if (!isAuthenticated) return;
    _consecutive401Count++;
    debugPrint('HTTP 401 encountered (consecutive: $_consecutive401Count)');
    if (_consecutive401Count >= 2) {
      debugPrint('Session expired: 2 consecutive 401s after refresh attempts. Auto-logout.');
      _consecutive401Count = 0;
      clearToken();
      AppEvents().triggerSessionExpired('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
    }
  }

  /// إعادة ضبط عداد الـ 401 عند أي استجابة ناجحة
  void resetUnauthorizedCount() {
    _consecutive401Count = 0;
  }

  /// تسجيل خروج كامل: إبطال رمز التحديث في الخادم (أفضل جهد) ثم مسح الجلسة المحلية
  Future<void> logout() async {
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse(ApiConstants.logout),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': _refreshToken}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // الخروج المحلي يتم حتى لو فشل الاتصال بالخادم
      }
    }
    await clearToken();
  }
}
