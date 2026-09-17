import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/session_manager.dart';
import 'core/theme/admin_theme.dart';
import 'views/auth/admin_login_screen.dart';
import 'views/dashboard/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager().init();
  runApp(const AlFadaaAdminApp());
}

class AlFadaaAdminApp extends StatelessWidget {
  const AlFadaaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final isLoggedIn = session.isAuthenticated && (session.currentUser?.hasAdminPrivilege ?? false);

    return MaterialApp(
      title: 'الفضاء الواسع — بوابة الإدارة والرقابة',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: isLoggedIn ? const AdminMainScreen() : const AdminLoginScreen(),
    );
  }
}
