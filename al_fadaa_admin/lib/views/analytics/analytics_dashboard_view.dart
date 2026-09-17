import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_user_model.dart';
import '../../models/analytics_model.dart';

class AnalyticsDashboardView extends StatefulWidget {
  const AnalyticsDashboardView({super.key});

  @override
  State<AnalyticsDashboardView> createState() => _AnalyticsDashboardViewState();
}

class _AnalyticsDashboardViewState extends State<AnalyticsDashboardView> {
  String _selectedPeriod = '30d';
  String _selectedDepartmentId = 'ALL';
  List<Department> _departments = [];
  AdminAnalyticsData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final depts = await AdminApiService().getDepartments();
    final data = await AdminApiService().getAnalytics(
      period: _selectedPeriod,
      departmentId: _selectedDepartmentId,
    );
    if (mounted) {
      setState(() {
        _departments = depts;
        _data = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await AdminApiService().getAnalytics(
      period: _selectedPeriod,
      departmentId: _selectedDepartmentId,
    );
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // شريط الفلاتر العلوي
            _buildFiltersBar(),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('جاري جمع وتحليل المؤشرات...', style: TextStyle(color: AdminTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else if (_data == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AdminTheme.crimson),
                      const SizedBox(height: 12),
                      const Text('تعذر تحميل بيانات التحليلات', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _fetchData, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              )
            else ...[
              // بطاقات المؤشرات الرئيسية (KPIs)
              _buildKpiGrid(_data!.summary),
              const SizedBox(height: 20),

              // بطاقة الـ SLA ومؤشر الالتزام + توزيع الأولويات
              _buildSlaAndPrioritySection(_data!.sla, _data!.priorities),
              const SizedBox(height: 20),

              // حركة المعاملات الزمنية (Trend)
              _buildTrendChart(_data!.trend),
              const SizedBox(height: 20),

              // جدول أداء الأقسام
              _buildDepartmentPerformanceTable(_data!.departmentPerformance),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // فترات التحليل
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_rounded, size: 18, color: AdminTheme.textMuted),
              const SizedBox(width: 8),
              const Text('الفترة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildPeriodChip('7 أيام', '7d'),
              _buildPeriodChip('30 يوماً', '30d'),
              _buildPeriodChip('90 يوماً', '90d'),
              _buildPeriodChip('سنة', '1y'),
            ],
          ),

          // فلتر الأقسام
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apartment_rounded, size: 18, color: AdminTheme.textMuted),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartmentId,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('كافة الأقسام والقطاعات')),
                      ..._departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDepartmentId = val);
                        _fetchData();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AdminTheme.accent),
                tooltip: 'تحديث المؤشرات',
                onPressed: _fetchData,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AdminTheme.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        visualDensity: VisualDensity.compact,
        onSelected: (sel) {
          if (sel) {
            setState(() => _selectedPeriod = value);
            _fetchData();
          }
        },
      ),
    );
  }

  Widget _buildKpiGrid(AnalyticsSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 6
            : (constraints.maxWidth >= 600 ? 3 : 2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKpiCard('إجمالي المعاملات', summary.total, Icons.all_inbox_rounded, const Color(0xFF0284C7)),
            _buildKpiCard('المعاملات النشطة', summary.active, Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
            _buildKpiCard('الوارد العام', summary.incoming, Icons.move_to_inbox_rounded, const Color(0xFF0369A1)),
            _buildKpiCard('المراسلات الصادرة', summary.outgoing, Icons.outbox_rounded, const Color(0xFF10B981)),
            _buildKpiCard('الخطابات الداخلية', summary.internal, Icons.description_outlined, const Color(0xFF8B5CF6)),
            _buildKpiCard('المغلقة والمؤرشفة', summary.closed + summary.archived, Icons.inventory_2_outlined, const Color(0xFF64748B)),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildSlaAndPrioritySection(SlaMetrics sla, PriorityBreakdown priorities) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final children = [
          // بطاقة SLA
          Expanded(
            flex: isWide ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 18, color: AdminTheme.accent),
                      SizedBox(width: 8),
                      Text('مؤشر الالتزام باتفاقيات الخدمة (SLA Compliance)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // دائرة النسبة
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (sla.complianceRate >= 90
                                  ? AdminTheme.emerald
                                  : (sla.complianceRate >= 75 ? AdminTheme.amber : AdminTheme.crimson))
                              .withAlpha(25),
                          border: Border.all(
                            color: sla.complianceRate >= 90
                                ? AdminTheme.emerald
                                : (sla.complianceRate >= 75 ? AdminTheme.amber : AdminTheme.crimson),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${sla.complianceRate}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetricRow('إجمالي المهام المقيّمة', '${sla.totalTasks} مهمة'),
                            const SizedBox(height: 4),
                            _buildMetricRow('المنجزة في موعدها', '${sla.onTimeTasks} مهمة', color: AdminTheme.emerald),
                            const SizedBox(height: 4),
                            _buildMetricRow('المهام المتجاوزة للموعد', '${sla.overdueTasks} مهمة', color: AdminTheme.crimson),
                            const SizedBox(height: 4),
                            _buildMetricRow('المهام قيد الإنجاز', '${sla.pendingTasks} مهمة', color: AdminTheme.amber),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

          // بطاقة توزيع الأولويات
          Expanded(
            flex: isWide ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 18, color: AdminTheme.purple),
                      SizedBox(width: 8),
                      Text('توزيع الأولويات ودرجات السرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPriorityBar('عاجل للغاية / فوري', priorities.urgent, AdminTheme.crimson),
                  const SizedBox(height: 8),
                  _buildPriorityBar('مهم / أولوية عالية', priorities.high, AdminTheme.amber),
                  const SizedBox(height: 8),
                  _buildPriorityBar('معاملات اعتيادية', priorities.normal, AdminTheme.accent),
                  const SizedBox(height: 8),
                  _buildPriorityBar('منخفضة الأولوية', priorities.low, AdminTheme.textMuted),
                ],
              ),
            ),
          ),
        ];

        return isWide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children) : Column(children: children);
      },
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? AdminTheme.textMain)),
      ],
    );
  }

  Widget _buildPriorityBar(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
        Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTrendChart(List<TrendPoint> trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: AdminTheme.accent),
              SizedBox(width: 8),
              Text('المسار الزمني لحجم المعاملات اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          if (trend.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('لا توجد حركة مسجلة في النطاق الزمني المحدد', style: TextStyle(color: AdminTheme.textMuted))),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.take(20).map((pt) {
                  final total = pt.incoming + pt.outgoing + pt.closed;
                  final heightFactor = total > 0 ? (total / 10).clamp(0.15, 1.0) : 0.05;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: '${pt.date}\nوارد: ${pt.incoming} | صادر: ${pt.outgoing} | مغلق: ${pt.closed}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$total', style: const TextStyle(fontSize: 9, color: AdminTheme.textMuted)),
                            const SizedBox(height: 2),
                            Container(
                              height: 80 * heightFactor,
                              decoration: BoxDecoration(
                                color: AdminTheme.accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pt.date.length >= 5 ? pt.date.substring(5) : pt.date,
                              style: const TextStyle(fontSize: 8, color: AdminTheme.textMuted),
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
        ],
      ),
    );
  }

  Widget _buildDepartmentPerformanceTable(List<DepartmentStat> depts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart_rounded, size: 18, color: AdminTheme.slate),
              SizedBox(width: 8),
              Text('تقييم أداء الأقسام والقطاعات التنفيذية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          if (depts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا توجد بيانات للأقسام', style: TextStyle(color: AdminTheme.textMuted)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('القسم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('الكود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('المراسلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('إجمالي المهام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('المنجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('المعلق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('نسبة الإنجاز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: depts.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Text(d.code, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                      DataCell(Text('${d.correspondences}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.tasksTotal}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${d.tasksCompleted}', style: const TextStyle(color: AdminTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Text('${d.tasksPending}', style: const TextStyle(color: AdminTheme.amber, fontSize: 12))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (d.complianceRate >= 80 ? AdminTheme.emerald : AdminTheme.amber).withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${d.complianceRate}%',
                            style: TextStyle(
                              color: d.complianceRate >= 80 ? AdminTheme.emerald : AdminTheme.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
