// جولة تدقيق شاملة لكل صفحات التطبيق على جهاز حقيقي:
// يتجاول الأقسام السبعة + التبويبات الفرعية، ويحفظ لقطة موثقة لكل صفحة
// في مجلد الملفات الخارجي للتطبيق (تُجلب عبر adb ثم تُراجع بصرياً).
//
// التشغيل:
//   flutter test integration_test/ui_audit_test.dart -d <device-id> \
//     --dart-define=API_URL=https://alfada-alwasaa-systame.onrender.com/api/v1

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:al_fadaa_admin/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('جولة تدقيق كل الصفحات مع لقطات موثقة', (tester) async {
    /// حفظ لقطة الصفحة الحالية في مجلد قابل للسحب عبر adb
    /// (على الأندرويد الحقيقي: تحويل السطح إلى صورة قبل الالتقاط)
    Future<void> shot(String name) async {
      try {
        await binding.convertFlutterSurfaceToImage();
        final bytes = await binding.takeScreenshot(name);
        final dir = Directory(
          '/storage/emulated/0/Android/data/com.alfadaa.admin.al_fadaa_admin/files/ui_audit',
        );
        dir.createSync(recursive: true);
        File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      } catch (e) {
        debugPrint('shot($name) error: $e');
      }
    }

    /// ضخّات ثابتة لانتظار تحميل بيانات الشاشة (مؤقتات اللوحة تمنع pumpAndSettle)
    Future<void> settle(int seconds) async {
      for (var i = 0; i < seconds; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    /// الانتقال لقسم من الشريط السفلي
    Future<void> gotoSection(String label) async {
      await tester.tap(find.text(label));
      await settle(5);
    }

    /// تبديل تبويب داخل صفحة بأرقام التبويبات
    Future<void> gotoTab(int index, {int settleSeconds = 4}) async {
      await tester.tap(find.byType(Tab).at(index));
      await settle(settleSeconds);
    }

    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AlFadaaAdminApp());
    await settle(6);

    // ═══ 1) لوحة الإحصائيات (الافتراضية) ═══
    await shot('01_analytics');

    // ═══ 2) المراسلات + تفاصيل أول معاملة ═══
    await gotoSection('المراسلات للمستخدمة...');
    await shot('02_correspondences');
    final cards = find.byType(Card);
    if (cards.evaluate().isNotEmpty) {
      await tester.tap(cards.first);
      await settle(4);
      await shot('03_correspondence_detail');
      // إغلاق نافذة التفاصيل
      final closeIcons = find.byIcon(Icons.close_rounded);
      if (closeIcons.evaluate().isNotEmpty) {
        await tester.tap(closeIcons.first);
        await settle(2);
      }
    }

    // ═══ 3) المستخدمون ═══
    await gotoSection('المستخدمين');
    await shot('04_users');

    // ═══ 4) الأقسام ═══
    await gotoSection('الأقسام');
    await shot('05_departments');

    // ═══ 5) محتوى الموقع — الخدمات ثم الأسئلة ثم الإعدادات ═══
    await gotoSection('المحتوى');
    await shot('06_content_services');
    await gotoTab(3);
    await shot('07_content_faqs');
    await gotoTab(4);
    await shot('08_content_settings');

    // ═══ 6) التشغيل — الصادر/الاعتماد/اليتامى/الوكالات/النسخ ═══
    await gotoSection('التشغيل');
    await shot('09_operations_outbox');
    await gotoTab(1);
    await shot('10_workflows');
    await gotoTab(2);
    await shot('11_orphans');
    await gotoTab(3);
    await shot('12_delegations');
    await gotoTab(4);
    await shot('13_backup');

    // ═══ 7) سجل التدقيق ═══
    await gotoSection('التدقيق');
    await shot('14_audit');

    // العودة للإحصائيات كحالة ختامية
    await gotoSection('الإحصائيات');
    await shot('15_back_to_analytics');
  });
}
