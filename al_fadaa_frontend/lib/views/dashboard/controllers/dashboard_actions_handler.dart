import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../models/correspondence_model.dart';
import '../../auth/login_screen.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/work_dossier_dialog.dart';

/// معالج العمليات التنفيذية ونوافذ التأكيد في لوحة التحكم
class DashboardActionsHandler {
  final BuildContext context;
  final DashboardViewModel vm;

  DashboardActionsHandler(this.context, this.vm);

  Future<void> handleStartReview(String id) async {
    final res = await ApiService().updateCorrespondenceStatus(id, 'UNDER_REVIEW');
    if (res['success'] == true) {
      await vm.fetchCorrespondences(selectId: id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الطلب كمعاملة رسمية بنجاح'), backgroundColor: Color(0xFF10B981)),
        );
      }
    }
  }

  void handleShowDossier() {
    if (vm.selectedItem == null) return;
    showDialog(
      context: context,
      builder: (_) => WorkDossierDialog(
        item: vm.selectedItem!,
        onDownloadAttachment: handleDownloadAttachment,
      ),
    );
  }

  Future<void> handleClose(String id) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إغلاق المعاملة وحفظها'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل تم إنجاز العمل وتريد إغلاق هذه المعاملة؟'),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'سبب الإغلاق (اختياري)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الإغلاق'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService().closeCorrespondence(id);
      if (res['success'] == true) {
        await vm.fetchCorrespondences();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إغلاق المعاملة بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
      }
    }
  }

  Future<void> handleArchive(String id) async {
    final res = await ApiService().archiveCorrespondence(id);
    if (res['success'] == true) {
      await vm.fetchCorrespondences();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت أرشفة المعاملة بنجاح'), backgroundColor: Color(0xFF10B981)),
        );
      }
    }
  }

  Future<void> addReply() async {
    if (vm.selectedItem == null) return;
    final text = vm.quickReplyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص المسودة قبل الحفظ'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    vm.isSendingReply = true;
    vm.updateUI();
    try {
      final res = await ApiService().createReply(vm.selectedItem!.id, text);
      if (res['success'] == true) {
        final replyId = res['data']?['id'];
        if (replyId != null && vm.pickedFile?.bytes != null) {
          await ApiService().uploadReplyAttachment(replyId, vm.pickedFile!.bytes!, vm.pickedFile!.name);
        }
        vm.quickReplyController.clear();
        vm.pickedFile = null;
        await vm.selectItem(vm.selectedItem!);
        await vm.silentRefresh();
      }
    } finally {
      vm.isSendingReply = false;
      vm.updateUI();
    }
  }

  Future<void> saveEditedReply() async {
    if (vm.editingReplyId == null) return;
    final text = vm.quickReplyController.text.trim();
    if (text.length < 5) return;

    vm.isSendingReply = true;
    vm.updateUI();
    try {
      final res = await ApiService().updateReply(vm.editingReplyId!, text);
      if (res['success'] == true) {
        if (vm.pickedFile?.bytes != null) {
          await ApiService().uploadReplyAttachment(vm.editingReplyId!, vm.pickedFile!.bytes!, vm.pickedFile!.name);
        }
        vm.cancelEditingReply();
        if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
        await vm.silentRefresh();
      }
    } finally {
      vm.isSendingReply = false;
      vm.updateUI();
    }
  }

  Future<void> submitReply(String replyId) async {
    final res = await ApiService().submitReply(replyId);
    if (res['success'] == true) {
      if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
      await vm.silentRefresh();
    }
  }

  Future<void> approveReply(String replyId) async {
    final res = await ApiService().approveReply(replyId);
    if (res['success'] == true) {
      if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
      await vm.silentRefresh();
    }
  }

  Future<void> rejectReply(String replyId) async {
    final noteCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض مسودة الرد وإعادتها للتعديل'),
        content: TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظات التعديل (إلزامي)', border: OutlineInputBorder()), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              if (noteCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );

    if (confirm == true && noteCtrl.text.trim().isNotEmpty) {
      final res = await ApiService().rejectReply(replyId, noteCtrl.text.trim());
      if (res['success'] == true) {
        if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
        await vm.silentRefresh();
      }
    }
  }

  Future<void> sendReply(String replyId) async {
    final res = await ApiService().sendReply(replyId);
    if (res['success'] == true) {
      if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
      await vm.silentRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرد رسميًا إلى بريد العميل بنجاح'), backgroundColor: Color(0xFF059669)),
        );
      }
    }
  }

  Future<void> sendDirectReply() async {
    if (vm.selectedItem == null) return;
    final text = vm.quickReplyController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الرد قبل الإرسال'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    vm.isSendingReply = true;
    vm.updateUI();
    try {
      final res = await ApiService().sendDirectReply(vm.selectedItem!.id, text);
      if (res['success'] == true) {
        vm.quickReplyController.clear();
        vm.pickedFile = null;
        await vm.selectItem(vm.selectedItem!);
        await vm.silentRefresh();
      }
    } finally {
      vm.isSendingReply = false;
      vm.updateUI();
    }
  }

  Future<void> handleDownloadAttachment(AttachmentItem att) async {
    vm.downloadingAttachmentIds.add(att.id);
    vm.updateUI();
    try {
      await ApiService().downloadAttachment(att.id, att.fileName);
    } finally {
      vm.downloadingAttachmentIds.remove(att.id);
      vm.updateUI();
    }
  }

  Future<void> logout() async {
    await ApiService().clearToken();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(EnterprisePageRoute(page: const LoginScreen()));
    }
  }
}
