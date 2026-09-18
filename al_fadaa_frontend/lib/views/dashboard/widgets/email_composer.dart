import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';

class EmailComposer extends StatelessWidget {
  final Correspondence item;
  final String role;
  final bool isEditing;
  final bool isSendingReply;
  final TextEditingController controller;
  final PlatformFile? pickedFile;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onSendDirect;
  final VoidCallback onSaveDraft;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const EmailComposer({
    super.key,
    required this.item,
    required this.role,
    required this.isEditing,
    required this.isSendingReply,
    required this.controller,
    required this.pickedFile,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onSendDirect,
    required this.onSaveDraft,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final doneTasks = item.tasks.where((t) => t.status == 'DONE').toList();
    final hasDoneTask = doneTasks.isNotEmpty;
    final activeTasks = item.tasks.where((t) => t.status != 'DONE' && t.status != 'CANCELLED').toList();
    final hasActiveTask = activeTasks.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس صندوق الرد
          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.amber.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.amber, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'أنت الآن في وضع تعديل مسودة الرد — عدّل النص أدناه ثم اضغط «حفظ التعديلات»',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.amber),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: onCancelEdit,
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('إلغاء التعديل', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.reply_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  (role == 'GM' || role == 'DEPUTY_GM' || role == 'ADMIN')
                      ? 'الرد على المحادثة والعميل:'
                      : 'إعداد وصياغة مسودة رد على المحادثة:',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const Spacer(),
                if (item.senderEmail != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alternate_email_rounded, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          item.senderEmail!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),

          // تنبيه ذكي عند اكتمال مهمة القطاع
          if (hasDoneTask && !isEditing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.emerald.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم إنجاز المهمة بواسطة القطاع: «${doneTasks.first.title}»',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                        ),
                        if (doneTasks.first.description != null && doneTasks.first.description!.trim().isNotEmpty)
                          Text(
                            doneTasks.first.description!.trim(),
                            style: const TextStyle(fontSize: 11, color: AppTheme.emerald),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.emerald,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.emerald.withAlpha(80)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                    label: const Text('تعبئة نص الرد بالإنجاز', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final note = doneTasks.first.description ?? '';
                      controller.text = 'السلام عليكم ورحمة الله وبركاته،\n\n'
                          'نود إفادتكم بأنه تم فحص طلبكم وإنجازه بنجاح.\n'
                          '${note.isNotEmpty ? '$note\n\n' : ''}'
                          'شاكرين ومقدرين تواصلكم الدائم مع شركة الفضاء الواسع.';
                    },
                  ),
                ],
              ),
            ),
          ] else if (hasActiveTask && !isEditing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.amber.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المعاملة حالياً قيد المعالجة لدى: ${activeTasks.first.assignedTo?.fullName ?? 'القطاع'} — يمكنك إرسال استفسار أو مراسلة العميل في أي وقت.',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // شريط القوالب السريعة الذكية
          if (!isEditing) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('قوالب سريعة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.accent),
                      backgroundColor: AppTheme.accent.withAlpha(20),
                      side: BorderSide(color: AppTheme.accent.withAlpha(60), width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      label: const Text('رد مبدئي (تأكيد استلام)', style: TextStyle(fontSize: 10.5, color: AppTheme.accent, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        controller.text = 'السلام عليكم ورحمة الله وبركاته،\n\n'
                            'نود إفادتكم باستلام رسالتكم واستفساركم بنجاح (معاملة رقم: ${item.serialNumber}). '
                            'يجري حالياً مراجعة الطلب وتوجيهه للمختصين وسنوافيكم بالمستجدات قريباً.\n\n'
                            'شاكرين ومقدرين تواصلكم معنا،\nشركة الفضاء الواسع.';
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.help_outline_rounded, size: 14, color: AppTheme.amber),
                      backgroundColor: AppTheme.amber.withAlpha(20),
                      side: BorderSide(color: AppTheme.amber.withAlpha(60), width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      label: const Text('طلب نواقص / تفاصيل', style: TextStyle(fontSize: 10.5, color: AppTheme.amber, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        controller.text = 'السلام عليكم ورحمة الله وبركاته،\n\n'
                            'بخصوص طلبكم الوارد إلينا (معاملة رقم: ${item.serialNumber})، '
                            'نرجو التكرم بتزويدنا بالتفاصيل والمستندات الإضافية التالية لنتمكن من استكمال الإجراءات:\n'
                            '1- ...\n\n'
                            'شاكرين تعاونكم معنا،\nشركة الفضاء الواسع.';
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          // حقل كتابة الرد
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: isEditing
                  ? 'عدّل نص المسودة هنا...'
                  : ((role == 'GM' || role == 'DEPUTY_GM' || role == 'ADMIN')
                      ? 'اكتب نص الرد للعميل هنا... (يُرسل مباشرة للعميل عبر البريد بنمط واتساب)'
                      : 'اكتب نص المسودة المقترحة للرد على هذه المراسلة (10 أحرف على الأقل)...'),
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textOnLight),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          if (pickedFile != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.accent.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${pickedFile!.name} (${(pickedFile!.size / 1024).toStringAsFixed(1)} KB)',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.accent, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onRemoveFile,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.crimson),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // أزرار الإجراء
          Row(
            children: [
              if (isEditing) ...[
                // زر حفظ التعديلات
                ElevatedButton.icon(
                  onPressed: isSendingReply ? null : onSaveEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: isSendingReply
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 15),
                  label: const Text(
                    'حفظ تعديلات المسودة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onCancelEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                // زر إرفاق ملف أثناء التعديل
                OutlinedButton.icon(
                  onPressed: isSendingReply ? null : onPickFile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: const Text('إرفاق ملف', style: TextStyle(fontSize: 12)),
                ),
              ] else ...[
                // زر الإرسال المباشر الفوري للعميل (للإدارة العليا ومسؤول النظام)
                if (role == 'GM' || role == 'DEPUTY_GM' || role == 'ADMIN') ...[
                  ElevatedButton.icon(
                    onPressed: isSendingReply ? null : onSendDirect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: isSendingReply
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 15),
                    label: const Text(
                      'إرسال الرد للعميل الآن عبر البريد',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // زر حفظ كمسودة داخلية للاعتماد (لكافة المستخدمين)
                OutlinedButton.icon(
                  onPressed: isSendingReply ? null : onSaveDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 15),
                  label: const Text(
                    'حفظ كمسودة رد للاعتماد',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),

                // زر إرفاق ملف
                OutlinedButton.icon(
                  onPressed: isSendingReply ? null : onPickFile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: const Text('إرفاق ملف', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
