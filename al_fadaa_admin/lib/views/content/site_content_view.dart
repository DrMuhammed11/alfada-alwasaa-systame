import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/site_content_model.dart';

/// إدارة محتويات الموقع الإلكتروني: الخدمات، القطاعات، سابقة الأعمال،
/// الأسئلة الشائعة، والإعدادات العامة — بصلاحية إدارة المحتوى (ADMIN)
class SiteContentView extends StatelessWidget {
  const SiteContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.web_rounded, color: AdminTheme.accent, size: 22),
                  const SizedBox(width: 8),
                  const Text('إدارة محتويات الموقع الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AdminTheme.primary,
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: AdminTheme.primary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(icon: Icon(Icons.miscellaneous_services_rounded, size: 16), text: 'الخدمات'),
                        Tab(icon: Icon(Icons.domain_rounded, size: 16), text: 'القطاعات'),
                        Tab(icon: Icon(Icons.emoji_events_rounded, size: 16), text: 'سابقة الأعمال'),
                        Tab(icon: Icon(Icons.quiz_rounded, size: 16), text: 'الأسئلة الشائعة'),
                        Tab(icon: Icon(Icons.tune_rounded, size: 16), text: 'إعدادات عامة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ServicesTab(),
                  _SectorsTab(),
                  _ProjectsTab(),
                  _FaqsTab(),
                  _SettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════ أدوات مشتركة لتبويبات المجموعات ═════════════════

typedef ContentEditor = Future<Map<String, dynamic>?> Function(
  BuildContext context,
  Map<String, dynamic>? current, // null = إنشاء جديد
);

/// تبويب مجموعة محتوى عام: قائمة + إضافة/تعديل/حذف/تفعيل
class _CollectionTab extends StatefulWidget {
  final String kind;
  final String addLabel;
  final String emptyLabel;
  final Widget Function(Map<String, dynamic> item) buildCard;
  final ContentEditor showEditor;

  const _CollectionTab({
    required this.kind,
    required this.addLabel,
    required this.emptyLabel,
    required this.buildCard,
    required this.showEditor,
  });

  @override
  State<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<_CollectionTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getContentList(widget.kind);
    if (!mounted) return;
    setState(() {
      _items = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _openEditor([Map<String, dynamic>? current]) async {
    final payload = await widget.showEditor(context, current);
    if (payload == null || !mounted) return;

    final Map<String, dynamic>? result;
    if (current == null) {
      result = await AdminApiService().createContent(widget.kind, payload);
    } else {
      result = await AdminApiService().updateContent(widget.kind, current['id'], payload);
    }
    if (!mounted) return;

    final error = result?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? (current == null ? 'تمت الإضافة بنجاح' : 'تم تحديث العنصر بنجاح')),
        backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
      ),
    );
    if (error == null) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    final result = await AdminApiService().updateContent(widget.kind, item['id'], {'isActive': !(item['isActive'] == true)});
    if (!mounted) return;
    final error = result?['__error'];
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AdminTheme.crimson),
      );
    }
    _load();
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنصر؟ سيختفي من الموقع الإلكتروني نهائيًا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.crimson, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await AdminApiService().deleteContent(widget.kind, item['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حذف العنصر بنجاح' : 'فشل حذف العنصر'),
        backgroundColor: ok ? AdminTheme.emerald : AdminTheme.crimson,
      ),
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // شريط العمليات
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Text('العدد: ${_items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(widget.addLabel, style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.primary,
                  side: const BorderSide(color: AdminTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'تحديث',
                onPressed: _load,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget(message: 'جارٍ تحميل العناصر...')
              : _hasError
                  ? ErrorStateWidget(
                      message: 'تعذر تحميل عناصر المحتوى',
                      onRetry: _load,
                    )
                  : _items.isEmpty
                      ? EmptyStateWidget(
                          message: widget.emptyLabel,
                          actionLabel: 'تحديث',
                          onAction: _load,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Stack(
                                children: [
                                  widget.buildCard(item),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // مفتاح التفعيل
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: item['isActive'] == true,
                                            activeColor: AdminTheme.emerald,
                                            onChanged: (_) => _toggleActive(item),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, size: 17, color: AdminTheme.accent),
                                          tooltip: 'تعديل',
                                          onPressed: () => _openEditor(item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AdminTheme.crimson),
                                          tooltip: 'حذف',
                                          onPressed: () => _confirmDelete(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─── عناصر واجهة مشتركة للنوافذ ───

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool enabled;
  final String? hint;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: !enabled,
              fillColor: enabled ? null : const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}

/// حقل قائمة متعددة الأسطر: كل سطر عنصر (المزايا / الخدمات / المؤشرات)
List<String> _linesToList(String text) =>
    text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

/// حقل مسار صورة مع معاينة حية — الروابط المطلقة (http/https) تُعرض فوراً،
/// والمسارات النسبية (أصول الموقع) تُعرض على الموقع فقط فلا يمكن معاينتها هنا
class _ImageField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _ImageField({required this.controller, required this.label, this.hint});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final url = value.text.trim();
        final isUrl = url.startsWith('http://') || url.startsWith('https://');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(controller: controller, label: label, hint: hint),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isUrl
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: AdminTheme.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 18,
                            color: AdminTheme.textMuted,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUrl
                          ? 'معاينة مباشرة للرابط أعلاه'
                          : 'مسار نسبي لأصول الموقع — أدخل رابطاً مطلقاً (http/https) لمعاينته هنا',
                      style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderAndActive extends StatelessWidget {
  final TextEditingController orderController;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _OrderAndActive({
    required this.orderController,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Field(controller: orderController, label: 'ترتيب العرض'),
        ),
        const SizedBox(width: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('مفعّل للعرض في الموقع', style: TextStyle(fontSize: 12)),
          value: isActive,
          activeColor: AdminTheme.emerald,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget _editorDialogScaffold({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required VoidCallback onSave,
}) {
  return AlertDialog(
    title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton.icon(
        onPressed: onSave,
        icon: const Icon(Icons.save_rounded, size: 16),
        label: const Text('حفظ'),
        style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
      ),
    ],
  );
}

// ═════════════════ تبويب الخدمات ═════════════════

class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    return _CollectionTab(
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: s.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s.slug, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                  const SizedBox(width: 8),
                  Text(s.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(width: 6),
                  Text(s.titleEn, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                  const SizedBox(width: 120),
                ],
              ),
              if (s.shortAr != null && s.shortAr!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.shortAr!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  _metaChip('ترتيب: ${s.order}'),
                  const SizedBox(width: 6),
                  if (s.features.isNotEmpty) _metaChip('${s.features.length} ميزة'),
                  if (s.image != null) ...[
                    const SizedBox(width: 6),
                    _metaChip('صورة محددة'),
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

Widget _metaChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
  );
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
      builder: (ctx, setState) => _editorDialogScaffold(
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
            'features': _linesToList(features.text),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          _Field(controller: slug, label: 'المعرف في روابط الموقع (slug) — لا يُعدل بعد الإنشاء', enabled: s == null, hint: 'contracting'),
          _Field(controller: titleAr, label: 'الاسم بالعربية *'),
          _Field(controller: titleEn, label: 'الاسم بالإنجليزية *'),
          _Field(controller: shortAr, label: 'وصف مختصر بالعربية (بطاقة الخدمة)', maxLines: 2),
          _Field(controller: shortEn, label: 'وصف مختصر بالإنجليزية', maxLines: 2),
          _Field(controller: fullAr, label: 'الوصف الكامل بالعربية', maxLines: 4),
          _Field(controller: fullEn, label: 'الوصف الكامل بالإنجليزية', maxLines: 4),
          _Field(controller: icon, label: 'اسم أيقونة lucide', hint: 'Building2'),
          _ImageField(controller: image, label: 'مسار الصورة الرئيسية', hint: '/profile/construction_building.webp'),
          _Field(controller: features, label: 'مزايا الخدمة — كل ميزة في سطر', maxLines: 4),
          _OrderAndActive(
            orderController: order,
            isActive: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════ تبويب القطاعات ═════════════════

class _SectorsTab extends StatelessWidget {
  const _SectorsTab();

  @override
  Widget build(BuildContext context) {
    return _CollectionTab(
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: s.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(s.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(width: 6),
                  Text(s.titleEn, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                  const SizedBox(width: 120),
                ],
              ),
              if (s.descAr != null && s.descAr!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(s.descAr!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  _metaChip('ترتيب: ${s.order}'),
                  const SizedBox(width: 6),
                  _metaChip('${s.services.length} خدمة'),
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
      builder: (ctx, setState) => _editorDialogScaffold(
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
            'services': _linesToList(services.text),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          _Field(controller: titleAr, label: 'اسم القطاع بالعربية *'),
          _Field(controller: titleEn, label: 'اسم القطاع بالإنجليزية *'),
          _Field(controller: descAr, label: 'وصف القطاع بالعربية', maxLines: 2),
          _Field(controller: descEn, label: 'وصف القطاع بالإنجليزية', maxLines: 2),
          _Field(controller: icon, label: 'اسم أيقونة lucide', hint: 'Antenna'),
          _Field(controller: services, label: 'خدمات القطاع — كل خدمة في سطر', maxLines: 4),
          _OrderAndActive(
            orderController: order,
            isActive: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════ تبويب سابقة الأعمال ═════════════════

class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context) {
    return _CollectionTab(
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (p.tagAr != null && p.tagAr!.isNotEmpty) ...[
                    _metaChip(p.tagAr!),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(p.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
              if (p.scopeAr != null && p.scopeAr!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.scopeAr!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  _metaChip('ترتيب: ${p.order}'),
                  const SizedBox(width: 6),
                  _metaChip('${p.metrics.length} مؤشر'),
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
      builder: (ctx, setState) => _editorDialogScaffold(
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
            'metrics': _linesToList(metrics.text),
            'image': image.text.trim(),
            'order': int.tryParse(order.text.trim()) ?? 0,
            'isActive': isActive,
          });
        },
        children: [
          _Field(controller: titleAr, label: 'عنوان المشروع بالعربية *'),
          _Field(controller: titleEn, label: 'عنوان المشروع بالإنجليزية *'),
          _Field(controller: tagAr, label: 'التصنيف بالعربية', hint: 'مقاولات وأعمال مدنية'),
          _Field(controller: tagEn, label: 'التصنيف بالإنجليزية'),
          _Field(controller: scopeAr, label: 'نطاق العمل ووصف المشروع بالعربية', maxLines: 4),
          _Field(controller: scopeEn, label: 'نطاق العمل بالإنجليزية', maxLines: 4),
          _Field(controller: metrics, label: 'مؤشرات المشروع — كل مؤشر في سطر', maxLines: 3),
          _ImageField(controller: image, label: 'مسار صورة المشروع', hint: '/profile/track_roller.webp'),
          _OrderAndActive(
            orderController: order,
            isActive: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════ تبويب الأسئلة الشائعة ═════════════════

class _FaqsTab extends StatelessWidget {
  const _FaqsTab();

  @override
  Widget build(BuildContext context) {
    return _CollectionTab(
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: f.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      f.questionAr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E293B)),
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
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _metaChip('ترتيب: ${f.order}'),
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
      builder: (ctx, setState) => _editorDialogScaffold(
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
          _Field(controller: questionAr, label: 'السؤال بالعربية *', maxLines: 2),
          _Field(controller: questionEn, label: 'السؤال بالإنجليزية *', maxLines: 2),
          _Field(controller: answerAr, label: 'الجواب بالعربية *', maxLines: 4),
          _Field(controller: answerEn, label: 'الجواب بالإنجليزية *', maxLines: 4),
          _OrderAndActive(
            orderController: order,
            isActive: isActive,
            onChanged: (v) => setState(() => isActive = v),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════ تبويب الإعدادات العامة ═════════════════

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _settings = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getSiteSettings();
    if (!mounted) return;
    setState(() {
      _settings = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _openEditor(Map<String, dynamic> setting) async {
    final valueController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(setting['value']),
    );
    final descController = TextEditingController(text: setting['description'] ?? '');

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _editorDialogScaffold(
        context: ctx,
        title: 'تعديل الإعداد: ${setting['key']}',
        onSave: () {
          try {
            final value = jsonDecode(valueController.text);
            Navigator.pop(ctx, {
              'value': value,
              'description': descController.text.trim(),
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('صيغة JSON غير صالحة: $e'), backgroundColor: AdminTheme.crimson),
            );
          }
        },
        children: [
          if ((setting['description'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(setting['description'], style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
            ),
          _Field(controller: descController, label: 'شرح المفتاح (يظهر في اللوحة)'),
          _Field(controller: valueController, label: 'محتوى الإعداد (JSON)', maxLines: 12),
        ],
      ),
    );
    if (payload == null || !mounted) return;

    final result = await AdminApiService().upsertSiteSetting(
      setting['key'],
      payload['value'],
      description: payload['description'],
    );
    if (!mounted) return;
    final error = result?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حفظ الإعداد بنجاح'),
        backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
      ),
    );
    if (error == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const LoadingWidget(message: 'جارٍ تحميل الإعدادات العامة...');
    }
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل الإعدادات العامة',
        onRetry: _load,
      );
    }
    if (_settings.isEmpty) {
      return const Center(
        child: Text('لا توجد إعدادات محفوظة بعد', style: TextStyle(color: AdminTheme.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _settings.length,
      itemBuilder: (context, index) {
        final s = _settings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.key_rounded, size: 16, color: AdminTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['key'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                    if (s['description'] != null)
                      Text(s['description'], style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openEditor(s),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('تحرير JSON', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.primary,
                  side: const BorderSide(color: AdminTheme.primary),
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}
