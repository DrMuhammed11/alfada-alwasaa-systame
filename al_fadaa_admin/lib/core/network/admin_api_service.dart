import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/admin_user_model.dart';
import '../../models/analytics_model.dart';
import '../../models/audit_model.dart';
import '../../models/correspondence_model.dart';
import 'http_client.dart';
import 'session_manager.dart';

class AdminApiService {
  static final AdminApiService _instance = AdminApiService._internal();
  factory AdminApiService() => _instance;
  AdminApiService._internal();

  final AdminHttpClient _http = AdminHttpClient();

  // ─── المصادقة والدخول الإداري ───
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // login-v2 يعيد رمز تحديث قابل للتجديد الصامت — والخادم القديم (قبل الترقية)
      // لا يعرفه (404) فنسقط تلقائياً إلى /auth/login العادي، فيعمل التطبيق مع الإصدارين
      var uri = Uri.parse('${ApiConstants.baseUrl}/auth/login-v2');
      var response = await _http.post(
        uri,
        body: {'email': email.trim(), 'password': password},
      );
      if (response.statusCode == 404) {
        uri = Uri.parse('${ApiConstants.baseUrl}/auth/login');
        response = await _http.post(
          uri,
          body: {'email': email.trim(), 'password': password},
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final token = body['accessToken'] ?? body['token'] ?? body['access_token'];
        final refreshToken = body['refreshToken'] as String?;
        final userData = body['user'];

        if (token != null && userData != null) {
          final user = AdminUser.fromJson(userData);
          // التحقق من أن المستخدم لديه صلاحيات الإدارة
          if (!user.hasAdminPrivilege) {
            return {
              'success': false,
              'message': 'الحساب ليس لديه صلاحية الدخول إلى لوحة الإدارة العليا',
            };
          }

          await SessionManager().saveSession(token, user, refreshToken: refreshToken);
          return {'success': true, 'user': user};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'البريد الإلكتروني أو كلمة المرور غير صحيحة'};
      } else {
        final err = jsonDecode(response.body);
        return {
          'success': false,
          'message': messageOf(err),
        };
      }
    } on UnauthorizedException {
      return {'success': false, 'message': 'البريد الإلكتروني أو كلمة المرور غير صحيحة'};
    } catch (e) {
      debugPrint('Admin login error: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم: $e'};
    }
    return {'success': false, 'message': 'فشل تسجيل الدخول'};
  }

  // ─── لوحة الإحصائيات التحليلية ───
  Future<AdminAnalyticsData?> getAnalytics({
    String? period,
    String? departmentId,
    String? from,
    String? to,
  }) async {
    try {
      final params = <String, String>{};
      if (period != null && period.isNotEmpty) params['period'] = period;
      if (departmentId != null && departmentId != 'ALL') params['departmentId'] = departmentId;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;

      final uri = Uri.parse(ApiConstants.adminAnalytics).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return AdminAnalyticsData.fromJson(body);
      }
    } catch (e) {
      debugPrint('getAnalytics error: $e');
    }
    return null;
  }

  /// استخراج رسالة الخطأ العربية من كائن خطأ — يدعم المصفوفات من ValidationPipe
  static String messageOf(dynamic err) {
    final msg = err is Map ? err['message'] : null;
    if (msg is List) return msg.join(' — ');
    if (msg != null) return msg.toString();
    return 'فشل الطلب';
  }

  // ─── إدارة المستخدمين ───
  /// قائمة المستخدمين مع الفلاتر والترقيم — يعيد صفحة كاملة
  /// (العناصر + العدد الكلي + عدد الصفحات) مع راية خطأ لتمييز فشل الطلب عن غياب النتائج
  Future<UsersPage> getUsers({
    String? search,
    String? departmentId,
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      if (departmentId != null && departmentId != 'ALL') params['departmentId'] = departmentId;
      if (role != null && role != 'ALL') params['role'] = role;

      final uri = Uri.parse(ApiConstants.users).replace(queryParameters: params);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        final meta = body['meta'] is Map ? body['meta'] as Map<String, dynamic> : const <String, dynamic>{};
        final items = list.map((u) => AdminUser.fromJson(u)).toList();
        return UsersPage(
          items: items,
          page: (meta['page'] as num?)?.toInt() ?? page,
          totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
          total: (meta['total'] as num?)?.toInt() ?? items.length,
        );
      }
      debugPrint('getUsers failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getUsers error: $e');
    }
    return UsersPage(items: [], page: page, totalPages: 1, total: 0, error: true);
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.users);
      final payload = {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (departmentId != null && departmentId != 'ALL' && departmentId.isNotEmpty) 'departmentId': departmentId,
      };

      final response = await _http.post(uri, body: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': messageOf(err)};
      }
    } catch (e) {
      debugPrint('createUser error: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id, {
    String? name,
    String? email,
    String? role,
    String? departmentId,
    bool? isActive,
    String? password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.users}/$id');
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (email != null) payload['email'] = email.trim();
      if (role != null) payload['role'] = role;
      if (departmentId != null) {
        payload['departmentId'] = departmentId == 'NONE' ? null : departmentId;
      }
      if (isActive != null) payload['isActive'] = isActive;
      if (password != null && password.isNotEmpty) payload['password'] = password;

      final response = await _http.patch(uri, body: payload);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': messageOf(err)};
      }
    } catch (e) {
      debugPrint('updateUser error: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.users}/$id');
      final response = await _http.delete(uri);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('deleteUser error: $e');
      return false;
    }
  }

  // ─── إدارة الأقسام ───
  // كاش قصير الأمد: أربع شاشات تجلب الأقسام عند كل فتح وعملياتها النادرة تمر من هنا
  // فيُبطل الكاش عند أي إنشاء/تعديل/حذف، ويمكن تجاوزه بـ forceRefresh
  static const Duration _deptsCacheTtl = Duration(seconds: 60);
  List<Department>? _deptsCache;
  DateTime? _deptsCacheAt;

  void invalidateDepartmentsCache() {
    _deptsCache = null;
    _deptsCacheAt = null;
  }

  Future<ApiListResult<Department>> getDepartments({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _deptsCache != null &&
        _deptsCacheAt != null &&
        DateTime.now().difference(_deptsCacheAt!) < _deptsCacheTtl) {
      return ApiListResult(items: _deptsCache!);
    }
    try {
      final uri = Uri.parse(ApiConstants.departments);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        final depts = list.map((d) => Department.fromJson(d)).toList();
        _deptsCache = depts;
        _deptsCacheAt = DateTime.now();
        return ApiListResult(items: depts);
      }
      debugPrint('getDepartments failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getDepartments error: $e');
    }
    return const ApiListResult(items: [], error: true);
  }

  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
    String? managerId,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.departments);
      final payload = {
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
        if (managerId != null && managerId.isNotEmpty && managerId != 'NONE') 'managerId': managerId,
      };

      final response = await _http.post(uri, body: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        invalidateDepartmentsCache();
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': messageOf(err)};
      }
    } catch (e) {
      debugPrint('createDepartment error: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDepartment(
    String id, {
    String? name,
    String? code,
    String? managerId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.departments}/$id');
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (code != null) payload['code'] = code.trim().toUpperCase();
      if (managerId != null) {
        payload['managerId'] = managerId == 'NONE' ? null : managerId;
      }

      final response = await _http.patch(uri, body: payload);
      if (response.statusCode == 200) {
        invalidateDepartmentsCache();
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': messageOf(err)};
      }
    } catch (e) {
      debugPrint('updateDepartment error: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<bool> deleteDepartment(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.departments}/$id');
      final response = await _http.delete(uri);
      if (response.statusCode == 200 || response.statusCode == 204) {
        invalidateDepartmentsCache();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('deleteDepartment error: $e');
      return false;
    }
  }

  // ─── سجل التدقيق والرقابة ───
  /// جلب سجلات التدقيق مع الفلاتر الخدمية والترقيم — يعيد صفحة كاملة
  /// (العناصر + العدد الكلي + عدد الصفحات) مع راية خطأ لتمييز فشل الطلب عن غياب النتائج.
  Future<AuditLogsPage> getAuditLogs({
    String? q,
    String? action,
    String? from,
    String? to,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (action != null && action.isNotEmpty && action != 'ALL') params['action'] = action;
      if (from != null && from.isNotEmpty) params['from'] = from;
      if (to != null && to.isNotEmpty) params['to'] = to;

      final uri = Uri.parse(ApiConstants.audit).replace(queryParameters: params);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        final items = list.map((a) => AuditLogItem.fromJson(a)).toList();
        final meta = body['meta'] is Map ? body['meta'] as Map<String, dynamic> : const <String, dynamic>{};
        return AuditLogsPage(
          items: items,
          page: (meta['page'] as num?)?.toInt() ?? page,
          totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
          total: (meta['total'] as num?)?.toInt() ?? items.length,
        );
      }
      debugPrint('getAuditLogs failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getAuditLogs error: $e');
    }
    return AuditLogsPage(items: [], page: page, totalPages: 1, total: 0, error: true);
  }

  Future<AuditIntegrityReport?> verifyAuditIntegrity({int limit = 1000}) async {
    try {
      final uri = Uri.parse('${ApiConstants.audit}/verify?limit=$limit');
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        return AuditIntegrityReport.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('verifyAuditIntegrity error: $e');
    }
    return null;
  }

  // ─── التشغيل: الصادر / الاعتماد / اليتامى / الوكالات / النسخ الاحتياطي ───

  /// قائمة صندوق البريد الصادر مع الفلترة والترقيم
  Future<Map<String, dynamic>?> getOutbox({String? status, int page = 1, int limit = 20}) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (status != null && status != 'ALL') params['status'] = status;
      final uri = Uri.parse('${ApiConstants.baseUrl}/admin/outbox').replace(queryParameters: params);
      final response = await _http.get(uri);
      if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
      debugPrint('getOutbox failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getOutbox error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> retryOutbox(String id) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.baseUrl}/admin/outbox/$id/retry'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'__error': messageOf(jsonDecode(response.body))};
    } catch (e) {
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>?> pauseOutbox(String id) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.baseUrl}/admin/outbox/$id/pause'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'__error': messageOf(jsonDecode(response.body))};
    } catch (e) {
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  /// مسارات الاعتماد المضبوطة للأولويات
  Future<ApiListResult<Map<String, dynamic>>> getWorkflows() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/admin/approval-workflows'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return ApiListResult(items: list.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      debugPrint('getWorkflows failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getWorkflows error: $e');
    }
    return const ApiListResult(items: [], error: true);
  }

  Future<Map<String, dynamic>?> updateWorkflow(String priority, List<Map<String, String>> steps) async {
    try {
      final response = await _http.put(
        Uri.parse('${ApiConstants.baseUrl}/admin/approval-workflows'),
        body: {'priority': priority, 'steps': steps},
      );
      if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
      return {'__error': messageOf(jsonDecode(response.body))};
    } catch (e) {
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  /// الكيانات اليتيمة المعلقة
  Future<Map<String, dynamic>?> getOrphans() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/admin/orphans'));
      if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (e) {
      debugPrint('getOrphans error: $e');
    }
    return null;
  }

  /// سجل كل التفويضات في النظام
  Future<ApiListResult<Map<String, dynamic>>> getDelegations() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/delegations'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return ApiListResult(items: list.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      debugPrint('getDelegations failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getDelegations error: $e');
    }
    return const ApiListResult(items: [], error: true);
  }

  Future<Map<String, dynamic>?> terminateDelegation(String id) async {
    try {
      final response = await _http.patch(Uri.parse('${ApiConstants.baseUrl}/delegations/$id/terminate'));
      if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
      return {'__error': messageOf(jsonDecode(response.body))};
    } catch (e) {
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  /// حالة النسخ الاحتياطي
  Future<Map<String, dynamic>?> getBackupStatus() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/admin/backups/status'));
      if (response.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (e) {
      debugPrint('getBackupStatus error: $e');
    }
    return null;
  }

  /// تغيير كلمة المرور الذاتي — يبطل كل الجلسات الأخرى
  Future<Map<String, dynamic>> changeMyPassword(String currentPassword, String newPassword) async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/auth/password'),
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': messageOf(jsonDecode(response.body))};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
  Future<Map<String, dynamic>> resendFailedMails() async {
    try {
      final uri = Uri.parse(ApiConstants.resendFailedMails);
      final response = await _http.post(uri);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'تمت إعادة محاولة إرسال الرسائل المعلقة بنجاح'};
      }
    } catch (e) {
      debugPrint('resendFailedMails error: $e');
    }
    return {'success': false, 'message': 'تعذر إعادة إرسال البريد'};
  }

  // ─── إدارة المراسلات (نطاق الإدارة العليا: كل المراسلات) ───

  /// قائمة المراسلات الجذرية مع الفلاتر والترقيم — يعيد (العناصر + العدد الكلي + عدد الصفحات)
  Future<CorrPage> getCorrespondences({
    String? type,
    String? status,
    String? priority,
    String? departmentId,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (type != null && type != 'ALL') params['type'] = type;
      if (status != null && status != 'ALL') params['status'] = status;
      if (priority != null && priority != 'ALL') params['priority'] = priority;
      if (departmentId != null && departmentId != 'ALL') params['departmentId'] = departmentId;
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

      final uri = Uri.parse(ApiConstants.correspondences).replace(queryParameters: params);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['data'] ?? [];
        final items = list.map((c) => CorrListItem.fromJson(Map<String, dynamic>.from(c))).toList();
        final meta = body['meta'] is Map ? body['meta'] as Map<String, dynamic> : const <String, dynamic>{};
        return CorrPage(
          items: items,
          page: (meta['page'] as num?)?.toInt() ?? page,
          totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
          total: (meta['total'] as num?)?.toInt() ?? items.length,
        );
      }
      debugPrint('getCorrespondences failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getCorrespondences error: $e');
    }
    return CorrPage(items: [], page: page, totalPages: 1, total: 0, error: true);
  }

  /// تفاصيل مراسلة كاملة (الإحالات / التكليفات / الردود / المرفقات)
  Future<CorrDetail?> getCorrespondence(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.correspondences}/$id');
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        return CorrDetail.fromJson(jsonDecode(response.body));
      }
      debugPrint('getCorrespondence failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getCorrespondence error: $e');
    }
    return null;
  }

  // ─── إدارة محتوى الموقع الإلكتروني ───

  /// قائمة عناصر مجموعة محتوى (services / sectors / projects / faqs) — شاملة غير المفعّلة
  Future<ApiListResult<Map<String, dynamic>>> getContentList(String kind) async {
    try {
      final uri = Uri.parse(ApiConstants.siteContentKind(kind));
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return ApiListResult(items: list.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      debugPrint('getContentList($kind) failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getContentList($kind) error: $e');
    }
    return const ApiListResult(items: [], error: true);
  }

  Future<Map<String, dynamic>?> createContent(String kind, Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse(ApiConstants.siteContentKind(kind));
      final response = await _http.post(uri, body: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'__error': _errorMessage(response)};
    } catch (e) {
      debugPrint('createContent($kind) error: $e');
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>?> updateContent(String kind, String id, Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse(ApiConstants.siteContentKindId(kind, id));
      final response = await _http.patch(uri, body: payload);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'__error': _errorMessage(response)};
    } catch (e) {
      debugPrint('updateContent($kind) error: $e');
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  Future<bool> deleteContent(String kind, String id) async {
    try {
      final uri = Uri.parse(ApiConstants.siteContentKindId(kind, id));
      final response = await _http.delete(uri);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('deleteContent($kind) error: $e');
      return false;
    }
  }

  /// كل الإعدادات العامة (contacts / stats / pillars / values ...)
  Future<ApiListResult<Map<String, dynamic>>> getSiteSettings() async {
    try {
      final uri = Uri.parse('${ApiConstants.siteContentManage}/settings');
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return ApiListResult(items: list.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      debugPrint('getSiteSettings failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('getSiteSettings error: $e');
    }
    return const ApiListResult(items: [], error: true);
  }

  Future<Map<String, dynamic>?> upsertSiteSetting(String key, dynamic value, {String? description}) async {
    try {
      final uri = Uri.parse(ApiConstants.siteContentSetting(key));
      final response = await _http.put(uri, body: {
        'value': value,
        if (description != null) 'description': description,
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return {'__error': _errorMessage(response)};
    } catch (e) {
      debugPrint('upsertSiteSetting($key) error: $e');
      return {'__error': 'خطأ في الاتصال: $e'};
    }
  }

  /// استخراج رسالة الخطأ العربية من استجابة الخادم إن وُجدت
  String _errorMessage(http.Response response) {
    try {
      final err = jsonDecode(response.body);
      final msg = err['message'];
      if (msg is List) return msg.join(' — ');
      if (msg != null) return msg.toString();
    } catch (_) {}
    return 'فشل الطلب (${response.statusCode})';
  }
}

/// صفحة من قائمة المراسلات — نتيجة استعلام مفلتر ومقسّم إلى صفحات
class CorrPage {
  final List<CorrListItem> items;
  final int page;
  final int totalPages;
  final int total;

  /// true يعني فشل الطلب (اتصال/خادم) — وليس غياب النتائج
  final bool error;

  CorrPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.error = false,
  });
}

/// صفحة من قائمة المستخدمين — نتيجة استعلام مفلتر ومقسّم إلى صفحات
class UsersPage {
  final List<AdminUser> items;
  final int page;
  final int totalPages;
  final int total;

  /// true يعني فشل الطلب (اتصال/خادم) — وليس غياب النتائج
  final bool error;

  UsersPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.error = false,
  });
}

/// نتيجة قائمة غير مرقّمة مع راية خطأ لتمييز فشل الطلب عن غياب النتائج
class ApiListResult<T> {
  final List<T> items;

  /// true يعني فشل الطلب (اتصال/خادم) — وليس غياب النتائج
  final bool error;

  const ApiListResult({required this.items, this.error = false});
}
