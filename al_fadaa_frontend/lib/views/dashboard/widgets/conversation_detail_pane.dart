import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';
import 'activity_boxes.dart';
import 'conversation_header.dart';
import 'conversation_timeline.dart';

class ConversationDetailPane extends StatelessWidget {
  final Correspondence? selectedItem;
  final bool isLoadingDetail;
  final String currentUserId;
  final String role;
  final bool showExtraDetails;
  final bool isEditing;
  final bool isSendingReply;
  final TextEditingController quickReplyController;
  final ScrollController detailScrollController;
  final PlatformFile? pickedFile;
  final Set<String> downloadingAttachmentIds;
  final VoidCallback onToggleExtraDetails;
  final Function(String) onStartReview;
  final Function(String) onClose;
  final Function(String) onArchive;
  final VoidCallback onRefresh;
  final VoidCallback onShowDossier;
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

  const ConversationDetailPane({
    super.key,
    required this.selectedItem,
    required this.isLoadingDetail,
    required this.currentUserId,
    required this.role,
    required this.showExtraDetails,
    required this.isEditing,
    required this.isSendingReply,
    required this.quickReplyController,
    required this.detailScrollController,
    required this.pickedFile,
    required this.downloadingAttachmentIds,
    required this.onToggleExtraDetails,
    required this.onStartReview,
    required this.onClose,
    required this.onArchive,
    required this.onRefresh,
    required this.onShowDossier,
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
    if (selectedItem == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drafts_outlined, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'اختر محادثة من القائمة لاستعراضها والرد عليها',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final item = selectedItem!;
    final priorityColor = AppTheme.getPriorityColor(item.priority);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // شريط المحادثة العلوي بنمط واتساب
          ConversationHeader(
            item: item,
            role: role,
            currentUserId: currentUserId,
            showExtraDetails: showExtraDetails,
            onToggleExtraDetails: onToggleExtraDetails,
            onStartReview: onStartReview,
            onClose: onClose,
            onArchive: onArchive,
            onRefresh: onRefresh,
            onShowDossier: onShowDossier,
          ),

          // المحتوى التفصيلي: المحادثة مباشرة تأخذ كامل المساحة!
          Expanded(
            child: isLoadingDetail
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Scrollbar(
                    controller: detailScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView(
                      controller: detailScrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // بطاقة تفاصيل المعاملة (تظهر فقط عند الضغط على زر المعلومات حتى لا تضيق على المحادثات)
                        if (showExtraDetails) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 14),
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
                                    MetaBox(label: 'المرسل / الاسم', value: item.senderName ?? 'غير محدد', icon: Icons.person_outline_rounded),
                                    const SizedBox(width: 10),
                                    MetaBox(label: 'البريد الإلكتروني', value: item.senderEmail ?? '-', icon: Icons.alternate_email_rounded),
                                    const SizedBox(width: 10),
                                    MetaBox(label: 'القسم المعني', value: item.department?.name ?? 'الإدارة العامة', icon: Icons.domain_rounded),
                                    const SizedBox(width: 10),
                                    MetaBox(label: 'الأولوية', value: ApiConstants.getPriorityLabel(item.priority), icon: Icons.flag_rounded, color: priorityColor),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),

                                // شريط تتبع المراحل
                                ProgressTracker(currentStatus: item.status),
                              ],
                            ),
                          ),
                        ],

                        // سلسلة المحادثة المتصلة الكاملة فوراً!
                        ConversationTimeline(
                          item: item,
                          currentUserId: currentUserId,
                          role: role,
                          isEditing: isEditing,
                          isSendingReply: isSendingReply,
                          quickReplyController: quickReplyController,
                          pickedFile: pickedFile,
                          downloadingAttachmentIds: downloadingAttachmentIds,
                          onEditDraft: onEditDraft,
                          onSubmitReply: onSubmitReply,
                          onApproveReply: onApproveReply,
                          onRejectReply: onRejectReply,
                          onSendReply: onSendReply,
                          onDownloadAttachment: onDownloadAttachment,
                          onCancelEdit: onCancelEdit,
                          onSaveEdit: onSaveEdit,
                          onSendDirect: onSendDirect,
                          onSaveDraft: onSaveDraft,
                          onPickFile: onPickFile,
                          onRemoveFile: onRemoveFile,
                        ),
                        const SizedBox(height: 16),

                        // سجل الإحالات الإدارية
                        if (item.referrals.isNotEmpty) ...[
                          ReferralsBox(referrals: item.referrals),
                          const SizedBox(height: 14),
                        ],

                        // سجل المهام والتكليفات
                        if (item.tasks.isNotEmpty) ...[
                          TasksBox(tasks: item.tasks),
                          const SizedBox(height: 14),
                        ],

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
