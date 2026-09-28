import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';

/// قائمة المتأخرات (SLA): مراسلات بها إحالات/مهام نشطة تجاوزت موعد الاستحقاق.
/// مصدر البيانات: حقل isOverdue المحسوب من الخادم على القائمة.
/// (الفلترة حاليًا على أول 100 معاملة نشطة — فلتر خدمي مخصص لاحقًا)
class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  List<Correspondence> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService().getCorrespondencesPaginated(page: 1, limit: 100);
    // getCorrespondencesPaginated تُعيد كائنات Correspondence محلَّلة مسبقاً —
    // محاولة إعادة تحليلها من JSON كانت ترمي TypeError وتُبقي الشاشة دوّاحة إلى الأبد
    final list = (res['data'] as List?) ?? const [];
    final overdue = list.whereType<Correspondence>().where((e) => e.isOverdue).toList();
    // الأكثر تأخيراً أولًا
    overdue.sort((a, b) => b.overdueDays.compareTo(a.overdueDays));
    if (!mounted) return;
    setState(() {
      _items = overdue;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('المتأخرات عن موعد الاستحقاق', style: TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 44),
                      SizedBox(height: 10),
                      Text('لا توجد معاملات متأخرة — التزام كامل بالمواعيد', style: TextStyle(color: AppTheme.textTertiary)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDanger,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.borderDanger),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.crimson, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_items.length} معاملة متأخرة — الأقدم تأخيراً تتصدر القائمة',
                              style: const TextStyle(fontSize: AppTheme.fontSm, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final c = _items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(color: AppTheme.borderDanger),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.crimson.withAlpha(20),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Text(
                                    '${c.overdueDays} ي',
                                    style: const TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${c.refNumber} — ${c.subject}',
                                        style: const TextStyle(fontSize: AppTheme.fontBase, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'أولوية: ${c.priority} — الحالة: ${c.status}',
                                        style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
