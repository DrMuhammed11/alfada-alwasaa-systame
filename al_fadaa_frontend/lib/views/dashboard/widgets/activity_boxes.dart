import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../models/referral_model.dart';
import '../../../models/task_model.dart';

class MetaBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const MetaBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color ?? AppTheme.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textOnLight)),
                  Text(
                    value,
                    style: TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: color ?? AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressTracker extends StatelessWidget {
  final String currentStatus;

  const ProgressTracker({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = ['RECEIVED', 'REFERRED', 'IN_PROGRESS', 'PENDING_APPROVAL', 'APPROVED', 'CLOSED'];
    final labels = ['استلام', 'إحالة', 'تنفيذ', 'تدقيق', 'اعتماد', 'إغلاق'];

    int currentIndex = 0;
    if (currentStatus == 'REFERRED') currentIndex = 1;
    if (currentStatus == 'IN_PROGRESS') currentIndex = 2;
    if (currentStatus == 'PENDING_APPROVAL') currentIndex = 3;
    if (currentStatus == 'APPROVED' || currentStatus == 'SENT') currentIndex = 4;
    if (currentStatus == 'CLOSED' || currentStatus == 'ARCHIVED') currentIndex = 5;

    return Row(
      children: List.generate(stages.length, (index) {
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: index == 0 ? Colors.transparent : (isDone ? AppTheme.emerald : AppTheme.borderLight),
                    ),
                  ),
                  Container(
                    width: isCurrent ? 20 : 14,
                    height: isCurrent ? 20 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.emerald : AppTheme.borderLight,
                      border: isCurrent ? Border.all(color: AppTheme.primary, width: 2) : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: index == stages.length - 1 ? Colors.transparent : (index < currentIndex ? AppTheme.emerald : AppTheme.borderLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: AppTheme.fontXs,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppTheme.primary : (isDone ? AppTheme.primary : AppTheme.textOnLight),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ReferralsBox extends StatelessWidget {
  final List<ReferralItem> referrals;

  const ReferralsBox({super.key, required this.referrals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 17, color: AppTheme.purple),
              const SizedBox(width: 8),
              Text(
                'سجل الإحالات والتوجيهات (${referrals.length})',
                style: const TextStyle(fontSize: AppTheme.fontBase, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...referrals.map((r) {
            final statusColor = AppTheme.getReferralStatusColor(r.status);
            final statusLabel = ApiConstants.getReferralStatusLabel(r.status);
            final toName = r.toUser?.fullName ?? 'المسؤول المختص';
            final fromName = r.fromUser?.fullName;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: AppTheme.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'إلى: $toName',
                              style: const TextStyle(fontSize: AppTheme.fontSm, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                            if (fromName != null && fromName.isNotEmpty)
                              Text(
                                '(من: $fromName)',
                                style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                border: Border.all(color: statusColor.withAlpha(50)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(color: statusColor, fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (r.note != null && r.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'التوجيه: ${r.note!.trim()}',
                            style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.secondary),
                          ),
                        ],
                        if (r.dueDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'الموعد النهائي: ${AppDateFormatter.formatListDate(r.dueDate!)}',
                            style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.amber, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    AppDateFormatter.formatListDate(r.createdAt),
                    style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TasksBox extends StatelessWidget {
  final List<TaskItem> tasks;

  const TasksBox({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, size: 17, color: AppTheme.amber),
              const SizedBox(width: 8),
              Text(
                'المهام والتكليفات الصادرة (${tasks.length})',
                style: const TextStyle(fontSize: AppTheme.fontBase, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.isDone ? AppTheme.backgroundLight : t.slaBgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: t.isDone ? AppTheme.borderLight : t.slaColor.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(t.slaIcon, size: 16, color: t.slaColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.title,
                            style: const TextStyle(fontSize: AppTheme.fontSm, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.slaBgColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                            border: Border.all(color: t.slaColor.withAlpha(80)),
                          ),
                          child: Text(
                            t.slaLabel,
                            style: TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: t.slaColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            'المكلف: ${t.assignedTo?.fullName ?? "-"} · الحالة: ${t.isDone ? "منجزة" : (t.status == "IN_PROGRESS" ? "قيد التنفيذ" : "معلقة")}',
                            style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
