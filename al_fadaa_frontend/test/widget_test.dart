// اختبار دخان لشاشة الدخول — يضمن بناء الواجهة بحقلي البريد وكلمة المرور
// (استُبدل قالب العداد الافتراضي الذي كان يفشل فورًا ضد هذا التطبيق)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:al_fadaa_frontend/views/auth/login_screen.dart';

void main() {
  testWidgets('شاشة الدخول تُبنى بحقلي البريد وكلمة المرور وزر الدخول', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
