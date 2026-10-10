import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/responsive_dialog.dart';
import '../../../models/site_content_model.dart';
import '../content_components.dart';

// ═════════════════ تبويب القطاعات ═════════════════

class SectorsTab extends StatelessWidget {
  const SectorsTab();

  @override
  Widget build(BuildContext context) {
    return CollectionTab(
      kind: 'sectors',
      addLabel: 'إضافة قطاع',
      emptyLabel: 'لا توجد قطاعات — أضف أول قطاع',
      showEditor: (context, current) => _showSectorEditor(context, current),
      buildCard: (item) {
        final s = SiteSectorItem.fromJson(item);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: s.isActive ? AdminTheme.border : AdminTheme.borderDanger),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوانان محصوران — كانا غير محددي العرض ففيضانا فوق
                  // أزرار التحكم المثبتة أعلى البطاقة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AdminTheme.fontMd, color: AdminTheme.textHeading), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (s.titleEn.isNotEmpty)
                          Text(s.titleEn, style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 120),
                ],
              ),
              if (s.descAr != null && s.descAr!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(s.descAr!, style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  metaChip('ترتيب: ${s.order}'),
                  const SizedBox(width: 6),
                  metaChip('${s.services.length} خدمة'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<Map<String, dynamic>?> _showSectorEditor(BuildContext context, Map<String, dynamic>? current) {
  final s = current != null ? SiteSectorItem.fromJson(current) : null;
  final titleAr = TextEditingController(text: s?.titleAr ?? '');
  final titleEn = TextEditingController(text: s?.titleEn ?? '');
  final descAr = TextEditingController(text: s?.descAr ?? '');
  final descEn = TextEditingController(text: s?.descEn ?? '');
  final icon = TextEditingController(text: s?.icon ?? '');
  final services = TextEditingController(text: s?.services.join('\n'));
  final order = TextEditingController(text: '${s?.order ?? 0}');
  bool isActive = s?.isActive ?? true;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => editorDialogScaffold(
        context: ctx,
        title: s == null ? 'إضافة قطاع جديد' : 'تعديل القطاع: ${s.titleAr}',
        onSave: () {
          if (titleAr.text.trim().isEmpty || titleEn.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الاسم العربي والإنجليزي مطلوبان'), backgroundColor: AdminTheme.crimson),
            );
            return;
          }
          Navigator.pop(ctx, {
            'titleAr': titleAr.text.trim(),
            'titleEn': titleEn.text.trim(),
            'descAr': descAr.text.trim(),
            'descEn': descEn.text.trim(),
            'icon': icon.text.trim(),
            'services': linesToList(services.text),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          ContentField(controller: titleAr, label: 'اسم القطاع بالعربية *'),
          ContentField(controller: titleEn, label: 'اسم القطاع بالإنجليزية *'),
          ContentField(controller: descAr, label: 'وصف القطاع بالعربية', maxLines: 2),
          ContentField(controller: descEn, label: 'وصف القطاع بالإنجليزية', maxLines: 2),
          ContentField(controller: icon, label: 'اسم أيقونة lucide', hint: 'Antenna'),
          ContentField(controller: services, label: 'خدمات القطاع — كل خدمة في سطر', maxLines: 4),
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

