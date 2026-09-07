import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/api_service.dart';
import 'core/theme/app_theme.dart';
import 'models/user_model.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    User? user;
    try {
      user = await ApiService().getMe().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          : _currentUser != null
              ? DashboardScreen(user: _currentUser!)
              : const LoginScreen(),
    );
  }
}
