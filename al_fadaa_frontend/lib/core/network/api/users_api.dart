import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/user_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات إدارة الموظفين والمستخدمين وتعيين الصلاحيات
class UsersApi {
  final AppHttpClient _http = AppHttpClient();

  Future<Map<String, dynamic>> getUsersPaginated({
    String? role,
    String? departmentId,
    bool? isActive,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (role != null && role.isNotEmpty && role != 'ALL') queryParams['role'] = role;
      if (departmentId != null && departmentId.isNotEmpty && departmentId != 'ALL') {
        queryParams['departmentId'] = departmentId;
      }
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      final uri = Uri.parse(ApiConstants.users).replace(queryParameters: queryParams);
      final response = await _http.get(uri, timeout: const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['data'] ?? (body is List ? body : []);
        final items = list.map((j) => User.fromJson(j)).toList();
        final meta = body['meta'] is Map<String, dynamic>
            ? body['meta'] as Map<String, dynamic>
            : {'page': page, 'limit': limit, 'total': items.length, 'totalPages': 1};
        return {'data': items, 'meta': meta};
      }
    } catch (e) {
      debugPrint('getUsersPaginated exception: $e');
    }
    return {'data': <User>[], 'meta': {'page': page, 'limit': limit, 'total': 0, 'totalPages': 0}};
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? jobTitle,
    String? employeeNumber,
    String? phone,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
      };
      if (departmentId != null && departmentId.isNotEmpty) payload['departmentId'] = departmentId;
      if (jobTitle != null && jobTitle.isNotEmpty) payload['jobTitle'] = jobTitle.trim();
      if (employeeNumber != null && employeeNumber.isNotEmpty) {
        payload['employeeNumber'] = employeeNumber.trim();
      }
      if (phone != null && phone.isNotEmpty) payload['phone'] = phone.trim();

      final response = await _http.post(
        Uri.parse(ApiConstants.users),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنشاء حساب الموظف', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createUser exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id, {
    String? name,
    String? email,
    String? password,
    String? role,
    String? departmentId,
    String? jobTitle,
    String? employeeNumber,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.isNotEmpty) payload['name'] = name.trim();
      if (email != null && email.isNotEmpty) payload['email'] = email.trim().toLowerCase();
      if (password != null && password.isNotEmpty) payload['password'] = password;
      if (role != null && role.isNotEmpty) payload['role'] = role;
      if (departmentId != null) payload['departmentId'] = departmentId.isEmpty ? null : departmentId;
      if (jobTitle != null) payload['jobTitle'] = jobTitle.trim();
      if (employeeNumber != null) payload['employeeNumber'] = employeeNumber.trim();
      if (phone != null) payload['phone'] = phone.trim();
      if (isActive != null) payload['isActive'] = isActive;

      final response = await _http.patch(
        Uri.parse('${ApiConstants.users}/$id'),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تحديث بيانات الموظف', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('updateUser exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> deactivateUser(String id) async {
    try {
      final response = await _http.delete(Uri.parse('${ApiConstants.users}/$id'));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تعطيل الحساب', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('deactivateUser exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }
}
