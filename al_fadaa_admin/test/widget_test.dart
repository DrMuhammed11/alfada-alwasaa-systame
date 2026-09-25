// اختبار دخان لشاشة دخول الأدمن — يضمن بناء الواجهة بدون أي بيانات تجريبية معبأة

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:al_fadaa_admin/views/auth/admin_login_screen.dart';

void main() {
  testWidgets('شاشة دخول الأدمن تُبنى وتعرض زر الدخول', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));
    await tester.pump();

    expect(find.text('دخول لوحة التحكم'), findsOneWidget);
    // لا رقاقات حسابات تجريبية خارج وضع العرض DEMO_MODE
    expect(find.text('حسابات الدخول المصرحة للتجربة:'), findsNothing);
  });
}
