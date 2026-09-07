import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';

class MasterListItemTile extends StatelessWidget {
  final Correspondence item;
  final bool isSelected;
  final VoidCallback onTap;

  const MasterListItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(item.status);
    final totalMessages = 1 + item.childrenCount + item.repliesCount;
    final snippet = (item.body != null && item.body!.trim().isNotEmpty)
        ? item.body!.trim().replaceAll('\n', ' ')
        : (item.content != null && item.content!.trim().isNotEmpty
            ? item.content!.trim().replaceAll('\n', ' ')
            : 'مراسلة واردة عبر البريد الإلكتروني');

    final senderDisplayName = (item.senderName != null && item.senderName!.trim().isNotEmpty)
        ? item.senderName!.trim()
        : (item.senderEmail != null && item.senderEmail!.trim().isNotEmpty
            ? item.senderEmail!.trim()
            : (item.department?.name ?? 'جهة خارجية'));

    final initial = senderDisplayName.isNotEmpty ? senderDisplayName[0] : 'U';

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? AppTheme.accent : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أفاتار الشخص مثل واتساب
            CircleAvatar(
              radius: 19,
              backgroundColor: isSelected
                  ? AppTheme.accent
                  : const Color(0xFF0F172A).withAlpha(18),
              child: Text(
                initial,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // البيانات: اسم الشخص أولاً، ثم العنوان والمقتطف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السطر 1: اسم الشخص + التوقيت
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          senderDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // السطر 2: العنوان (الموضوع)
                  Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // السطر 3: مقتطف المحادثة + شارة الحالة + عدد الرسائل
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snippet,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalMessages > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withAlpha(18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalMessages',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withAlpha(40)),
                        ),
                        child: Text(
                          ApiConstants.getStatusLabel(item.status),
                          style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
