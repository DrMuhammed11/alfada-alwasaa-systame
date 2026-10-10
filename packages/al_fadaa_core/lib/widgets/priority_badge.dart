import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/api_constants.dart';
import '../theme/brand_theme.dart';

/// شارة درجة الأسبقية والأهمية (Priority Badge)
class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final label = CoreApiConstants.getPriorityLabel(priority);
    final color = CoreApiConstants.getPriorityColor(priority);
    final isUrgent = priority.toUpperCase() == 'URGENT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(BrandTheme.radiusSm),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Icon(Icons.bolt_rounded, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
