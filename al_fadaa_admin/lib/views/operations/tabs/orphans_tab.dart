import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/stat_tile.dart';
import '../operations_helpers.dart';

class OrphansTab extends StatefulWidget {
  const OrphansTab({super.key});
  @override
  State<OrphansTab> createState() => OrphansTabState();
}

class OrphansTabState extends State<OrphansTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _report;
  bool _isLoading = true, _hasError = false;
  // وقت إتمام آخر فحص ناجح — من الخادم فعلياً لا من لحظة البناء
  DateTime? _lastCheckedAt;

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
    final report = await AdminApiService().getOrphans();
    if (!mounted) return;
    setState(() {
      _report = report;
      _isLoading = false;
      _hasError = report == null;
      if (report != null) _lastCheckedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ فحص الكيانات اليتيمة...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل تقرير الكيانات اليتيمة',
        onRetry: _load,
      );
    }
    final summary = (_report?['summary'] as Map?) ?? {};
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // صف إحصاءات متجاوب — يلتف بدل أن ينكسر في النوافذ الضيقة
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final cardWidth = w > 700 ? (w - 20) / 3 : w > 480 ? (w - 10) / 2 : w;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: cardWidth, child: _statCard('إحالات مفتوحة على مراسلات مغلقة', summary['openReferralsCount'], AdminTheme.crimson)),
              SizedBox(width: cardWidth, child: _statCard('تكليفات معلقة على مراسلات مغلقة', summary['pendingTasksCount'], AdminTheme.amber)),
              SizedBox(width: cardWidth, child: _statCard('مسودات ردود على مراسلات مغلقة', summary['draftRepliesCount'], AdminTheme.purple)),
            ],
          );
        }),
        const SizedBox(height: 12),
        // بطاقة ملخص النزاهة البنيوية
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (summary['totalOrphans'] ?? 0) == 0
                ? AdminTheme.surfaceSuccess
                : AdminTheme.surfaceDanger,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
              color: (summary['totalOrphans'] ?? 0) == 0
                  ? AdminTheme.borderSuccess
                  : AdminTheme.borderDanger,
            ),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Text(
            (summary['totalOrphans'] ?? 0) == 0
                ? 'لا توجد كيانات يتيمة — سلامة بنيوية كاملة'
                : 'رُصدت ${(summary['totalOrphans'] ?? 0)} كيانات يتيمة تحتاج معالجة يدوية (فتح المراسلة وإتمام دورتها)',
            style: TextStyle(
              fontSize: AdminTheme.fontBase,
              fontWeight: FontWeight.bold,
              color: (summary['totalOrphans'] ?? 0) == 0 ? AdminTheme.emerald : AdminTheme.crimson,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'آخر فحص: ${_lastCheckedAt != null ? opDateFormat.format(_lastCheckedAt!) : '—'}',
          style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
        ),
      ],
        ),
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    // بطاقة موحّدة عبر StatTile — كانت نسخة خاصة بحشوة 12 وقيمة 20px
    // تخالف بطاقات الـKPI (حشوة 16 وقيمة 26px)
    return StatTile(
      label: label,
      value: AppFormatters.number((value ?? 0) as num),
      color: color,
    );
  }
}

