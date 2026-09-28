// اختبار وحدة — إحياء التجديد الصامت للتوكن:
// 401 ← tryRefresh ← إعادة الطلب تنجح، والجلسة تنجو من انتهاء access token.
// (كان clearSession يُمسح عند أول 401 فيُقتل refresh token ويُطرد المدير كل 15 دقيقة)
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:al_fadaa_admin/core/network/http_client.dart';
import 'package:al_fadaa_admin/core/network/session_manager.dart';
import 'package:al_fadaa_admin/models/admin_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.refreshClientOverride = null;
  });

  tearDown(() {
    SessionManager.refreshClientOverride = null;
  });

  AdminUser adminUser() => AdminUser(
        id: 'u-1',
        email: 'gm@al-fadaa.com',
        name: 'المدير العام',
        role: 'GM',
      );

  test('401 ← تجديد ناجح ← إعادة الطلب تنجح بالتوكن الجديد والجلسة تنجو', () async {
    final session = SessionManager();
    await session.saveSession('old-access', adminUser(), refreshToken: 'refresh-1');
    expect(session.isAuthenticated, isTrue);

    // عميل الطلب: أول نداء 401، وبعد التجديد 200 — ونسجل ترويسة كل نداء
    final authHeaders = <String?>[];
    var requestCount = 0;
    final requestClient = MockClient((req) async {
      requestCount++;
      authHeaders.add(req.headers['Authorization']);
      if (requestCount == 1) {
        return http.Response('{"message":"expired"}', 401);
      }
      return http.Response('{"ok":true}', 200);
    });

    // عميل التجديد: يرجع توكنات جديدة
    SessionManager.refreshClientOverride = () => MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['refreshToken'], 'refresh-1');
          return http.Response(
            jsonEncode({'accessToken': 'new-access', 'refreshToken': 'refresh-2'}),
            200,
          );
        });

    final client = AdminHttpClient.forTest(requestClient);
    final res = await client.get(Uri.parse('http://localhost:3000/api/v1/anything'));

    // الطلب أعيد ونبح بنجاح بالتوكن الجديد
    expect(requestCount, 2);
    expect(authHeaders[0], 'Bearer old-access');
    expect(authHeaders[1], 'Bearer new-access');
    expect(res.statusCode, 200);
    // الجلسة نجت: توكن جديد محفوظ ولا بث انتهاء جلسة
    expect(session.token, 'new-access');
    expect(session.isAuthenticated, isTrue);
    expect(session.sessionExpiredTick.value, 0);
  });

  test('فشل التجديد هو نقطة موت الجلسة الوحيدة — تُبثّ وتُمسح', () async {
    final session = SessionManager();
    await session.saveSession('old-access', adminUser(), refreshToken: 'refresh-1');
    final tickBefore = session.sessionExpiredTick.value;

    final requestClient = MockClient((req) async => http.Response('{"message":"expired"}', 401));
    // التجديد يفشل (رمز محدث مرفوض)
    SessionManager.refreshClientOverride =
        () => MockClient((req) async => http.Response('{"message":"invalid"}', 401));

    final client = AdminHttpClient.forTest(requestClient);

    await expectLater(
      client.get(Uri.parse('http://localhost:3000/api/v1/anything')),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(session.token, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.sessionExpiredTick.value, tickBefore + 1);
  });

  test('401 ثانٍ بعد تجديد ناجح يعني انتهاء الجلسة فعلاً — لا حلقة لا نهائية', () async {
    final session = SessionManager();
    await session.saveSession('old-access', adminUser(), refreshToken: 'refresh-1');
    // العدّاد تراكمي عبر الاختبارات (singleton) — نقارن نسبيًا
    final tickBefore = session.sessionExpiredTick.value;

    // كل الطلبات 401 رغم التجديد الناجح (رمز مبطَّل من الخادم)
    SessionManager.refreshClientOverride = () => MockClient((req) async {
          return http.Response(
            jsonEncode({'accessToken': 'new-access', 'refreshToken': 'refresh-2'}),
            200,
          );
        });
    final requestClient = MockClient((req) async => http.Response('{"message":"revoked"}', 401));

    final client = AdminHttpClient.forTest(requestClient);

    await expectLater(
      client.get(Uri.parse('http://localhost:3000/api/v1/anything')),
      throwsA(isA<UnauthorizedException>()),
    );
    // انتهت الجلسة بثقة — ولم يُعاد الطلب أكثر من مرتين
    expect(session.isAuthenticated, isFalse);
    expect(session.sessionExpiredTick.value, tickBefore + 1);
  });
}
