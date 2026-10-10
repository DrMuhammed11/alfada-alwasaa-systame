import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/responsive_dialog.dart';

// ═════════════════ أدوات مشتركة لتبويبات المجموعات ═════════════════

typedef ContentEditor = Future<Map<String, dynamic>?> Function(
  BuildContext context,
  Map<String, dynamic>? current, // null = إنشاء جديد
);

/// تبويب مجموعة محتوى عام: قائمة + إضافة/تعديل/حذف/تفعيل
class CollectionTab extends StatefulWidget {
  final String kind;
  final String addLabel;
  final String emptyLabel;
  final Widget Function(Map<String, dynamic> item) buildCard;
  final ContentEditor showEditor;

  const CollectionTab({
    required this.kind,
    required this.addLabel,
    required this.emptyLabel,
    required this.buildCard,
    required this.showEditor,
  });

  @override
  State<CollectionTab> createState() => CollectionTabState();
}

class CollectionTabState extends State<CollectionTab> with AutomaticKeepAliveClientMixin {
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
              Text('العدد: ${_items.length}', style: const TextStyle(fontSize: AdminTheme.fontBase, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(widget.addLabel, style: const TextStyle(fontSize: AdminTheme.fontBase)),
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

class ContentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool enabled;
  final String? hint;

  const ContentField({
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
          Text(label, style: const TextStyle(fontSize: AdminTheme.fontSm, fontWeight: FontWeight.w600, color: AdminTheme.textMuted)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            style: const TextStyle(fontSize: AdminTheme.fontMd),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
              filled: !enabled,
              fillColor: enabled ? null : AdminTheme.surface2,
            ),
          ),
        ],
      ),
    );
  }
}

/// حقل قائمة متعددة الأسطر: كل سطر عنصر (المزايا / الخدمات / المؤشرات)
List<String> linesToList(String text) =>
    text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

/// حقل مسار صورة مع معاينة حية — الروابط المطلقة (http/https) تُعرض فوراً،
/// والمسارات النسبية (أصول الموقع) تُعرض على الموقع فقط فلا يمكن معاينتها هنا
class ContentImageField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const ContentImageField({required this.controller, required this.label, this.hint});

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
            ContentField(controller: controller, label: label, hint: hint),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminTheme.bgLight,
                      borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                      border: Border.all(color: AdminTheme.border),
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
                      style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
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

class ContentOrderAndActive extends StatelessWidget {
  final TextEditingController orderController;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const ContentOrderAndActive({
    required this.orderController,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ContentField(controller: orderController, label: 'ترتيب العرض'),
        ),
        const SizedBox(width: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('مفعّل للعرض في الموقع', style: TextStyle(fontSize: AdminTheme.fontBase)),
          value: isActive,
          activeColor: AdminTheme.emerald,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget editorDialogScaffold({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required VoidCallback onSave,
}) {
  return AlertDialog(
    title: Text(title, style: const TextStyle(fontSize: AdminTheme.fontTitle, fontWeight: FontWeight.bold)),
    content: SizedBox(
      width: ResponsiveDialog.maxWidth(context, 560),
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


Widget metaChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AdminTheme.bgLight,
      borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
      border: Border.all(color: AdminTheme.border),
    ),
    child: Text(text, style: const TextStyle(fontSize: AdminTheme.fontXs, color: AdminTheme.textMuted)),
  );
}
