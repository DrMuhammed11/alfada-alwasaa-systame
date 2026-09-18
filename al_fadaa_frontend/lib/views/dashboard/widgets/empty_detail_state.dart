import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class EmptyDetailState extends StatelessWidget {
  const EmptyDetailState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'اختر مراسلة لعرض التفاصيل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إدارة سلسلة المحادثة، مراجعة واعتماد مسودات الردود، وتكليف القطاعات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.05, end: 0);
  }
}
