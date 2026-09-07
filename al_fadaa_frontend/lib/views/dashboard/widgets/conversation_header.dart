import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';
import '../../referrals/referral_dialog.dart';
import '../../tasks/create_task_dialog.dart';
import '../../tasks/complete_task_dialog.dart';

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
        statusColor = const Color(0xFFD97706);
      } else if (hasDoneTask) {
        statusLabel = 'تم إنجاز المهمة ✅ — جاهزة للرد';
        statusColor = const Color(0xFF059669);
      }
    }

    final bool isExecutive = role == 'ADMIN' || role == 'GM' || role == 'DEPUTY_GM';
    final bool canAssign = isExecutive || role == 'DEPT_MANAGER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // أفاتار المرسل
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accent.withAlpha(25),
            child: Text(
              (item.senderName != null && item.senderName!.trim().isNotEmpty)
                  ? item.senderName!.trim()[0]
                  : 'U',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // اسم الشخص وعنوان المراسلة والرقم المرجعي الموحد للطلبية
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // شارة الرقم المرجعي الموحد للطلبية
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.serialNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رقم الطلبية')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withAlpha(12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF0F172A).withAlpha(35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tag_rounded, size: 11, color: Color(0xFF334155)),
                            const SizedBox(width: 2),
                            Text(
                              item.serialNumber,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // شارة الحالة الذكية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveTask && item.status != 'CLOSED' && item.status != 'ARCHIVED') ...[
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
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
          const SizedBox(width: 6),

          // زر تفاصيل إضافية
          IconButton(
            icon: Icon(
              showExtraDetails ? Icons.info_rounded : Icons.info_outline_rounded,
              size: 20,
              color: showExtraDetails ? AppTheme.accent : const Color(0xFF64748B),
            ),
            tooltip: showExtraDetails ? 'إخفاء تفاصيل المعاملة' : 'عرض تفاصيل المعاملة',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggleExtraDetails,
          ),
          const SizedBox(width: 10),

          // --- أزرار سير العمل المرحلية ---

          // 1. زر قبول كمعاملة (عندما تكون الرسالة واردة جديدة RECEIVED)
          if (canAssign && item.status == 'RECEIVED') ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => onStartReview(item.id),
              icon: const Icon(Icons.check_box_rounded, size: 15),
              label: const Text('قبول كمعاملة 📋', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            // زر أرشفة / استبعاد للرسائل الواردة غير المقبولة
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => onArchive(item.id),
              icon: const Icon(Icons.archive_outlined, size: 15),
              label: const Text('أرشفة / استبعاد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],

          // 2. زر إنجاز المهمة (يظهر فوراً عند وجود تكليف نشط للمعنيين أو للإدارة)
          if (hasActiveTask && (canAssign || activeTasks.any((t) => t.assignedTo?.id == currentUserId))) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => CompleteTaskDialog(task: activeTasks.first),
                );
                if (res == true) onRefresh();
              },
              icon: const Icon(Icons.check_circle_rounded, size: 15),
              label: const Text('تم إنجاز المهمة ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],

          // 3. زر تكليف قطاع بالمهمة
          if (canAssign && item.status != 'CLOSED' && item.status != 'ARCHIVED') ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasActiveTask ? const Color(0xFF475569) : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => CreateTaskDialog(correspondenceId: item.id),
                );
                if (res == true) onRefresh();
              },
              icon: const Icon(Icons.domain_add_rounded, size: 15),
              label: Text(
                hasActiveTask ? 'تكليف قطاع آخر' : 'تكليف قطاع بالمهمة',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // 4. زر إحالة (اختياري للإدارات)
          if (canAssign &&
              (item.status == 'UNDER_REVIEW' || item.status == 'REFERRED')) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFFDDD6FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () async {
                final res = await showDialog<bool>(
                  context: context,
                  builder: (_) => ReferralDialog(correspondenceId: item.id),
                );
                if (res == true) onRefresh();
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 15),
              label: const Text('إحالة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],

          // 5. زر إغلاق المعاملة
          if (isExecutive && item.status != 'CLOSED' && item.status != 'ARCHIVED') ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => onClose(item.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
              label: const Text('إغلاق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],

          // 6. زر كشف كامل للعمل (متاح دائماً ويبرز عند إغلاق المعاملة)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: (item.status == 'CLOSED' || item.status == 'ARCHIVED')
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              foregroundColor: (item.status == 'CLOSED' || item.status == 'ARCHIVED')
                  ? Colors.white
                  : const Color(0xFF0F172A),
              side: BorderSide(
                color: (item.status == 'CLOSED' || item.status == 'ARCHIVED')
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFCBD5E1),
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: onShowDossier,
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 15),
            label: const Text('كشف كامل للعمل 📄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),

          // 7. زر الأرشفة للمغلقة
          if (isExecutive && item.status == 'CLOSED')
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => onArchive(item.id),
              icon: const Icon(Icons.archive_outlined, size: 15),
              label: const Text('أرشفة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
