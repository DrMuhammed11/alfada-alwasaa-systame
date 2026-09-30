import 'package:boosthis_flutter/boosthis_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/session_manager.dart';
import 'core/theme/admin_theme.dart';
import 'views/auth/admin_login_screen.dart';
import 'views/dashboard/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // قياس الأداء Boosthis — الهوية ثابتة لكل هذا التثبيت ولا تتغير
  BoosthisFlutter.start(installId: '9b2fa877-a815-4f06-b1f0-a304d217f029');
  await SessionManager().init();
  BoosthisFlutter.run(() => runApp(const AlFadaaAdminApp()));
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
