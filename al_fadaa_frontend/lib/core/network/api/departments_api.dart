import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/user_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات إدارة القطاعات والأقسام
class DepartmentsApi {
  final AppHttpClient _http = AppHttpClient();

  Future<List<Department>> getDepartments({String? search}) async {
    try {
      final query = (search != null && search.isNotEmpty)
          ? '?limit=100&q=${Uri.encodeComponent(search)}'
          : '?limit=100';
      final response = await _http.get(
        Uri.parse('${ApiConstants.departments}$query'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return list.map((j) => Department.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getDepartments exception: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
    String? managerId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
      };
      if (managerId != null && managerId.isNotEmpty) {
        payload['managerId'] = managerId;
      }

      final response = await _http.post(
        Uri.parse(ApiConstants.departments),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنشاء القطاع', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createDepartment exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateDepartment(
    String id, {
    String? name,
    String? code,
    String? managerId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.isNotEmpty) payload['name'] = name.trim();
      if (code != null && code.isNotEmpty) payload['code'] = code.trim().toUpperCase();
      if (managerId != null) payload['managerId'] = managerId.isEmpty ? null : managerId;

      final response = await _http.patch(
        Uri.parse('${ApiConstants.departments}/$id'),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تحديث القطاع', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('updateDepartment exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> deleteDepartment(String id) async {
    try {
      final response = await _http.delete(Uri.parse('${ApiConstants.departments}/$id'));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل حذف القطاع', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('deleteDepartment exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }
}
