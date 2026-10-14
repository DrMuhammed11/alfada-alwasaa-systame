import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/offline/offline_sync_engine.dart';
import '../../core/offline/sync_queue_model.dart';
import '../../core/offline/offline_storage_service.dart';
import '../../core/theme/app_theme.dart';

/// شاشة طابور العمليات المعلقة والفاشلة (Pending & Failed Sync Queue)
/// تتيح للمستخدم متابعة العمليات غير المكتملة وإعادة محاولتها أو إلغائها
class PendingOperationsScreen extends StatefulWidget {
  const PendingOperationsScreen({super.key});

  @override
  State<PendingOperationsScreen> createState() => _PendingOperationsScreenState();
}

class _PendingOperationsScreenState extends State<PendingOperationsScreen> {
  final OfflineStorageService _storage = OfflineStorageService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  List<SyncQueueItem> _items = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, FAILED, PENDING

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final queue = await _storage.getSyncQueue();
    queue.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) {
      setState(() {
        _items = queue;
        _isLoading = false;
      });
    }
  }

  List<SyncQueueItem> get _filteredItems {
    if (_filter == 'FAILED') {
      return _items.where((i) => i.status == 'FAILED').toList();
    }
    if (_filter == 'PENDING') {
      return _items.where((i) => i.status == 'PENDING' || i.status == 'SYNCING').toList();
    }
    return _items;
  }

  int get _failedCount => _items.where((i) => i.status == 'FAILED').length;
  int get _pendingCount => _items.where((i) => i.status == 'PENDING' || i.status == 'SYNCING').length;

  @override
  Widget build(BuildContext context) {
    final engine = OfflineSyncEngine();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text(
          'طابور العمليات والمزامنة السحابية',
          style: TextStyle(color: Colors.white, fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الطابور',
            onPressed: _loadQueue,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // شريط الحالة والمعلومات العلوية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        title: 'العمليات المعلقة',
                        count: _pendingCount,
                        color: const Color(0xFFD97706),
                        icon: Icons.hourglass_top_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        title: 'العمليات الفاشلة',
                        count: _failedCount,
                        color: AppTheme.crimson,
                        icon: Icons.error_outline_rounded,
                        isAlert: _failedCount > 0,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        title: 'إجمالي العمليات',
                        count: _items.length,
                        color: AppTheme.primary,
                        icon: Icons.queue_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: engine.isSyncing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final res = await engine.syncPendingMutations(force: true);
                          await _loadQueue();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? AppTheme.emerald : AppTheme.crimson,
                            ),
                          );
                        },
                  icon: engine.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(engine.isSyncing ? 'جاري المزامنة...' : 'مزامنة الكل الآن'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // شريط الفلاتر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('الكل (${_items.length})', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('العمليات الفاشلة ($_failedCount)', 'FAILED', badgeColor: _failedCount > 0 ? AppTheme.crimson : null),
                const SizedBox(width: 8),
                _buildFilterChip('قيد الانتظار ($_pendingCount)', 'PENDING'),
                const Spacer(),
                if (engine.lastSyncMessage != null)
                  Text(
                    engine.lastSyncMessage!,
                    style: const TextStyle(fontSize: AppTheme.fontXs, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // قائمة العمليات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done_rounded, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد عمليات في هذا القسم',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontLg),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'كافة العمليات المحلية تم رفعها ومزامنتها بنجاح مع السحابة.',
                              style: TextStyle(color: Colors.grey, fontSize: AppTheme.fontSm),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildOperationCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? color.withAlpha(20) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isAlert ? color : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: AppTheme.fontXs, color: Colors.grey.shade700)),
              Text('$count', style: TextStyle(fontSize: AppTheme.fontMd, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? badgeColor}) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (badgeColor ?? AppTheme.primary).withAlpha(30),
      labelStyle: TextStyle(
        color: isSelected ? (badgeColor ?? AppTheme.primary) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: AppTheme.fontSm,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
    );
  }

  Widget _buildOperationCard(SyncQueueItem item) {
    Color statusColor;
    String statusText;

    switch (item.status) {
      case 'SYNCING':
        statusColor = AppTheme.info;
        statusText = 'جاري الرفع الآن';
        break;
      case 'FAILED':
        statusColor = AppTheme.crimson;
        statusText = 'تعذر الرفع (فشل)';
        break;
      case 'COMPLETED':
        statusColor = AppTheme.emerald;
        statusText = 'مكتمل بنجاح';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusText = 'معلق محلياً';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: item.status == 'FAILED' ? AppTheme.crimson.withAlpha(120) : Colors.grey.shade200,
          width: item.status == 'FAILED' ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(_getActionIcon(item.actionType), size: 22, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.actionTitleArabic,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontBase),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: statusColor.withAlpha(70)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        if (item.rollbackRegistered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.emerald.withAlpha(60)),
                            ),
                            child: const Text(
                              'تم عكس التعديل تلقائياً',
                              style: TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.entitySummary,
                      style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ),
              Text(
                _dateFormat.format(item.createdAt),
                style: const TextStyle(fontSize: AppTheme.fontXs, color: Colors.grey),
              ),
            ],
          ),

          // تفاصيل المسار التقني
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                Text(
                  item.httpMethod,
                  style: const TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.endpoint,
                    style: TextStyle(fontSize: AppTheme.fontXs, fontFamily: 'monospace', color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.retryCount > 0)
                  Text(
                    'المحاولات: ${item.retryCount}',
                    style: const TextStyle(fontSize: AppTheme.fontXs, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // إظهار سبب الخطأ عند الفشل
          if (item.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withAlpha(15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.crimson.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.crimson),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سبب الفشل: ${item.lastError}',
                      style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.crimson, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // أزرار العمليات
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (item.status == 'FAILED') ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    await OfflineSyncEngine().retryFailedItem(item.id);
                    _loadQueue();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('إعادة المحاولة الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: AppTheme.fontSm),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تأكيد إلغاء الإجراء'),
                      content: const Text('هل أنت متأكد من إلغاء هذا الإجراء من طابور العمليات بشكل نهائي؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('نعم، قم بالإلغاء'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await OfflineSyncEngine().cancelMutation(item.id);
                    _loadQueue();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.crimson),
                label: const Text('إلغاء الإجراء', style: TextStyle(color: AppTheme.crimson)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.crimson),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: AppTheme.fontSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'APPROVE_REPLY':
        return Icons.verified_rounded;
      case 'REJECT_REPLY':
        return Icons.cancel_outlined;
      case 'CREATE_REPLY':
      case 'UPDATE_REPLY':
        return Icons.edit_note_rounded;
      case 'CLOSE_CORRESPONDENCE':
        return Icons.task_alt_rounded;
      case 'ARCHIVE_CORRESPONDENCE':
        return Icons.inventory_2_outlined;
      case 'UPDATE_STATUS':
        return Icons.change_circle_outlined;
      case 'UPDATE_TASK_STATUS':
        return Icons.checklist_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}
