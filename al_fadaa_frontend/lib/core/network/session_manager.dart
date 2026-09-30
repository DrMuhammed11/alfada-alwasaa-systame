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
///
/// سياسة الجلسة الدائمة: المستخدم لا يُطرد من التطبيق إلا في حالتين فقط:
/// 1. خروج يدوي (زر تسجيل الخروج).
/// 2. رفض حاسم من الخادم لرمز التحديث — إبطال من الأدمن (تغيير كلمة المرور/
///    تعطيل الحساب/تغيير الدور) أو انتهاء صلاحية رمز التحديث (30 يوماً بلا اتصال).
///
/// انقطاعات الشبكة وأخطاء الخادم المؤقتة لا تُنهي الجلسة — تُعاد المحاولة لاحقًا.
/// مع تجديد استباقي دوري (كل 10 دقائق) يحافظ على حيوية رمز التحديث بالتدوير.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';

  /// فاصل التجديد الاستباقي — أقصر من صلاحية رمز الوصول (15 دقيقة) بهامش
  static const _keepAliveInterval = Duration(minutes: 10);

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  bool _refreshRejected = false;
  Timer? _keepAliveTimer;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// تجديد متزامن مشترك — كل 401s المتزامنة تنتظر نفس عملية التجديد
  Completer<bool>? _refreshCompleter;

  /// تهيئة الجلسة واسترجاع الرموز المحفوظة — ومع وجود رمز تحديث صالح
  /// يُجرى تجديد استباقي فوري لضمان رمز وصول حي عند بدء الجلسة
  Future<void> init() async {
    try {
      _token = await _secure.read(key: _kToken);
      _refreshToken = await _secure.read(key: _kRefresh);
    } catch (e) {
      debugPrint('Error initializing secure storage: $e');
    }
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      _startKeepAlive();
      // بلا انتظار: تجديد خلفي ينعش رمز الوصول إن كان منتهيًا
      unawaited(tryRefresh());
    }
  }

  /// حفظ زوج الرموز (الوصول + التحديث إن وُجد)
  Future<void> saveToken(String token, {String? refreshToken}) async {
    _token = token;
    _refreshRejected = false;
    if (refreshToken != null && refreshToken.isNotEmpty) _refreshToken = refreshToken;
    try {
      await _secure.write(key: _kToken, value: token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secure.write(key: _kRefresh, value: refreshToken);
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
    _startKeepAlive();
  }

  /// مسح الجلسة عند الخروج أو انتهائها النهائي
  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    _refreshRejected = false;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    try {
      await _secure.delete(key: _kToken);
      await _secure.delete(key: _kRefresh);
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  /// مؤقت التجديد الاستباقي: يدوّر رمز التحديث كل 10 دقائق طالما الجلسة حية،
  /// فلا يمر رمز الوصول على انتهائه أصلاً ولا يقترب رمز التحديث من 30 يوماً
  void _startKeepAlive() {
    if (_refreshToken == null || _refreshToken!.isEmpty) return;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
      if (isAuthenticated && _refreshCompleter == null) {
        debugPrint('Session keep-alive: proactive token refresh');
        unawaited(tryRefresh());
      }
    });
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

      // رفض حاسم من الخادم: رمز التحديث مُبطَل من الأدمن أو منتهي أو مُدار
      // — هذه هي نقطة نهاية الجلسة الوحيدة غير اليدوية
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        debugPrint('Refresh token rejected by server (${response.statusCode})');
        _refreshRejected = true;
      } else {
        // 5xx وأكواد أخرى: خلل خادم مؤقت — الجلسة تبقى وتُعاد المحاولة لاحقًا
        debugPrint('Refresh endpoint error ${response.statusCode} — keeping session');
      }
      if (!completer.isCompleted) completer.complete(false);
    } catch (e) {
      // انقطاع شبكة/مهلة: لا يُعتبر رفضًا — الجلسة تبقى ويُعاد المحاولة مع الطلب القادم
      debugPrint('Session refresh network error: $e');
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  /// معالجة 401 بعد فشل التجديد — الجلسة تنتهي فقط عند رفض حاسم من الخادم
  /// (إبطال الأدمن أو انتهاء صلاحية رمز التحديث). أخطاء الشبكة تُترك للتجديد لاحقًا.
  void handleUnauthorizedResponse() {
    if (!isAuthenticated) return;
    if (!_refreshRejected) {
      debugPrint('HTTP 401 with non-rejected refresh token — session preserved, will retry');
      return;
    }
    debugPrint('Session ended: refresh token rejected by server (admin revocation or expiry)');
    _refreshRejected = false;
    clearToken();
    AppEvents().triggerSessionExpired('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
  }

  /// إعادة ضبط عداد الرفض عند أي استجابة ناجحة
  void resetUnauthorizedCount() {
    _refreshRejected = false;
  }

  /// تسجيل خروج كامل (يدوي): إبطال رمز التحديث في الخادم ثم مسح الجلسة المحلية
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
