import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
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

/// محرك المزامنة الثنائي الذكي وإدارة الاتصال لوضع Offline-First.
///
/// إصلاحات الجيل الثاني:
/// - الاتصال يُراقب فعلياً عبر connectivity_plus — العودة للشبكة تعيد المزامنة تلقائياً
///   (كان المحرك يعلق «غير متصل» إلى الأبد بعد أول فشل)
/// - سقف إعادة محاولة (5) مع تراجع أسي (30ث → 10د) لكل عنصر — لا إعادة لانهائية
///   لعناصر ترمي 500 باستمرار
/// - معرف عنصر الطابور فريد (طابع زمني + عشوائي) بدل الطابع وحده المعرض للتصادم
class OfflineSyncEngine extends ChangeNotifier {
  static final OfflineSyncEngine _instance = OfflineSyncEngine._internal();
  factory OfflineSyncEngine() => _instance;
  OfflineSyncEngine._internal();

  final OfflineStorageService _storage = OfflineStorageService();
  final AppHttpClient _http = AppHttpClient();

  static const int _maxRetries = 5;
  static const Duration _baseBackoff = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(minutes: 10);

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _manualOfflineMode = false;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;
  String? _lastSyncMessage;
  Timer? _autoSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

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

    // مراقبة الاتصال الفعلية — الخروج من التعليق يحدث هنا تلقائياً
    _connectivitySub?.cancel();
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final hasConnection =
            results.any((r) => r != ConnectivityResult.none);
        setOnlineStatus(hasConnection);
      });
      // فحص أولي فوري للحالة الراهنة
      Connectivity().checkConnectivity().then((results) {
        setOnlineStatus(results.any((r) => r != ConnectivityResult.none));
      }).catchError((_) {});
    } catch (e) {
      // بيئات الاختبار بلا منصة اتصال — تُدار الحالة يدوياً عبر setOnlineStatus
      debugPrint('Connectivity watch unavailable: $e');
    }

    // مزامنة دورية خفيفة كل دقيقتين
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
    _connectivitySub?.cancel();
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
    // 1. وضع الأوفلاين (يدوي أو فعلي): حفظ تفاؤلي في الطابور
    if (isOffline) {
      return _enqueueOffline(
        actionType: actionType,
        endpoint: endpoint,
        httpMethod: httpMethod,
        payload: payload,
        entityId: entityId,
        entitySummary: entitySummary,
        onOptimisticUpdate: onOptimisticUpdate,
        message: 'تم تسجيل الإجراء محلياً بنجاح وسيتم رفعه تلقائياً فور توفر الاتصال',
      );
    }

    // 2. أونلاين: التنفيذ الفوري، وعند فشل الشبكة التحويل للطابور
    try {
      return await onlineAction();
    } catch (e) {
      debugPrint('Action network error, falling back to offline queue: $e');
      setOnlineStatus(false);
      return _enqueueOffline(
        actionType: actionType,
        endpoint: endpoint,
        httpMethod: httpMethod,
        payload: payload,
        entityId: entityId,
        entitySummary: entitySummary,
        onOptimisticUpdate: onOptimisticUpdate,
        message: 'تعذر الاتصال بالخادم، تم حفظ الإجراء محلياً وسيتم رفعه تلقائياً',
      );
    }
  }

  Future<Map<String, dynamic>> _enqueueOffline({
    required String actionType,
    required String endpoint,
    required String httpMethod,
    required Map<String, dynamic> payload,
    required String entityId,
    required String entitySummary,
    required Future<void> Function() onOptimisticUpdate,
    required String message,
  }) async {
    await onOptimisticUpdate();
    // معرف فريد: طابع زمني + لاحقة عشوائية (الطابع وحده يتصادم في نفس المللي ثانية)
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(0x7FFFFFFF)}';
    final item = SyncQueueItem(
      id: id,
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

    return {'success': true, 'offline': true, 'message': message};
  }

  /// تراجع أسي: 30ث، 1د، 2د، 4د، 8د — بسقف 10 دقائق
  Duration _backoffFor(int retryCount) {
    final seconds = _baseBackoff.inSeconds * pow(2, max(0, retryCount - 1)).toInt();
    return seconds > _maxBackoff.inSeconds ? _maxBackoff : Duration(seconds: seconds);
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
      final now = DateTime.now();
      final pendingItems = queue
          .where((q) =>
              (q.status == 'PENDING' || q.status == 'SYNCING') &&
              (force || q.nextRetryAt == null || q.nextRetryAt!.isBefore(now)))
          .toList();

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
            // خطأ تحقق أو تعارض أعمال — إعادة المحاولة لن تغير النتيجة
            item.status = 'FAILED';
            item.lastError = 'رفض الخادم: رمز ${response.statusCode}';
            item.nextRetryAt = null;
            await _storage.updateMutation(item);
            failed++;
          } else {
            // خطأ سيرفر: سقف محاولات + تراجع أسي بدل التكرار اللانهائي
            item.retryCount++;
            if (item.retryCount >= _maxRetries) {
              item.status = 'FAILED';
              item.lastError = 'استُنفدت المحاولات (${item.retryCount}) — آخر رمز: ${response.statusCode}';
              item.nextRetryAt = null;
            } else {
              item.nextRetryAt = DateTime.now().add(_backoffFor(item.retryCount));
            }
            await _storage.updateMutation(item);
          }
        } catch (netErr) {
          debugPrint('Sync network drop on item ${item.id}: $netErr');
          setOnlineStatus(false);
          break; // إيقاف المزامنة مؤقتاً — عودة الاتصال (connectivity) تعيد المحاولة
        }
      }

      final now2 = DateTime.now();
      _lastSyncTime = now2;
      await _storage.setLastSyncTime(now2);
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
    item.retryCount = 0;
    item.nextRetryAt = null;
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
