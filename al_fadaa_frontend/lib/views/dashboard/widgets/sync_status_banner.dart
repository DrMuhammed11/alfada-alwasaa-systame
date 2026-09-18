import 'package:flutter/material.dart';
import '../../../../core/offline/offline_sync_engine.dart';
import '../../../../core/theme/app_theme.dart';
import 'sync_queue_dialog.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineSyncEngine(),
      builder: (context, _) {
        final engine = OfflineSyncEngine();
        final isOffline = engine.isOffline;
        final isSyncing = engine.isSyncing;
        final pending = engine.pendingCount;

        if (!isOffline && !isSyncing && pending == 0) {
          return const SizedBox.shrink();
        }

        Color bgColor;
        Color borderColor;
        Color textColor;
        Widget leadingIcon;
        String title;
        String subtitle;

        if (isSyncing) {
          bgColor = AppTheme.accent.withAlpha(20);
          borderColor = AppTheme.accent.withAlpha(80);
          textColor = AppTheme.accent;
          leadingIcon = const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.accent),
          );
          title = 'جاري مزامنة الإجراءات مع الخادم السحابي...';
          subtitle = 'يتم رفع العمليات المنفذة محلياً وجلب أحدث البيانات بالترتيب الزمني.';
        } else if (isOffline) {
          bgColor = AppTheme.amber.withAlpha(20);
          borderColor = AppTheme.amber.withAlpha(80);
          textColor = AppTheme.amber;
          leadingIcon = const Icon(Icons.cloud_off_rounded, color: AppTheme.amber, size: 20);
          title = engine.isManualOffline
              ? 'وضع العمل دون اتصال (تم التفعيل يدوياً)'
              : 'أنت تعمل الآن في وضع عدم الاتصال (Offline Mode)';
          subtitle = pending > 0
              ? 'لديك ($pending) إجراء محفوظ محلياً بأمان، وسيتم رفعه تلقائياً فور التقاط الشبكة.'
              : 'يمكنك قراءة وتوجيه المعاملات واعتماد الردود؛ كافة الإجراءات تُحفظ محلياً.';
        } else {
          // أونلاين ولكن يوجد عناصر معلقة تنتظر المزامنة
          bgColor = AppTheme.emerald.withAlpha(20);
          borderColor = AppTheme.emerald.withAlpha(80);
          textColor = AppTheme.emerald;
          leadingIcon = const Icon(Icons.cloud_queue_rounded, color: AppTheme.emerald, size: 20);
          title = 'تم استعادة الاتصال بالشبكة';
          subtitle = 'يوجد ($pending) إجراء معلق جاهز للمزامنة الفورية مع الخادم.';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
          ),
          child: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (pending > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: textColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pending معلق',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: textColor.withAlpha(220)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (pending > 0)
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SyncQueueDialog(),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 15),
                  label: const Text('طابور العمليات', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isSyncing ? null : () => engine.syncPendingMutations(),
                icon: const Icon(Icons.sync_rounded, size: 15),
                label: Text(
                  isSyncing ? 'جاري المزامنة' : 'مزامنة الآن',
                  style: const TextStyle(fontSize: 11.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
