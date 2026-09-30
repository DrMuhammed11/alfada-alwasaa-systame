import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../models/correspondence_model.dart';
import 'email_composer.dart';
import 'message_card.dart';

class ConversationTimeline extends StatelessWidget {
  final Correspondence item;
  final String currentUserId;
  final String role;
  final bool isEditing;
  final bool isSendingReply;
  final TextEditingController quickReplyController;
  final PlatformFile? pickedFile;
  final Set<String> downloadingAttachmentIds;
  final Function(ReplyItem) onEditDraft;
  final Function(String) onSubmitReply;
  final Function(String) onApproveReply;
  final Function(String) onRejectReply;
  final Function(String) onSendReply;
  final Function(AttachmentItem) onDownloadAttachment;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onSendDirect;
  final VoidCallback onSaveDraft;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const ConversationTimeline({
    super.key,
    required this.item,
    required this.currentUserId,
    required this.role,
    required this.isEditing,
    required this.isSendingReply,
    required this.quickReplyController,
    required this.pickedFile,
    required this.downloadingAttachmentIds,
    required this.onEditDraft,
    required this.onSubmitReply,
    required this.onApproveReply,
    required this.onRejectReply,
    required this.onSendReply,
    required this.onDownloadAttachment,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onSendDirect,
    required this.onSaveDraft,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    // 1. تجميع كل أطراف المحادثة في تسلسل زمني موحد
    final List<Map<String, dynamic>> messages = [];

    // أ) الرسالة الأصلية الجذرية (من العميل أو منشئ الخطاب)
    messages.add({
      'id': item.id,
      'isRoot': true,
      'isClient': item.type == 'INCOMING',
      'type': item.type,
      'senderName': item.senderName ?? (item.type == 'INCOMING' ? 'عميل خارجي' : 'شركة الفضاء الواسع'),
      'senderEmail': item.senderEmail,
      'date': item.receivedAt ?? item.createdAt,
      'body': (item.body != null && item.body!.trim().isNotEmpty)
          ? item.body!
          : 'لا يوجد نص مرفق مع الرسالة',
      'badge': item.type == 'INCOMING' ? 'رسالة العميل (وارد أساسي)' : 'خطاب رسمي أصلي',
      'badgeColor': item.type == 'INCOMING' ? AppTheme.info : AppTheme.emerald,
      'attachments': item.attachments.where((a) => a.replyId == null).toList(),
    });

    // ب) الرسائل الفرعية التابعة لنفس الموضوع — واردة من العميل أو صادرة مرسلة له.
    // كل الأبناء تُعرض: الصادر المرسل له مصدر رد (sourceReplyId) هو نفسه
    // الرسالة التي وصلت العميل فروعده هنا يمنع اختفاء الردود المرسلة،
    // بينما يُستثنى سجل الرد الداخلي المطابق لاحقًا بمنع التكرار.
    for (final child in item.children) {
      _addCorrMessage(messages, child,
          rootSenderName: item.senderName,
          nonClientBadge: 'رد مرسل للعميل بالبريد');
    }

    // ب-2) أحفاد الجذر: ردود صادرة قديمة أُلصقت تحت ابن قبل توحيد التعليق
    // على الجذر في الخادم — بدون هذا المشي تختفي عن الخيط بعد جلسة جديدة
    for (final child in item.children) {
      for (final grand in child.children) {
        _addCorrMessage(messages, grand,
            rootSenderName: item.senderName,
            nonClientBadge: 'رد مرسل للعميل بالبريد');
      }
    }

    // ج) ردود ومسودات موظفي الشركة (مسودات داخلية أو معتمدة أو مرسلة)
    // الرد الذي وُلِّد منه بريد صادر فعلي (sourceReplyId) يظهر أصلاً كفقاعة
    // صادرة ضمن الأبناء فنُخفي نسخته هنا منعًا للتكرار
    final sentReplyIds = {
      for (final c in item.children) ...[
        if (c.sourceReplyId != null) c.sourceReplyId!,
        for (final g in c.children)
          if (g.sourceReplyId != null) g.sourceReplyId!,
      ],
    };
    for (final reply in item.replies) {
      if (sentReplyIds.contains(reply.id)) continue;

      final bool canView = role == 'ADMIN' ||
          role == 'GM' ||
          role == 'DEPUTY_GM' ||
          role == 'DEPT_MANAGER' ||
          reply.author?.id == currentUserId ||
          reply.status == 'APPROVED' ||
          reply.status == 'SENT';

      if (canView) {
        String badge = 'رد رسمي صادر';
        Color badgeColor = AppTheme.emerald;

        if (reply.status == 'DRAFT') {
          badge = 'مسودة قيد الإعداد';
          badgeColor = AppTheme.amber;
        } else if (reply.status == 'SUBMITTED') {
          badge = 'مسودة بانتظار الاعتماد';
          badgeColor = AppTheme.accent;
        } else if (reply.status == 'REJECTED') {
          badge = 'مسودة مرفوضة (تحتاج تعديل)';
          badgeColor = AppTheme.crimson;
        } else if (reply.status == 'APPROVED') {
          badge = 'رد معتمد (جاهز للإرسال)';
          badgeColor = AppTheme.emerald;
        } else if (reply.status == 'SENT') {
          badge = 'رد مرسل رسميًا للعميل بالبريد';
          badgeColor = AppTheme.emerald;
        }

        messages.add({
          'id': reply.id,
          'isRoot': false,
          'isClient': false,
          'type': reply.status == 'SENT' ? 'SENT_REPLY' : 'DRAFT_REPLY',
          'senderName': reply.author?.fullName ?? 'فريق شركة الفضاء الواسع',
          'senderEmail': reply.author?.email,
          'date': reply.createdAt,
          'body': reply.body,
          'replyStatus': reply.status,
          'isApproved': reply.isApproved,
          'replyItem': reply,
          'badge': badge,
          'badgeColor': badgeColor,
          'attachments': reply.attachments,
        });
      }
    }

    // د) أحداث تكليف القطاعات وإنجاز المهام
    for (final task in item.tasks) {
      // 1. حدث تكليف القطاع بالمهمة
      messages.add({
        'id': 'task_assign_${task.id}',
        'isRoot': false,
        'isClient': false,
        'isSystemEvent': true,
        'type': 'TASK_EVENT',
        'senderName': 'النظام',
        'date': task.createdAt,
        'title': '📋 تكليف قطاع بالمهمة: «${task.title}»',
        'subtitle': 'المسؤول المكلف: ${task.assignedTo?.fullName ?? 'القطاع'}${task.dueDate != null ? ' | الموعد المتوقع: ${task.dueDate!.year}/${task.dueDate!.month}/${task.dueDate!.day}' : ''}',
        'description': task.description,
        'eventColor': AppTheme.amber,
      });

      // 2. حدث إنجاز المهمة بواسطة القطاع
      if (task.status == 'DONE') {
        messages.add({
          'id': 'task_done_${task.id}',
          'isRoot': false,
          'isClient': false,
          'isSystemEvent': true,
          'type': 'TASK_EVENT',
          'senderName': 'النظام',
          'date': task.doneAt ?? task.createdAt.add(const Duration(minutes: 1)),
          'title': '✅ تم إنجاز المهمة بواسطة: «${task.assignedTo?.fullName ?? 'القطاع'}»',
          'subtitle': 'المعاملة عادت لتكون جاهزة للرد على العميل بالانتهاء وإغلاقها',
          'description': task.description,
          'eventColor': AppTheme.emerald,
        });
      }
    }

    // هـ) أحداث الإحالات الإدارية والتوجيه
    for (final ref in item.referrals) {
      messages.add({
        'id': 'referral_${ref.id}',
        'isRoot': false,
        'isClient': false,
        'isSystemEvent': true,
        'type': 'REFERRAL_EVENT',
        'senderName': 'النظام',
        'date': ref.createdAt,
        'title': '↪️ إحالة وتوجيه إلى: «${ref.toUser?.fullName ?? 'المسؤول المختص'}»',
        'subtitle': 'الحالة: ${ApiConstants.getReferralStatusLabel(ref.status)}${ref.dueDate != null ? ' | الموعد النهائي: ${ref.dueDate!.year}/${ref.dueDate!.month}/${ref.dueDate!.day}' : ''}',
        'description': ref.note,
        'eventColor': AppTheme.purple,
      });
    }

    // فرز الرسائل ترتيباً زمنياً تصاعدياً (من الأقدم إلى الأحدث مثل واتساب وبريد Gmail)
    messages.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // فواصل الأيام بنمط الدردشة — بين كل مجموعة رسائل من يوم مختلف
    final List<Widget> timelineWidgets = [];
    DateTime? lastDay;
    for (final msg in messages) {
      final msgDate = msg['date'] as DateTime;
      final day = DateTime(msgDate.year, msgDate.month, msgDate.day);
      if (lastDay == null || day != lastDay) {
        timelineWidgets.add(_DaySeparator(date: msgDate));
        lastDay = day;
      }
      timelineWidgets.add(MessageCard(
        msg: msg,
        item: item,
        currentUserId: currentUserId,
        role: role,
        downloadingAttachmentIds: downloadingAttachmentIds,
        onEditDraft: onEditDraft,
        onSubmitReply: onSubmitReply,
        onApproveReply: onApproveReply,
        onRejectReply: onRejectReply,
        onSendReply: onSendReply,
        onDownloadAttachment: onDownloadAttachment,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...timelineWidgets,

        const SizedBox(height: 14),

        // صندوق الرد المباشر
        EmailComposer(
          item: item,
          role: role,
          isEditing: isEditing,
          isSendingReply: isSendingReply,
          controller: quickReplyController,
          pickedFile: pickedFile,
          onCancelEdit: onCancelEdit,
          onSaveEdit: onSaveEdit,
          onSendDirect: onSendDirect,
          onSaveDraft: onSaveDraft,
          onPickFile: onPickFile,
          onRemoveFile: onRemoveFile,
        ),
      ],
    );
  }

  /// إضافة مراسلة (ابن أو حفيد) كرسالة دردشة موحدة — الواردة من العميل
  /// والصادرة المرسلة إليه على حد سواء، فكلاهما جزء من محادثة واحدة
  void _addCorrMessage(
    List<Map<String, dynamic>> messages,
    Correspondence corr, {
    String? rootSenderName,
    required String nonClientBadge,
  }) {
    final isClient = corr.type == 'INCOMING';
    messages.add({
      'id': corr.id,
      'isRoot': false,
      'isClient': isClient,
      'type': isClient ? 'CHILD_EMAIL' : corr.type,
      'senderName': (corr.senderName != null && corr.senderName!.trim().isNotEmpty)
          ? corr.senderName!
          : (isClient ? (rootSenderName ?? 'العميل (رد إضافي)') : 'شركة الفضاء الواسع'),
      'senderEmail': corr.senderEmail,
      'date': corr.receivedAt ?? corr.sentAt ?? corr.createdAt,
      'body': (corr.body != null && corr.body!.trim().isNotEmpty) ? corr.body! : 'لا يوجد نص',
      'badge': isClient ? 'رسالة إضافية من العميل' : nonClientBadge,
      'badgeColor': isClient ? AppTheme.info : AppTheme.emerald,
      'attachments': corr.attachments,
      'corrStatus': corr.status,
    });
  }
}

/// فاصل يوم داخل الخط الزمني — كبسولة مركزية بنمط واتساب
class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return AppDateFormatter.formatListDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _label(date),
          style: const TextStyle(
            fontSize: AppTheme.fontXs,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
