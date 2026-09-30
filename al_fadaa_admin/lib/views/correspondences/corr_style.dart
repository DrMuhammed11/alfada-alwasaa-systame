import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_formatters.dart';

/// أنماط وعناصر مشتركة بين قائمة المحادثات وشاشة الدردشة (نمط واتساب)
class CorrStyle {
  CorrStyle._();

  // ─── ألوان الحالة ───
  static Color statusColor(String s) => switch (s.toUpperCase()) {
        'CLOSED' || 'ARCHIVED' || 'SENT' || 'APPROVED' => AdminTheme.emerald,
        'RECEIVED' || 'UNDER_REVIEW' => AdminTheme.amber,
        _ => AdminTheme.accent,
      };

  static Color typeColor(String type) => switch (type.toUpperCase()) {
        'INCOMING' => AdminTheme.accent,
        'OUTGOING' => AdminTheme.emerald,
        'INTERNAL' => AdminTheme.purple,
        _ => AdminTheme.textMuted,
      };

  static IconData typeIcon(String type) => switch (type.toUpperCase()) {
        'INCOMING' => Icons.call_received_rounded,
        'OUTGOING' => Icons.call_made_rounded,
        'INTERNAL' => Icons.sync_alt_rounded,
        _ => Icons.mail_rounded,
      };

  /// لون ثابت مشتق من بذرة (بريد أو اسم الجهة) — نفس الجهة بلونها دائماً
  static Color avatarColor(String seed) {
    const palette = [
      AdminTheme.accent,
      AdminTheme.purple,
      AdminTheme.emerald,
      AdminTheme.amber,
      AdminTheme.slate,
      AdminTheme.crimson,
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  /// الحرف الأول من الاسم للصورة الرمزية
  static String avatarInitial(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '؟';
    return n.characters.first.toUpperCase();
  }

  /// الصورة الرمزية الدائرية الموحدة
  static Widget avatar({String? name, required String seed, double size = 46}) {
    final color = avatarColor(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          avatarInitial(name),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size >= 44 ? AdminTheme.fontXl : AdminTheme.fontLg,
          ),
        ),
      ),
    );
  }

  /// أرشيف ذكي للوقت بنمط واتساب: اليوم = الساعة، أمس، أيام الأسبوع، ثم التاريخ
  static String smartTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return AppFormatters.timeOnly(local);
    if (diff == 1) return 'أمس';
    if (diff > 1 && diff < 7) return DateFormat('EEEE', 'ar').format(local);
    if (local.year == now.year) return DateFormat('dd/MM', 'ar').format(local);
    return AppFormatters.dateOnly(local);
  }

  /// فاصل يوم داخل الدردشة: اليوم / أمس / التاريخ الكامل بالعربية
  static String daySeparatorLabel(DateTime dt) {
    final local = DateTime(dt.toLocal().year, dt.toLocal().month, dt.toLocal().day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(local).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return DateFormat('EEEE، d MMMM yyyy', 'ar').format(local);
  }
}
