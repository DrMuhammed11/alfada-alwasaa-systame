import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/api_service.dart';
import 'core/network/app_events.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/page_transitions.dart';
import 'core/utils/in_app_notification_manager.dart';
import 'core/utils/system_notification_service.dart';
import 'models/user_model.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// سلوك تمرير مخصص يدعم الماوس واللوحة اللمسية والقلم
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiService().init();
  } catch (e) {
    debugPrint('ApiService init error: $e');
  }
  runApp(const AlFadaaApp());
}

class AlFadaaApp extends StatefulWidget {
  const AlFadaaApp({super.key});

  @override
  State<AlFadaaApp> createState() => _AlFadaaAppState();
}

class _AlFadaaAppState extends State<AlFadaaApp> {
  User? _currentUser;
  bool _isCheckingAuth = true;
  bool _authCheckFailed = false;
  String? _authErrorMessage;
  StreamSubscription<String>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuth();

    // تهيئة مدير التنبيهات المنبثقة التفاعلية اللحظية
    InAppNotificationManager().init(
      navigatorKey: appNavigatorKey,
    );

    // طلب إذن إشعارات المتصفح والنظام
    SystemNotificationService().requestPermission();

    // الاستماع لحدث انتهاء الجلسة المركزي عند خطأين 401 متتاليين
    _sessionExpiredSubscription = AppEvents().onSessionExpired.listen((message) {
      if (!mounted) return;
      setState(() {
        _currentUser = null;
      });
      appNavigatorKey.currentState?.pushAndRemoveUntil(
        EnterprisePageRoute(page: const LoginScreen()),
        (route) => false,
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    InAppNotificationManager().dispose();
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    setState(() {
      _isCheckingAuth = true;
      _authCheckFailed = false;
      _authErrorMessage = null;
    });

    if (ApiService().token == null) {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isCheckingAuth = false;
        });
      }
      return;
    }

    User? user;
    bool isUnauthorized = false;
    String? failureMessage;

    // مهلة 10 ثوانٍ مع محاولة إعادة واحدة عند حدوث Timeout أو مشكلة شبكية مؤقتة
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        user = await ApiService().getMe(timeout: const Duration(seconds: 10));
        break;
      } on UnauthorizedException {
        isUnauthorized = true;
        break; // خطأ 401 قطعي ولا يحتاج إعادة المحاولة
      } catch (e) {
        debugPrint('Auth check attempt $attempt error: $e');
        if (attempt == 1) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          failureMessage = 'الخادم يستغرق وقتًا أطول من المعتاد للاستجابة. يرجى إعادة المحاولة دون فقدان جلستك.';
        }
      }
    }

    if (!mounted) return;

    if (isUnauthorized) {
      await ApiService().clearToken();
      setState(() {
        _currentUser = null;
        _isCheckingAuth = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text(
              'انتهت الجلسة، يرجى تسجيل الدخول مجددًا',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    } else if (user != null) {
      setState(() {
        _currentUser = user;
        _isCheckingAuth = false;
      });
    } else {
      setState(() {
        _isCheckingAuth = false;
        _authCheckFailed = true;
        _authErrorMessage = failureMessage ?? 'تعذر التحقق من الجلسة بسبب بطء أو انقطاع الاتصال بالخادم';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      title: 'نظام إدارة المراسلات — شركة الفضاء الواسع',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      home: _isCheckingAuth
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _authCheckFailed
              ? _buildAuthErrorScreen()
              : _currentUser != null
                  ? DashboardScreen(user: _currentUser!)
                  : const LoginScreen(),
    );
  }

  Widget _buildAuthErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          width: 440,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.amberAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تعذر التحقق من الجلسة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _authErrorMessage ?? 'الخادم يستغرق وقتًا أطول من المعتاد للاستجابة. يمكنك إعادة المحاولة دون فقدان جلستك.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textOnLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _checkAuth,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ApiService().clearToken();
                  setState(() {
                    _currentUser = null;
                    _authCheckFailed = false;
                  });
                },
                child: const Text(
                  'تسجيل الخروج والعودة لشاشة الدخول',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
