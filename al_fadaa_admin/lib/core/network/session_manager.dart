import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/admin_user_model.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'انتهت الجلسة، يرجى إعادة تسجيل الدخول']);
  @override
  String toString() => message;
}

/// إدارة جلسة الأدمن — التوكنات في التخزين الآمن المشفر (لا SharedPreferences نصية)
/// مع رمز تحديث للتجديد الصامت وبثّ انتهاء الجلسة لإعادة التوجيه لشاشة الدخول.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const _kToken = 'admin_token';
  static const _kRefresh = 'admin_refresh_token';
  static const _kUser = 'admin_user';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  AdminUser? _currentUser;

  String? get token => _token;
  AdminUser? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// عدّاد انتهاء الجلسة — الشاشة الرئيسية تستمع له لتوجيه الأدمن لشاشة الدخول
  final ValueNotifier<int> sessionExpiredTick = ValueNotifier<int>(0);

  /// تجديد متزامن مشترك: كل طلبات 401 المتزامنة تنتظر نفس عملية التجديد
  Completer<String?>? _refreshCompleter;

  Future<void> init() async {
    try {
      _token = await _secure.read(key: _kToken);
      _refreshToken = await _secure.read(key: _kRefresh);
      final userStr = await _secure.read(key: _kUser);
      if (userStr != null) {
        _currentUser = AdminUser.fromJson(jsonDecode(userStr));
      }
    } catch (e) {
      debugPrint('Error loading admin session: $e');
    }
  }

  Future<void> saveSession(String token, AdminUser user, {String? refreshToken}) async {
    _token = token;
    _currentUser = user;
    _refreshToken = refreshToken ?? _refreshToken;
    try {
      await _secure.write(key: _kToken, value: token);
      if (refreshToken != null) {
        await _secure.write(key: _kRefresh, value: refreshToken);
      }
      await _secure.write(key: _kUser, value: jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving admin session: $e');
    }
  }

  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    try {
      await _secure.delete(key: _kToken);
      await _secure.delete(key: _kRefresh);
      await _secure.delete(key: _kUser);
    } catch (e) {
      debugPrint('Error clearing admin session: $e');
    }
  }

  /// انتهاء الجلسة بعد فشل التجديد: مسح محلي + بث للشاشة الرئيسية
  Future<void> expireSession() async {
    await clearSession();
    sessionExpiredTick.value++;
  }

  /// تجديد رمز الوصول بالرمز المحدث — يُشارك بين كل الطلبات المتزامنة
  Future<String?> tryRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return null;
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<String?>();
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
            Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccess = body['accessToken'] as String?;
        final newRefresh = body['refreshToken'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          _token = newAccess;
          if (newRefresh != null && newRefresh.isNotEmpty) _refreshToken = newRefresh;
          try {
            await _secure.write(key: _kToken, value: newAccess);
            if (newRefresh != null) await _secure.write(key: _kRefresh, value: newRefresh);
          } catch (_) {}
          if (!completer.isCompleted) completer.complete(newAccess);
          return;
        }
      }
      if (!completer.isCompleted) completer.complete(null);
    } catch (e) {
      debugPrint('Session refresh error: $e');
      if (!completer.isCompleted) completer.complete(null);
    }
  }

  /// تسجيل خروج كامل: إبطال رمز التحديث في الخادم ثم مسح الجلسة المحلية
  Future<void> logout() async {
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': _refreshToken}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // الخروج المحلي يتم حتى لو فشل الاتصال بالخادم
      }
    }
    await clearSession();
  }
}
