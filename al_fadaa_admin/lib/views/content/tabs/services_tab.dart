import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/responsive_dialog.dart';
import '../../../models/site_content_model.dart';
import '../content_components.dart';

// ═════════════════ تبويب الخدمات ═════════════════

class ServicesTab extends StatelessWidget {
  const ServicesTab();

  @override
  Widget build(BuildContext context) {
    return CollectionTab(
      kind: 'services',
      addLabel: 'إضافة خدمة',
      emptyLabel: 'لا توجد خدمات — أضف أول خدمة للموقع',
      showEditor: (context, current) => _showServiceEditor(context, current),
      buildCard: (item) {
        final s = SiteServiceItem.fromJson(item);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminTheme.surface2,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
                    ),
                    child: Text(s.slug, style: const TextStyle(fontFamily: 'monospace', fontSize: AdminTheme.fontXs, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  // العنوانان محصوران في المساحة المتبقية — كانت غير محددة
                  // العرض فتفيضان فوق أزرار التحكم المثبتة أعلى البطاقة
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
              if (s.shortAr != null && s.shortAr!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.shortAr!, style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  metaChip('ترتيب: ${s.order}'),
                  const SizedBox(width: 6),
                  if (s.features.isNotEmpty) metaChip('${s.features.length} ميزة'),
                  if (s.image != null) ...[
                    const SizedBox(width: 6),
                    metaChip('صورة محددة'),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


Future<Map<String, dynamic>?> _showServiceEditor(BuildContext context, Map<String, dynamic>? current) {
  final s = current != null ? SiteServiceItem.fromJson(current) : null;
  final slug = TextEditingController(text: s?.slug ?? '');
  final titleAr = TextEditingController(text: s?.titleAr ?? '');
  final titleEn = TextEditingController(text: s?.titleEn ?? '');
  final shortAr = TextEditingController(text: s?.shortAr ?? '');
  final shortEn = TextEditingController(text: s?.shortEn ?? '');
  final fullAr = TextEditingController(text: s?.fullAr ?? '');
  final fullEn = TextEditingController(text: s?.fullEn ?? '');
  final icon = TextEditingController(text: s?.icon ?? '');
  final image = TextEditingController(text: s?.image ?? '');
  final features = TextEditingController(text: s?.features.join('\n'));
  final order = TextEditingController(text: '${s?.order ?? 0}');
  bool isActive = s?.isActive ?? true;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => editorDialogScaffold(
        context: ctx,
        title: s == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة: ${s.titleAr}',
        onSave: () {
          if (titleAr.text.trim().isEmpty || titleEn.text.trim().isEmpty || slug.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('المعرف والاسم العربي والإنجليزي مطلوبة'), backgroundColor: AdminTheme.crimson),
            );
            return;
          }
          Navigator.pop(ctx, {
            'slug': slug.text.trim(),
            'titleAr': titleAr.text.trim(),
            'titleEn': titleEn.text.trim(),
            'shortAr': shortAr.text.trim(),
            'shortEn': shortEn.text.trim(),
            'fullAr': fullAr.text.trim(),
            'fullEn': fullEn.text.trim(),
            'icon': icon.text.trim(),
            'image': image.text.trim(),
            'features': linesToList(features.text),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          ContentField(controller: slug, label: 'المعرف في روابط الموقع (slug) — لا يُعدل بعد الإنشاء', enabled: s == null, hint: 'contracting'),
          ContentField(controller: titleAr, label: 'الاسم بالعربية *'),
          ContentField(controller: titleEn, label: 'الاسم بالإنجليزية *'),
          ContentField(controller: shortAr, label: 'وصف مختصر بالعربية (بطاقة الخدمة)', maxLines: 2),
          ContentField(controller: shortEn, label: 'وصف مختصر بالإنجليزية', maxLines: 2),
          ContentField(controller: fullAr, label: 'الوصف الكامل بالعربية', maxLines: 4),
          ContentField(controller: fullEn, label: 'الوصف الكامل بالإنجليزية', maxLines: 4),
          ContentField(controller: icon, label: 'اسم أيقونة lucide', hint: 'Building2'),
          ContentImageField(controller: image, label: 'مسار الصورة الرئيسية', hint: '/profile/construction_building.webp'),
          ContentField(controller: features, label: 'مزايا الخدمة — كل ميزة في سطر', maxLines: 4),
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

