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
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 32, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              const Text(
                'اختر مراسلة لاستعراض تفاصيلها والرد عليها',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك إدارة سلسلة المحادثة، مراجعة واعتماد مسودات الردود، تكليف القطاعات، ومتابعة سجل التدقيق الموثق.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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

          // المحتوى التفصيلي: متوازن ومريح للقراءة دون تشتت أو اتساع مفرط
          Expanded(
            child: isLoadingDetail
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Scrollbar(
                    controller: detailScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: ListView(
                          controller: detailScrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              ),
          ),
        ],
      ),
    );
  }
}
