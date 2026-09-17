import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/admin_user_model.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'انتهت الجلسة، يرجى إعادة تسجيل الدخول']);
  @override
  String toString() => message;
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _token;
  AdminUser? _currentUser;

  String? get token => _token;
  AdminUser? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('admin_token');
      final userStr = prefs.getString('admin_user');
      if (userStr != null) {
        _currentUser = AdminUser.fromJson(jsonDecode(userStr));
      }
    } catch (e) {
      debugPrint('Error loading admin session: $e');
    }
  }

  Future<void> saveSession(String token, AdminUser user) async {
    _token = token;
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', token);
      await prefs.setString('admin_user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving admin session: $e');
    }
  }

  Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_token');
      await prefs.remove('admin_user');
    } catch (e) {
      debugPrint('Error clearing admin session: $e');
    }
  }
}
