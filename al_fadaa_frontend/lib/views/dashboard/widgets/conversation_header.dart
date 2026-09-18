import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../models/correspondence_model.dart';
import '../../referrals/referral_dialog.dart';
import '../../tasks/create_task_dialog.dart';
import '../../tasks/complete_task_dialog.dart';
import 'correspondence_lineage_dialog.dart';

class ConversationHeader extends StatelessWidget {
  final Correspondence item;
  final String role;
  final String? currentUserId;
  final bool showExtraDetails;
  final VoidCallback onToggleExtraDetails;
  final Function(String) onStartReview;
  final Function(String) onClose;
  final Function(String) onArchive;
  final VoidCallback onRefresh;
  final VoidCallback onShowDossier;

  const ConversationHeader({
    super.key,
    required this.item,
    required this.role,
    this.currentUserId,
    required this.showExtraDetails,
    required this.onToggleExtraDetails,
    required this.onStartReview,
    required this.onClose,
    required this.onArchive,
    required this.onRefresh,
    required this.onShowDossier,
  });

  @override
  Widget build(BuildContext context) {
    final activeTasks = item.tasks.where((t) => t.status != 'DONE' && t.status != 'CANCELLED').toList();
    final hasActiveTask = activeTasks.isNotEmpty;
    final doneTasks = item.tasks.where((t) => t.status == 'DONE').toList();
    final hasDoneTask = doneTasks.isNotEmpty;

    // حالة المراسلة البصرية الذكية
    String statusLabel = ApiConstants.getStatusLabel(item.status);
    Color statusColor = AppTheme.getStatusColor(item.status);

    if (item.status != 'CLOSED' && item.status != 'ARCHIVED') {
      if (hasActiveTask) {
        final task = activeTasks.first;
        final assignee = task.assignedTo?.fullName ?? 'القطاع';
        statusLabel = 'قيد المعالجة لدى: $assignee';
        statusColor = AppTheme.amber;
      } else if (hasDoneTask) {
        statusLabel = 'تم إنجاز المهمة ✅ — جاهزة للرد';
        statusColor = AppTheme.emerald;
      }
    }

    final bool isExecutive = role == 'ADMIN' || role == 'GM' || role == 'DEPUTY_GM';
    final bool canAssign = isExecutive || role == 'DEPT_MANAGER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // أفاتار المرسل
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accent.withAlpha(20),
            child: Text(
              (item.senderName != null && item.senderName!.trim().isNotEmpty)
                  ? item.senderName!.trim()[0]
                  : 'U',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // اسم المرسل ورقم المعاملة وموضوعها
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.senderName ?? item.senderEmail ?? 'عميل خارجي',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // شارة الرقم المرجعي
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.serialNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رقم المعاملة')),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tag_rounded, size: 11, color: AppTheme.textMuted),
                            const SizedBox(width: 2),
                            Text(
                              item.serialNumber,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (item.channel == 'website') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.emerald.withAlpha(80)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language_rounded, size: 12, color: AppTheme.emerald),
                            SizedBox(width: 3),
                            Text(
                              'وارد من الموقع الإلكتروني',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.accent.withAlpha(60), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded, size: 11.5, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            AppDateFormatter.formatDetailedArrival(item.receivedAt ?? item.createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // شارة الحالة الهادئة والذكية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(16),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withAlpha(50), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveTask && item.status != 'CLOSED' && item.status != 'ARCHIVED') ...[
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // زر تفاصيل إضافية
          IconButton(
            icon: Icon(
              showExtraDetails ? Icons.info_rounded : Icons.info_outline_rounded,
              size: 20,
              color: showExtraDetails ? AppTheme.accent : AppTheme.textMuted,
            ),
            tooltip: showExtraDetails ? 'إخفاء تفاصيل المعاملة' : 'عرض تفاصيل المعاملة',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: onToggleExtraDetails,
          ),
          const SizedBox(width: 10),

          // --- 1. الإجراء الأساسي المباشر الموحد (Primary Action) ---
          if (canAssign && item.status == 'RECEIVED') ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => onStartReview(item.id),
              icon: const Icon(Icons.check_box_rounded, size: 15),
              label: const Text('قبول كمعاملة 📋', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ] else if (hasActiveTask && (canAssign || activeTasks.any((t) => t.assignedTo?.id == currentUserId))) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => CompleteTaskDialog(
                    task: activeTasks.first,
                    correspondenceId: item.id,
                  ),
                );
                if (res == true) onRefresh();
              },
              icon: const Icon(Icons.check_circle_rounded, size: 15),
              label: const Text('تم إنجاز المهمة ✅', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ] else if (canAssign && item.status != 'CLOSED' && item.status != 'ARCHIVED') ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.borderLight),
                backgroundColor: AppTheme.backgroundLight,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => CreateTaskDialog(correspondenceId: item.id),
                );
                if (res == true) onRefresh();
              },
              icon: const Icon(Icons.domain_add_rounded, size: 15, color: AppTheme.accent),
              label: Text(
                hasActiveTask ? 'تكليف قطاع آخر' : 'تكليف قطاع بالمهمة',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // --- زر شجرة المعاملة والترابط البياني ---
          IconButton(
            icon: const Icon(Icons.account_tree_rounded, size: 19, color: AppTheme.accent),
            tooltip: 'شجرة المعاملة والترابط البياني',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppTheme.borderLight),
              ),
              padding: const EdgeInsets.all(6),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CorrespondenceLineageDialog(
                  correspondenceId: item.id,
                  onSelectCorrespondence: (id) => onRefresh(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // --- 2. قائمة الخيارات والإجراءات التكميلية الموحدة (⋮) ---
          PopupMenuButton<String>(
            tooltip: 'خيارات وإجراءات المعاملة',
            offset: const Offset(0, 38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderLight),
                color: AppTheme.backgroundLight,
              ),
              child: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
            ),
            onSelected: (action) async {
              if (action == 'lineage') {
                showDialog(
                  context: context,
                  builder: (_) => CorrespondenceLineageDialog(
                    correspondenceId: item.id,
                    onSelectCorrespondence: (id) => onRefresh(),
                  ),
                );
              } else if (action == 'dossier') {
                onShowDossier();
              } else if (action == 'task') {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => CreateTaskDialog(correspondenceId: item.id),
                );
                if (res == true) onRefresh();
              } else if (action == 'referral') {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => ReferralDialog(correspondenceId: item.id),
                );
                if (res == true) onRefresh();
              } else if (action == 'close') {
                onClose(item.id);
              } else if (action == 'archive') {
                onArchive(item.id);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'lineage',
                child: Row(
                  children: [
                    Icon(Icons.account_tree_rounded, size: 16, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text('شجرة المعاملة والترابط البياني 🌳', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dossier',
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, size: 16, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text('كشف كامل للعمل 📄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (canAssign && item.status != 'CLOSED' && item.status != 'ARCHIVED')
                PopupMenuItem(
                  value: 'task',
                  child: Row(
                    children: [
                      const Icon(Icons.domain_add_rounded, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(hasActiveTask ? 'تكليف قطاع آخر' : 'تكليف قطاع بالمهمة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (canAssign && (item.status == 'UNDER_REVIEW' || item.status == 'REFERRED'))
                const PopupMenuItem(
                  value: 'referral',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 16, color: AppTheme.purple),
                      SizedBox(width: 8),
                      Text('إحالة وتوجيه إداري', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (isExecutive && item.status != 'CLOSED' && item.status != 'ARCHIVED')
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.crimson),
                      SizedBox(width: 8),
                      Text('إغلاق المعاملة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.crimson)),
                    ],
                  ),
                ),
              if ((isExecutive && item.status == 'CLOSED') || (canAssign && item.status == 'RECEIVED'))
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 16, color: AppTheme.textMuted),
                      SizedBox(width: 8),
                      Text('أرشفة / استبعاد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
