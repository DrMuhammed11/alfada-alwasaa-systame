import 'package:flutter/material.dart';
import '../../../models/correspondence_model.dart';
import '../../../models/user_model.dart';
import '../controllers/dashboard_actions_handler.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'conversation_detail_pane.dart';

/// شاشة تفاصيل المحادثة على الموبايل — full screen route
class MobileDetailScreen extends StatelessWidget {
  final Correspondence item;
  final DashboardViewModel vm;
  final User user;
  final DashboardActionsHandler actions;
  final ScrollController detailScrollController;

  const MobileDetailScreen({
    super.key,
    required this.item,
    required this.vm,
    required this.user,
    required this.actions,
    required this.detailScrollController,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role.toUpperCase();

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final currentItem = vm.selectedItem ?? item;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentItem.refNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  currentItem.subject,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          body: ConversationDetailPane(
            selectedItem: currentItem,
            isLoadingDetail: vm.isLoadingDetail,
            currentUserId: user.id,
            role: role,
            showExtraDetails: vm.showExtraDetails,
            isEditing: vm.editingReplyId != null,
            isSendingReply: vm.isSendingReply,
            quickReplyController: vm.quickReplyController,
            detailScrollController: detailScrollController,
            pickedFile: vm.pickedFile,
            downloadingAttachmentIds: vm.downloadingAttachmentIds,
            onToggleExtraDetails: vm.toggleExtraDetails,
            onStartReview: actions.handleStartReview,
            onClose: actions.handleClose,
            onArchive: actions.handleArchive,
            onRefresh: () => vm.fetchCorrespondences(selectId: currentItem.id),
            onShowDossier: actions.handleShowDossier,
            onEditDraft: vm.startEditingReply,
            onSubmitReply: actions.submitReply,
            onApproveReply: actions.approveReply,
            onRejectReply: actions.rejectReply,
            onSendReply: actions.sendReply,
            onDownloadAttachment: actions.handleDownloadAttachment,
            onCancelEdit: vm.cancelEditingReply,
            onSaveEdit: actions.saveEditedReply,
            onSendDirect: actions.sendDirectReply,
            onSaveDraft: actions.addReply,
            onPickFile: vm.pickFile,
            onRemoveFile: vm.removeFile,
          ),
        );
      },
    );
  }
}
