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
    // أحداث النظام (تكليف/إنجاز/إحالة) — كبسولة مركزية بنمط دردشة واتساب
    if (msg['isSystemEvent'] == true) {
      final Color eventColor = (msg['eventColor'] as Color?) ?? AppTheme.textMuted;
      final String title = msg['title'] as String;
      final String? subtitle = msg['subtitle'] as String?;
      final String? description = msg['description'] as String?;
      final DateTime date = msg['date'] as DateTime;

      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: eventColor.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: eventColor.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      title.contains('✅')
                          ? Icons.check_circle_rounded
                          : (title.contains('↪️')
                              ? Icons.swap_horiz_rounded
                              : Icons.assignment_rounded),
                      color: eventColor,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.bold,
                          color: eventColor),
                    ),
                  ),
                ],
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                ),
              ],
              if (description != null && description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description.trim(),
                  style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.secondary, height: 1.4),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                AppDateFormatter.formatListDate(date),
                style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary),
              ),
            ],
          ),
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
    final String? corrStatus = msg['corrStatus'] as String?;

    // الصادرة المرسلة فعلاً للعميل تأخذ علامة الإرسال المزدوجة
    final bool sentToClient = !isClient && !isDraft &&
        (corrStatus == 'SENT' ||
            replyItem?.status == 'SENT' ||
            replyItem?.isApproved == true);

    final canApprove = role == 'GM' || role == 'DEPUTY_GM' || role == 'DEPT_MANAGER' || role == 'ADMIN';

    // اتجاه الفقاعة: الواردة من العميل عند بداية السطر (يمين في RTL)
    // وردود الشركة ومسوداتها الداخلية عند نهايته (يسار في RTL)
    final Color bubbleColor = isClient
        ? Colors.white
        : (isDraft ? AppTheme.surfaceWarning : AppTheme.surfaceInfo);
    final Color bubbleBorder = isClient
        ? AppTheme.borderLight
        : (isDraft ? AppTheme.borderWarning : AppTheme.info.withAlpha(60));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment:
            isClient ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.radiusLg),
              topRight: const Radius.circular(AppTheme.radiusLg),
              bottomLeft: Radius.circular(isClient ? AppTheme.radiusXs : AppTheme.radiusLg),
              bottomRight: Radius.circular(isClient ? AppTheme.radiusLg : AppTheme.radiusXs),
            ),
            border: Border.all(color: bubbleBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // رأس الفقاعة: المرسل + شارات الحالة
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Icon(
                      isClient ? Icons.south_west_rounded : Icons.north_east_rounded,
                      size: 13,
                      color: isDraft ? AppTheme.amber : badgeColor,
                    ),
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.bold,
                        color: isDraft ? AppTheme.amber : badgeColor,
                      ),
                    ),
                    if (senderEmail != null && senderEmail.isNotEmpty && isClient)
                      Text(
                        senderEmail,
                        style: const TextStyle(
                            fontSize: AppTheme.fontXs, color: AppTheme.textTertiary),
                      ),
                    // شارة نوع الرسالة (للمسودات والردود المرسلة فقط — الواردة واضحة بذاتها)
                    if (isDraft || replyItem != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                          border: Border.all(color: badgeColor.withAlpha(60), width: 0.8),
                        ),
                        child: Text(
                          msg['badge'] as String,
                          style: TextStyle(
                            fontSize: AppTheme.fontXs,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    // شارة الإصدار إن وُجدت
                    if (replyItem != null)
                      InkWell(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => ReplyVersionsDialog(reply: replyItem),
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.purple.withAlpha(20),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                            border: Border.all(color: AppTheme.purple.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_rounded, size: 11, color: AppTheme.purple),
                              const SizedBox(width: 3),
                              Text(
                                'v${replyItem.version}',
                                style: const TextStyle(
                                    fontSize: AppTheme.fontXs,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.purple),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // شارة الوكالة إن كانت المعاملة قد اعتُمدت بتفويض
                    if (replyItem != null &&
                        replyItem.approvalSteps
                            .any((s) => s.decidedBy != null && s.decidedBy?.role != s.requiredRole))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                          border: Border.all(color: AppTheme.amber.withAlpha(60)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.supervised_user_circle_outlined, size: 11, color: AppTheme.amber),
                            SizedBox(width: 3),
                            Text(
                              'وكالة',
                              style: TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.amber),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // نص الرسالة الفعلي المنظم مع كشف رسائل إعادة التوجيه
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _ForwardedEmailBlock(body: body),
              ),

              // قائمة المرفقات
              if (attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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

              // تذييل الفقاعة: الوقت + علامة الإرسال + نسخ النص
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 8, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppDateFormatter.formatFullDateTime(date),
                      style: const TextStyle(
                        fontSize: AppTheme.fontXs,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (sentToClient) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: AppTheme.info),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 14, color: AppTheme.textTertiary),
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
            ],
          ),
        ),
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
            fontSize: AppTheme.fontMd,
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
                fontSize: AppTheme.fontMd,
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
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس بطاقة التوجيه
                InkWell(
                  onTap: () => setState(() => _showDetails = !_showDetails),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                                  fontSize: AppTheme.fontSm,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (parsed.from != null && parsed.from!.isNotEmpty)
                                Text(
                                  'من: ${parsed.from}${parsed.date != null ? " | ${parsed.date}" : ""}',
                                  style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _showDetails ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                          style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.accent, fontWeight: FontWeight.w600),
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
              fontSize: AppTheme.fontMd,
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
              style: const TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textDark),
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

