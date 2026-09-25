import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';

/// مركز الإشعارات الكامل — بترقيم صفحات وفلترة غير المقروء ووسم المقروء
/// (كانت الإشعارات محصورة في قائمة منبثقة بـ 20 عنصرًا بلا ترقيم)
class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

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
    if (n['readAt'] == null) {
      await ApiService().markNotificationRead(n['id'] ?? '');
      if (mounted) _load();
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
        title: const Text('مركز الإشعارات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          // فلتر غير المقروء
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterChip(
              label: const Text('غير المقروء', style: TextStyle(fontSize: 11)),
              selected: _unreadOnly,
              selectedColor: AppTheme.accent,
              labelStyle: TextStyle(color: _unreadOnly ? Colors.white : Colors.white70, fontSize: 11),
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
              ? const Center(child: Text('لا توجد إشعارات', style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
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
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isUnread ? AppTheme.accent.withAlpha(90) : AppTheme.secondary.withAlpha(70)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isUnread ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded,
                          color: isUnread ? AppTheme.accent : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          n['body'] ?? '',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
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
    );
  }
}
