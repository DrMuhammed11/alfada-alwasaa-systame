import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/correspondence_model.dart';
import '../network/api_service.dart';
import '../network/app_events.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(seconds: 60);
}

/// مستودع المراسلات مع ذاكرة تخزين مؤقتة ذكية لمدة 60 ثانية وإلغاء صلاحية فوري عبر SSE
class CorrespondencesRepository {
  static final CorrespondencesRepository _instance =
      CorrespondencesRepository._internal();
  factory CorrespondencesRepository() => _instance;

  final ApiService _api = ApiService();
  final Map<String, _CacheEntry<Map<String, dynamic>>> _pageCache = {};
  final Map<String, _CacheEntry<Correspondence>> _detailCache = {};

  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<void>? _refreshSub;

  CorrespondencesRepository._internal() {
    // إبطال فوري للذاكرة المؤقتة عند ورود أي إشعار SSE حي
    _notificationSub = AppEvents().onNotificationReceived.listen((_) {
      debugPrint('Repository: Invalidation triggered by SSE event');
      clearCache();
    });

    // إبطال الذاكرة المؤقتة عند طلب تحديث صريح من التطبيق
    _refreshSub = AppEvents().onRefreshCorrespondences.listen((_) {
      debugPrint('Repository: Invalidation triggered by AppEvents refresh');
      clearCache();
    });
  }

  String _buildCacheKey({
    String? type,
    String? status,
    String? priority,
    String? search,
    int page = 1,
    int limit = 20,
  }) {
    return 't:${type ?? ""}_s:${status ?? ""}_p:${priority ?? ""}_q:${search ?? ""}_pg:${page}_l:$limit';
  }

  /// استرجاع صفحة المراسلات مع اعتماد الكاش المؤقت إلا عند فرض التحديث
  Future<Map<String, dynamic>> getCorrespondencesPaginated({
    String? type,
    String? status,
    String? priority,
    String? search,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final key = _buildCacheKey(
      type: type,
      status: status,
      priority: priority,
      search: search,
      page: page,
      limit: limit,
    );

    if (!forceRefresh && _pageCache.containsKey(key)) {
      final cached = _pageCache[key]!;
      if (!cached.isExpired) {
        return cached.data;
      }
    }

    final result = await _api.getCorrespondencesPaginated(
      type: type,
      status: status,
      priority: priority,
      search: search,
      page: page,
      limit: limit,
    );

    // تخزين في الكاش إذا كانت النتيجة صحيحة وبها بيانات
    if (result['data'] is List && (result['data'] as List).isNotEmpty) {
      _pageCache[key] = _CacheEntry(result);
    }

    return result;
  }

  /// استرجاع تفاصيل مراسلة واحدة مع الكاش
  Future<Correspondence?> getCorrespondenceById(
    String id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _detailCache.containsKey(id)) {
      final cached = _detailCache[id]!;
      if (!cached.isExpired) {
        return cached.data;
      }
    }

    final item = await _api.getCorrespondenceById(id);
    if (item != null) {
      _detailCache[id] = _CacheEntry(item);
    }
    return item;
  }

  /// تفريغ الذاكرة المؤقتة بالكامل
  void clearCache() {
    _pageCache.clear();
    _detailCache.clear();
  }

  void dispose() {
    _notificationSub?.cancel();
    _refreshSub?.cancel();
    clearCache();
  }
}
