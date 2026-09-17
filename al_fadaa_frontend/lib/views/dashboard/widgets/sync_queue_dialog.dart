import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/offline/offline_storage_service.dart';
import '../../../../core/offline/offline_sync_engine.dart';
import '../../../../core/offline/sync_queue_model.dart';

class SyncQueueDialog extends StatefulWidget {
  const SyncQueueDialog({super.key});

  @override
  State<SyncQueueDialog> createState() => _SyncQueueDialogState();
}

class _SyncQueueDialogState extends State<SyncQueueDialog> {
  final OfflineStorageService _storage = OfflineStorageService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
  List<SyncQueueItem> _items = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          const Text('طابور العمليات المؤجلة (Offline Sync Queue)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'تحديث',
            onPressed: _loadQueue,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 420,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_rounded, size: 52, color: Colors.green.shade400),
                        const SizedBox(height: 12),
                        const Text('كافة العمليات متزامنة بالكامل!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('لا توجد أي إجراءات معلقة بانتظار الرفع إلى السحابة.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildQueueItemTile(item);
                    },
                  ),
      ),
      actions: [
        if (_items.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () async {
              await OfflineSyncEngine().syncPendingMutations();
              _loadQueue();
            },
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('مزامنة الكل الآن'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildQueueItemTile(SyncQueueItem item) {
    Color statusColor;
    String statusText;

    switch (item.status) {
      case 'SYNCING':
        statusColor = const Color(0xFF2563EB);
        statusText = 'جاري المزامنة';
        break;
      case 'FAILED':
        statusColor = const Color(0xFFDC2626);
        statusText = 'تعذر الرفع';
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF16A34A);
        statusText = 'مكتمل';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusText = 'معلق محلياً';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActionIcon(item.actionType), size: 20, color: statusColor),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withAlpha(60)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _dateFormat.format(item.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.entitySummary,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                ),
                if (item.lastError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الخطأ: ${item.lastError}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (item.status == 'FAILED')
            IconButton(
              icon: const Icon(Icons.replay_rounded, size: 18, color: Color(0xFF2563EB)),
              tooltip: 'إعادة المحاولة',
              onPressed: () async {
                await OfflineSyncEngine().retryFailedItem(item.id);
                _loadQueue();
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
            tooltip: 'إلغاء الإجراء',
            onPressed: () async {
              await OfflineSyncEngine().cancelMutation(item.id);
              _loadQueue();
            },
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
      case 'UPDATE_TASK_STATUS':
        return Icons.checklist_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}
