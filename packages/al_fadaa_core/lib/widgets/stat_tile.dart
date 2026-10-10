import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/brand_theme.dart';

/// بطاقة إحصائية موحّدة (KPI Tile) لتطبيقات الفضاء الواسع
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
    this.color = BrandTheme.navyPrimary,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(BrandTheme.spaceMd),
      decoration: BoxDecoration(
        color: BrandTheme.cardSurface,
        borderRadius: BorderRadius.circular(BrandTheme.radiusMd),
        border: Border.all(color: BrandTheme.borderLight),
        boxShadow: BrandTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(BrandTheme.spaceSm),
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(BrandTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: BrandTheme.spaceSm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BrandTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: BrandTheme.spaceSm),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BrandTheme.textHeading,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: BrandTheme.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BrandTheme.radiusMd),
      child: content,
    );
  }
}
