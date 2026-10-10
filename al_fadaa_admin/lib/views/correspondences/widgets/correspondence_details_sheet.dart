import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/correspondence_model.dart';
import '../corr_style.dart';

/// ورقة التفاصيل الكاملة للمحادثة (بيانات المرسل والإحالات والتكليفات والمرفقات)
class CorrespondenceDetailsSheet extends StatelessWidget {
  final CorrDetail detail;

  const CorrespondenceDetailsSheet({super.key, required this.detail});

  static void show(BuildContext context, CorrDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AdminTheme.radiusXl)),
      ),
      builder: (ctx) => CorrespondenceDetailsSheet(detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'تفاصيل المحادثة',
                    style: TextStyle(
                        fontSize: AdminTheme.fontTitle,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: AdminTheme.iconMd),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              d.subject,
              style: const TextStyle(
                fontSize: AdminTheme.fontLg,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: AdminTheme.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CorrStyle.typeColor(d.type).withAlpha(24),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Text(
                    d.type,
                    style: TextStyle(
                      fontSize: AdminTheme.fontSm,
                      fontWeight: FontWeight.bold,
                      color: CorrStyle.typeColor(d.type),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CorrStyle.statusColor(d.status).withAlpha(24),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Text(
                    d.status,
                    style: TextStyle(
                      fontSize: AdminTheme.fontSm,
                      fontWeight: FontWeight.bold,
                      color: CorrStyle.statusColor(d.status),
                    ),
                  ),
                ),
                Text(
                  'الرقم: ${d.refNumber}',
                  style: const TextStyle(
                      fontSize: AdminTheme.fontSm,
                      color: AdminTheme.textMuted,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoGrid(d),
            const SizedBox(height: 16),
            // الإحالات
            _sheetSection(
              title: 'الإحالات (${d.referrals.length})',
              icon: Icons.alt_route_rounded,
              child: d.referrals.isEmpty
                  ? _emptyHint('لا توجد إحالات')
                  : Column(
                      children: d.referrals
                          .map((r) => _sheetRow(
                                icon: Icons.alt_route_rounded,
                                color: AdminTheme.accent,
                                title:
                                    '${r.toName} — ${referralStatusLabel(r.status)}',
                                subtitle: r.note ?? '—',
                                extra: r.fromName.isNotEmpty
                                    ? 'أحالها: ${r.fromName}'
                                    : null,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            // التكليفات
            _sheetSection(
              title: 'التكليفات (${d.tasks.length})',
              icon: Icons.assignment_rounded,
              child: d.tasks.isEmpty
                  ? _emptyHint('لا توجد تكليفات')
                  : Column(
                      children: d.tasks
                          .map((t) => _sheetRow(
                                icon: Icons.assignment_rounded,
                                color: AdminTheme.purple,
                                title: t.title,
                                subtitle:
                                    '${taskStatusLabel(t.status)} — المنفذ: ${t.assignedToName}',
                                extra: t.assignedByName.isNotEmpty
                                    ? 'كلّفه: ${t.assignedByName}'
                                    : null,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            // الردود الداخلية
            _sheetSection(
              title: 'الردود الداخلية (${d.replies.length})',
              icon: Icons.reply_rounded,
              child: d.replies.isEmpty
                  ? _emptyHint('لا توجد ردود داخلية')
                  : Column(
                      children: d.replies
                          .map((r) => _sheetRow(
                                icon: Icons.reply_rounded,
                                color: AdminTheme.emerald,
                                title:
                                    '${r.authorName} — ${replyStatusLabel(r.status)}',
                                subtitle: r.body,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            // المرفقات
            _sheetSection(
              title: 'المرفقات (${d.attachments.length})',
              icon: Icons.attach_file_rounded,
              child: d.attachments.isEmpty
                  ? _emptyHint('لا توجد مرفقات')
                  : Column(
                      children: d.attachments
                          .map((a) => _sheetRow(
                                icon: Icons.insert_drive_file_rounded,
                                color: AdminTheme.amber,
                                title: a.fileName,
                                subtitle:
                                    '${a.mimeType} — ${AppFormatters.fileSize(a.size)}',
                              ))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AdminTheme.iconSm, color: AdminTheme.accent),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AdminTheme.fontMd)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoGrid(CorrDetail d) {
    final pairs = <(String, String)>[
      ('الاسم', d.senderName ?? '-'),
      ('البريد الإلكتروني', d.senderEmail ?? '-'),
      ('الهاتف', d.senderPhone ?? '-'),
      ('سجّلها', d.createdByName ?? '-'),
      (
        'تاريخ الاستلام',
        d.receivedAt != null ? AppFormatters.dateTime(d.receivedAt!) : '-'
      ),
      (
        'تاريخ الإرسال',
        d.sentAt != null ? AppFormatters.dateTime(d.sentAt!) : '-'
      ),
    ];
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: pairs
          .map((p) => SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$1,
                      style: const TextStyle(
                        fontSize: AdminTheme.fontXs,
                        color: AdminTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      p.$2,
                      style: const TextStyle(
                        fontSize: AdminTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _sheetRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AdminTheme.iconSm, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: AdminTheme.fontBase,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                SelectableText(
                  subtitle,
                  style: const TextStyle(
                      fontSize: AdminTheme.fontBase,
                      color: AdminTheme.textMuted,
                      height: 1.5),
                ),
                if (extra != null && extra.isNotEmpty)
                  Text(extra,
                      style: const TextStyle(
                          fontSize: AdminTheme.fontSm,
                          color: AdminTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Row(
      children: [
        const Icon(Icons.inbox_outlined, size: AdminTheme.iconXs, color: AdminTheme.textLight),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted)),
      ],
    );
  }
}
