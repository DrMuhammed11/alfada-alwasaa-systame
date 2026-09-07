import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../utils/download_helper.dart';
import '../../models/user_model.dart';
import '../../models/correspondence_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String? get token => _token;
  String get sseNotificationsUrl => '${ApiConstants.baseUrl}/notifications/stream';

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['accessToken'] ?? data['access_token'];
        if (token != null) {
          await saveToken(token);
        }
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'فشل تسجيل الدخول'};
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم (تأكد من تشغيل backend على منفذ 3000)',
      };
    }
  }

  Future<User?> getMe() async {
    if (_token == null) return null;
    try {
      final response = await http.get(Uri.parse(ApiConstants.me), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getMe exception: $e');
    }
    return null;
  }

  // --- Correspondences ---
  Future<Map<String, dynamic>> getCorrespondencesPaginated({
    String? type,
    String? status,
    String? priority,
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
      if (search != null && search.isNotEmpty) queryParams['q'] = search;

      final uri = Uri.parse(ApiConstants.correspondences).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

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
      final response = await http.get(Uri.parse('${ApiConstants.correspondences}/$id'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return Correspondence.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('getCorrespondenceById exception: $e');
    }
    return null;
  }

  String _extractErrorMessage(dynamic body, [String fallback = 'حدث خطأ في الخادم']) {
    if (body == null) return fallback;
    try {
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is Map) {
        final msg = decoded['message'];
        if (msg is List) {
          return msg.map((m) => m.toString()).join('، ');
        } else if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
        final err = decoded['error'];
        if (err is String && err.trim().isNotEmpty) return err.trim();
      }
    } catch (_) {}
    return fallback;
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

      final response = await http.post(
        Uri.parse(ApiConstants.incomingCorrespondences),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل تسجيل المراسلة')};
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

      final response = await http.post(
        Uri.parse(ApiConstants.internalCorrespondences),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إنشاء الخطاب الداخلي')};
      }
    } catch (e) {
      debugPrint('createInternal exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  // --- Workflow Actions ---
  Future<Map<String, dynamic>> referCorrespondence(
    String correspondenceId, {
    required String toUserId,
    String? note,
    String? dueDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'toUserId': toUserId,
      };
      if (note != null && note.trim().isNotEmpty) {
        payload['note'] = note.trim();
      }
      if (dueDate != null && dueDate.trim().isNotEmpty) {
        payload['dueDate'] = dueDate.trim();
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId/referrals'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إجراء الإحالة')};
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
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }
      if (dueDate != null && dueDate.trim().isNotEmpty) {
        payload['dueDate'] = dueDate.trim();
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId/tasks'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إسناد المهمة')};
      }
    } catch (e) {
      debugPrint('createTask exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
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
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tasks/$taskId/status'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل تحديث حالة المهمة')};
      }
    } catch (e) {
      debugPrint('updateTaskStatus exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateCorrespondenceStatus(String correspondenceId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.correspondences}/$correspondenceId'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل تحديث حالة المراسلة')};
      }
    } catch (e) {
      debugPrint('updateCorrespondenceStatus exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> closeCorrespondence(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.correspondences}/$id/close'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إغلاق المراسلة')};
      }
    } catch (e) {
      debugPrint('closeCorrespondence exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> archiveCorrespondence(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.correspondences}/$id/archive'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل أرشفة المراسلة')};
      }
    } catch (e) {
      debugPrint('archiveCorrespondence exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  // --- Replies ---
  Future<Map<String, dynamic>> createReply(String correspondenceId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies'),
        headers: _headers,
        body: jsonEncode({
          'correspondenceId': correspondenceId,
          'body': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إنشاء الرد')};
      }
    } catch (e) {
      debugPrint('createReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> updateReply(String replyId, String content) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId'),
        headers: _headers,
        body: jsonEncode({
          'body': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل تحديث الرد')};
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

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/direct'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إرسال الرد')};
      }
    } catch (e) {
      debugPrint('sendDirectReply exception: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء إرسال الرد للعميل'};
    }
  }

  Future<Map<String, dynamic>> submitReply(String replyId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/submit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل رفع الرد للاعتماد')};
      }
    } catch (e) {
      debugPrint('submitReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> approveReply(String replyId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/approve'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل اعتماد الرد')};
      }
    } catch (e) {
      debugPrint('approveReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> rejectReply(String replyId, String note) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/reject'),
        headers: _headers,
        body: jsonEncode({'note': note}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل رفض الرد')};
      }
    } catch (e) {
      debugPrint('rejectReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> sendReply(String replyId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/replies/$replyId/send'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _extractErrorMessage(response.body, 'فشل إرسال الرد بالبريد')};
      }
    } catch (e) {
      debugPrint('sendReply exception: $e');
      return {'success': false, 'message': 'تعذر الاتصال بالخادم'};
    }
  }

  // --- System Metadata ---
  Future<List<Department>> getDepartments() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.departments}?limit=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
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
      final response = await http.get(Uri.parse('${ApiConstants.users}?limit=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
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
      final response = await http.get(Uri.parse('${ApiConstants.audit}?limit=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
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

  // --- Mail Sync ---
  Future<Map<String, dynamic>> syncMail() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mail/sync'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('syncMail exception: $e');
    }
    return {'success': false, 'newCount': 0, 'message': 'فشل الاتصال بالخادم'};
  }

  // --- Tasks & Referrals ---
  Future<List<TaskItem>> getMyTasks() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/tasks/my?limit=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
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

  Future<List<ReferralItem>> getMyReferrals() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.referrals}?limit=100'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => ReferralItem.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getMyReferrals exception: $e');
    }
    return [];
  }

  // --- Notifications ---
  Future<List<Map<String, dynamic>>> getMyNotifications({bool unreadOnly = false}) async {
    try {
      final query = unreadOnly ? '?unreadOnly=true&limit=20' : '?limit=20';
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/my$query'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['data'] ?? (body is List ? body : []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('getMyNotifications exception: $e');
    }
    return [];
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['count'] ?? 0;
      }
    } catch (e) {
      debugPrint('getUnreadNotificationsCount exception: $e');
    }
    return 0;
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markNotificationAsRead exception: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markAllNotificationsAsRead exception: $e');
      return false;
    }
  }

  // --- Attachments ---
  Future<Map<String, dynamic>> uploadCorrespondenceAttachment(
    String correspondenceId,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.correspondences}/$correspondenceId/attachments');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(response.body, 'فشل رفع المرفق'),
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
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(response.body, 'فشل رفع المرفق'),
        };
      }
    } catch (e) {
      debugPrint('uploadReplyAttachment exception: $e');
      return {'success': false, 'message': 'تعذر رفع المرفق'};
    }
  }

  Future<bool> downloadAttachment(String attachmentId, String fileName) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/attachments/$attachmentId/download');
      final headers = <String, String>{};
      if (_token != null && _token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_token';
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await saveAndDownloadFile(response.bodyBytes, fileName);
        return true;
      }
    } catch (e) {
      debugPrint('downloadAttachment exception: $e');
    }
    return false;
  }
}
