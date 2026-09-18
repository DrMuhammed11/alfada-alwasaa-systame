import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_formatter.dart';
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
      final Color eventColor = (msg['eventColor'] as Color?) ?? AppTheme.textMuted;
      final String title = msg['title'] as String;
      final String? subtitle = msg['subtitle'] as String?;
      final String? description = msg['description'] as String?;
      final DateTime date = msg['date'] as DateTime;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description.trim(),
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.secondary, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppDateFormatter.formatListDate(date),
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDraft
            ? AppTheme.amber.withAlpha(12)
            : (isClient ? Colors.white : AppTheme.backgroundLight),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDraft
              ? AppTheme.amber.withAlpha(50)
              : AppTheme.borderLight,
          width: isClient ? 1.2 : 1.0,
        ),
        boxShadow: isClient
            ? [
                BoxShadow(
                  color: AppTheme.accent.withAlpha(8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDraft
                  ? AppTheme.amber.withAlpha(20)
                  : (isClient ? AppTheme.accent.withAlpha(15) : AppTheme.backgroundLight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDraft ? AppTheme.amber.withAlpha(50) : AppTheme.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                // أفاتار المرسل
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isClient
                      ? AppTheme.accent.withAlpha(25)
                      : (isDraft ? AppTheme.amber.withAlpha(25) : AppTheme.emerald.withAlpha(25)),
                  child: Icon(
                    isClient ? Icons.person_rounded : (isDraft ? Icons.edit_note_rounded : Icons.business_rounded),
                    size: 16,
                    color: isClient
                        ? AppTheme.accent
                        : (isDraft ? AppTheme.amber : AppTheme.emerald),
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
                                color: AppTheme.primary,
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
                                  color: AppTheme.purple.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.purple.withAlpha(80)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.history_rounded, size: 11, color: AppTheme.purple),
                                    const SizedBox(width: 3),
                                    Text(
                                      'v${replyItem.version}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.purple),
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
                                color: AppTheme.amber.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.amber.withAlpha(60)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.supervised_user_circle_outlined, size: 11, color: AppTheme.amber),
                                  SizedBox(width: 3),
                                  Text(
                                    'وكالة',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.amber),
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
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // التوقيت الفعلي
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        AppDateFormatter.formatFullDateTime(date),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // زر النسخ
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textOnLight),
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

          // نص الرسالة الفعلي المنظم مع كشف رسائل إعادة التوجيه
          _ForwardedEmailBlock(body: body),

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
}

/// مكوّن منظم لعرض نص الرسالة وكشف وتنسيق ترويسات البريد الموجه (Forwarded Emails)
class _ForwardedEmailBlock extends StatefulWidget {
  final String body;

  const _ForwardedEmailBlock({required this.body});

  @override
  State<_ForwardedEmailBlock> createState() => _ForwardedEmailBlockState();
}

class _ForwardedEmailBlockState extends State<_ForwardedEmailBlock> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseBody(widget.body);

    if (!parsed.hasForwarded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: SelectableText(
          widget.body,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.textDark,
            height: 1.65,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نص تمهيدي يسبق الرسالة الموجهة إن وُجد
          if (parsed.introText != null && parsed.introText!.trim().isNotEmpty) ...[
            SelectableText(
              parsed.introText!.trim(),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textDark,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // بطاقة الرسالة الموجهة المرتبة
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس بطاقة التوجيه
                InkWell(
                  onTap: () => setState(() => _showDetails = !_showDetails),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.forward_to_inbox_rounded, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رسالة بريد إلكتروني موجهة: ${parsed.subject ?? "بدون موضوع"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (parsed.from != null && parsed.from!.isNotEmpty)
                                Text(
                                  'من: ${parsed.from}${parsed.date != null ? " | ${parsed.date}" : ""}',
                                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _showDetails ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.accent, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                      ],
                    ),
                  ),
                ),

                // تفاصيل الترويسة الفنية القابلة للطي
                if (_showDetails) ...[
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.backgroundLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parsed.from != null) _buildDetailRow('المرسل (From):', parsed.from!),
                        if (parsed.to != null) _buildDetailRow('إلى (To):', parsed.to!),
                        if (parsed.date != null) _buildDetailRow('التاريخ (Date):', parsed.date!),
                        if (parsed.subject != null) _buildDetailRow('الموضوع (Subject):', parsed.subject!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // نص الرسالة الأصلي المنظف
          SelectableText(
            parsed.cleanBody,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textDark,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  _ParsedMessage _parseBody(String text) {
    final lines = text.split('\n');
    int markerIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('Forwarded message') ||
          line.contains('الرسالة الموجهة') ||
          line.contains('الرسالة المعاد توجيهها') ||
          line.contains('Begin forwarded message:')) {
        markerIndex = i;
        break;
      }
    }

    if (markerIndex == -1) {
      return _ParsedMessage(hasForwarded: false, cleanBody: text);
    }

    final intro = lines.sublist(0, markerIndex).join('\n').trim();
    String? from;
    String? date;
    String? subject;
    String? to;
    int endHeaderIndex = markerIndex + 1;

    for (int i = markerIndex + 1; i < lines.length && i < markerIndex + 14; i++) {
      final line = lines[i].trim();
      if (line.isEmpty && (from != null || date != null || subject != null)) {
        endHeaderIndex = i + 1;
        break;
      }

      final lower = line.toLowerCase();
      if (lower.startsWith('from:') || line.startsWith('من:')) {
        from = line.replaceFirst(RegExp(r'^(from:|من:)\s*', caseSensitive: false), '').trim();
        endHeaderIndex = i + 1;
      } else if (lower.startsWith('date:') || line.startsWith('التاريخ:')) {
        date = line.replaceFirst(RegExp(r'^(date:|التاريخ:)\s*', caseSensitive: false), '').trim();
        endHeaderIndex = i + 1;
      } else if (lower.startsWith('subject:') || line.startsWith('الموضوع:')) {
        subject = line.replaceFirst(RegExp(r'^(subject:|الموضوع:)\s*', caseSensitive: false), '').trim();
        endHeaderIndex = i + 1;
      } else if (lower.startsWith('to:') || line.startsWith('إلى:')) {
        to = line.replaceFirst(RegExp(r'^(to:|إلى:)\s*', caseSensitive: false), '').trim();
        endHeaderIndex = i + 1;
      }
    }

    final clean = lines.sublist(endHeaderIndex).join('\n').trim();

    return _ParsedMessage(
      hasForwarded: true,
      introText: intro.isNotEmpty ? intro : null,
      from: from,
      date: date,
      subject: subject,
      to: to,
      cleanBody: clean.isNotEmpty ? clean : text,
    );
  }
}

class _ParsedMessage {
  final bool hasForwarded;
  final String? introText;
  final String? from;
  final String? date;
  final String? subject;
  final String? to;
  final String cleanBody;

  _ParsedMessage({
    required this.hasForwarded,
    this.introText,
    this.from,
    this.date,
    this.subject,
    this.to,
    required this.cleanBody,
  });
}

