import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/correspondence_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات المهام والتكليفات
class TasksApi {
  final AppHttpClient _http = AppHttpClient();

  Future<List<TaskItem>> getMyTasks() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.baseUrl}/tasks/my?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => TaskItem.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getMyTasks exception: $e');
    }
    return [];
  }

  Future<List<TaskItem>> getAllTasks() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.tasks}?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => TaskItem.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getAllTasks exception: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    String status, {
    String? completionNote,
  }) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (completionNote != null && completionNote.trim().isNotEmpty) {
        payload['completionNote'] = completionNote.trim();
      }
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tasks/$taskId/status'),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تحديث حالة المهمة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('updateTaskStatus exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }
}
