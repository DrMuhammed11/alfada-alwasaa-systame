import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../models/user_model.dart';
import '../../constants/api_constants.dart';
import '../../utils/download_helper.dart';
import '../http_client.dart';
import '../http_error_translator.dart';

/// عميل استدعاءات النظام والمرفقات والتفويضات وسجلات التدقيق
class SystemApi {
  final AppHttpClient _http = AppHttpClient();
  final Map<String, Uint8List> _attachmentBytesCache = {};

  Future<List<Department>> getDepartments() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.departments}?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => Department.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getDepartments exception: $e');
    }
    return [];
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.users}?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => User.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getUsers exception: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.audit}?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('getAuditLogs exception: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> syncMail() async {
    try {
      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/mail/sync'),
        timeout: const Duration(seconds: 30),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('syncMail exception: $e');
    }
    return {'success': false, 'newCount': 0, 'message': 'فشل الاتصال بالخادم'};
  }

  /// الوكالات الممنوحة لي (أنا الوكيل فيها)
  Future<List<Map<String, dynamic>>> getDelegationsForMe() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/delegations/for-me'));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
    } catch (e) {
      debugPrint('getDelegationsForMe error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyDelegations() async {
    try {
      final response = await _http.get(Uri.parse('${ApiConstants.baseUrl}/delegations/my'));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
    } catch (e) {
      debugPrint('getMyDelegations error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createDelegation({
    required String delegateId,
    required DateTime startDate,
    required DateTime endDate,
    String? note,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('${ApiConstants.baseUrl}/delegations'),
        body: jsonEncode({
          'delegateId': delegateId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنشاء التفويض', response.statusCode),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> terminateDelegation(String delegationId) async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/delegations/$delegationId/terminate'),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل إنهاء التفويض', response.statusCode),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  static MediaType _lookupMediaType(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf': return MediaType('application', 'pdf');
      case 'jpg': case 'jpeg': return MediaType('image', 'jpeg');
      case 'png': return MediaType('image', 'png');
      case 'gif': return MediaType('image', 'gif');
      case 'webp': return MediaType('image', 'webp');
      case 'doc': return MediaType('application', 'msword');
      case 'docx': return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'xls': return MediaType('application', 'vnd.ms-excel');
      case 'xlsx': return MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case 'zip': return MediaType('application', 'zip');
      case 'txt': return MediaType('text', 'plain');
      default: return MediaType('application', 'octet-stream');
    }
  }

  Future<Map<String, dynamic>> uploadCorrespondenceAttachment(
    String correspondenceId,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.correspondences}/$correspondenceId/attachments');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: _lookupMediaType(filename)),
      );
      final response = await _http.sendMultipart(request);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل رفع المرفق', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('uploadCorrespondenceAttachment exception: $e');
      return {'success': false, 'message': 'تعذر رفع المرفق'};
    }
  }

  Future<Map<String, dynamic>> uploadReplyAttachment(
    String replyId,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/attachments');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: _lookupMediaType(filename)),
      );
      final response = await _http.sendMultipart(request);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': HttpErrorTranslator.extractErrorMessage(response.body, 'فشل رفع المرفق', response.statusCode),
        };
      }
    } catch (e) {
      debugPrint('uploadReplyAttachment exception: $e');
      return {'success': false, 'message': 'تعذر رفع المرفق'};
    }
  }

  Future<Uint8List?> getAttachmentBytes(String attachmentId) async {
    if (_attachmentBytesCache.containsKey(attachmentId)) {
      return _attachmentBytesCache[attachmentId];
    }
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/attachments/$attachmentId/download');
      final response = await _http.get(uri, timeout: const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _attachmentBytesCache[attachmentId] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint('getAttachmentBytes exception: $e');
    }
    return null;
  }

  Future<bool> viewAttachment(String attachmentId, String fileName, [String? mimeType]) async {
    try {
      final bytes = await getAttachmentBytes(attachmentId);
      if (bytes != null && bytes.isNotEmpty) {
        await openFileInViewer(bytes, fileName, mimeType);
        return true;
      }
    } catch (e) {
      debugPrint('viewAttachment exception: $e');
    }
    return false;
  }

  Future<bool> downloadAttachment(String attachmentId, String fileName) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/attachments/$attachmentId/download');
      final response = await _http.get(uri, timeout: const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await saveAndDownloadFile(response.bodyBytes, fileName);
        return true;
      }
    } catch (e) {
      debugPrint('downloadAttachment exception: $e');
    }
    return false;
  }

  // ─── الإشعارات ومركزها وكلمة المرور ───

  /// إشعاراتي — الأحدث أولًا مع ترقيم صفحات وفلترة غير المقروء
  Future<Map<String, dynamic>> getMyNotificationsPaged({
    int page = 1,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '$limit'};
      if (unreadOnly) params['unread'] = 'true';
      final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/my').replace(queryParameters: params);
      final response = await _http.get(uri);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getMyNotifications error: $e');
    }
    return {'data': [], 'meta': {'total': 0, 'totalPages': 1, 'page': page}};
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await _http.patch(Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      final response = await _http.patch(Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
      return false;
    }
  }

  /// تغيير كلمة المرور الذاتي — الخادم يبطل كل الجلسات الأخرى
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/auth/password'),
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'تم تغيير كلمة المرور'};
      }
      final msg = data['message'];
      return {'success': false, 'message': msg is List ? msg.join(' — ') : (msg ?? 'فشل تغيير كلمة المرور')};
    } catch (e) {
      debugPrint('changePassword error: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }
}
