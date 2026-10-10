import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../content_components.dart';

// ═════════════════ تبويب الإعدادات العامة ═════════════════

class SettingsTab extends StatefulWidget {
  const SettingsTab();

  @override
  State<SettingsTab> createState() => SettingsTabState();
}

class SettingsTabState extends State<SettingsTab> with AutomaticKeepAliveClientMixin {
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
      builder: (ctx) => editorDialogScaffold(
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
              child: Text(setting['description'], style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted)),
            ),
          ContentField(controller: descController, label: 'شرح المفتاح (يظهر في اللوحة)'),
          ContentField(controller: valueController, label: 'محتوى الإعداد (JSON)', maxLines: 12),
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
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.key_rounded, size: 16, color: AdminTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['key'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: AdminTheme.fontBase, color: AdminTheme.textHeading)),
                    if (s['description'] != null)
                      Text(s['description'], style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openEditor(s),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('تحرير JSON', style: TextStyle(fontSize: AdminTheme.fontSm)),
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
