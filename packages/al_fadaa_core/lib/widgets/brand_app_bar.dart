import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/brand_theme.dart';

/// الشريط العلوي الموحد (Brand AppBar) لتطبيقي الفضاء الواسع
/// يوحد المظهر البصري بالكامل مع موقع الويب الرسمي
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const BrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? 64.0 : 64.0 + bottom!.preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: BrandTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: Row(
          children: [
            // الشعار الذهبي للشركة
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BrandTheme.navyDarker,
                borderRadius: BorderRadius.circular(BrandTheme.radiusSm),
                border: Border.all(color: BrandTheme.goldAccent.withAlpha(120), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.all_inclusive_rounded,
                  color: BrandTheme.goldAccent,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: BrandTheme.goldLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}
