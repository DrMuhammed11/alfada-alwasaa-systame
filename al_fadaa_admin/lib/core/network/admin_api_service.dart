import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../../models/admin_user_model.dart';
import '../../models/analytics_model.dart';
import '../../models/audit_model.dart';
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
      final uri = Uri.parse(ApiConstants.login);
      final response = await _http.post(
        uri,
        body: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final token = body['accessToken'] ?? body['token'] ?? body['access_token'];
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

          await SessionManager().saveSession(token, user);
          return {'success': true, 'user': user};
        }
      } else {
        final err = jsonDecode(response.body);
        return {
          'success': false,
          'message': err['message'] ?? 'بيانات الدخول غير صحيحة',
        };
      }
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

  // ─── إدارة المستخدمين ───
  Future<List<AdminUser>> getUsers({String? search, String? departmentId, String? role}) async {
    try {
      final params = <String, String>{'limit': '100'};
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      if (departmentId != null && departmentId != 'ALL') params['departmentId'] = departmentId;
      if (role != null && role != 'ALL') params['role'] = role;

      final uri = Uri.parse(ApiConstants.users).replace(queryParameters: params);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return list.map((u) => AdminUser.fromJson(u)).toList();
      }
    } catch (e) {
      debugPrint('getUsers error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    List<String>? permissions,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.users);
      final payload = {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (departmentId != null && departmentId != 'ALL' && departmentId.isNotEmpty) 'departmentId': departmentId,
        if (permissions != null) 'permissions': permissions,
      };

      final response = await _http.post(uri, body: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'فشل إضافة المستخدم'};
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
    List<String>? permissions,
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
      if (permissions != null) payload['permissions'] = permissions;

      final response = await _http.patch(uri, body: payload);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'فشل تحديث المستخدم'};
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
  Future<List<Department>> getDepartments() async {
    try {
      final uri = Uri.parse(ApiConstants.departments);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return list.map((d) => Department.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('getDepartments error: $e');
    }
    return [];
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
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'فشل إضافة القسم'};
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
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'فشل تحديث القسم'};
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('deleteDepartment error: $e');
      return false;
    }
  }

  // ─── سجل التدقيق والرقابة ───
  Future<List<AuditLogItem>> getAuditLogs() async {
    try {
      final uri = Uri.parse(ApiConstants.audit);
      final response = await _http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body is List ? body : (body['data'] ?? []);
        return list.map((a) => AuditLogItem.fromJson(a)).toList();
      }
    } catch (e) {
      debugPrint('getAuditLogs error: $e');
    }
    return [];
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

  // ─── أدوات النظام والنسخ الاحتياطي ───
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
}
