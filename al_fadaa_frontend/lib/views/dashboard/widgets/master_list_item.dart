import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_formatter.dart';
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
    final displayDate = item.children.isNotEmpty
        ? (item.children.first.receivedAt ?? item.children.first.createdAt)
        : (item.receivedAt ?? item.createdAt);
    final snippet = (item.children.isNotEmpty && item.children.first.body != null && item.children.first.body!.trim().isNotEmpty)
        ? item.children.first.body!.trim().replaceAll('\n', ' ')
        : ((item.body != null && item.body!.trim().isNotEmpty)
            ? item.body!.trim().replaceAll('\n', ' ')
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withAlpha(20) : Colors.transparent,
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
            // أفاتار الشخص
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? AppTheme.accent
                  : AppTheme.primary.withAlpha(16),
              child: Text(
                initial,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // البيانات: اسم الشخص أولاً، ثم العنوان والمقتطف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السطر 1: اسم الشخص بارزاً + رقم المعاملة + التوقيت
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                senderDisplayName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: AppTheme.borderLight, width: 0.8),
                              ),
                              child: Text(
                                item.serialNumber,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            if (item.channel == 'website') ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.emerald.withAlpha(20),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: AppTheme.emerald.withAlpha(80), width: 0.8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.language_rounded, size: 10, color: AppTheme.emerald),
                                    SizedBox(width: 2.5),
                                    Text(
                                      'الموقع',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (item.isOverdue) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.crimson.withAlpha(20),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: AppTheme.crimson.withAlpha(80), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 9, color: AppTheme.crimson),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.overdueDays > 0 ? 'متأخر بـ${item.overdueDays} يوم' : 'متأخر',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.crimson,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppDateFormatter.formatListDate(displayDate),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // السطر 2: العنوان (الموضوع) بخط متوسط ومقروء
                  Text(
                    item.subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppTheme.textDark : AppTheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // السطر 3: مقتطف المحادثة + شارة الحالة الهادئة + عدد الرسائل
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snippet,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.25,
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
                            color: AppTheme.accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalMessages',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(14),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withAlpha(45), width: 0.8),
                        ),
                        child: Text(
                          ApiConstants.getStatusLabel(item.status),
                          style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
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
}
