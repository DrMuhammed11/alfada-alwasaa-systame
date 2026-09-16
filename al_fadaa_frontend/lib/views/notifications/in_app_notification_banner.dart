import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class InAppNotificationBanner extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;
  final Function(String entityId)? onTap;
  final Duration duration;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _dismissTimer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.forward();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.duration, () {
      if (mounted && !_isHovered) {
        widget.onDismiss();
      }
    });
  }

  void _onMouseEnter(_) {
    setState(() => _isHovered = true);
    _progressController.stop();
    _dismissTimer?.cancel();
  }

  void _onMouseExit(_) {
    setState(() => _isHovered = false);
    final remainingMillis = (widget.duration.inMilliseconds * (1.0 - _progressController.value)).round();
    _progressController.duration = Duration(milliseconds: remainingMillis > 0 ? remainingMillis : 500);
    _progressController.forward(from: _progressController.value);
    _dismissTimer = Timer(Duration(milliseconds: remainingMillis), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
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
        return Icons.notifications_active_rounded;
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

  @override
  Widget build(BuildContext context) {
    final type = widget.notification['type'] as String? ?? '';
    final title = widget.notification['title'] as String? ?? 'إشعار جديد';
    final body = widget.notification['body'] as String?;
    final entityId = widget.notification['entityId'] as String?;
    final iconColor = _getTypeColor(type);
    final iconData = _getTypeIcon(type);

    return MouseRegion(
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      child: Container(
        width: 440,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: entityId != null && entityId.isNotEmpty && widget.onTap != null
                    ? () {
                        widget.onDismiss();
                        widget.onTap!(entityId);
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة النوع داخل دائرة متوهجة
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(iconData, color: iconColor, size: 19),
                      ),
                      const SizedBox(width: 12),

                      // العنوان والمحتوى
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'الآن',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (body != null && body.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                body,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // زر الإغلاق
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'إغلاق',
                        onPressed: widget.onDismiss,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // شريط التقدم الزمني للاختفاء التلقائي
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return LinearProgressIndicator(
                  value: 1.0 - _progressController.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor.withValues(alpha: 0.6)),
                  minHeight: 2.5,
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(
          begin: -0.6,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 350.ms,
        )
        .fadeIn(duration: 250.ms);
  }
}
