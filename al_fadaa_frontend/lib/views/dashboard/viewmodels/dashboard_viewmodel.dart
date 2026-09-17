import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/app_events.dart';
import '../../../core/offline/offline_storage_service.dart';
import '../../../core/offline/offline_sync_engine.dart';
import '../../../models/correspondence_model.dart';
import '../../../models/user_model.dart';

/// نموذج إدارة حالة لوحة التحكم الرئيسية (Dashboard ViewModel)
class DashboardViewModel extends ChangeNotifier {
  final User user;
  DashboardViewModel({required this.user});

  List<Correspondence> items = [];
  List<TaskItem> myTasks = [];
  bool isLoading = true;
  Correspondence? selectedItem;
  bool isLoadingDetail = false;

  int currentPage = 1;
  int totalItems = 0;
  bool isLoadingMore = false;
  bool hasMorePages = true;

  bool isSidebarCollapsed = false;
  bool showExtraDetails = false;

  PlatformFile? pickedFile;
  final Set<String> downloadingAttachmentIds = {};

  String selectedNav = 'ALL';
  String selectedStatus = 'ALL';
  bool isWebsiteFilter = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quickReplyController = TextEditingController();
  String? editingReplyId;
  bool isSendingReply = false;
  bool isSyncing = false;

  StreamSubscription? _notifSub;
  StreamSubscription? _refreshSub;
  Timer? _autoRefreshTimer;

  void init() {
    OfflineSyncEngine().init();
    fetchCorrespondences();
    fetchMyTasks();

    _notifSub = AppEvents().onNotificationReceived.listen((_) => silentRefresh());
    _refreshSub = AppEvents().onRefreshCorrespondences.listen((_) => silentRefresh());
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => silentRefresh());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _refreshSub?.cancel();
    _autoRefreshTimer?.cancel();
    searchController.dispose();
    quickReplyController.dispose();
    super.dispose();
  }

  void toggleSidebar() {
    isSidebarCollapsed = !isSidebarCollapsed;
    notifyListeners();
  }

  void toggleExtraDetails() {
    showExtraDetails = !showExtraDetails;
    notifyListeners();
  }

  void setNav(String nav) {
    selectedNav = nav;
    fetchCorrespondences();
  }

  void setStatus(String status) {
    selectedStatus = status;
    fetchCorrespondences();
  }

  void toggleWebsiteFilter() {
    isWebsiteFilter = !isWebsiteFilter;
    fetchCorrespondences();
  }

  Future<void> fetchMyTasks() async {
    try {
      // 1. تحميل المهام المحفوظة محلياً فورياً (0 ثوانٍ تأخير)
      final cached = await OfflineStorageService().getCachedMyTasks();
      if (cached.isNotEmpty) {
        myTasks = cached;
        notifyListeners();
      }

      // 2. إذا كان متصلاً، تحديثها من الخادم وحفظها محلياً
      if (OfflineSyncEngine().isOnline) {
        final onlineTasks = await ApiService().getMyTasks();
        if (onlineTasks.isNotEmpty) {
          myTasks = onlineTasks;
          await OfflineStorageService().cacheMyTasks(onlineTasks);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('fetchMyTasks error: $e');
    }
  }

  Future<void> fetchCorrespondences({String? selectId}) async {
    isLoading = true;
    currentPage = 1;
    notifyListeners();

    try {
      final isMyTasks = selectedNav == 'MY_TASKS';
      final apiType = isMyTasks ? null : selectedNav;
      final query = searchController.text.trim();

      // 1. استرجاع فوري من الذاكرة المحلية (Cache-First)
      final cached = await OfflineStorageService().getCachedCorrespondences(
        type: apiType,
        status: selectedStatus,
        search: query,
      );
      if (cached.isNotEmpty) {
        items = cached;
        totalItems = cached.length;
        isLoading = false;
        if (selectId != null) {
          final target = items.where((i) => i.id == selectId);
          if (target.isNotEmpty) selectedItem = target.first;
        } else if (selectedItem == null || !items.any((i) => i.id == selectedItem!.id)) {
          selectedItem = items.first;
        }
        notifyListeners();
      }

      // 2. إذا كان أونلاين، تحديث البيانات من الخادم في الخلفية
      if (OfflineSyncEngine().isOnline) {
        final res = await ApiService().getCorrespondencesPaginated(
          type: apiType,
          status: selectedStatus,
          channel: isWebsiteFilter ? 'website' : null,
          search: query,
          page: 1,
          limit: 20,
        );

        final networkItems = res['data'] as List<Correspondence>;
        if (networkItems.isNotEmpty) {
          items = networkItems;
          final meta = res['meta'] as Map<String, dynamic>;
          totalItems = meta['total'] as int? ?? items.length;
          final totalPages = meta['totalPages'] as int? ?? 1;
          hasMorePages = currentPage < totalPages;
          await OfflineStorageService().cacheCorrespondences(networkItems);
          OfflineSyncEngine().setOnlineStatus(true);
        }
      }

      if (items.isNotEmpty) {
        if (selectId != null) {
          final target = items.where((i) => i.id == selectId);
          await selectItem(target.isNotEmpty ? target.first : items.first);
        } else if (selectedItem == null || !items.any((i) => i.id == selectedItem!.id)) {
          await selectItem(items.first);
        }
      } else {
        selectedItem = null;
      }
    } catch (e) {
      debugPrint('fetchCorrespondences network error: $e');
      OfflineSyncEngine().setOnlineStatus(false);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMorePages || selectedNav == 'MY_TASKS') return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = currentPage + 1;
      final res = await ApiService().getCorrespondencesPaginated(
        type: selectedNav,
        status: selectedStatus,
        channel: isWebsiteFilter ? 'website' : null,
        search: searchController.text.trim(),
        page: nextPage,
        limit: 20,
      );

      final nextData = res['data'] as List<Correspondence>;
      final meta = res['meta'] as Map<String, dynamic>;
      totalItems = meta['total'] as int? ?? totalItems;
      final totalPages = meta['totalPages'] as int? ?? 1;

      final existingIds = items.map((e) => e.id).toSet();
      for (final item in nextData) {
        if (!existingIds.contains(item.id)) items.add(item);
      }
      currentPage = nextPage;
      hasMorePages = nextPage < totalPages;
      await OfflineStorageService().cacheCorrespondences(nextData);
    } catch (e) {
      debugPrint('loadMore network error: $e');
      OfflineSyncEngine().setOnlineStatus(false);
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> selectItem(Correspondence item) async {
    if (selectedItem?.id != item.id) {
      editingReplyId = null;
      quickReplyController.clear();
      pickedFile = null;
    }
    selectedItem = item;
    isLoadingDetail = true;
    notifyListeners();

    try {
      if (OfflineSyncEngine().isOnline) {
        final detailed = await ApiService().getCorrespondenceById(item.id);
        if (detailed != null && selectedItem?.id == item.id) {
          selectedItem = detailed;
          await OfflineStorageService().updateCachedCorrespondence(detailed);
        }
      } else {
        final local = await OfflineStorageService().getCachedCorrespondence(item.id);
        if (local != null && selectedItem?.id == item.id) {
          selectedItem = local;
        }
      }
    } catch (e) {
      debugPrint('selectItem online fetch error, using local: $e');
      final local = await OfflineStorageService().getCachedCorrespondence(item.id);
      if (local != null && selectedItem?.id == item.id) {
        selectedItem = local;
      }
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> silentRefresh() async {
    try {
      fetchMyTasks();
      final isMyTasks = selectedNav == 'MY_TASKS';
      final apiType = isMyTasks ? null : selectedNav;
      if (OfflineSyncEngine().isOnline) {
        final res = await ApiService().getCorrespondencesPaginated(
          type: apiType,
          status: selectedStatus,
          search: searchController.text.trim(),
          page: 1,
          limit: 20,
        );
        final freshItems = res['data'] as List<Correspondence>;
        if (freshItems.isNotEmpty) {
          items = freshItems;
          final meta = res['meta'] as Map<String, dynamic>;
          totalItems = meta['total'] as int? ?? items.length;
          await OfflineStorageService().cacheCorrespondences(freshItems);
        }

        if (selectedItem != null) {
          final detailed = await ApiService().getCorrespondenceById(selectedItem!.id);
          if (detailed != null) {
            selectedItem = detailed;
            await OfflineStorageService().updateCachedCorrespondence(detailed);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('silentRefresh error: $e');
    }
  }

  Future<bool> syncMail() async {
    isSyncing = true;
    notifyListeners();
    try {
      // 1. رفع كافة العمليات المعلقة محلياً
      await OfflineSyncEngine().syncPendingMutations();
      // 2. جلب البريد الجديد من الخادم
      final res = await ApiService().syncMail();
      await silentRefresh();
      return res['success'] == true;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        pickedFile = result.files.first;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('pickFile error: $e');
    }
  }

  void removeFile() {
    pickedFile = null;
    notifyListeners();
  }

  void startEditingReply(ReplyItem reply) {
    editingReplyId = reply.id;
    quickReplyController.text = reply.body;
    notifyListeners();
  }

  void cancelEditingReply() {
    editingReplyId = null;
    quickReplyController.clear();
    pickedFile = null;
    notifyListeners();
  }

  void updateUI() => notifyListeners();
}
