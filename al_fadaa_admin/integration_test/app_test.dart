// اختبار تكامل دخان على جهاز حقيقي — التطبيق يقلع ويعرض شاشة الدخول
// التشغيل: flutter test integration_test -d <device-id>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:al_fadaa_admin/main.dart';
import 'package:al_fadaa_admin/views/dashboard/admin_main_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('التطبيق يقلع ويعرض شاشة دخول الأدمن', (tester) async {
    await tester.pumpWidget(const AlFadaaAdminApp());
    await tester.pump();

    // تثبيت جديد بلا جلسة → شاشة الدخول، لا لوحة التحكم
    expect(find.text('دخول لوحة التحكم'), findsOneWidget);
    expect(find.byType(AdminMainScreen), findsNothing);
  });
}
