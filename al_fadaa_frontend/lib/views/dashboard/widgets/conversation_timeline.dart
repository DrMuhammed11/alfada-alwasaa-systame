import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
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
          : (item.content ?? 'لا يوجد نص مرفق مع الرسالة'),
      'badge': item.type == 'INCOMING' ? 'رسالة العميل (وارد أساسي)' : 'خطاب رسمي أصلي',
      'badgeColor': item.type == 'INCOMING' ? const Color(0xFF0284C7) : const Color(0xFF10B981),
      'attachments': item.attachments,
    });

    // ب) الرسائل الفرعية التابعة لنفس الموضوع (رسائل بريد تابعة واردة من العميل)
    for (final child in item.children) {
      messages.add({
        'id': child.id,
        'isRoot': false,
        'isClient': true,
        'type': 'CHILD_EMAIL',
        'senderName': item.senderName ?? 'العميل (رد إضافي)',
        'senderEmail': item.senderEmail,
        'date': child.createdAt,
        'body': (child.body != null && child.body!.trim().isNotEmpty) ? child.body! : (child.content ?? 'لا يوجد نص'),
        'badge': 'رسالة إضافية من العميل',
        'badgeColor': const Color(0xFF0284C7),
        'attachments': <AttachmentItem>[],
      });
    }

    // ج) ردود ومسودات موظفي الشركة (مسودات داخلية أو معتمدة أو مرسلة)
    for (final reply in item.replies) {
      final bool canView = role == 'ADMIN' ||
          role == 'GM' ||
          role == 'DEPUTY_GM' ||
          role == 'DEPT_MANAGER' ||
          reply.author?.id == currentUserId ||
          reply.status == 'APPROVED' ||
          reply.status == 'SENT';

      if (canView) {
        String badge = 'رد رسمي صادر';
        Color badgeColor = const Color(0xFF059669);

        if (reply.status == 'DRAFT') {
          badge = 'مسودة قيد الإعداد';
          badgeColor = const Color(0xFFD97706);
        } else if (reply.status == 'SUBMITTED') {
          badge = 'مسودة بانتظار الاعتماد';
          badgeColor = const Color(0xFF2563EB);
        } else if (reply.status == 'REJECTED') {
          badge = 'مسودة مرفوضة (تحتاج تعديل)';
          badgeColor = const Color(0xFFDC2626);
        } else if (reply.status == 'APPROVED') {
          badge = 'رد معتمد (جاهز للإرسال)';
          badgeColor = const Color(0xFF059669);
        } else if (reply.status == 'SENT') {
          badge = 'رد مرسل رسميًا للعميل بالبريد';
          badgeColor = const Color(0xFF059669);
        }

        messages.add({
          'id': reply.id,
          'isRoot': false,
          'isClient': false,
          'type': reply.status == 'SENT' ? 'SENT_REPLY' : 'DRAFT_REPLY',
          'senderName': reply.author?.fullName ?? 'فريق شركة الفضاء الواسع',
          'senderEmail': reply.author?.email,
          'date': reply.createdAt,
          'body': reply.content,
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
        'eventColor': const Color(0xFFD97706),
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
          'eventColor': const Color(0xFF059669),
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
        'eventColor': const Color(0xFF7C3AED),
      });
    }

    // فرز الرسائل ترتيباً زمنياً تصاعدياً (من الأقدم إلى الأحدث مثل واتساب وبريد Gmail)
    messages.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // بطاقات الرسائل المتتالية
        ...messages.map((msg) => MessageCard(
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
            )),

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
}
