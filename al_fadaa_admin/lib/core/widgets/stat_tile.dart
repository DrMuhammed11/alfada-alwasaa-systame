import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

/// بطاقة إحصائية موحّدة — البديل الوحيد لأربع تطبيقات متنافسة كانت
/// بأحجام وحشوات مختلفة (KpiCard / _statCard / _sectionCard / _statChip).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final String? hint;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = AdminTheme.accent,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(AdminTheme.spaceLg),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AdminTheme.spaceSm),
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Icon(icon, size: AdminTheme.iconSm, color: color),
                ),
                const SizedBox(width: AdminTheme.spaceSm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: AdminTheme.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spaceSm),
          Text(
            value,
            style: const TextStyle(
              fontSize: AdminTheme.fontDisplay,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textHeading,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: AdminTheme.fontXs,
                color: AdminTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AdminTheme.radiusMd), child: content);
  }
}
