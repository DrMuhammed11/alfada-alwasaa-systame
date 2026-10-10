import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../operations_helpers.dart';

class DelegationsTab extends StatefulWidget {
  const DelegationsTab({super.key});
  @override
  State<DelegationsTab> createState() => DelegationsTabState();
}

class DelegationsTabState extends State<DelegationsTab> with AutomaticKeepAliveClientMixin {
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
    final res = await AdminApiService().getDelegations();
    if (!mounted) return;
    setState(() {
      _items = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _terminate(Map<String, dynamic> d) async {
    final res = await AdminApiService().terminateDelegation(d['id']);
    if (!mounted) return;
    final error = res?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم إنهاء التفويض'),
      backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل سجل الوكالات...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل سجل الوكالات',
        onRetry: _load,
      );
    }
    // حالة الفراغ — ودجة موحدة
    if (_items.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد تفويضات مسجلة',
        icon: Icons.swap_horiz_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final d = _items[i];
        final isActive =
            d['isActive'] == true || (d['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
              color: isActive ? AdminTheme.borderSuccess : AdminTheme.border,
            ),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المفوِّض: ${_nameOf(d, 'delegator')} → الوكيل: ${_nameOf(d, 'delegate')}',
                      style: const TextStyle(
                        fontSize: AdminTheme.fontBase,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      // شارة حالة التفويض — StatusBadge من app_utils
                      StatusBadge(
                        text: isActive ? 'نشط' : 'منتهٍ',
                        color: isActive ? AdminTheme.emerald : AdminTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      if (d['startsAt'] != null)
                        _metaChip('من: ${opDateFormat.format(DateTime.parse(d['startsAt']).toLocal())}'),
                      const SizedBox(width: 6),
                      if (d['endsAt'] != null)
                        _metaChip('إلى: ${opDateFormat.format(DateTime.parse(d['endsAt']).toLocal())}'),
                    ]),
                  ],
                ),
              ),
              if (isActive)
                OutlinedButton.icon(
                  onPressed: () => _terminate(d),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('إنهاء', style: TextStyle(fontSize: AdminTheme.fontSm)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.crimson,
                    side: const BorderSide(color: AdminTheme.crimson),
                  ),
                ),
            ],
          ),
        );
      },
      ),
    );
  }

  String _nameOf(Map<String, dynamic> d, String key) {
    final obj = d[key];
    if (obj is Map) return (obj['name'] ?? '-').toString();
    return (d['${key}Name'] ?? '-').toString();
  }

  Widget _metaChip(String text) {
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
}

