import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// شارة حالة موحّدة — البديل الوحيد لأنماط الشارات المكررة في
/// قائمة المراسلات وترويسة المحادثة وشاشات الإدارة.
/// استخدم [AppTheme.getStatusColor] أو [getPriorityColor] للّون.
class AppStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const AppStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  /// شارة بلون حالة مراسلة (يستهلك مُحدِّد اللون المركزي)
  factory AppStatusPill.status(String status, {String? label}) {
    final color = AppTheme.getStatusColor(status);
    return AppStatusPill(label: label ?? status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withAlpha(28) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
