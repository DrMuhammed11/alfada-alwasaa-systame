import 'package:flutter/material.dart';
import '../theme/brand_theme.dart';

/// غلاف بطاقة موحّد لتطبيقات الفضاء الواسع — أبيض + حواف دائرية + ظل ناعم
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BrandTheme.spaceMd),
    this.margin,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? BrandTheme.cardSurface,
      borderRadius: BorderRadius.circular(BrandTheme.radiusMd),
      border: border ?? Border.all(color: BrandTheme.borderLight),
      boxShadow: BrandTheme.cardShadow,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BrandTheme.radiusMd),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
