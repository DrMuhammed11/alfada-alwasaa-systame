import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/correspondence_model.dart';
import 'attachments_preview.dart';
import 'draft_action_bar.dart';
import 'reply_versions_dialog.dart';

class MessageCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final Correspondence item;
  final String currentUserId;
  final String role;
  final Set<String> downloadingAttachmentIds;
  final Function(ReplyItem) onEditDraft;
  final Function(String) onSubmitReply;
  final Function(String) onApproveReply;
  final Function(String) onRejectReply;
  final Function(String) onSendReply;
  final Function(AttachmentItem) onDownloadAttachment;

  const MessageCard({
    super.key,
    required this.msg,
    required this.item,
    required this.currentUserId,
    required this.role,
    required this.downloadingAttachmentIds,
    required this.onEditDraft,
    required this.onSubmitReply,
    required this.onApproveReply,
    required this.onRejectReply,
    required this.onSendReply,
    required this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    if (msg['isSystemEvent'] == true) {
      final Color eventColor = (msg['eventColor'] as Color?) ?? const Color(0xFF64748B);
      final String title = msg['title'] as String;
      final String? subtitle = msg['subtitle'] as String?;
      final String? description = msg['description'] as String?;
      final DateTime date = msg['date'] as DateTime;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: eventColor.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: eventColor.withAlpha(60)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              title.contains('✅')
                  ? Icons.check_circle_rounded
                  : (title.contains('↪️')
                      ? Icons.swap_horiz_rounded
                      : Icons.assignment_rounded),
              color: eventColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: eventColor),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description.trim(),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    final bool isClient = msg['isClient'] == true;
    final bool isDraft = msg['type'] == 'DRAFT_REPLY';
    final Color badgeColor = msg['badgeColor'] as Color;
    final String senderName = msg['senderName'] as String;
    final String? senderEmail = msg['senderEmail'] as String?;
    final String body = msg['body'] as String;
    final DateTime date = msg['date'] as DateTime;
    final ReplyItem? replyItem = msg['replyItem'] as ReplyItem?;
    final List<AttachmentItem> attachments =
        (msg['attachments'] as List<AttachmentItem>?) ?? [];

    final canApprove = role == 'GM' || role == 'DEPUTY_GM' || role == 'DEPT_MANAGER' || role == 'ADMIN';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDraft
            ? const Color(0xFFFFFBEB)
            : (isClient ? Colors.white : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDraft
              ? const Color(0xFFFDE68A)
              : (isClient ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
          width: isClient ? 1.2 : 1.0,
        ),
        boxShadow: isClient
            ? [
                BoxShadow(
                  color: const Color(0xFF0284C7).withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الرسالة (Sender Bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDraft
                  ? const Color(0xFFFEF3C7).withAlpha(60)
                  : (isClient ? const Color(0xFFF0F9FF) : const Color(0xFFF1F5F9)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDraft ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                // أفاتار المرسل
                CircleAvatar(
                  radius: 15,
                  backgroundColor: isClient
                      ? const Color(0xFF0284C7).withAlpha(25)
                      : (isDraft ? const Color(0xFFD97706).withAlpha(25) : const Color(0xFF059669).withAlpha(25)),
                  child: Icon(
                    isClient ? Icons.person_rounded : (isDraft ? Icons.edit_note_rounded : Icons.business_rounded),
                    size: 16,
                    color: isClient
                        ? const Color(0xFF0284C7)
                        : (isDraft ? const Color(0xFFD97706) : const Color(0xFF059669)),
                  ),
                ),
                const SizedBox(width: 10),

                // اسم المرسل والبريد والشارة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              senderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // شارة نوع الرسالة
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: badgeColor.withAlpha(60), width: 0.8),
                            ),
                            child: Text(
                              msg['badge'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          // شارة الإصدار إن وُجدت
                          if (replyItem != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => ReplyVersionsDialog(reply: replyItem),
                              ),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.history_rounded, size: 11, color: Color(0xFF4338CA)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'v${replyItem.version}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // شارة الوكالة إن كانت المعاملة قد اعتُمدت بتفويض
                          if (replyItem != null &&
                              replyItem.approvalSteps.any((s) => s.decidedBy != null && s.decidedBy?.role != s.requiredRole)) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.supervised_user_circle_outlined, size: 11, color: Color(0xFFD97706)),
                                  SizedBox(width: 3),
                                  Text(
                                    'وكالة',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (senderEmail != null && senderEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          senderEmail,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // التوقيت
                Text(
                  _formatDate(date),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 6),

                // زر النسخ
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                  tooltip: 'نسخ نص الرسالة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ نص الرسالة')),
                    );
                  },
                ),
              ],
            ),
          ),

          // نص الرسالة الفعلي
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                height: 1.6,
              ),
            ),
          ),

          // قائمة المرفقات
          if (attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: AttachmentsPreview(
                attachments: attachments,
                downloadingAttachmentIds: downloadingAttachmentIds,
                onDownloadAttachment: onDownloadAttachment,
              ),
            ),

          // شريط أزرار اتخاذ القرار الخاصة بالمسودات
          if (replyItem != null)
            DraftActionBar(
              replyItem: replyItem,
              currentUserId: currentUserId,
              role: role,
              canApprove: canApprove,
              onEditDraft: onEditDraft,
              onSubmitReply: onSubmitReply,
              onApproveReply: onApproveReply,
              onRejectReply: onRejectReply,
              onSendReply: onSendReply,
            ),
        ],
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
