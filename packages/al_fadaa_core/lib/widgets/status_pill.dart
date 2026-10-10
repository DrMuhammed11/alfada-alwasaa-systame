import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/brand_theme.dart';
import '../constants/api_constants.dart';

/// شارة حالة موحّدة (Status Pill) للمعاملات والإحالات
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
    this.icon,
  });

  /// إنشاء شارة بحسب كود الحالة من الباك إند
  factory StatusPill.fromStatus(String status) {
    final label = CoreApiConstants.getStatusLabel(status);
    final color = CoreApiConstants.getStatusColor(status);
    return StatusPill(label: label, color: color);
  }

  /// إنشاء شارة بحسب حالة الإحالة
  factory StatusPill.fromReferralStatus(String status) {
    final label = CoreApiConstants.getReferralStatusLabel(status);
    final color = status == 'CLOSED'
        ? BrandTheme.emerald
        : status == 'ANSWERED'
            ? BrandTheme.sky
            : BrandTheme.amber;
    return StatusPill(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withAlpha(24) : Colors.transparent,
        borderRadius: BorderRadius.circular(BrandTheme.radiusLg),
        border: Border.all(color: color.withAlpha(90), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
