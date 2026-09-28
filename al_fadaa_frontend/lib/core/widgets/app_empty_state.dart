import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// حالة فراغ موحّدة — أيقونة + عنوان + وصف اختياري، بتباين AA
/// (كانت الحالات الفارغة منسوخة يدويًا بألوان رمادية فاشلة التباين).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = AppTheme.emerald,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 44),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppTheme.fontXs,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
