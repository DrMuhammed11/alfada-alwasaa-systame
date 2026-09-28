import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// صندوق «قيمة/عنوان» الموحّد — بديل MetaBox و_buildMetaBadge و_buildStatBadge
/// المكررة سابقًا بثلاثة أشكال مختلفة من الحشوات والأشعة والأحجام.
class AppMetaBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const AppMetaBox({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontXs,
              color: AppTheme.textTertiary,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
