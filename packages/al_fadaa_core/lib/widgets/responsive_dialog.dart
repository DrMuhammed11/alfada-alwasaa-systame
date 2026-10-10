import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/brand_theme.dart';

/// حوار متجاوب — يقيّد العرض المطلوب بنسبة من نافذة الشاشة
class ResponsiveDialog {
  ResponsiveDialog._();

  /// عرض آمن: أصغر من [preferredWidth] أو 90% من عرض الشاشة
  static double maxWidth(BuildContext context, double preferredWidth) {
    final screen = MediaQuery.sizeOf(context).width;
    return preferredWidth.clamp(280.0, screen * 0.9);
  }

  /// showDialog جاهز بالقيد
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double preferredWidth = 560,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth(dialogContext, preferredWidth)),
          child: builder(dialogContext),
        ),
      ),
    );
  }
}

/// مربع حوار متكامل بهوية الفضاء الواسع
class AppDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  final List<Widget>? actions;
  final IconData? icon;

  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.width = 600,
    this.actions,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BrandTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandTheme.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveDialog.maxWidth(context, width)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BrandTheme.borderLight)),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: BrandTheme.navyPrimary, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BrandTheme.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: BrandTheme.textTertiary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFC),
                  border: Border(top: BorderSide(color: BrandTheme.borderLight)),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(BrandTheme.radiusLg),
                    bottomRight: Radius.circular(BrandTheme.radiusLg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
