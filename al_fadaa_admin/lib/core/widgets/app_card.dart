import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

/// غلاف بطاقة موحّد — أبيض + حد + ظل موحد + نصف قطر radiusMd.
/// كان كل عرض يبني نسخته الخاصة بحشوة ومسافة مختلفة.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AdminTheme.spaceLg),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: onTap == null
          ? Padding(padding: padding ?? EdgeInsets.zero, child: child)
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ),
    );
  }
}
