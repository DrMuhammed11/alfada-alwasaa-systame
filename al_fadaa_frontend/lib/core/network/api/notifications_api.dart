import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';

/// عميل استدعاءات الإشعارات وقراءتها
class NotificationsApi {
  final AppHttpClient _http = AppHttpClient();

  String get sseNotificationsUrl => '${ApiConstants.baseUrl}/notifications/stream';

  Future<List<Map<String, dynamic>>> getMyNotifications({bool unreadOnly = false}) async {
    try {
      final query = unreadOnly ? '?unreadOnly=true&limit=20' : '?limit=20';
      final response = await _http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/my$query'),
        timeout: const Duration(seconds: 5),
      );

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
      final response = await _http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count'),
        timeout: const Duration(seconds: 5),
      );

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
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
        timeout: const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markNotificationAsRead exception: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await _http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
        timeout: const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('markAllNotificationsAsRead exception: $e');
      return false;
    }
  }
}
