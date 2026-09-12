import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/correspondence_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات المراسلات وسير العمل الخاصة بها
class CorrespondencesApi {
  final AppHttpClient _http = AppHttpClient();

  Future<Map<String, dynamic>> getCorrespondencesPaginated({
    String? type,
    String? status,
    String? priority,
    String? channel,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (type != null && type.isNotEmpty && type != 'ALL') queryParams['type'] = type;
      if (status != null && status.isNotEmpty && status != 'ALL') queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty && priority != 'ALL') queryParams['priority'] = priority;
      if (channel != null && channel.isNotEmpty && channel != 'ALL') queryParams['channel'] = channel;
      if (search != null && search.isNotEmpty) queryParams['q'] = search;

      final uri = Uri.parse(ApiConstants.correspondences).replace(queryParameters: queryParams);
      final response = await _http.get(uri, timeout: const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['data'] ?? (body is List ? body : []);
        final items = list.map((json) => Correspondence.fromJson(json)).toList();
        final meta = body['meta'] is Map<String, dynamic>
            ? body['meta'] as Map<String, dynamic>
            : {
                'page': page,
                'limit': limit,
                'total': items.length,
                'totalPages': 1,
              };
        return {'data': items, 'meta': meta};
      }
    } catch (e) {
      debugPrint('getCorrespondencesPaginated exception: $e');
    }
    return {
      'data': <Correspondence>[],
      'meta': {'page': page, 'limit': limit, 'total': 0, 'totalPages': 0}
    };
  }

  Future<List<Correspondence>> getCorrespondences({
    String? type,
    String? status,
    String? priority,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await getCorrespondencesPaginated(
      type: type,
      status: status,
      priority: priority,
      search: search,
      page: page,
      limit: limit,
    );
    return result['data'] as List<Correspondence>;
  }

  Future<Correspondence?> getCorrespondenceById(String id) async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.correspondences}/$id'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        return Correspondence.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getCorrespondenceById exception: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> createIncoming({
    required String subject,
    required String senderName,
    String? senderEmail,
    String? senderPhone,
    String? body,
    String priority = 'NORMAL',
  }) async {
    try {
      final payload = <String, dynamic>{
        'subject': subject,
        'senderName': senderName,
        'priority': priority,
      };
      if (senderEmail != null && senderEmail.trim().isNotEmpty) {
        payload['senderEmail'] = senderEmail.trim();
      }
      if (senderPhone != null && senderPhone.trim().isNotEmpty) {
        payload['senderPhone'] = senderPhone.trim();
      }
      if (body != null && body.trim().isNotEmpty) {
        payload['body'] = body.trim();
      }

      final response = await _http.post(
        Uri.parse(ApiConstants.incomingCorrespondences),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تسجيل المراسلة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createIncoming exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> createInternal({
    required String subject,
    required String body,
    String priority = 'NORMAL',
  }) async {
    try {
      final payload = <String, dynamic>{
        'subject': subject,
        'body': body,
        'priority': priority,
      };

      final response = await _http.post(
        Uri.parse(ApiConstants.internalCorrespondences),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنشاء الخطاب الداخلي', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createInternal exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> referCorrespondence(
    String correspondenceId, {
    required String toUserId,
    String? note,
    String? dueDate,
  }) async {
    try {
      final payload = <String, dynamic>{'toUserId': toUserId};
      if (note != null && note.trim().isNotEmpty) payload['note'] = note.trim();
      if (dueDate != null && dueDate.trim().isNotEmpty) payload['dueDate'] = dueDate.trim();

      final response = await _http.post(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId/referrals'),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إجراء الإحالة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('referCorrespondence exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> createTask(
    String correspondenceId, {
    required String title,
    String? description,
    required String assignedToId,
    String? dueDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'title': title,
        'assignedToId': assignedToId,
      };
      if (description != null && description.trim().isNotEmpty) payload['description'] = description.trim();
      if (dueDate != null && dueDate.trim().isNotEmpty) payload['dueDate'] = dueDate.trim();

      final response = await _http.post(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId/tasks'),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إسناد المهمة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createTask exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateCorrespondenceStatus(String correspondenceId, String status) async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId'),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تحديث حالة المراسلة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('updateCorrespondenceStatus exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> closeCorrespondence(String id) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.correspondences}/$id/close'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إغلاق المراسلة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('closeCorrespondence exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> archiveCorrespondence(String id) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.correspondences}/$id/archive'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل أرشفة المراسلة', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('archiveCorrespondence exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }
}
