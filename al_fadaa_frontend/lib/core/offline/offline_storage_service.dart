import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/correspondence_model.dart';
import '../../models/user_model.dart';
import 'sync_queue_model.dart';

/// خدمة التخزين المحلي المنظم والمحمي لدعم العمل بدون اتصال بالإنترنت (Offline-First)
class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _kCorrespondences = 'alfadaa_offline_correspondences';
  static const String _kTasks = 'alfadaa_offline_tasks';
  static const String _kReferrals = 'alfadaa_offline_referrals';
  static const String _kSyncQueue = 'alfadaa_offline_sync_queue';
  static const String _kLastSync = 'alfadaa_offline_last_sync';
  static const String _kUserProfile = 'alfadaa_offline_user_profile';

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('OfflineStorageService init error: $e');
    }
  }

  SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError('OfflineStorageService must be initialized before use.');
    }
    return _prefs!;
  }

  // ─── تخزين واسترجاع الملف الشخصي للمستخدم ───
  Future<void> cacheUserProfile(User user) async {
    try {
      await init();
      await _safePrefs.setString(_kUserProfile, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('cacheUserProfile error: $e');
    }
  }

  User? getCachedUserProfile() {
    try {
      if (_prefs == null) return null;
      final raw = _safePrefs.getString(_kUserProfile);
      if (raw != null && raw.isNotEmpty) {
        return User.fromJson(jsonDecode(raw));
      }
    } catch (e) {
      debugPrint('getCachedUserProfile error: $e');
    }
    return null;
  }

  // ─── تخزين واسترجاع وفهرسة المراسلات محلياً ───
  Future<void> cacheCorrespondences(List<Correspondence> items) async {
    try {
      await init();
      // دمج المراسلات الجديدة مع المخزنة سابقاً بناءً على المعرف id
      final currentMap = <String, Map<String, dynamic>>{};
      final raw = _safePrefs.getString(_kCorrespondences);
      if (raw != null && raw.isNotEmpty) {
        final List existing = jsonDecode(raw);
        for (final item in existing) {
          if (item is Map<String, dynamic> && item['id'] != null) {
            currentMap[item['id']] = item;
          }
        }
      }

      for (final item in items) {
        currentMap[item.id] = item.toJson();
      }

      await _safePrefs.setString(_kCorrespondences, jsonEncode(currentMap.values.toList()));
    } catch (e) {
      debugPrint('cacheCorrespondences error: $e');
    }
  }

  Future<void> updateCachedCorrespondence(Correspondence item) async {
    try {
      await init();
      final currentMap = <String, Map<String, dynamic>>{};
      final raw = _safePrefs.getString(_kCorrespondences);
      if (raw != null && raw.isNotEmpty) {
        final List existing = jsonDecode(raw);
        for (final ex in existing) {
          if (ex is Map<String, dynamic> && ex['id'] != null) {
            currentMap[ex['id']] = ex;
          }
        }
      }
      currentMap[item.id] = item.toJson();
      await _safePrefs.setString(_kCorrespondences, jsonEncode(currentMap.values.toList()));
    } catch (e) {
      debugPrint('updateCachedCorrespondence error: $e');
    }
  }

  Future<List<Correspondence>> getCachedCorrespondences({
    String? type,
    String? status,
    String? priority,
    String? search,
  }) async {
    try {
      await init();
      final raw = _safePrefs.getString(_kCorrespondences);
      if (raw == null || raw.isEmpty) return [];

      final List list = jsonDecode(raw);
      List<Correspondence> result = list
          .whereType<Map<String, dynamic>>()
          .map((j) => Correspondence.fromJson(j))
          .toList();

      // تطبيق الفلاتر محلياً
      if (type != null && type.isNotEmpty && type != 'ALL') {
        result = result.where((c) => c.type == type).toList();
      }
      if (status != null && status.isNotEmpty && status != 'ALL') {
        result = result.where((c) => c.status == status).toList();
      }
      if (priority != null && priority.isNotEmpty && priority != 'ALL') {
        result = result.where((c) => c.priority == priority).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        result = result.where((c) {
          return c.subject.toLowerCase().contains(q) ||
              c.serialNumber.toLowerCase().contains(q) ||
              (c.senderName != null && c.senderName!.toLowerCase().contains(q)) ||
              (c.body != null && c.body!.toLowerCase().contains(q));
        }).toList();
      }

      // ترتيب تنازلي حسب تاريخ الإنشاء
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    } catch (e) {
      debugPrint('getCachedCorrespondences error: $e');
      return [];
    }
  }

  Future<Correspondence?> getCachedCorrespondence(String id) async {
    try {
      await init();
      final raw = _safePrefs.getString(_kCorrespondences);
      if (raw == null || raw.isEmpty) return null;

      final List list = jsonDecode(raw);
      for (final j in list) {
        if (j is Map<String, dynamic> && j['id'] == id) {
          return Correspondence.fromJson(j);
        }
      }
    } catch (e) {
      debugPrint('getCachedCorrespondence error: $e');
    }
    return null;
  }

  // ─── تخزين واسترجاع المهام والإحالات محلياً ───
  Future<void> cacheMyTasks(List<TaskItem> tasks) async {
    try {
      await init();
      final list = tasks.map((t) => t.toJson()).toList();
      await _safePrefs.setString(_kTasks, jsonEncode(list));
    } catch (e) {
      debugPrint('cacheMyTasks error: $e');
    }
  }

  Future<List<TaskItem>> getCachedMyTasks() async {
    try {
      await init();
      final raw = _safePrefs.getString(_kTasks);
      if (raw == null || raw.isEmpty) return [];
      final List list = jsonDecode(raw);
      return list.whereType<Map<String, dynamic>>().map((j) => TaskItem.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getCachedMyTasks error: $e');
      return [];
    }
  }

  Future<void> cacheMyReferrals(List<ReferralItem> referrals) async {
    try {
      await init();
      final list = referrals.map((r) => r.toJson()).toList();
      await _safePrefs.setString(_kReferrals, jsonEncode(list));
    } catch (e) {
      debugPrint('cacheMyReferrals error: $e');
    }
  }

  Future<List<ReferralItem>> getCachedMyReferrals() async {
    try {
      await init();
      final raw = _safePrefs.getString(_kReferrals);
      if (raw == null || raw.isEmpty) return [];
      final List list = jsonDecode(raw);
      return list.whereType<Map<String, dynamic>>().map((j) => ReferralItem.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getCachedMyReferrals error: $e');
      return [];
    }
  }

  // ─── طابور المزامنة للعمليات المعلقة (Sync Mutation Queue) ───
  Future<List<SyncQueueItem>> getSyncQueue() async {
    try {
      await init();
      final raw = _safePrefs.getString(_kSyncQueue);
      if (raw == null || raw.isEmpty) return [];
      final List list = jsonDecode(raw);
      return list.whereType<Map<String, dynamic>>().map((j) => SyncQueueItem.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getSyncQueue error: $e');
      return [];
    }
  }

  Future<void> enqueueMutation(SyncQueueItem item) async {
    try {
      await init();
      final queue = await getSyncQueue();
      queue.add(item);
      final raw = jsonEncode(queue.map((q) => q.toJson()).toList());
      await _safePrefs.setString(_kSyncQueue, raw);
    } catch (e) {
      debugPrint('enqueueMutation error: $e');
    }
  }

  Future<void> updateMutation(SyncQueueItem item) async {
    try {
      await init();
      final queue = await getSyncQueue();
      final idx = queue.indexWhere((q) => q.id == item.id);
      if (idx != -1) {
        queue[idx] = item;
        final raw = jsonEncode(queue.map((q) => q.toJson()).toList());
        await _safePrefs.setString(_kSyncQueue, raw);
      }
    } catch (e) {
      debugPrint('updateMutation error: $e');
    }
  }

  Future<void> removeMutation(String id) async {
    try {
      await init();
      final queue = await getSyncQueue();
      queue.removeWhere((q) => q.id == id);
      final raw = jsonEncode(queue.map((q) => q.toJson()).toList());
      await _safePrefs.setString(_kSyncQueue, raw);
    } catch (e) {
      debugPrint('removeMutation error: $e');
    }
  }

  Future<void> clearCompletedMutations() async {
    try {
      await init();
      final queue = await getSyncQueue();
      queue.removeWhere((q) => q.status == 'COMPLETED');
      final raw = jsonEncode(queue.map((q) => q.toJson()).toList());
      await _safePrefs.setString(_kSyncQueue, raw);
    } catch (e) {
      debugPrint('clearCompletedMutations error: $e');
    }
  }

  Future<int> getPendingMutationsCount() async {
    final queue = await getSyncQueue();
    return queue.where((q) => q.status == 'PENDING' || q.status == 'SYNCING').length;
  }

  // ─── توقيت آخر مزامنة ناجحة ───
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      await init();
      await _safePrefs.setString(_kLastSync, time.toIso8601String());
    } catch (e) {
      debugPrint('setLastSyncTime error: $e');
    }
  }

  DateTime? getLastSyncTime() {
    try {
      if (_prefs == null) return null;
      final raw = _safePrefs.getString(_kLastSync);
      if (raw != null && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
    } catch (e) {
      debugPrint('getLastSyncTime error: $e');
    }
    return null;
  }
}
