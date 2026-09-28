import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/app_max_width.dart';
import '../../../core/theme/app_theme.dart';

/// مركز الإشعارات الكامل — بترقيم صفحات وفلترة غير المقروء ووسم المقروء
/// (كانت الإشعارات محصورة في قائمة منبثقة بـ 20 عنصرًا بلا ترقيم)
class NotificationsCenterScreen extends StatefulWidget {
  /// فتح المعاملة المرتبطة عند نقر الإشعار — يعاد توجيهها عبر AppEvents
  /// ليعثر عليها مدخل اللوحة أياً كان شكل التوجيه في السياق الحالي
  final void Function(String correspondenceId)? onOpenCorrespondence;

  const NotificationsCenterScreen({super.key, this.onOpenCorrespondence});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _items = [];
  bool _unreadOnly = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _page < _totalPages) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getMyNotificationsPaged(page: 1, unreadOnly: _unreadOnly);
    final List list = (res['data'] as List?) ?? [];
    if (!mounted) return;
    setState(() {
      _items = List<Map<String, dynamic>>.from(list);
      _page = (res['meta']?['page'] as num?)?.toInt() ?? 1;
      _totalPages = (res['meta']?['totalPages'] as num?)?.toInt() ?? 1;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final res = await ApiService().getMyNotificationsPaged(page: _page + 1, unreadOnly: _unreadOnly);
    final List list = (res['data'] as List?) ?? [];
    if (!mounted) return;
    setState(() {
      _items.addAll(List<Map<String, dynamic>>.from(list));
      _page = (res['meta']?['page'] as num?)?.toInt() ?? _page + 1;
      _totalPages = (res['meta']?['totalPages'] as num?)?.toInt() ?? _totalPages;
      _isLoadingMore = false;
    });
  }

  Future<void> _open(Map<String, dynamic> n) async {
    // وسم المقروء ثم فتح المعاملة المرتبطة — كان النقر طريقاً مسدوداً
    // يعلّم مقروءاً ولا يذهب المستخدم لأي مكان
    if (n['readAt'] == null) {
      await ApiService().markNotificationRead(n['id'] ?? '');
      if (mounted) _load();
    }
    final entityId = n['entityId'] as String?;
    final handler = widget.onOpenCorrespondence;
    if (entityId != null && entityId.isNotEmpty && handler != null) {
      handler(entityId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _markAll() async {
    await ApiService().markAllNotificationsRead();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('مركز الإشعارات', style: TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold)),
        actions: [
          // فلتر غير المقروء
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterChip(
              label: const Text('غير المقروء', style: TextStyle(fontSize: AppTheme.fontXs)),
              selected: _unreadOnly,
              selectedColor: AppTheme.accent,
              labelStyle: TextStyle(color: _unreadOnly ? Colors.white : Colors.white70, fontSize: AppTheme.fontXs),
              checkmarkColor: Colors.white,
              onSelected: (v) {
                _unreadOnly = v;
                _load();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
            tooltip: 'وسم الكل كمقروء',
            onPressed: _markAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('لا توجد إشعارات', style: TextStyle(color: AppTheme.textTertiary)))
              : AppMaxWidth(
                  child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final n = _items[i];
                    final isUnread = n['readAt'] == null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isUnread ? AppTheme.accent.withAlpha(12) : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: isUnread ? AppTheme.accent.withAlpha(90) : AppTheme.secondary.withAlpha(70)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isUnread ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                          color: isUnread ? AppTheme.accent : AppTheme.textTertiary,
                          size: 20,
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: TextStyle(
                            fontSize: AppTheme.fontBase,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppTheme.textHeading,
                          ),
                        ),
                        subtitle: Text(
                          n['body'] ?? '',
                          style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textMuted),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isUnread
                            ? const Icon(Icons.circle, color: AppTheme.accent, size: 9)
                            : null,
                        onTap: () => _open(n),
                      ),
                    );
                  },
                ),
                ),
    );
  }
}
