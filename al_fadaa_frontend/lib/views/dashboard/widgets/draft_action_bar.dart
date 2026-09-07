import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/reply_model.dart';
import 'reply_versions_dialog.dart';

class DraftActionBar extends StatelessWidget {
  final ReplyItem replyItem;
  final String currentUserId;
  final String role;
  final bool canApprove;
  final Function(ReplyItem) onEditDraft;
  final Function(String) onSubmitReply;
  final Function(String) onApproveReply;
  final Function(String) onRejectReply;
  final Function(String) onSendReply;

  const DraftActionBar({
    super.key,
    required this.replyItem,
    required this.currentUserId,
    required this.role,
    required this.canApprove,
    required this.onEditDraft,
    required this.onSubmitReply,
    required this.onApproveReply,
    required this.onRejectReply,
    required this.onSendReply,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuthor = replyItem.author?.id == currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط الحالة ومسار الاعتماد وتاريخ الإصدارات
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'حالة المسودة: ${getReplyStatusText(replyItem.status)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 10),

              // زر سجل الإصدارات
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
                      const Icon(Icons.history_rounded, size: 12, color: Color(0xFF4338CA)),
                      const SizedBox(width: 4),
                      Text(
                        'إصدار v${replyItem.version}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // خطوات مسار الاعتماد المتتابع إن وُجدت
              if (replyItem.approvalSteps.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: replyItem.approvalSteps.map((step) {
                    Color stepColor = const Color(0xFF94A3B8);
                    IconData stepIcon = Icons.radio_button_unchecked;
                    if (step.status == 'APPROVED') {
                      stepColor = const Color(0xFF059669);
                      stepIcon = Icons.check_circle_rounded;
                    } else if (step.status == 'REJECTED') {
                      stepColor = const Color(0xFFDC2626);
                      stepIcon = Icons.cancel_rounded;
                    } else if (step.status == 'PENDING') {
                      stepColor = const Color(0xFF2563EB);
                      stepIcon = Icons.hourglass_top_rounded;
                    }

                    final bool isDelegated = step.decidedBy != null && step.decidedBy?.role != step.requiredRole;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: stepColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: stepColor.withAlpha(80), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stepIcon, size: 10, color: stepColor),
                          const SizedBox(width: 3),
                          Text(
                            '${ApiConstants.getRoleName(step.requiredRole)}${isDelegated ? ' (وكالة)' : ''}',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: stepColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          const Divider(height: 12, thickness: 0.8, color: Color(0xFFE2E8F0)),

          // أزرار اتخاذ القرار والإجراءات
          Row(
            children: [
              const Spacer(),

              // للمؤلف: تعديل المسودة (إجراء ثانوي)
              if (isAuthor && (replyItem.status == 'DRAFT' || replyItem.status == 'REJECTED')) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => onEditDraft(replyItem),
                  icon: const Icon(Icons.edit_note_rounded, size: 15, color: Color(0xFF475569)),
                  label: const Text('تعديل المسودة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // للمؤلف: رفع للاعتماد (إجراء رئيسي)
              if (isAuthor && replyItem.status == 'DRAFT') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => onSubmitReply(replyItem.id),
                  icon: const Icon(Icons.upload_rounded, size: 15),
                  label: const Text('رفع للاعتماد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // للمشرفين والمعتمدين: اعتماد الرد أو رفضه
              if ((replyItem.status == 'SUBMITTED' || replyItem.status == 'DRAFT') && canApprove) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => onRejectReply(replyItem.id),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('رفض الرد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => onApproveReply(replyItem.id),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                  label: const Text('اعتماد الرد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // للإدارة العليا ومسؤول النظام: إرسال نهائي للعميل بالبريد
              if ((replyItem.status == 'APPROVED' || replyItem.status == 'SUBMITTED' || replyItem.status == 'DRAFT') &&
                  (role == 'GM' || role == 'DEPUTY_GM' || role == 'ADMIN'))
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => onSendReply(replyItem.id),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('إرسال نهائي للعميل بالبريد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
    ],
  ),
);
  }

  static String getReplyStatusText(String status) {
    switch (status) {
      case 'DRAFT':
        return 'مسودة قيد الإعداد';
      case 'SUBMITTED':
        return 'مرفوعة للاعتماد';
      case 'APPROVED':
        return 'معتمدة جاهزة للإرسال';
      case 'REJECTED':
        return 'مرفوضة وتحتاج تعديل';
      case 'SENT':
        return 'مرسلة رسميًا للعميل';
      default:
        return status;
    }
  }
}
