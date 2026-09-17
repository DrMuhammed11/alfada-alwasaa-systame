import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/offline/offline_storage_service.dart';
import '../../../core/offline/offline_sync_engine.dart';
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
    final cur = vm.selectedItem;
    final res = await OfflineSyncEngine().executeAction(
      actionType: 'UPDATE_STATUS',
      endpoint: '${ApiConstants.correspondences}/$id/status',
      httpMethod: 'PATCH',
      payload: {'status': 'UNDER_REVIEW'},
      entityId: id,
      entitySummary: 'بدء مراجعة المعاملة ${cur?.serialNumber ?? ""}',
      onlineAction: () => ApiService().updateCorrespondenceStatus(id, 'UNDER_REVIEW'),
      onOptimisticUpdate: () async {
        if (cur != null && cur.id == id) {
          final updated = cur.copyWith(status: 'UNDER_REVIEW');
          vm.selectedItem = updated;
          await OfflineStorageService().updateCachedCorrespondence(updated);
          vm.updateUI();
        }
      },
    );

    if (res['success'] == true) {
      if (res['offline'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم بدء المراجعة محلياً (وضع عدم الاتصال) — بانتظار المزامنة'),
              backgroundColor: Color(0xFFD97706),
            ),
          );
        }
      } else {
        await vm.fetchCorrespondences(selectId: id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم قبول الطلب كمعاملة رسمية بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
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
      final cur = vm.selectedItem;
      final res = await OfflineSyncEngine().executeAction(
        actionType: 'CLOSE_CORRESPONDENCE',
        endpoint: '${ApiConstants.correspondences}/$id/close',
        httpMethod: 'POST',
        payload: {'reason': noteCtrl.text.trim()},
        entityId: id,
        entitySummary: 'إغلاق المعاملة ${cur?.serialNumber ?? ""}',
        onlineAction: () => ApiService().closeCorrespondence(id),
        onOptimisticUpdate: () async {
          if (cur != null && cur.id == id) {
            final updated = cur.copyWith(status: 'CLOSED', closedAt: DateTime.now());
            vm.selectedItem = updated;
            await OfflineStorageService().updateCachedCorrespondence(updated);
            vm.updateUI();
          }
        },
      );

      if (res['success'] == true) {
        if (res['offline'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إغلاق المعاملة محلياً (وضع عدم الاتصال) — بانتظار المزامنة'),
                backgroundColor: Color(0xFFD97706),
              ),
            );
          }
        } else {
          await vm.fetchCorrespondences();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إغلاق المعاملة بنجاح'), backgroundColor: Color(0xFF10B981)),
            );
          }
        }
      }
    }
  }

  Future<void> handleArchive(String id) async {
    final cur = vm.selectedItem;
    final res = await OfflineSyncEngine().executeAction(
      actionType: 'ARCHIVE_CORRESPONDENCE',
      endpoint: '${ApiConstants.correspondences}/$id/archive',
      httpMethod: 'POST',
      payload: {},
      entityId: id,
      entitySummary: 'أرشفة المعاملة ${cur?.serialNumber ?? ""}',
      onlineAction: () => ApiService().archiveCorrespondence(id),
      onOptimisticUpdate: () async {
        if (cur != null && cur.id == id) {
          final updated = cur.copyWith(status: 'ARCHIVED');
          vm.selectedItem = updated;
          await OfflineStorageService().updateCachedCorrespondence(updated);
          vm.updateUI();
        }
      },
    );

    if (res['success'] == true) {
      if (res['offline'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت أرشفة المعاملة محلياً (وضع عدم الاتصال) — بانتظار المزامنة'),
              backgroundColor: Color(0xFFD97706),
            ),
          );
        }
      } else {
        await vm.fetchCorrespondences();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت أرشفة المعاملة بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
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
    final cur = vm.selectedItem;
    final res = await OfflineSyncEngine().executeAction(
      actionType: 'APPROVE_REPLY',
      endpoint: '${ApiConstants.baseUrl}/replies/$replyId/approve',
      httpMethod: 'POST',
      payload: {},
      entityId: replyId,
      entitySummary: 'اعتماد الرد على معاملة ${cur?.serialNumber ?? ""}',
      onlineAction: () => ApiService().approveReply(replyId),
      onOptimisticUpdate: () async {
        if (cur != null) {
          final updatedReplies = cur.replies.map((r) {
            if (r.id == replyId) {
              return r.copyWith(status: 'APPROVED', isApproved: true);
            }
            return r;
          }).toList();
          final updatedCorr = cur.copyWith(replies: updatedReplies);
          vm.selectedItem = updatedCorr;
          await OfflineStorageService().updateCachedCorrespondence(updatedCorr);
          vm.updateUI();
        }
      },
    );

    if (res['success'] == true) {
      if (res['offline'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم اعتماد الرد محلياً (وضع عدم الاتصال) — بانتظار المزامنة'),
              backgroundColor: Color(0xFFD97706),
            ),
          );
        }
      } else {
        if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
        await vm.silentRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم اعتماد الرد بنجاح'), backgroundColor: Color(0xFF10B981)),
          );
        }
      }
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
      final note = noteCtrl.text.trim();
      final cur = vm.selectedItem;
      final res = await OfflineSyncEngine().executeAction(
        actionType: 'REJECT_REPLY',
        endpoint: '${ApiConstants.baseUrl}/replies/$replyId/reject',
        httpMethod: 'POST',
        payload: {'note': note},
        entityId: replyId,
        entitySummary: 'رفض الرد على معاملة ${cur?.serialNumber ?? ""}',
        onlineAction: () => ApiService().rejectReply(replyId, note),
        onOptimisticUpdate: () async {
          if (cur != null) {
            final updatedReplies = cur.replies.map((r) {
              if (r.id == replyId) {
                return r.copyWith(status: 'REJECTED', reviewNote: note);
              }
              return r;
            }).toList();
            final updatedCorr = cur.copyWith(replies: updatedReplies);
            vm.selectedItem = updatedCorr;
            await OfflineStorageService().updateCachedCorrespondence(updatedCorr);
            vm.updateUI();
          }
        },
      );

      if (res['success'] == true) {
        if (res['offline'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفض الرد محلياً (وضع عدم الاتصال) — بانتظار المزامنة'),
                backgroundColor: Color(0xFFD97706),
              ),
            );
          }
        } else {
          if (vm.selectedItem != null) await vm.selectItem(vm.selectedItem!);
          await vm.silentRefresh();
        }
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
