import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_service.dart';
import '../../core/network/app_events.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_formatter.dart';

class NotificationsBell extends StatefulWidget {
  final Function(String correspondenceId)? onNotificationTap;
  final Color iconColor;
  final double iconSize;

  const NotificationsBell({
    super.key,
    this.onNotificationTap,
    this.iconColor = const Color(0xFF94A3B8),
    this.iconSize = 18,
  });

  @override
  State<NotificationsBell> createState() => NotificationsBellState();
}

class NotificationsBellState extends State<NotificationsBell> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  http.Client? _sseClient;
  bool _isSseConnected = false;
  StreamSubscription<void>? _bellRefreshSubscription;

  @override
  void initState() {
    super.initState();
    refresh();
    _connectSse();
    // الاستماع لطلبات التحديث المركزية للجرس دون الحاجة لـ GlobalKey
    _bellRefreshSubscription = AppEvents().onRefreshBell.listen((_) {
      if (mounted) refresh();
    });
  }

  @override
  void dispose() {
    _bellRefreshSubscription?.cancel();
    _sseClient?.close();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _connectSse() async {
    _sseClient?.close();
    final client = http.Client();
    _sseClient = client;

    try {
      final request = http.Request('GET', Uri.parse(ApiService().sseNotificationsUrl));
      final token = ApiService().token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);
      if (response.statusCode == 200) {
        _isSseConnected = true;
        AppEvents().isSseConnected = true;
        _pollTimer?.cancel();
        _pollTimer = null;

        String currentEvent = 'message';

        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) return;

          if (trimmed.startsWith('event:')) {
            currentEvent = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            _handleSseMessage(currentEvent, dataStr);
            currentEvent = 'message';
          }
        }, onError: (_) {
          _onSseDisconnected();
        }, onDone: () {
          _onSseDisconnected();
        });
      } else {
        _onSseDisconnected();
      }
    } catch (_) {
      _onSseDisconnected();
    }
  }

  void _onSseDisconnected() {
    if (!mounted) return;
    _isSseConnected = false;
    AppEvents().isSseConnected = false;
    _startFallbackPolling();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _connectSse();
    });
  }

  void _startFallbackPolling() {
    if (_pollTimer == null || !_pollTimer!.isActive) {
      _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        refresh();
      });
    }
  }

  void _handleSseMessage(String event, String dataStr) {
    try {
      final data = jsonDecode(dataStr);
      if (event == 'unread-count') {
        final count = data['count'] as int? ?? 0;
        if (mounted) {
          setState(() => _unreadCount = count);
        }
      } else if (event == 'new-notification') {
        // بث الإشعار الجديد لناقل الأحداث لتحديث Dashboard بدون استطلاع دوري أعمى
        AppEvents().emitNotification(data);
        if (mounted) {
          setState(() {
            _unreadCount++;
            if (_notifications.isNotEmpty) {
              _notifications.insert(0, data);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      final count = await ApiService().getUnreadNotificationsCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchList() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService().getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTapNotification(Map<String, dynamic> notif) async {
    final id = notif['id'] as String?;
    final entityId = notif['entityId'] as String?;
    final isRead = notif['isRead'] == true;

    if (id != null && !isRead) {
      await ApiService().markNotificationAsRead(id);
      if (mounted) {
        setState(() {
          notif['isRead'] = true;
          if (_unreadCount > 0) _unreadCount--;
        });
      }
    }

    if (entityId != null && entityId.isNotEmpty && widget.onNotificationTap != null) {
      widget.onNotificationTap!(entityId);
    }
  }

  Future<void> _handleMarkAllRead() async {
    await ApiService().markAllNotificationsAsRead();
    if (mounted) {
      setState(() {
        _unreadCount = 0;
        for (final n in _notifications) {
          n['isRead'] = true;
        }
      });
    }
  }

  void _showNotificationsMenu(Offset position) async {
    await _fetchList();
    if (!mounted) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 380, 480),
        Offset.zero & overlay.size,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (ctx, setMenuState) {
              return Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // رأس قائمة الإشعارات
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 17, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          const Text(
                            'التنبيهات والإشعارات',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_unreadCount جديد',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (_unreadCount > 0)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                await _handleMarkAllRead();
                                setMenuState(() {});
                              },
                              child: const Text(
                                'تحديد الكل كمقروء',
                                style: TextStyle(fontSize: 11, color: AppTheme.accent),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // قائمة الإشعارات
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (_notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 8),
                            Text(
                              'لا توجد إشعارات حتى الآن',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (itemCtx, index) {
                            final n = _notifications[index];
                            final isRead = n['isRead'] == true;
                            final type = n['type'] as String? ?? '';
                            final title = n['title'] as String? ?? 'إشعار جديد';
                            final body = n['body'] as String?;
                            final createdAtStr = n['createdAt'] as String?;
                            DateTime? date;
                            if (createdAtStr != null) {
                              date = DateTime.tryParse(createdAtStr);
                            }

                            final iconData = _getTypeIcon(type);
                            final iconColor = _getTypeColor(type);

                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                _handleTapNotification(n);
                              },
                              child: Container(
                                color: isRead ? Colors.white : const Color(0xFFF0F9FF),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: iconColor.withAlpha(25),
                                      child: Icon(iconData, size: 14, color: iconColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                    color: isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF0284C7),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (body != null && body.trim().isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              body,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (date != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTimeAgo(date),
                                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'NEW_INCOMING':
        return Icons.mark_email_unread_rounded;
      case 'NEW_REFERRAL':
        return Icons.swap_horiz_rounded;
      case 'NEW_TASK':
        return Icons.assignment_ind_rounded;
      case 'TASK_CANCELLED':
        return Icons.assignment_late_rounded;
      case 'REPLY_SUBMITTED':
        return Icons.rate_review_rounded;
      case 'REPLY_APPROVED':
        return Icons.check_circle_rounded;
      case 'REPLY_REJECTED':
        return Icons.cancel_rounded;
      case 'REPLY_SENT':
        return Icons.send_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'NEW_INCOMING':
        return const Color(0xFF0284C7);
      case 'NEW_REFERRAL':
        return const Color(0xFF7C3AED);
      case 'NEW_TASK':
        return const Color(0xFFD97706);
      case 'TASK_CANCELLED':
        return const Color(0xFF64748B);
      case 'REPLY_SUBMITTED':
        return const Color(0xFF2563EB);
      case 'REPLY_APPROVED':
        return const Color(0xFF059669);
      case 'REPLY_REJECTED':
        return const Color(0xFFDC2626);
      case 'REPLY_SENT':
        return const Color(0xFF0D9488);
      default:
        return AppTheme.accent;
    }
  }

  String _formatTimeAgo(DateTime date) {
    return AppDateFormatter.formatListDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                _unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                color: _unreadCount > 0 ? const Color(0xFFF59E0B) : widget.iconColor,
                size: widget.iconSize,
              ),
              tooltip: _unreadCount > 0
                  ? 'التنبيهات ($_unreadCount جديد)'
                  : (_isSseConnected ? 'التنبيهات (بث حي)' : 'التنبيهات'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                final box = btnContext.findRenderObject() as RenderBox?;
                if (box != null) {
                  final position = box.localToGlobal(Offset.zero);
                  _showNotificationsMenu(position + Offset(0, box.size.height + 4));
                }
              },
            ),
            if (_unreadCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0F172A), width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
