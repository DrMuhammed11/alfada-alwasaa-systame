import 'package:flutter/material.dart';
import '../../../models/reply_model.dart';

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
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            'حالة المسودة: ${getReplyStatusText(replyItem.status)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const Spacer(),

          // للمؤلف: تعديل المسودة
          if (isAuthor && (replyItem.status == 'DRAFT' || replyItem.status == 'REJECTED'))
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD97706)),
              onPressed: () => onEditDraft(replyItem),
              icon: const Icon(Icons.edit_note_rounded, size: 15),
              label: const Text('تعديل المسودة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),

          // للمؤلف: رفع للاعتماد
          if (isAuthor && replyItem.status == 'DRAFT')
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
              onPressed: () => onSubmitReply(replyItem.id),
              icon: const Icon(Icons.upload_rounded, size: 15),
              label: const Text('رفع للاعتماد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),

          // للمشرفين والمعتمدين: اعتماد الرد أو رفضه (سواء كان مرفوعاً أو مسودة)
          if ((replyItem.status == 'SUBMITTED' || replyItem.status == 'DRAFT') && canApprove) ...[
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF059669)),
              onPressed: () => onApproveReply(replyItem.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
              label: const Text('اعتماد الرد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
              onPressed: () => onRejectReply(replyItem.id),
              icon: const Icon(Icons.cancel_outlined, size: 15),
              label: const Text('رفض الرد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => onSendReply(replyItem.id),
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('إرسال نهائي للعميل بالبريد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
