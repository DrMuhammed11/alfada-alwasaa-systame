import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:al_fadaa_frontend/core/offline/sync_queue_model.dart';
import 'package:al_fadaa_frontend/core/offline/offline_storage_service.dart';
import 'package:al_fadaa_frontend/core/offline/offline_sync_engine.dart';
import 'package:al_fadaa_frontend/models/correspondence_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    OfflineStorageService().resetForTesting();
    await OfflineStorageService().init();
    OfflineSyncEngine().resetForTesting();
    await OfflineSyncEngine().init();
  });

  tearDown(() async {
    OfflineSyncEngine().resetForTesting();
    await Hive.close();
    await Hive.deleteFromDisk();
    OfflineStorageService().resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('SyncQueueItem Model Tests', () {
    test('يجب تحويل واسترجاع عنصر طابور المزامنة من وإلى JSON بنجاح مع حقل rollbackRegistered', () {
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
        rollbackRegistered: true,
      );

      final json = item.toJson();
      expect(json['rollbackRegistered'], true);

      final fromJson = SyncQueueItem.fromJson(json);
      expect(fromJson.id, 'sync-101');
      expect(fromJson.actionType, 'APPROVE_REPLY');
      expect(fromJson.actionTitleArabic, 'اعتماد مسودة رد');
      expect(fromJson.status, 'PENDING');
      expect(fromJson.entitySummary, 'اعتماد الرد على معاملة INC-2026-0001');
      expect(fromJson.payload['reason'], 'Approved by GM');
      expect(fromJson.rollbackRegistered, true);

      final copy = fromJson.copyWith(status: 'FAILED', rollbackRegistered: false);
      expect(copy.status, 'FAILED');
      expect(copy.rollbackRegistered, false);
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

      final all = await storage.getCachedCorrespondences();
      expect(all.length, 2);

      final internalOnly = await storage.getCachedCorrespondences(type: 'INTERNAL');
      expect(internalOnly.length, 1);
      expect(internalOnly.first.serialNumber, 'INT-2026-0002');

      final searchResult = await storage.getCachedCorrespondences(search: 'خوادم');
      expect(searchResult.length, 1);
      expect(searchResult.first.serialNumber, 'INC-2026-0001');

      final fetched = await storage.getCachedCorrespondence('c-1');
      expect(fetched?.subject, 'طلب توريد أجهزة خوادم سحابية');
    });

    test('يجب إدارة طابور العمليات وحساب العناصر الفاشلة والمعلقة بدقة', () async {
      final storage = OfflineStorageService();
      await storage.init();

      final item1 = SyncQueueItem(
        id: 'mut-1',
        actionType: 'CLOSE_CORRESPONDENCE',
        endpoint: '/api/v1/correspondences/c-1/close',
        httpMethod: 'POST',
        createdAt: DateTime.now(),
        entityId: 'c-1',
        entitySummary: 'إغلاق المعاملة',
        status: 'PENDING',
      );

      final item2 = SyncQueueItem(
        id: 'mut-2',
        actionType: 'APPROVE_REPLY',
        endpoint: '/api/v1/replies/r-2/approve',
        httpMethod: 'POST',
        createdAt: DateTime.now(),
        entityId: 'r-2',
        entitySummary: 'اعتماد الرد',
        status: 'FAILED',
        lastError: 'Server 400',
      );

      await storage.enqueueMutation(item1);
      await storage.enqueueMutation(item2);

      expect(await storage.getPendingMutationsCount(), 1);
      expect(await storage.getFailedMutationsCount(), 1);

      final failedList = await storage.getFailedMutations();
      expect(failedList.length, 1);
      expect(failedList.first.id, 'mut-2');

      await storage.removeMutation('mut-1');
      await storage.removeMutation('mut-2');
      expect(await storage.getPendingMutationsCount(), 0);
      expect(await storage.getFailedMutationsCount(), 0);
    });
  });

  group('OfflineSyncEngine Rollback & Failed Operations Tests (P1-6)', () {
    test('يجب تسجيل دالة onRollback وحفظ rollbackRegistered=true عند حفظ العملية أوفلاين', () async {
      final engine = OfflineSyncEngine();
      await engine.init();
      engine.setOnlineStatus(false);

      bool rollbackTriggered = false;
      bool optimisticApplied = false;

      final res = await engine.executeAction(
        actionType: 'UPDATE_STATUS',
        endpoint: '/api/v1/correspondences/c-10',
        httpMethod: 'PATCH',
        payload: {'status': 'UNDER_REVIEW'},
        entityId: 'c-10',
        entitySummary: 'بدء مراجعة المعاملة c-10',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {
          optimisticApplied = true;
        },
        onRollback: () async {
          rollbackTriggered = true;
        },
      );

      expect(res['success'], true);
      expect(res['offline'], true);
      expect(optimisticApplied, true);
      expect(rollbackTriggered, false);

      final pending = await engine.pendingItems;
      expect(pending.length, 1);
      expect(pending.first.rollbackRegistered, true);
      expect(engine.rollbackCallbacks.containsKey(pending.first.id), true);
    });

    test('يجب استدعاء onRollback وتعليم العنصر FAILED عند تلقي رمز 4xx من الخادم', () async {
      final engine = OfflineSyncEngine();
      await engine.init();
      engine.setOnlineStatus(false);

      bool rollbackExecuted = false;

      await engine.executeAction(
        actionType: 'CLOSE_CORRESPONDENCE',
        endpoint: '/api/v1/correspondences/c-20/close',
        httpMethod: 'POST',
        payload: {'reason': 'Done'},
        entityId: 'c-20',
        entitySummary: 'إغلاق المعاملة c-20',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {},
        onRollback: () async {
          rollbackExecuted = true;
        },
      );

      // محاكاة استجابة الخادم بخطأ تعارض أعمال 400
      engine.mockHttpHandler = (uri, {Map<String, String>? headers, Object? body, Duration? timeout}) async {
        return http.Response('{"message": "Already closed"}', 400);
      };

      final syncResult = await engine.syncPendingMutations(force: true);

      expect(syncResult.success, false);
      expect(syncResult.failedCount, 1);
      expect(rollbackExecuted, true, reason: 'onRollback must be called on 4xx rejection');
      expect(engine.failedCount, 1);

      final failedItems = await engine.failedItems;
      expect(failedItems.length, 1);
      expect(failedItems.first.status, 'FAILED');
      expect(failedItems.first.lastError, contains('400'));
      expect(engine.lastSyncMessage, contains('1'));
    });

    test('يجب استدعاء onRollback عند استنفاد محاولات إعادة الاتصال (5xx) والوصول للحد الأقصى', () async {
      final engine = OfflineSyncEngine();
      await engine.init();
      engine.setOnlineStatus(false);

      bool rollbackExecuted = false;

      await engine.executeAction(
        actionType: 'APPROVE_REPLY',
        endpoint: '/api/v1/replies/rep-99/approve',
        httpMethod: 'POST',
        payload: {},
        entityId: 'rep-99',
        entitySummary: 'اعتماد الرد rep-99',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {},
        onRollback: () async {
          rollbackExecuted = true;
        },
      );

      final storage = OfflineStorageService();
      final queue = await storage.getSyncQueue();
      final item = queue.first;
      // ضبط عدد المحاولات إلى 4 (المحاولة القادمة ستكون الخامسة وتستنفد السقف)
      item.retryCount = 4;
      await storage.updateMutation(item);

      // محاكاة خطأ سيرفر داخلي 500
      engine.mockHttpHandler = (uri, {Map<String, String>? headers, Object? body, Duration? timeout}) async {
        return http.Response('{"message": "Internal Server Error"}', 500);
      };

      await engine.syncPendingMutations(force: true);

      expect(rollbackExecuted, true, reason: 'onRollback must be called when max retries exhausted');
      expect(engine.failedCount, 1);

      final failedItems = await engine.failedItems;
      expect(failedItems.first.status, 'FAILED');
      expect(failedItems.first.retryCount, 5);
      expect(failedItems.first.lastError, contains('استُنفدت المحاولات'));
    });

    test('لا يجب استدعاء onRollback عند نجاح العملية (200/201) مع حذفها من الطابور', () async {
      final engine = OfflineSyncEngine();
      await engine.init();
      engine.setOnlineStatus(false);

      bool rollbackExecuted = false;

      await engine.executeAction(
        actionType: 'ARCHIVE_CORRESPONDENCE',
        endpoint: '/api/v1/correspondences/c-30/archive',
        httpMethod: 'POST',
        payload: {},
        entityId: 'c-30',
        entitySummary: 'أرشفة المعاملة c-30',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {},
        onRollback: () async {
          rollbackExecuted = true;
        },
      );

      // محاكاة نجاح الخادم 200
      engine.mockHttpHandler = (uri, {Map<String, String>? headers, Object? body, Duration? timeout}) async {
        return http.Response('{"success": true}', 200);
      };

      final syncResult = await engine.syncPendingMutations(force: true);

      expect(syncResult.success, true);
      expect(syncResult.syncedCount, 1);
      expect(rollbackExecuted, false, reason: 'onRollback must NOT be called on success');
      expect(engine.failedCount, 0);
      expect(engine.pendingCount, 0);
      expect(engine.rollbackCallbacks.isEmpty, true);
    });

    test('يجب استدعاء onRollback وحذف العملية عند استدعاء cancelMutation', () async {
      final engine = OfflineSyncEngine();
      await engine.init();
      engine.setOnlineStatus(false);

      bool rollbackExecuted = false;

      await engine.executeAction(
        actionType: 'REJECT_REPLY',
        endpoint: '/api/v1/replies/rep-50/reject',
        httpMethod: 'POST',
        payload: {'note': 'Cancel me'},
        entityId: 'rep-50',
        entitySummary: 'رفض الرد rep-50',
        onlineAction: () async => {'success': true},
        onOptimisticUpdate: () async {},
        onRollback: () async {
          rollbackExecuted = true;
        },
      );

      final queue = await OfflineStorageService().getSyncQueue();
      final itemId = queue.first.id;

      await engine.cancelMutation(itemId);

      expect(rollbackExecuted, true, reason: 'onRollback should be executed on user cancellation');
      expect(engine.pendingCount, 0);
      expect(engine.rollbackCallbacks.containsKey(itemId), false);
    });
  });
}
