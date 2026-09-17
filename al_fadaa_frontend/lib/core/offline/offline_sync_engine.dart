import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/http_client.dart';
import 'offline_storage_service.dart';
import 'sync_queue_model.dart';

class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
  });
}

/// محرك المزامنة الثنائي الذكي وإدارة الاتصال لوضع Offline-First
class OfflineSyncEngine extends ChangeNotifier {
  static final OfflineSyncEngine _instance = OfflineSyncEngine._internal();
  factory OfflineSyncEngine() => _instance;
  OfflineSyncEngine._internal();

  final OfflineStorageService _storage = OfflineStorageService();
  final AppHttpClient _http = AppHttpClient();

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _manualOfflineMode = false;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;
  String? _lastSyncMessage;
  Timer? _autoSyncTimer;

  bool get isOnline => _isOnline && !_manualOfflineMode;
  bool get isOffline => !isOnline;
  bool get isSyncing => _isSyncing;
  bool get isManualOffline => _manualOfflineMode;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncMessage => _lastSyncMessage;

  Future<void> init() async {
    await _storage.init();
    _pendingCount = await _storage.getPendingMutationsCount();
    _lastSyncTime = _storage.getLastSyncTime();
    notifyListeners();

    // فحص دوري خفيف للمزامنة التلقائية كل دقيقتين
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (isOnline && _pendingCount > 0 && !_isSyncing) {
        syncPendingMutations();
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  void setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
      if (_isOnline && _pendingCount > 0 && !_isSyncing) {
        syncPendingMutations();
      }
    }
  }

  void toggleManualOffline() {
    _manualOfflineMode = !_manualOfflineMode;
    notifyListeners();
    if (!_manualOfflineMode && _pendingCount > 0 && !_isSyncing) {
      syncPendingMutations();
    }
  }

  /// تنفيذ أي عملية تنفيذية بنمط الأوفلاين التفاؤلي (Optimistic Execution)
  Future<Map<String, dynamic>> executeAction({
    required String actionType,
    required String endpoint,
    required String httpMethod,
    required Map<String, dynamic> payload,
    required String entityId,
    required String entitySummary,
    required Future<Map<String, dynamic>> Function() onlineAction,
    required Future<void> Function() onOptimisticUpdate,
  }) async {
    // 1. إذا كان التطبيق في وضع الأوفلاين يدوياً أو فعلياً:
    if (isOffline) {
      await onOptimisticUpdate();
      final item = SyncQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        actionType: actionType,
        endpoint: endpoint,
        httpMethod: httpMethod,
        payload: payload,
        createdAt: DateTime.now(),
        entityId: entityId,
        entitySummary: entitySummary,
      );
      await _storage.enqueueMutation(item);
      _pendingCount = await _storage.getPendingMutationsCount();
      notifyListeners();

      return {
        'success': true,
        'offline': true,
        'message': 'تم تسجيل الإجراء محلياً بنجاح وسيتم رفعه تلقائياً فور توفر الاتصال',
      };
    }

    // 2. إذا كان أونلاين: نحاول التنفيذ الفوري
    try {
      final res = await onlineAction();
      if (res['success'] == true) {
        return res;
      }
      return res;
    } catch (e) {
      debugPrint('Action network error, falling back to offline queue: $e');
      // عند فشل الشبكة أو timeout، نتحول فوراً للأوفلاين ونحفظ الإجراء
      setOnlineStatus(false);
      await onOptimisticUpdate();
      final item = SyncQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        actionType: actionType,
        endpoint: endpoint,
        httpMethod: httpMethod,
        payload: payload,
        createdAt: DateTime.now(),
        entityId: entityId,
        entitySummary: entitySummary,
      );
      await _storage.enqueueMutation(item);
      _pendingCount = await _storage.getPendingMutationsCount();
      notifyListeners();

      return {
        'success': true,
        'offline': true,
        'message': 'تعذر الاتصال بالخادم، تم حفظ الإجراء محلياً وسيتم رفعه تلقائياً',
      };
    }
  }

  /// رفع ومعالجة طابور العمليات المعلقة (Background Sync Worker)
  Future<SyncResult> syncPendingMutations({bool force = false}) async {
    if (_isSyncing) {
      return SyncResult(
        success: true,
        syncedCount: 0,
        failedCount: 0,
        message: 'عملية المزامنة قيد التشغيل بالفعل',
      );
    }

    _isSyncing = true;
    notifyListeners();

    int synced = 0;
    int failed = 0;

    try {
      final queue = await _storage.getSyncQueue();
      final pendingItems = queue.where((q) => q.status == 'PENDING' || q.status == 'SYNCING').toList();

      if (pendingItems.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: true,
          syncedCount: 0,
          failedCount: 0,
          message: 'لا توجد عمليات معلقة للمزامنة',
        );
      }

      // معالجة العناصر بالترتيب الزمني FIFO
      pendingItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final item in pendingItems) {
        try {
          final uri = Uri.parse(item.endpoint);
          final response = item.httpMethod == 'POST'
              ? await _http.post(uri, body: jsonEncode(item.payload), timeout: const Duration(seconds: 10))
              : (item.httpMethod == 'PATCH'
                  ? await _http.patch(uri, body: jsonEncode(item.payload), timeout: const Duration(seconds: 10))
                  : await _http.put(uri, body: jsonEncode(item.payload), timeout: const Duration(seconds: 10)));

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _storage.removeMutation(item.id);
            synced++;
            setOnlineStatus(true);
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            // خطأ تحقق أو تعارض أعمال (Business Conflict)
            item.status = 'FAILED';
            item.lastError = 'رفض الخادم: رمز ${response.statusCode}';
            await _storage.updateMutation(item);
            failed++;
          } else {
            // خطأ سيرفر أو انقطاع
            item.retryCount++;
            await _storage.updateMutation(item);
          }
        } catch (netErr) {
          debugPrint('Sync network drop on item ${item.id}: $netErr');
          setOnlineStatus(false);
          break; // إيقاف المزامنة مؤقتاً لحين استقرار الشبكة
        }
      }

      final now = DateTime.now();
      _lastSyncTime = now;
      await _storage.setLastSyncTime(now);
      _pendingCount = await _storage.getPendingMutationsCount();

      _lastSyncMessage = synced > 0
          ? 'تمت مزامنة $synced إجراء بنجاح مع الخادم'
          : (failed > 0 ? 'تعذر مزامنة $failed إجراء بسبب تعارض البيانات' : 'تم التحقق من المزامنة');

      _isSyncing = false;
      notifyListeners();

      return SyncResult(
        success: failed == 0,
        syncedCount: synced,
        failedCount: failed,
        message: _lastSyncMessage!,
      );
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return SyncResult(
        success: false,
        syncedCount: synced,
        failedCount: failed,
        message: 'حدث خطأ أثناء المزامنة: $e',
      );
    }
  }

  Future<void> retryFailedItem(String id) async {
    final queue = await _storage.getSyncQueue();
    final item = queue.firstWhere((q) => q.id == id, orElse: () => throw 'Item not found');
    item.status = 'PENDING';
    item.lastError = null;
    await _storage.updateMutation(item);
    _pendingCount = await _storage.getPendingMutationsCount();
    notifyListeners();
    syncPendingMutations();
  }

  Future<void> cancelMutation(String id) async {
    await _storage.removeMutation(id);
    _pendingCount = await _storage.getPendingMutationsCount();
    notifyListeners();
  }
}
