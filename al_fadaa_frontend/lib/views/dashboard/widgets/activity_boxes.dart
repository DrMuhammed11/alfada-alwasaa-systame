import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color ?? const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                  Text(
                    value,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A)),
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
                      color: index == 0 ? Colors.transparent : (isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Container(
                    width: isCurrent ? 20 : 14,
                    height: isCurrent ? 20 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      border: isCurrent ? Border.all(color: AppTheme.primary, width: 2) : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: index == stages.length - 1 ? Colors.transparent : (index < currentIndex ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppTheme.primary : (isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 17, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'سجل الإحالات والتوجيهات (${referrals.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...referrals.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إلى: ${r.toDepartment?.name ?? r.toUser?.fullName ?? "القسم المعني"} — التوجيه: ${r.actionType}${r.notes != null ? " (${r.notes})" : ""}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _formatDate(r.createdAt),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, size: 17, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                'المهام والتكليفات الصادرة (${tasks.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tasks.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 15, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('المكلف: ${t.assignedTo?.fullName ?? "-"} · الحالة: ${t.status}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
