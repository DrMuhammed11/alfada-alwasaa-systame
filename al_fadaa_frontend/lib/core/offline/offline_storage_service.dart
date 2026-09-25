import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/correspondence_model.dart';
import '../../models/user_model.dart';
import 'sync_queue_model.dart';

/// خدمة التخزين المحلي — مبنية على Hive (صناديق دائمة، كتابة O(1) لكل معرف،
/// بلا إعادة تحليل JSON كامل لكل عملية كما كان في SharedPreferences).
/// الواجهة العامة للدوال محفوظة كما هي حتى لا يتأثر المحرك والواجهات.
class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _kCorrBox = 'offline_correspondences';
  static const String _kTasksBox = 'offline_tasks';
  static const String _kReferralsBox = 'offline_referrals';
  static const String _kQueueBox = 'offline_sync_queue';
  static const String _kMetaBox = 'offline_meta';

  /// سقف ذاكرة المراسلات المؤقتة — الأقدم استحقاقاً يُمحى عند التجاوز
  static const int _maxCachedCorrespondences = 300;

  bool _opened = false;

  Future<void> init() async {
    // الصناديق قد تُغلق خارجياً (اختبارات) — الفحص مباشر على Hive لا راية فقط
    if (_opened &&
        Hive.isBoxOpen(_kCorrBox) &&
        Hive.isBoxOpen(_kTasksBox) &&
        Hive.isBoxOpen(_kReferralsBox) &&
        Hive.isBoxOpen(_kQueueBox) &&
        Hive.isBoxOpen(_kMetaBox)) {
      return;
    }
    try {
      try {
        // الإنتاج: يضبط مسار التخزين عبر path_provider
        // الاختبارات: يفشل ويُتجاهل — المسار مضبوط مسبقاً عبر Hive.init
        await Hive.initFlutter();
      } catch (_) {}
      await Hive.openBox(_kCorrBox);
      await Hive.openBox(_kTasksBox);
      await Hive.openBox(_kReferralsBox);
      await Hive.openBox(_kQueueBox);
      await Hive.openBox(_kMetaBox);
      _opened = true;
    } catch (e) {
      debugPrint('OfflineStorageService init error: $e');
    }
  }

  Box get _corrBox => Hive.box(_kCorrBox);
  Box get _tasksBox => Hive.box(_kTasksBox);
  Box get _referralsBox => Hive.box(_kReferralsBox);
  Box get _queueBox => Hive.box(_kQueueBox);
  Box get _metaBox => Hive.box(_kMetaBox);

  // ─── الملف الشخصي ───
  Future<void> cacheUserProfile(User user) async {
    try {
      await init();
      await _metaBox.put('user_profile', user.toJson());
    } catch (e) {
      debugPrint('cacheUserProfile error: $e');
    }
  }

  User? getCachedUserProfile() {
    try {
      if (!_opened) return null;
      final raw = _metaBox.get('user_profile');
      if (raw is Map) return User.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('getCachedUserProfile error: $e');
    }
    return null;
  }

  // ─── المراسلات ───
  Future<void> cacheCorrespondences(List<Correspondence> items) async {
    try {
      await init();
      for (final item in items) {
        await _corrBox.put(item.id, item.toJson());
      }
      await _evictOverflow();
    } catch (e) {
      debugPrint('cacheCorrespondences error: $e');
    }
  }

  /// إخلاء الأقدم إن تجاوز المخزون السقف — يمنع النمو غير المحدود
  Future<void> _evictOverflow() async {
    if (_corrBox.length <= _maxCachedCorrespondences) return;
    final entries = _corrBox.toMap().entries
        .map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          final created = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime(2000);
          return MapEntry(e.key as String, created);
        })
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final toDelete = entries.length - _maxCachedCorrespondences;
    for (var i = 0; i < toDelete; i++) {
      await _corrBox.delete(entries[i].key);
    }
  }

  Future<void> updateCachedCorrespondence(Correspondence item) async {
    try {
      await init();
      await _corrBox.put(item.id, item.toJson());
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
      List<Correspondence> result = _corrBox.values
          .map((v) => Correspondence.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();

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
      final raw = _corrBox.get(id);
      if (raw is Map) return Correspondence.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('getCachedCorrespondence error: $e');
    }
    return null;
  }

  // ─── المهام والإحالات ───
  Future<void> cacheMyTasks(List<TaskItem> tasks) async {
    try {
      await init();
      await _tasksBox.clear();
      for (final t in tasks) {
        await _tasksBox.add(t.toJson());
      }
    } catch (e) {
      debugPrint('cacheMyTasks error: $e');
    }
  }

  Future<List<TaskItem>> getCachedMyTasks() async {
    try {
      await init();
      return _tasksBox.values
          .map((j) => TaskItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      debugPrint('getCachedMyTasks error: $e');
      return [];
    }
  }

  Future<void> cacheMyReferrals(List<ReferralItem> referrals) async {
    try {
      await init();
      await _referralsBox.clear();
      for (final r in referrals) {
        await _referralsBox.add(r.toJson());
      }
    } catch (e) {
      debugPrint('cacheMyReferrals error: $e');
    }
  }

  Future<List<ReferralItem>> getCachedMyReferrals() async {
    try {
      await init();
      return _referralsBox.values
          .map((j) => ReferralItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      debugPrint('getCachedMyReferrals error: $e');
      return [];
    }
  }

  // ─── طابور المزامنة ───
  Future<List<SyncQueueItem>> getSyncQueue() async {
    try {
      await init();
      return _queueBox.values
          .map((j) => SyncQueueItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      debugPrint('getSyncQueue error: $e');
      return [];
    }
  }

  Future<void> enqueueMutation(SyncQueueItem item) async {
    try {
      await init();
      await _queueBox.put(item.id, item.toJson());
    } catch (e) {
      debugPrint('enqueueMutation error: $e');
    }
  }

  Future<void> updateMutation(SyncQueueItem item) async {
    try {
      await init();
      await _queueBox.put(item.id, item.toJson());
    } catch (e) {
      debugPrint('updateMutation error: $e');
    }
  }

  Future<void> removeMutation(String id) async {
    try {
      await init();
      await _queueBox.delete(id);
    } catch (e) {
      debugPrint('removeMutation error: $e');
    }
  }

  Future<void> clearCompletedMutations() async {
    try {
      await init();
      final keys = _queueBox.keys.toList();
      for (final key in keys) {
        final raw = _queueBox.get(key);
        if (raw is Map && raw['status'] == 'COMPLETED') {
          await _queueBox.delete(key);
        }
      }
    } catch (e) {
      debugPrint('clearCompletedMutations error: $e');
    }
  }

  Future<int> getPendingMutationsCount() async {
    final queue = await getSyncQueue();
    return queue.where((q) => q.status == 'PENDING' || q.status == 'SYNCING').length;
  }

  // ─── آخر مزامنة ───
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      await init();
      await _metaBox.put('last_sync', time.toIso8601String());
    } catch (e) {
      debugPrint('setLastSyncTime error: $e');
    }
  }

  DateTime? getLastSyncTime() {
    try {
      if (!_opened) return null;
      final raw = _metaBox.get('last_sync');
      if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('getLastSyncTime error: $e');
    }
    return null;
  }
}
