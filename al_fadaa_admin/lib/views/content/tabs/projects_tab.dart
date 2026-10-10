import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/responsive_dialog.dart';
import '../../../models/site_content_model.dart';
import '../content_components.dart';

// ═════════════════ تبويب سابقة الأعمال ═════════════════

class ProjectsTab extends StatelessWidget {
  const ProjectsTab();

  @override
  Widget build(BuildContext context) {
    return CollectionTab(
      kind: 'projects',
      addLabel: 'إضافة مشروع',
      emptyLabel: 'لا توجد مشاريع — أضف أول مشروع لسابقة الأعمال',
      showEditor: (context, current) => _showProjectEditor(context, current),
      buildCard: (item) {
        final p = SiteProjectItem.fromJson(item);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: p.isActive ? AdminTheme.border : AdminTheme.borderDanger),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوانان متراصان ومحصوران، ومساحة أزرار التحكم محفوظة يساراً
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AdminTheme.fontMd, color: AdminTheme.textHeading), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (p.titleEn.isNotEmpty)
                          Text(p.titleEn, style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
              // شارة التصنيف تحت العنوان مباشرة بلون مميز بدل طفوها وسط البطاقة
              if (p.tagAr != null && p.tagAr!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminTheme.accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
                    border: Border.all(color: AdminTheme.accent.withAlpha(70)),
                  ),
                  child: Text(p.tagAr!, style: const TextStyle(fontSize: AdminTheme.fontXs, fontWeight: FontWeight.bold, color: AdminTheme.accent)),
                ),
              ],
              if (p.scopeAr != null && p.scopeAr!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.scopeAr!, style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  metaChip('ترتيب: ${p.order}'),
                  const SizedBox(width: 6),
                  metaChip('${p.metrics.length} مؤشر'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<Map<String, dynamic>?> _showProjectEditor(BuildContext context, Map<String, dynamic>? current) {
  final p = current != null ? SiteProjectItem.fromJson(current) : null;
  final titleAr = TextEditingController(text: p?.titleAr ?? '');
  final titleEn = TextEditingController(text: p?.titleEn ?? '');
  final tagAr = TextEditingController(text: p?.tagAr ?? '');
  final tagEn = TextEditingController(text: p?.tagEn ?? '');
  final scopeAr = TextEditingController(text: p?.scopeAr ?? '');
  final scopeEn = TextEditingController(text: p?.scopeEn ?? '');
  final metrics = TextEditingController(text: p?.metrics.join('\n'));
  final image = TextEditingController(text: p?.image ?? '');
  final order = TextEditingController(text: '${p?.order ?? 0}');
  bool isActive = p?.isActive ?? true;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => editorDialogScaffold(
        context: ctx,
        title: p == null ? 'إضافة مشروع جديد' : 'تعديل المشروع: ${p.titleAr}',
        onSave: () {
          if (titleAr.text.trim().isEmpty || titleEn.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('العنوان العربي والإنجليزي مطلوبان'), backgroundColor: AdminTheme.crimson),
            );
            return;
          }
          Navigator.pop(ctx, {
            'titleAr': titleAr.text.trim(),
            'titleEn': titleEn.text.trim(),
            'tagAr': tagAr.text.trim(),
            'tagEn': tagEn.text.trim(),
            'scopeAr': scopeAr.text.trim(),
            'scopeEn': scopeEn.text.trim(),
            'metrics': linesToList(metrics.text),
            'image': image.text.trim(),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          ContentField(controller: titleAr, label: 'عنوان المشروع بالعربية *'),
          ContentField(controller: titleEn, label: 'عنوان المشروع بالإنجليزية *'),
          ContentField(controller: tagAr, label: 'التصنيف بالعربية', hint: 'مقاولات وأعمال مدنية'),
          ContentField(controller: tagEn, label: 'التصنيف بالإنجليزية'),
          ContentField(controller: scopeAr, label: 'نطاق العمل ووصف المشروع بالعربية', maxLines: 4),
          ContentField(controller: scopeEn, label: 'نطاق العمل بالإنجليزية', maxLines: 4),
          ContentField(controller: metrics, label: 'مؤشرات المشروع — كل مؤشر في سطر', maxLines: 3),
          ContentImageField(controller: image, label: 'مسار صورة المشروع', hint: '/profile/track_roller.webp'),
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

