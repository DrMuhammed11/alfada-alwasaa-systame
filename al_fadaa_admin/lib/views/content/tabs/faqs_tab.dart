import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/responsive_dialog.dart';
import '../../../models/site_content_model.dart';
import '../content_components.dart';

// ═════════════════ تبويب الأسئلة الشائعة ═════════════════

class FaqsTab extends StatelessWidget {
  const FaqsTab();

  @override
  Widget build(BuildContext context) {
    return CollectionTab(
      kind: 'faqs',
      addLabel: 'إضافة سؤال',
      emptyLabel: 'لا توجد أسئلة — أضف أول سؤال شائع',
      showEditor: (context, current) => _showFaqEditor(context, current),
      buildCard: (item) {
        final f = SiteFaqItem.fromJson(item);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: f.isActive ? AdminTheme.border : AdminTheme.borderDanger),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      f.questionAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AdminTheme.fontMd, color: AdminTheme.textHeading),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                f.answerAr,
                style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              metaChip('ترتيب: ${f.order}'),
            ],
          ),
        );
      },
    );
  }
}

Future<Map<String, dynamic>?> _showFaqEditor(BuildContext context, Map<String, dynamic>? current) {
  final f = current != null ? SiteFaqItem.fromJson(current) : null;
  final questionAr = TextEditingController(text: f?.questionAr ?? '');
  final questionEn = TextEditingController(text: f?.questionEn ?? '');
  final answerAr = TextEditingController(text: f?.answerAr ?? '');
  final answerEn = TextEditingController(text: f?.answerEn ?? '');
  final order = TextEditingController(text: '${f?.order ?? 0}');
  bool isActive = f?.isActive ?? true;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => editorDialogScaffold(
        context: ctx,
        title: f == null ? 'إضافة سؤال شائع' : 'تعديل السؤال',
        onSave: () {
          if (questionAr.text.trim().isEmpty ||
              questionEn.text.trim().isEmpty ||
              answerAr.text.trim().isEmpty ||
              answerEn.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('السؤال والجواب باللغتين مطلوبة'), backgroundColor: AdminTheme.crimson),
            );
            return;
          }
          Navigator.pop(ctx, {
            'questionAr': questionAr.text.trim(),
            'questionEn': questionEn.text.trim(),
            'answerAr': answerAr.text.trim(),
            'answerEn': answerEn.text.trim(),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          ContentField(controller: questionAr, label: 'السؤال بالعربية *', maxLines: 2),
          ContentField(controller: questionEn, label: 'السؤال بالإنجليزية *', maxLines: 2),
          ContentField(controller: answerAr, label: 'الجواب بالعربية *', maxLines: 4),
          ContentField(controller: answerEn, label: 'الجواب بالإنجليزية *', maxLines: 4),
          ContentOrderAndActive(
            orderController: order,
            isActive: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    ),
  );
}

