import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/correspondence_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات الردود وإصداراتها واعتماداتها
class RepliesApi {
  final AppHttpClient _http = AppHttpClient();

  Future<Map<String, dynamic>> createReply(String correspondenceId, String content) async {
    try {
      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies'),
        body: jsonEncode({
          'correspondenceId': correspondenceId,
          'body': content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنشاء الرد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('createReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateReply(String replyId, String content) async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId'),
        body: jsonEncode({'body': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل تحديث الرد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('updateReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> sendDirectReply(
    String correspondenceId,
    String body, [
    List<String>? attachmentIds,
  ]) async {
    try {
      final payload = <String, dynamic>{
        'correspondenceId': correspondenceId,
        'body': body,
      };
      if (attachmentIds != null && attachmentIds.isNotEmpty) {
        payload['attachmentIds'] = attachmentIds;
      }

      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/direct'),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إرسال الرد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('sendDirectReply exception: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء إرسال الرد للعميل'};
    }
  }

  Future<Map<String, dynamic>> submitReply(String replyId) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/submit'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل رفع الرد للاعتماد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('submitReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> approveReply(String replyId) async {
    try {
      final response = await _http.post(Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/approve'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل اعتماد الرد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('approveReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> rejectReply(String replyId, String note) async {
    try {
      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/reject'),
        body: jsonEncode({'note': note}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل رفض الرد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('rejectReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> sendReply(String replyId) async {
    try {
      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/send'),
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إرسال الرد بالبريد', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('sendReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<List<ReplyVersionItem>> getReplyVersions(String replyId) async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/versions'));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => ReplyVersionItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getReplyVersions error: $e');
      return [];
    }
  }

  Future<DiffResult?> getReplyDiff(String replyId, {int? v1, int? v2}) async {
    try {
      final queryParams = <String, String>{};
      if (v1 != null) queryParams['v1'] = v1.toString();
      if (v2 != null) queryParams['v2'] = v2.toString();
      final uri = Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/diff')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        return DiffResult.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('getReplyDiff error: $e');
      return null;
    }
  }
}
