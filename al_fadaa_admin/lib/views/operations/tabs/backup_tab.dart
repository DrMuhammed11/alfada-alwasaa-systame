import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../operations_helpers.dart';

class BackupTab extends StatefulWidget {
  const BackupTab({super.key});
  @override
  State<BackupTab> createState() => BackupTabState();
}

class BackupTabState extends State<BackupTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _status;
  bool _isLoading = true, _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final s = await AdminApiService().getBackupStatus();
    if (!mounted) return;
    setState(() {
      _status = s;
      _isLoading = false;
      _hasError = s == null;
    });
  }

  String _sizeOf(num bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل حالة النسخ الاحتياطي...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل حالة النسخ الاحتياطي',
        onRetry: _load,
      );
    }
    final files = ((_status?['files'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final enabled = _status?['enabled'] == true;
    final offsite = _status?['offsiteConfigured'] == true;
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // شارات حالة النسخ الاحتياطي — StatusBadge من app_utils
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            StatusBadge(
              text: enabled
                  ? 'النسخ المجدول مفعّل'
                  : 'النسخ المجدول معطّل (BACKUP_ENABLED=false)',
              color: enabled ? AdminTheme.emerald : AdminTheme.crimson,
            ),
            StatusBadge(
              text: offsite
                  ? 'رفع خارجي مضبوط'
                  : 'لا رفع خارجي — القرص المحلي فاني!',
              color: offsite ? AdminTheme.emerald : AdminTheme.crimson,
            ),
            StatusBadge(
              text: 'الاحتفاظ: ${_status?['retentionDays'] ?? 7} يوم',
              color: AdminTheme.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          const EmptyStateWidget(
            message: 'لا توجد نسخ محفوظة محليًا بعد',
            icon: Icons.backup_rounded,
          )
        else
          ...files.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: Border.all(color: AdminTheme.border),
                  boxShadow: AdminTheme.cardShadow,
                ),
                child: Row(children: [
                  const Icon(Icons.archive_rounded, size: 16, color: AdminTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f['name'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AdminTheme.fontBase,
                        color: AdminTheme.borderDark,
                      ),
                    ),
                  ),
                  Text(
                    _sizeOf((f['sizeBytes'] as num?) ?? 0),
                    style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    opDateFormat.format(DateTime.parse(f['modifiedAt']).toLocal()),
                    style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
                  ),
                ]),
              )),
      ],
        ),
    );
  }
}

/// نافذة تحرير مسار الاعتماد: اختيار الأدوار بالتسلسل عبر رقائق مع
