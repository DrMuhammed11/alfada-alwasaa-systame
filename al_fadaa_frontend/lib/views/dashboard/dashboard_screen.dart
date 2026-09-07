import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/network/app_events.dart';
import '../../core/utils/page_transitions.dart';
import '../../models/correspondence_model.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'widgets/conversation_detail_pane.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/master_list_pane.dart';
import 'widgets/work_dossier_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // البيانات
  List<Correspondence> _items = [];
  List<TaskItem> _myTasks = [];
  bool _isLoading = true;
  Correspondence? _selectedItem;
  bool _isLoadingDetail = false;

  // التمرير اللانهائي وتقسيم الصفحات
  int _currentPage = 1;
  int _totalItems = 0;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  // إعدادات واجهة المستخدم
  bool _isSidebarCollapsed = false;
  bool _showExtraDetails = false;

  // المرفقات
  PlatformFile? _pickedFile;
  final Set<String> _downloadingAttachmentIds = {};

  // الفلاتر والتحكم
  String _selectedNav = 'ALL';
  String _selectedStatus = 'ALL';
  final _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  // صياغة الرد السريع
  final _quickReplyController = TextEditingController();
  bool _isSendingReply = false;
  String? _editingReplyId;

  // المزامنة والتحديث الموجّه بالأحداث
  bool _isSyncing = false;
  late AnimationController _syncIconController;
  Timer? _autoRefreshTimer;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<void>? _refreshCorrespondencesSubscription;

  @override
  void initState() {
    super.initState();
    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _listScrollController.addListener(_onListScroll);
    _fetchCorrespondences();
    _fetchMyTasks();

    // تحديث موجّه بالأحداث (Event-Driven) فور وصول أي إشعار حي من SSE
    _notificationSubscription = AppEvents().onNotificationReceived.listen((data) {
      debugPrint('Live SSE notification received -> silent refresh');
      _silentRefresh();
    });

    // الاستماع لطلبات تحديث قائمة المراسلات
    _refreshCorrespondencesSubscription = AppEvents().onRefreshCorrespondences.listen((_) {
      _silentRefresh();
    });

    // مؤقت أمان احتياطي بطيء (60 ثانية) كضمانة احتياطية فقط عند غياب أحداث SSE
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _silentRefresh();
    });
  }

  Future<void> _fetchMyTasks() async {
    try {
      final tasks = await ApiService().getMyTasks();
      if (mounted) {
        setState(() {
          _myTasks = tasks;
        });
      }
    } catch (e) {
      debugPrint('fetchMyTasks error: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _refreshCorrespondencesSubscription?.cancel();
    _syncIconController.dispose();
    _autoRefreshTimer?.cancel();
    _listScrollController.removeListener(_onListScroll);
    _searchController.dispose();
    _listScrollController.dispose();
    _detailScrollController.dispose();
    _quickReplyController.dispose();
    super.dispose();
  }

  void _onListScroll() {
    if (_listScrollController.hasClients &&
        _listScrollController.position.pixels >=
            _listScrollController.position.maxScrollExtent - 200) {
      _loadMoreCorrespondences();
    }
  }

  // ─────────────── جلب البيانات والصفحات ───────────────

  Future<void> _fetchCorrespondences({String? selectId}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMorePages = true;
    });

    final isMyTasks = _selectedNav == 'MY_TASKS';
    final apiType = isMyTasks ? null : _selectedNav;
    if (isMyTasks && _myTasks.isEmpty) {
      await _fetchMyTasks();
    }

    try {
      final res = await ApiService().getCorrespondencesPaginated(
        type: apiType,
        status: _selectedStatus,
        search: _searchController.text.trim(),
        page: 1,
        limit: isMyTasks ? 100 : 20,
      );
      if (mounted) {
        List<Correspondence> data = res['data'] as List<Correspondence>;
        if (isMyTasks) {
          final taskCorrIds = _myTasks
              .map((t) => t.correspondenceId)
              .whereType<String>()
              .toSet();
          data = data.where((item) =>
              taskCorrIds.contains(item.id) ||
              item.tasks.any((t) => t.assignedTo?.id == widget.user.id)).toList();
        }
        final Map<String, dynamic> meta = res['meta'] as Map<String, dynamic>;
        final total = isMyTasks ? data.length : (meta['total'] as int? ?? data.length);
        final totalPages = isMyTasks ? 1 : (meta['totalPages'] as int? ?? 1);

        setState(() {
          _items = data;
          _totalItems = total;
          _currentPage = 1;
          _hasMorePages = 1 < totalPages;

          if (_items.isNotEmpty) {
            if (selectId != null) {
              final found = _items.firstWhere((i) => i.id == selectId, orElse: () => _items.first);
              _selectItem(found);
            } else if (_selectedItem == null || !_items.any((i) => i.id == _selectedItem!.id)) {
              _selectItem(_items.first);
            }
          } else {
            _selectedItem = null;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreCorrespondences() async {
    if (_isLoading || _isLoadingMore || !_hasMorePages) return;
    final isMyTasks = _selectedNav == 'MY_TASKS';
    if (isMyTasks) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final res = await ApiService().getCorrespondencesPaginated(
        type: _selectedNav,
        status: _selectedStatus,
        search: _searchController.text.trim(),
        page: nextPage,
        limit: 20,
      );
      if (mounted) {
        final List<Correspondence> nextData = res['data'] as List<Correspondence>;
        final Map<String, dynamic> meta = res['meta'] as Map<String, dynamic>;
        final total = meta['total'] as int? ?? _totalItems;
        final totalPages = meta['totalPages'] as int? ?? 1;

        setState(() {
          final existingIds = _items.map((e) => e.id).toSet();
          for (final item in nextData) {
            if (!existingIds.contains(item.id)) {
              _items.add(item);
            }
          }
          _currentPage = nextPage;
          _totalItems = total;
          _hasMorePages = nextPage < totalPages;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _selectItem(Correspondence item) async {
    setState(() {
      if (_selectedItem?.id != item.id) {
        _editingReplyId = null;
        _quickReplyController.clear();
      }
      _selectedItem = item;
      _isLoadingDetail = true;
    });

    try {
      final detailed = await ApiService().getCorrespondenceById(item.id);
      if (mounted && detailed != null && _selectedItem?.id == item.id) {
        setState(() {
          _selectedItem = detailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  Future<void> _silentRefresh() async {
    try {
      _fetchMyTasks();
      final isMyTasks = _selectedNav == 'MY_TASKS';
      final apiType = isMyTasks ? null : _selectedNav;

      List<Correspondence> refreshedItems = [];
      int total = _totalItems;
      int totalPages = 1;

      if (_currentPage <= 1 || isMyTasks) {
        final res = await ApiService().getCorrespondencesPaginated(
          type: apiType,
          status: _selectedStatus,
          search: _searchController.text.trim(),
          page: 1,
          limit: isMyTasks ? 100 : 20,
        );
        refreshedItems = res['data'] as List<Correspondence>;
        final meta = res['meta'] as Map<String, dynamic>;
        total = meta['total'] as int? ?? refreshedItems.length;
        totalPages = meta['totalPages'] as int? ?? 1;
      } else if (_currentPage * 20 <= 100) {
        // جلب العناصر حتى الصفحة الحالية بدفعة واحدة لتجنب أي انحراف (Pagination Drift)
        final res = await ApiService().getCorrespondencesPaginated(
          type: apiType,
          status: _selectedStatus,
          search: _searchController.text.trim(),
          page: 1,
          limit: _currentPage * 20,
        );
        refreshedItems = res['data'] as List<Correspondence>;
        final meta = res['meta'] as Map<String, dynamic>;
        total = meta['total'] as int? ?? refreshedItems.length;
        totalPages = (total / 20).ceil();
      } else {
        // عند تصفح صفحات متقدمة جدًا (>100 عنصر)، نجلب الصفحات بالتوازي للحفاظ على اتساق القائمة
        final futures = <Future<Map<String, dynamic>>>[];
        for (int p = 1; p <= _currentPage; p++) {
          futures.add(ApiService().getCorrespondencesPaginated(
            type: apiType,
            status: _selectedStatus,
            search: _searchController.text.trim(),
            page: p,
            limit: 20,
          ));
        }
        final results = await Future.wait(futures);
        for (final res in results) {
          refreshedItems.addAll(res['data'] as List<Correspondence>);
        }
        final lastMeta = results.first['meta'] as Map<String, dynamic>;
        total = lastMeta['total'] as int? ?? refreshedItems.length;
        totalPages = lastMeta['totalPages'] as int? ?? 1;
      }

      if (isMyTasks) {
        final taskCorrIds = _myTasks
            .map((t) => t.correspondenceId)
            .whereType<String>()
            .toSet();
        refreshedItems = refreshedItems.where((item) =>
            taskCorrIds.contains(item.id) ||
            item.tasks.any((t) => t.assignedTo?.id == widget.user.id)).toList();
        total = refreshedItems.length;
        totalPages = 1;
      }

      if (mounted && refreshedItems.isNotEmpty) {
        setState(() {
          _items = refreshedItems;
          _totalItems = total;
          _hasMorePages = _currentPage < totalPages;
        });
      }

      if (_selectedItem != null) {
        final currentId = _selectedItem!.id;
        final detailed = await ApiService().getCorrespondenceById(currentId);
        if (mounted && detailed != null && _selectedItem?.id == currentId) {
          setState(() {
            _selectedItem = detailed;
          });
        }
      }

      // تحديث الجرس عبر ناقل الأحداث دون اقتران مباشر
      AppEvents().triggerBellRefresh();
    } catch (_) {}
  }

  Future<void> _openCorrespondenceById(String correspondenceId) async {
    final found = _items.where((i) => i.id == correspondenceId).firstOrNull;
    if (found != null) {
      _selectItem(found);
    } else {
      final detailed = await ApiService().getCorrespondenceById(correspondenceId);
      if (detailed != null && mounted) {
        setState(() {
          _items.insert(0, detailed);
          _selectItem(detailed);
        });
      }
    }
  }

  Future<void> _syncMail() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    _syncIconController.repeat();

    try {
      final result = await ApiService().syncMail();
      await _fetchCorrespondences(selectId: _selectedItem?.id);
      AppEvents().triggerBellRefresh();

      if (mounted) {
        final pulled = result['pulled'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pulled > 0
                ? 'تمت المزامنة بنجاح — تم سحب $pulled رسالة جديدة'
                : 'تمت المزامنة — لا توجد رسائل بريد جديدة في الصندوق'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بخادم البريد'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) {
        _syncIconController.stop();
        _syncIconController.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حجم الملف يتجاوز الحد المسموح (15MB)'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
          }
          return;
        }
        setState(() {
          _pickedFile = file;
        });
      }
    } catch (e) {
      debugPrint('pickFiles error: $e');
    }
  }

  // ─────────────── إجراءات دورة العمل ───────────────

  Future<void> _handleStartReview(String id) async {
    final res = await ApiService().updateCorrespondenceStatus(id, 'UNDER_REVIEW');
    if (res['success'] == true) {
      await _fetchCorrespondences(selectId: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الطلب كمعاملة رسمية بنجاح — يمكنك الآن تكليف قطاع بالمهمة'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _handleShowDossier() {
    if (_selectedItem == null) return;
    showDialog(
      context: context,
      builder: (_) => WorkDossierDialog(
        item: _selectedItem!,
        onDownloadAttachment: _handleDownloadAttachment,
      ),
    );
  }

  Future<void> _handleClose(String id) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إغلاق المعاملة وحفظها'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل تم إنجاز العمل بالكامل وتريد إغلاق هذه المعاملة؟'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'سبب الإغلاق / ملاحظة ختامية (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الإغلاق وحفظ الكشف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService().closeCorrespondence(id);
      if (res['success'] == true) {
        await _fetchCorrespondences(selectId: id);
        if (mounted && _selectedItem != null) {
          _handleShowDossier();
        }
      }
    }
  }

  Future<void> _handleArchive(String id) async {
    final res = await ApiService().archiveCorrespondence(id);
    if (res['success'] == true) await _fetchCorrespondences(selectId: id);
  }

  Future<void> _handleDownloadAttachment(AttachmentItem att) async {
    setState(() => _downloadingAttachmentIds.add(att.id));
    try {
      final ok = await ApiService().downloadAttachment(att.id, att.fileName);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تنزيل المرفق: ${att.fileName}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingAttachmentIds.remove(att.id));
      }
    }
  }

  Future<void> _addReply() async {
    if (_selectedItem == null) return;
    final text = _quickReplyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص المسودة المقترحة (5 أحرف على الأقل)'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSendingReply = true);
    try {
      final res = await ApiService().createReply(_selectedItem!.id, text);
      if (res['success'] == true) {
        final replyData = res['data'];
        final replyId = replyData != null && replyData['id'] != null ? replyData['id'] as String : null;
        if (replyId != null && _pickedFile != null && _pickedFile!.bytes != null) {
          await ApiService().uploadReplyAttachment(replyId, _pickedFile!.bytes!, _pickedFile!.name);
        }
        _quickReplyController.clear();
        setState(() => _pickedFile = null);
        await _selectItem(_selectedItem!);
        await _silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ مسودة الرد بنجاح — جاهزة للاعتماد'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'فشل حفظ المسودة'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _sendDirectReply() async {
    if (_selectedItem == null) return;
    final text = _quickReplyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الرد الرسمي للعميل (5 أحرف على الأقل)'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSendingReply = true);
    try {
      List<String>? attachmentIds;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        final upRes = await ApiService().uploadCorrespondenceAttachment(
          _selectedItem!.id,
          _pickedFile!.bytes!,
          _pickedFile!.name,
        );
        if (upRes['success'] == true && upRes['data'] != null && upRes['data']['id'] != null) {
          attachmentIds = [upRes['data']['id'] as String];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(upRes['message'] ?? 'فشل رفع المرفق، لم يتم إرسال الرد'),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
          return;
        }
      }

      final sendRes = await ApiService().sendDirectReply(
        _selectedItem!.id,
        text,
        attachmentIds,
      );

      if (sendRes['success'] == true) {
        _quickReplyController.clear();
        setState(() => _pickedFile = null);
        await _selectItem(_selectedItem!);
        await _silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم اعتماد الرد وإرساله للعميل بالبريد بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sendRes['message'] ?? 'فشل إرسال الرد للعميل'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _saveEditedReply() async {
    if (_editingReplyId == null) return;
    final text = _quickReplyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص المسودة المعدل'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSendingReply = true);
    try {
      final res = await ApiService().updateReply(_editingReplyId!, text);
      if (res['success'] == true) {
        if (_pickedFile != null && _pickedFile!.bytes != null) {
          await ApiService().uploadReplyAttachment(_editingReplyId!, _pickedFile!.bytes!, _pickedFile!.name);
        }
        _quickReplyController.clear();
        setState(() {
          _editingReplyId = null;
          _pickedFile = null;
        });
        if (_selectedItem != null) await _selectItem(_selectedItem!);
        await _silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ تعديلات مسودة الرد بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'فشل حفظ التعديلات'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _submitReply(String replyId) async {
    final res = await ApiService().submitReply(replyId);
    if (res['success'] == true) {
      if (_selectedItem != null) await _selectItem(_selectedItem!);
      await _silentRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع مسودة الرد للاعتماد الإداري بنجاح'), backgroundColor: Color(0xFF2563EB)),
        );
      }
    }
  }

  Future<void> _approveReply(String replyId) async {
    final res = await ApiService().approveReply(replyId);
    if (res['success'] == true) {
      if (_selectedItem != null) await _selectItem(_selectedItem!);
      await _silentRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم اعتماد مسودة الرد — جاهزة للإرسال للعميل بالبريد'), backgroundColor: Color(0xFF059669)),
        );
      }
    }
  }

  Future<void> _rejectReply(String replyId) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض مسودة الرد وإعادتها للتعديل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('يرجى كتابة ملاحظات وتوجيهات التعديل للكاتب:'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظات وتوجيهات التعديل (إلزامي)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );

    if (confirm == true && noteController.text.trim().isNotEmpty) {
      final res = await ApiService().rejectReply(replyId, noteController.text.trim());
      if (res['success'] == true) {
        if (_selectedItem != null) await _selectItem(_selectedItem!);
        await _silentRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض مسودة الرد وإعادتها للكاتب مع التوجيهات'), backgroundColor: Color(0xFFD97706)),
          );
        }
      }
    }
  }

  Future<void> _sendReply(String replyId) async {
    final res = await ApiService().sendReply(replyId);
    if (res['success'] == true) {
      if (_selectedItem != null) await _selectItem(_selectedItem!);
      await _silentRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرد رسميًا إلى بريد العميل بنجاح'), backgroundColor: Color(0xFF059669)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'فشل إرسال الرد بالبريد'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService().clearToken();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        EnterprisePageRoute(page: const LoginScreen()),
      );
    }
  }

  // ─────────────── بناء الواجهة الرئيسية ───────────────

  @override
  Widget build(BuildContext context) {
    final role = widget.user.role.toUpperCase();
    final isAdminOrGM = role == 'ADMIN' || role == 'GM';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 860;
        final sidebarWidth = _isSidebarCollapsed ? 64.0 : 220.0;
        final listWidth = isWide ? 310.0 : width - sidebarWidth;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Row(
            children: [
              // ─── 1. الشريط الجانبي (Sidebar) ───
              SizedBox(
                width: sidebarWidth,
                child: DashboardSidebar(
                  user: widget.user,
                  isAdminOrGM: isAdminOrGM,
                  isCollapsed: _isSidebarCollapsed,
                  selectedNav: _selectedNav,
                  totalCount: _items.length,
                  incomingCount: _items.where((i) => i.type == 'INCOMING').length,
                  internalCount: _items.where((i) => i.type == 'INTERNAL').length,
                  outgoingCount: _items.where((i) => i.type == 'OUTGOING').length,
                  myTasksCount: _myTasks.where((t) => !t.isDone).length,
                  isSyncing: _isSyncing,
                  syncIconController: _syncIconController,
                  onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  onSelectNav: (nav) {
                    setState(() => _selectedNav = nav);
                    _fetchCorrespondences();
                  },
                  onOpenCorrespondence: _openCorrespondenceById,
                  onRefresh: () {
                    _fetchMyTasks();
                    _fetchCorrespondences();
                  },
                  onSyncMail: _syncMail,
                  onLogout: _logout,
                ),
              ),

              // ─── 2. قائمة المحادثات (Master List Pane) ───
              SizedBox(
                width: listWidth,
                child: MasterListPane(
                  items: _items,
                  isLoading: _isLoading,
                  isLoadingMore: _isLoadingMore,
                  hasMorePages: _hasMorePages,
                  totalItems: _totalItems,
                  selectedItem: _selectedItem,
                  selectedStatus: _selectedStatus,
                  searchController: _searchController,
                  scrollController: _listScrollController,
                  onStatusChanged: (status) {
                    setState(() => _selectedStatus = status);
                    _fetchCorrespondences();
                  },
                  onSearchSubmitted: _fetchCorrespondences,
                  onRefresh: _fetchCorrespondences,
                  onSelectItem: _selectItem,
                ),
              ),

              // ─── 3. لوحة تفاصيل المحادثة (Detail Pane) ───
              if (isWide)
                Expanded(
                  child: ConversationDetailPane(
                    selectedItem: _selectedItem,
                    isLoadingDetail: _isLoadingDetail,
                    currentUserId: widget.user.id,
                    role: role,
                    showExtraDetails: _showExtraDetails,
                    isEditing: _editingReplyId != null,
                    isSendingReply: _isSendingReply,
                    quickReplyController: _quickReplyController,
                    detailScrollController: _detailScrollController,
                    pickedFile: _pickedFile,
                    downloadingAttachmentIds: _downloadingAttachmentIds,
                    onToggleExtraDetails: () => setState(() => _showExtraDetails = !_showExtraDetails),
                    onStartReview: _handleStartReview,
                    onClose: _handleClose,
                    onArchive: _handleArchive,
                    onRefresh: () => _fetchCorrespondences(selectId: _selectedItem?.id),
                    onShowDossier: _handleShowDossier,
                    onEditDraft: (reply) {
                      setState(() {
                        _editingReplyId = reply.id;
                        _quickReplyController.text = reply.body;
                      });
                    },
                    onSubmitReply: _submitReply,
                    onApproveReply: _approveReply,
                    onRejectReply: _rejectReply,
                    onSendReply: _sendReply,
                    onDownloadAttachment: _handleDownloadAttachment,
                    onCancelEdit: () {
                      setState(() {
                        _editingReplyId = null;
                        _quickReplyController.clear();
                      });
                    },
                    onSaveEdit: _saveEditedReply,
                    onSendDirect: _sendDirectReply,
                    onSaveDraft: _addReply,
                    onPickFile: _pickFile,
                    onRemoveFile: () => setState(() => _pickedFile = null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
