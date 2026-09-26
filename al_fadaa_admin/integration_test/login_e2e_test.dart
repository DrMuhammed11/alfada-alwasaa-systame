// اختبار تكامل E2E كامل على جهاز حقيقي — مقابل الخادم السحابي المنشور:
// 1) بيانات خاطئة → رسالة الرفض الصحيحة
// 2) بيانات صحيحة → وصول اللوحة الرئيسية (إحصائيات/تحليلات)
//
// التشغيل:
//   flutter test integration_test/login_e2e_test.dart -d <device-id> \
//     --dart-define=API_URL=https://alfada-alwasaa-systame.onrender.com/api/v1

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:al_fadaa_admin/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('بيانات خاطئة → رسالة رفض صحيحة دون دخول', (tester) async {
    await tester.pumpWidget(const AlFadaaAdminApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('دخول لوحة التحكم'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'admin@al-fadaa.com');
    await tester.enterText(find.byType(TextField).at(1), 'WrongPass@9999');
    await tester.pump();
    await tester.tap(find.text('دخول لوحة التحكم'));

    // انتظار استجابة الخادم — ضخّات ثابتة (مؤقتات اللوحة تمنع pumpAndSettle)
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(
      find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
      findsOneWidget,
      reason: 'الخادم يجب أن يرفض البيانات الخاطئة برسالة عربية واضحة',
    );
    // ولم يقع أي دخول
    expect(find.text('لوحة الإحصائيات والتحليلات'), findsNothing);
  });

  testWidgets('بيانات صحيحة → دخول فعلي حتى لوحة الإحصائيات والتحليلات', (tester) async {
    await tester.pumpWidget(const AlFadaaAdminApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // إن كانت جلسة سابقة مفتوحة فنجاح الدخول محسوم — نتحقق مباشرة
    final alreadyIn = find.text('لوحة الإحصائيات والتحليلات').evaluate().isNotEmpty;
    if (!alreadyIn) {
      expect(find.text('دخول لوحة التحكم'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'admin@al-fadaa.com');
      await tester.enterText(find.byType(TextField).at(1), 'Alfadaa@2026');
      await tester.pump();
      await tester.tap(find.text('دخول لوحة التحكم'));

      // انتظار round-trip الخادم السحابي + بناء اللوحة (حتى 30 ثانية)
      var reached = false;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('لوحة الإحصائيات والتحليلات').evaluate().isNotEmpty) {
          reached = true;
          break;
        }
        // فشل صريح برسالة رفض يعني توقف المسار — نستمر بالضخ لالتقاط الحالة النهائية
      }
      expect(
        reached,
        true,
        reason: 'الدخول بالبيانات الصحيحة يجب أن يصل للوحة الإحصائيات خلال 30 ثانية',
      );
    }

    // عناصر اللوحة الحقيقية بعد الدخول
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('لوحة الإحصائيات والتحليلات'), findsOneWidget);
    expect(find.text('الفترة:'), findsOneWidget);
  });
}
