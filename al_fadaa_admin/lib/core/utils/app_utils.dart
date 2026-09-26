import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/admin_theme.dart';

/// أدوات مساعدة مشتركة للتطبيق
class AppUtils {
  AppUtils._();

  /// تنسيق الأرقام الكبيرة بالفواصل العربية
  static String formatNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} م';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} ألف';
    return value.toInt().toString();
  }

  /// لون حسب نسبة الأداء
  static Color performanceColor(double rate) {
    if (rate >= 85) return AdminTheme.emerald;
    if (rate >= 60) return AdminTheme.amber;
    return AdminTheme.crimson;
  }

  /// أيقونة حالة الحساب
  static IconData statusIcon(bool isActive) =>
      isActive ? Icons.check_circle_rounded : Icons.cancel_rounded;

  /// نسخ نص للحافظة مع إشعار
  static Future<void> copyToClipboard(BuildContext context, String text, {String? message}) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'تم النسخ إلى الحافظة'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// حقل CSV واحد — يُقتبس إذا احتوى فاصلة أو اقتباساً أو سطراً جديداً
  static String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// بناء نص CSV من صفوف نصية
  static String buildCsv(List<List<String>> rows) {
    return rows.map((row) => row.map(_csvField).join(',')).join('\r\n');
  }

  /// تصدير صفوف CSV إلى ملف يختاره المستخدم (نافذة حفظ النظام)
  /// تُسبق البيانات بـ BOM لضمان قراءة العربية في Excel — يعيد true عند نجاح الحفظ
  static Future<bool> exportCsv({
    required BuildContext context,
    required String suggestedName,
    required List<List<String>> rows,
  }) async {
    try {
      final location = await getSaveLocation(suggestedName: suggestedName);
      if (location == null) return false; // ألغى المستخدم نافذة الحفظ
      // BOM لضمان فك ترميز UTF-8 العربي في Excel
      await File(location.path).writeAsString('\uFEFF${buildCsv(rows)}', flush: true);
      if (!context.mounted) return true;
      showSuccess(context, 'تم حفظ الملف: ${location.path.split(Platform.pathSeparator).last}');
      return true;
    } catch (e) {
      if (context.mounted) showError(context, 'تعذر حفظ ملف التصدير: $e');
      return false;
    }
  }

  /// عرض تأكيد الحذف بتصميم موحد
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'حذف',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusLg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminTheme.crimson.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AdminTheme.crimson, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, color: AdminTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: Text(confirmLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AdminTheme.crimson,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// عرض Snackbar نجاح
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AdminTheme.emerald,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// عرض Snackbar خطأ
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AdminTheme.crimson,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إخفاء',
          textColor: Colors.white70,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// عرض Snackbar تحذير
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AdminTheme.amber,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// ودجة Badge (شارة) مُعاد استخدامها
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final EdgeInsets? padding;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// ودجة KPI Card لإعادة الاستخدام في لوحة الإحصائيات
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          border: Border.all(color: AdminTheme.border),
          boxShadow: AdminTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AdminTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AdminTheme.textMain,
                height: 1.1,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// ودجة تحميل فارغة مع رسالة
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AdminTheme.surface2,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AdminTheme.textLight),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AdminTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// ودجة خطأ تحميل موحدة
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.message = 'تعذر الاتصال بالخادم',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminTheme.crimson.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, size: 36, color: AdminTheme.crimson),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'تحقق من الاتصال بالإنترنت أو اتصل بالمدير التقني',
            style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('إعادة المحاولة'),
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.accent),
          ),
        ],
      ),
    );
  }
}

/// ودجة تحميل موحدة مع نص
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AdminTheme.accent,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// ودجة شريط ترقيم الصفحات الموحد
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final void Function(int) onPageChange;
  final bool isLoading;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPageChange,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: [
          Text(
            'إجمالي: $total  |  الصفحة $currentPage من $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminTheme.textMuted,
            ),
          ),
          const Spacer(),
          // زر الصفحة الأولى
          IconButton(
            icon: const Icon(Icons.first_page_rounded),
            iconSize: 18,
            tooltip: 'الصفحة الأولى',
            onPressed: currentPage > 1 && !isLoading ? () => onPageChange(1) : null,
          ),
          // الصفحة السابقة
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 18,
            tooltip: 'الصفحة السابقة',
            onPressed: currentPage > 1 && !isLoading ? () => onPageChange(currentPage - 1) : null,
          ),
          // رقم الصفحة الحالي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.primary,
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Text(
              '$currentPage',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          // الصفحة التالية
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 18,
            tooltip: 'الصفحة التالية',
            onPressed: currentPage < totalPages && !isLoading ? () => onPageChange(currentPage + 1) : null,
          ),
          // زر الصفحة الأخيرة
          IconButton(
            icon: const Icon(Icons.last_page_rounded),
            iconSize: 18,
            tooltip: 'الصفحة الأخيرة',
            onPressed: currentPage < totalPages && !isLoading ? () => onPageChange(totalPages) : null,
          ),
        ],
      ),
    );
  }
}
