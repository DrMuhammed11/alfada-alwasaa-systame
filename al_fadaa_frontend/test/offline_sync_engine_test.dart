import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_fadaa_frontend/core/offline/sync_queue_model.dart';
import 'package:al_fadaa_frontend/core/offline/offline_storage_service.dart';
import 'package:al_fadaa_frontend/core/offline/offline_sync_engine.dart';
import 'package:al_fadaa_frontend/models/correspondence_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncQueueItem Model Tests', () {
    test('يجب تحويل واسترجاع عنصر طابور المزامنة من وإلى JSON بنجاح', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: 'sync-101',
        actionType: 'APPROVE_REPLY',
        endpoint: '/api/v1/replies/rep-1/approve',
        httpMethod: 'POST',
        payload: {'reason': 'Approved by GM'},
        createdAt: now,
        entityId: 'rep-1',
        entitySummary: 'اعتماد الرد على معاملة INC-2026-0001',
      );

      final json = item.toJson();
      final fromJson = SyncQueueItem.fromJson(json);

      expect(fromJson.id, 'sync-101');
      expect(fromJson.actionType, 'APPROVE_REPLY');
      expect(fromJson.actionTitleArabic, 'اعتماد مسودة رد');
      expect(fromJson.status, 'PENDING');
      expect(fromJson.entitySummary, 'اعتماد الرد على معاملة INC-2026-0001');
      expect(fromJson.payload['reason'], 'Approved by GM');
    });
  });

  group('OfflineStorageService Tests', () {
    test('يجب حفظ واسترجاع المراسلات وتطبيق الفلترة والبحث محلياً', () async {
      final storage = OfflineStorageService();
      await storage.init();

      final corr1 = Correspondence(
        id: 'c-1',
        serialNumber: 'INC-2026-0001',
        subject: 'طلب توريد أجهزة خوادم سحابية',
        type: 'INCOMING',
        status: 'RECEIVED',
        priority: 'HIGH',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final corr2 = Correspondence(
        id: 'c-2',
        serialNumber: 'INT-2026-0002',
        subject: 'خطاب داخلي بشأن موازنة المشاريع',
        type: 'INTERNAL',
        status: 'UNDER_REVIEW',
        priority: 'NORMAL',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await storage.cacheCorrespondences([corr1, corr2]);

      // استرجاع الكل
      final all = await storage.getCachedCorrespondences();
      expect(all.length, 2);

      // فلترة بالنوع
      final internalOnly = await storage.getCachedCorrespondences(type: 'INTERNAL');
      expect(internalOnly.length, 1);
      expect(internalOnly.first.serialNumber, 'INT-2026-0002');

      // بحث نصي
      final searchResult = await storage.getCachedCorrespondences(search: 'خوادم');
      expect(searchResult.length, 1);
      expect(searchResult.first.serialNumber, 'INC-2026-0001');

      // استرجاع بالمعرف
      final fetched = await storage.getCachedCorrespondence('c-1');
      expect(fetched?.subject, 'طلب توريد أجهزة خوادم سحابية');
    });

    test('يجب إدارة طابور العمليات (Enqueue, Query, Update, Remove) محلياً', () async {
      final storage = OfflineStorageService();
      await storage.init();

      final item = SyncQueueItem(
        id: 'mut-1',
        actionType: 'CLOSE_CORRESPONDENCE',
        endpoint: '/api/v1/correspondences/c-1/close',
        httpMethod: 'POST',
        createdAt: DateTime.now(),
        entityId: 'c-1',
        entitySummary: 'إغلاق المعاملة',
      );

      await storage.enqueueMutation(item);
      expect(await storage.getPendingMutationsCount(), 1);

      final queue = await storage.getSyncQueue();
      expect(queue.first.id, 'mut-1');

      // تحديث الحالة
      item.status = 'FAILED';
      item.lastError = 'Conflict';
      await storage.updateMutation(item);

      final updatedQueue = await storage.getSyncQueue();
      expect(updatedQueue.first.status, 'FAILED');
      expect(updatedQueue.first.lastError, 'Conflict');

      // حذف العنصر
      await storage.removeMutation('mut-1');
      expect(await storage.getPendingMutationsCount(), 0);
    });
  });

  group('OfflineSyncEngine Tests', () {
    test('يجب تنفيذ الإجراءات التفاؤلية وحفظها في طابور الأوفلاين عند انقطاع الاتصال', () async {
      final engine = OfflineSyncEngine();
      await engine.init();

      // تفعيل وضع الأوفلاين
      engine.setOnlineStatus(false);
      expect(engine.isOffline, true);

      bool optimisticExecuted = false;

      final result = await engine.executeAction(
        actionType: 'APPROVE_REPLY',
        endpoint: '/api/v1/replies/r-10/approve',
        httpMethod: 'POST',
        payload: {},
        entityId: 'r-10',
        entitySummary: 'اعتماد الرد رقم 10',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {
          optimisticExecuted = true;
        },
      );

      expect(result['success'], true);
      expect(result['offline'], true);
      expect(optimisticExecuted, true);
      expect(engine.pendingCount, greaterThanOrEqualTo(1));
    });
  });
}
