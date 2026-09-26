import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/admin_user_model.dart';
import '../../models/analytics_model.dart';

class AnalyticsDashboardView extends StatefulWidget {
  const AnalyticsDashboardView({super.key});

  @override
  State<AnalyticsDashboardView> createState() => _AnalyticsDashboardViewState();
}

class _AnalyticsDashboardViewState extends State<AnalyticsDashboardView>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '30d';
  String _selectedDepartmentId = 'ALL';
  List<Department> _departments = [];
  AdminAnalyticsData? _data;
  bool _isLoading = true;
  // نطاق تاريخ مخصص — عند تفعيله يُهمل اختيار الفترة الجاهزة
  DateTime? _fromDate;
  DateTime? _toDate;
  bool get _hasCustomRange => _fromDate != null || _toDate != null;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AdminTheme.slow,
    );
    _loadInitial();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// معاملات الاستعلام: النطاق المخصص عند تفعيله وإلا الفترة الجاهزة
  Map<String, String> _periodParams() {
    final params = <String, String>{'departmentId': _selectedDepartmentId};
    if (_hasCustomRange) {
      if (_fromDate != null) params['from'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
      if (_toDate != null) params['to'] = DateFormat('yyyy-MM-dd').format(_toDate!);
    } else {
      params['period'] = _selectedPeriod;
    }
    return params;
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final deptsRes = await AdminApiService().getDepartments();
    final data = await AdminApiService().getAnalytics(
      period: _hasCustomRange ? null : _selectedPeriod,
      departmentId: _selectedDepartmentId,
      from: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
      to: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
    );
    if (mounted) {
      setState(() {
        _departments = deptsRes.items;
        _data = data;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    _fadeController.reset();
    final params = _periodParams();
    final data = await AdminApiService().getAnalytics(
      period: params['period'],
      departmentId: params['departmentId']!,
      from: params['from'],
      to: params['to'],
    );
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? now.subtract(const Duration(days: 30))) : (_toDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
    _fetchData();
  }

  Future<void> _clearCustomRange() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AdminTheme.accent,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildFiltersBar(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: LoadingWidget(message: 'جاري جمع وتحليل المؤشرات...'),
              )
            else if (_data == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: ErrorStateWidget(
                  message: 'تعذر تحميل بيانات التحليلات',
                  onRetry: _fetchData,
                ),
              )
            else
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    // بطاقات KPI
                    _buildKpiGrid(_data!.summary),
                    const SizedBox(height: 20),
                    // SLA وتوزيع الأولويات
                    _buildSlaAndPrioritySection(
                        _data!.sla, _data!.priorities),
                    const SizedBox(height: 20),
                    // رسم الترند الزمني
                    _buildTrendChart(_data!.trend),
                    const SizedBox(height: 20),
                    // تقييم الأقسام
                    _buildDepartmentPerformanceTable(
                        _data!.departmentPerformance),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // فترات التحليل
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface2,
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusXs),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AdminTheme.textMuted),
                ),
                const SizedBox(width: 8),
                const Text('الفترة:',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ...[
                  ('7 أيام', '7d'),
                  ('30 يوماً', '30d'),
                  ('90 يوماً', '90d'),
                  ('سنة', 'year'),
                ].map((p) => _buildPeriodChip(p.$1, p.$2)),
                const SizedBox(width: 10),
                // النطاق الزمني المخصص (from/to) — يتجاوز الفترات الجاهزة
                _buildDateChip(isFrom: true),
                const SizedBox(width: 6),
                _buildDateChip(isFrom: false),
                if (_hasCustomRange) ...[
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('مسح النطاق', style: TextStyle(fontSize: 11, color: AdminTheme.crimson)),
                    avatar: const Icon(Icons.filter_alt_off_rounded, size: 15, color: AdminTheme.crimson),
                    side: BorderSide(color: AdminTheme.crimson.withAlpha(80)),
                    onPressed: _clearCustomRange,
                  ),
                ],
              ],
            ),
          ),
          // فلتر الأقسام
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface2,
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusXs),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      size: 16, color: AdminTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AdminTheme.bgLight,
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDepartmentId,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AdminTheme.textMain,
                          fontWeight: FontWeight.w600),
                      items: [
                        const DropdownMenuItem(
                            value: 'ALL',
                            child: Text('كافة الأقسام والقطاعات')),
                        ..._departments.map((d) => DropdownMenuItem(
                            value: d.id, child: Text(d.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(
                              () => _selectedDepartmentId = val);
                          _fetchData();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // زر تحديث
                Tooltip(
                  message: 'تحديث المؤشرات',
                  child: InkWell(
                    onTap: _fetchData,
                    borderRadius: BorderRadius.circular(
                        AdminTheme.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AdminTheme.accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(
                            AdminTheme.radiusSm),
                        border: Border.all(
                            color: AdminTheme.accent.withAlpha(40)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 18, color: AdminTheme.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = !_hasCustomRange && _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: AnimatedContainer(
        duration: AdminTheme.fast,
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: AdminTheme.primary,
          backgroundColor: AdminTheme.surface2,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AdminTheme.textMuted,
            fontSize: 11,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          visualDensity: VisualDensity.compact,
          side: BorderSide(
              color: isSelected ? AdminTheme.primary : AdminTheme.border),
          onSelected: (sel) {
            if (sel) {
              setState(() {
                _selectedPeriod = value;
                _fromDate = null;
                _toDate = null;
              });
              _fetchData();
            }
          },
        ),
      ),
    );
  }

  /// رقائق النطاق الزمني المخصص — نسخة عن نمط سجل التدقيق
  Widget _buildDateChip({required bool isFrom}) {
    final date = isFrom ? _fromDate : _toDate;
    final label = date == null
        ? (isFrom ? 'من تاريخ' : 'إلى تاريخ')
        : '${isFrom ? 'من' : 'إلى'}: ${DateFormat('yyyy/MM/dd').format(date)}';
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(
        isFrom ? Icons.event_rounded : Icons.event_available_rounded,
        size: 15,
        color: date != null ? AdminTheme.accent : AdminTheme.textMuted,
      ),
      onPressed: () => _pickDate(isFrom: isFrom),
    );
  }

  Widget _buildKpiGrid(AnalyticsSummary summary) {
    final kpis = [
      ('إجمالي المعاملات', summary.total, Icons.all_inbox_rounded, AdminTheme.accent),
      ('المعاملات النشطة', summary.active, Icons.pending_actions_rounded, AdminTheme.amber),
      ('الوارد العام', summary.incoming, Icons.move_to_inbox_rounded, const Color(0xFF0369A1)),
      ('المراسلات الصادرة', summary.outgoing, Icons.outbox_rounded, AdminTheme.emerald),
      ('الخطابات الداخلية', summary.internal, Icons.description_outlined, AdminTheme.purple),
      ('المغلقة والمؤرشفة', summary.closed + summary.archived, Icons.inventory_2_outlined, AdminTheme.textMuted),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 900
            ? 6
            : (constraints.maxWidth >= 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: kpis
              .asMap()
              .entries
              .map((entry) => _AnimatedCard(
                    delay: Duration(
                        milliseconds: entry.key * 60),
                    child: KpiCard(
                      title: entry.value.$1,
                      value: AppUtils.formatNumber(
                          entry.value.$2),
                      icon: entry.value.$3,
                      color: entry.value.$4,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSlaAndPrioritySection(
      SlaMetrics sla, PriorityBreakdown priorities) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final slaCard = _buildSlaCard(sla);
        final priorityCard = _buildPriorityCard(priorities);
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: slaCard),
                const SizedBox(width: 16),
                Expanded(child: priorityCard),
              ],
            ),
          );
        }
        return Column(
          children: [
            slaCard,
            const SizedBox(height: 16),
            priorityCard,
          ],
        );
      },
    );
  }

  Widget _buildSlaCard(SlaMetrics sla) {
    final color = AppUtils.performanceColor(sla.complianceRate);
    return _sectionCard(
      icon: Icons.speed_rounded,
      iconColor: AdminTheme.accent,
      title: 'مؤشر الالتزام باتفاقيات الخدمة (SLA)',
      child: Column(
        children: [
          Row(
            children: [
              // دائرة النسبة
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: sla.complianceRate / 100,
                      strokeWidth: 7,
                      backgroundColor:
                          color.withAlpha(30),
                      valueColor:
                          AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    '${sla.complianceRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricRow('إجمالي المهام',
                        '${sla.totalTasks} مهمة'),
                    const SizedBox(height: 5),
                    _metricRow('منجزة في موعدها',
                        '${sla.onTimeTasks}',
                        color: AdminTheme.emerald),
                    const SizedBox(height: 5),
                    _metricRow('متأخرة',
                        '${sla.overdueTasks}',
                        color: AdminTheme.crimson),
                    const SizedBox(height: 5),
                    _metricRow('قيد التنفيذ',
                        '${sla.pendingTasks}',
                        color: AdminTheme.amber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شريط تقدم الالتزام
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AdminTheme.radiusSm),
            child: LinearProgressIndicator(
              value: sla.complianceRate / 100,
              minHeight: 6,
              backgroundColor: AdminTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%',
                  style: TextStyle(
                      fontSize: 9, color: AdminTheme.textLight)),
              Text(
                sla.complianceRate >= 85
                    ? 'جيد جداً'
                    : (sla.complianceRate >= 60
                        ? 'متوسط'
                        : 'تحتاج تحسين'),
                style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold),
              ),
              const Text('100%',
                  style: TextStyle(
                      fontSize: 9, color: AdminTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(PriorityBreakdown priorities) {
    final total = priorities.urgent +
        priorities.high +
        priorities.normal +
        priorities.low;
    return _sectionCard(
      icon: Icons.flag_rounded,
      iconColor: AdminTheme.purple,
      title: 'توزيع الأولويات ودرجات السرية',
      child: Column(
        children: [
          _priorityRow('عاجل للغاية / فوري',
              priorities.urgent, total, AdminTheme.crimson),
          const SizedBox(height: 10),
          _priorityRow('مهم / أولوية عالية',
              priorities.high, total, AdminTheme.amber),
          const SizedBox(height: 10),
          _priorityRow('معاملات اعتيادية',
              priorities.normal, total, AdminTheme.accent),
          const SizedBox(height: 10),
          _priorityRow('منخفضة الأولوية',
              priorities.low, total, AdminTheme.textMuted),
        ],
      ),
    );
  }

  Widget _priorityRow(
      String label, int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AdminTheme.textMain)),
            ),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius:
              BorderRadius.circular(AdminTheme.radiusSm),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AdminTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _metricRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: AdminTheme.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? AdminTheme.textMain)),
      ],
    );
  }

  /// تجميع السلسلة الزمنية للعرض: النقاط اليومية تُعرض كاملة حتى 45 نقطة،
  /// وإلا تُجمَّع أسبوعياً حتى يظهر النطاق كاملاً (سنة = 53 أسبوعاً) دون اقتطاع
  List<TrendPoint> _bucketTrend(List<TrendPoint> trend) {
    if (trend.length <= 45) return trend;
    final buckets = <TrendPoint>[];
    for (var i = 0; i < trend.length; i += 7) {
      final end = (i + 7).clamp(0, trend.length);
      final chunk = trend.sublist(i, end);
      buckets.add(TrendPoint(
        date: chunk.first.date,
        incoming: chunk.fold(0, (s, p) => s + p.incoming),
        outgoing: chunk.fold(0, (s, p) => s + p.outgoing),
        closed: chunk.fold(0, (s, p) => s + p.closed),
      ));
    }
    return buckets;
  }

  Widget _buildTrendChart(List<TrendPoint> rawTrend) {
    final trend = _bucketTrend(rawTrend);
    final isBucketed = trend.length != rawTrend.length;
    // حساب أقصى قيمة لمقياس أبعاد الأعمدة
    final maxTotal = trend.isEmpty
        ? 1
        : trend
            .map((p) => p.incoming + p.outgoing + p.closed)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 99999);

    return _sectionCard(
      icon: Icons.show_chart_rounded,
      iconColor: AdminTheme.accent,
      title: isBucketed
          ? 'المسار الزمني لحجم المعاملات (تجميع أسبوعي — ${rawTrend.length} يوماً)'
          : 'المسار الزمني لحجم المعاملات اليومية',
      child: trend.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyStateWidget(
                message: 'لا توجد حركة مسجلة في النطاق الزمني المحدد',
                icon: Icons.insert_chart_outlined_rounded,
              ),
            )
          : SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.take(30).map((pt) {
                  final total = pt.incoming + pt.outgoing + pt.closed;
                  final heightFactor =
                      (total / maxTotal).clamp(0.05, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 1.5),
                      child: Tooltip(
                        message:
                            '${pt.date}\nوارد: ${pt.incoming} | صادر: ${pt.outgoing} | مغلق: ${pt.closed}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (total > 0)
                              Text(
                                '$total',
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: AdminTheme.textMuted),
                              ),
                            const SizedBox(height: 2),
                            // عمود بتدرج لوني
                            Container(
                              height: 90 * heightFactor,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AdminTheme.accent
                                        .withAlpha(180),
                                    AdminTheme.accent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius
                                    .vertical(
                                    top: Radius.circular(3)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pt.date.length >= 5
                                  ? pt.date.substring(5)
                                  : pt.date,
                              style: const TextStyle(
                                  fontSize: 7,
                                  color: AdminTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildDepartmentPerformanceTable(
      List<DepartmentStat> depts) {
    return _sectionCard(
      icon: Icons.table_chart_rounded,
      iconColor: AdminTheme.slate,
      title: 'تقييم أداء الأقسام والقطاعات التنفيذية',
      child: depts.isEmpty
          ? const EmptyStateWidget(
              message: 'لا توجد بيانات للأقسام',
              icon: Icons.apartment_rounded,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    AdminTheme.surface2),
                columns: const [
                  DataColumn(
                      label: Text('القسم',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('الكود',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('المراسلات',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('إجمالي المهام',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('منجز',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('معلق',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                  DataColumn(
                      label: Text('نسبة الإنجاز',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                ],
                rows: depts.map((d) {
                  final color =
                      AppUtils.performanceColor(d.complianceRate);
                  return DataRow(
                    cells: [
                      DataCell(Text(d.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12))),
                      DataCell(Text(d.code,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AdminTheme.textMuted))),
                      DataCell(Text('${d.correspondences}',
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.tasksTotal}',
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.tasksCompleted}',
                          style: const TextStyle(
                              color: AdminTheme.emerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 12))),
                      DataCell(Text('${d.tasksPending}',
                          style: const TextStyle(
                              color: AdminTheme.amber,
                              fontSize: 12))),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                '${d.complianceRate.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AdminTheme.radiusSm),
                                child: LinearProgressIndicator(
                                  value:
                                      d.complianceRate / 100,
                                  minHeight: 4,
                                  backgroundColor: AdminTheme.border,
                                  valueColor:
                                      AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  // بطاقة قسم موحدة
  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(18),
                  borderRadius:
                      BorderRadius.circular(AdminTheme.radiusXs),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// بطاقة متحركة بتأخير لتحسين ظهور KPI
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedCard({required this.child, required this.delay});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AdminTheme.medium,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // تشغيل بعد التأخير
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}
