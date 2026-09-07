import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/download_helper.dart';
import '../../models/correspondence_model.dart';
import '../../models/user_model.dart';

class ExecutiveReportsScreen extends StatefulWidget {
  final User? currentUser;

  const ExecutiveReportsScreen({super.key, this.currentUser});

  @override
  State<ExecutiveReportsScreen> createState() => _ExecutiveReportsScreenState();
}

class _ExecutiveReportsScreenState extends State<ExecutiveReportsScreen> {
  bool _isLoading = true;
  List<Correspondence> _correspondences = [];
  List<TaskItem> _tasks = [];
  List<Department> _departments = [];
  String _selectedPeriod = 'ALL'; // ALL, TODAY, WEEK, MONTH

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getCorrespondencesPaginated(limit: 100),
        ApiService().getAllTasks(),
        ApiService().getDepartments(),
      ]);

      if (!mounted) return;

      final corrRes = results[0] as Map<String, dynamic>;
      final tasksRes = results[1] as List<TaskItem>;
      final deptsRes = results[2] as List<Department>;

      setState(() {
        _correspondences = (corrRes['data'] as List<Correspondence>?) ?? [];
        _tasks = tasksRes;
        _departments = deptsRes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ExecutiveReportsScreen load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Correspondence> get _filteredCorrespondences {
    final now = DateTime.now();
    if (_selectedPeriod == 'TODAY') {
      return _correspondences.where((c) {
        return c.createdAt.year == now.year &&
            c.createdAt.month == now.month &&
            c.createdAt.day == now.day;
      }).toList();
    } else if (_selectedPeriod == 'WEEK') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return _correspondences.where((c) => c.createdAt.isAfter(weekAgo)).toList();
    } else if (_selectedPeriod == 'MONTH') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return _correspondences.where((c) => c.createdAt.isAfter(monthAgo)).toList();
    }
    return _correspondences;
  }

  List<TaskItem> get _filteredTasks {
    final now = DateTime.now();
    if (_selectedPeriod == 'TODAY') {
      return _tasks.where((t) {
        return t.createdAt.year == now.year &&
            t.createdAt.month == now.month &&
            t.createdAt.day == now.day;
      }).toList();
    } else if (_selectedPeriod == 'WEEK') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return _tasks.where((t) => t.createdAt.isAfter(weekAgo)).toList();
    } else if (_selectedPeriod == 'MONTH') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return _tasks.where((t) => t.createdAt.isAfter(monthAgo)).toList();
    }
    return _tasks;
  }

  // ─── المؤشرات الإجمالية ───
  int get _totalCorrespondences => _filteredCorrespondences.length;

  int get _incomingCount =>
      _filteredCorrespondences.where((c) => c.type == 'INCOMING').length;

  int get _inProgressCount => _filteredCorrespondences.where((c) =>
      c.status == 'UNDER_REVIEW' ||
      c.status == 'REFERRED' ||
      c.status == 'IN_PROGRESS' ||
      c.status == 'PENDING_APPROVAL').length;

  int get _completedCount => _filteredCorrespondences.where((c) =>
      c.status == 'APPROVED' || c.status == 'SENT' || c.status == 'DONE').length;

  int get _closedOrArchivedCount => _filteredCorrespondences
      .where((c) => c.status == 'CLOSED' || c.status == 'ARCHIVED')
      .length;

  int get _totalTasks => _filteredTasks.length;

  int get _doneTasks => _filteredTasks.where((t) => t.isDone).length;

  int get _overdueTasks => _filteredTasks.where((t) => t.isOverdue).length;

  double get _tasksCompletionRate =>
      _totalTasks == 0 ? 0 : (_doneTasks / _totalTasks) * 100;

  // ─── طباعة التقرير التنفيذي ───
  void _printReport() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final periodArabic = _selectedPeriod == 'TODAY'
        ? 'اليوم الحالي'
        : _selectedPeriod == 'WEEK'
            ? 'آخر 7 أيام'
            : _selectedPeriod == 'MONTH'
                ? 'آخر 30 يوماً'
                : 'كافة الفترات';

    final deptRowsHtml = _departments.map((d) {
      final deptName = d.name;
      final deptCode = d.code;
      final managerName = d.managerName ?? 'غير محدد';
      final corrCount = d.correspondencesCount;
      final usersCount = d.usersCount;

      return '''
        <tr>
          <td><strong>$deptName</strong> ($deptCode)</td>
          <td>$managerName</td>
          <td>$usersCount موظف</td>
          <td>$corrCount معاملة</td>
        </tr>
      ''';
    }).join('\n');

    final recentCorrsHtml = _filteredCorrespondences.take(15).map((c) {
      return '''
        <tr>
          <td><strong>${c.serialNumber}</strong></td>
          <td>${c.subject}</td>
          <td>${c.senderName ?? '-'}</td>
          <td>${c.type}</td>
          <td>${c.status}</td>
        </tr>
      ''';
    }).join('\n');

    final html = '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>التقرير التنفيذي الشامل - شركة الفضاء الواسع</title>
  <style>
    @page { size: A4; margin: 15mm; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: #fff;
      color: #1e293b;
      margin: 0;
      padding: 20px;
      direction: rtl;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #0284c7;
      padding-bottom: 12px;
      margin-bottom: 20px;
    }
    .header h1 { margin: 0; font-size: 20px; color: #0f172a; }
    .header .subtitle { font-size: 13px; color: #64748b; margin-top: 4px; }
    .meta-box {
      font-size: 11px;
      color: #475569;
      text-align: left;
      line-height: 1.6;
    }
    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      margin-bottom: 24px;
    }
    .kpi-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 12px;
      text-align: center;
    }
    .kpi-title { font-size: 11px; color: #64748b; margin-bottom: 6px; }
    .kpi-value { font-size: 20px; font-weight: bold; color: #0284c7; }
    .section-title {
      font-size: 14px;
      font-weight: bold;
      color: #0f172a;
      border-right: 4px solid #0284c7;
      padding-right: 8px;
      margin: 20px 0 10px 0;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
      font-size: 11px;
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 8px 10px;
      text-align: right;
    }
    th {
      background: #f1f5f9;
      color: #334155;
      font-weight: bold;
    }
    tr:nth-child(even) { background: #f8fafc; }
    .footer {
      border-top: 1px solid #e2e8f0;
      padding-top: 10px;
      font-size: 10px;
      color: #94a3b8;
      text-align: center;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1>شركة الفضاء الواسع للتجارة العامة والمقاولات</h1>
      <div class="subtitle">نظام إدارة المراسلات المؤسسي — التقرير التنفيذي لمؤشرات الأداء والمعاملات</div>
    </div>
    <div class="meta-box">
      <div><strong>تاريخ الإصدار:</strong> $dateStr</div>
      <div><strong>نطاق التقرير:</strong> $periodArabic</div>
      <div><strong>المُصدر:</strong> ${widget.currentUser?.fullName ?? 'المدير العام'}</div>
    </div>
  </div>

  <div class="section-title">المؤشرات الكلية للمعاملات والطلبيات (Key Performance Indicators)</div>
  <div class="kpi-grid">
    <div class="kpi-card">
      <div class="kpi-title">إجمالي المعاملات والطلبيات</div>
      <div class="kpi-value">$_totalCorrespondences</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">المعاملات قيد التنفيذ والدراسة</div>
      <div class="kpi-value" style="color: #d97706;">$_inProgressCount</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">المعاملات المعتمدة والمنجزة</div>
      <div class="kpi-value" style="color: #16a34a;">$_completedCount</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">المغلقة والمؤرشفة</div>
      <div class="kpi-value" style="color: #475569;">$_closedOrArchivedCount</div>
    </div>
  </div>

  <div class="kpi-grid">
    <div class="kpi-card">
      <div class="kpi-title">إجمالي المهام والتكليفات</div>
      <div class="kpi-value">$_totalTasks</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">المهام المنجزة بالقطاعات</div>
      <div class="kpi-value" style="color: #16a34a;">$_doneTasks</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">المهام المتأخرة عن SLA</div>
      <div class="kpi-value" style="color: #dc2626;">$_overdueTasks</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-title">نسبة إنجاز المهام العامة</div>
      <div class="kpi-value">${_tasksCompletionRate.toStringAsFixed(1)}%</div>
    </div>
  </div>

  <div class="section-title">تفصيل أداء القطاعات والإدارات التنفيذية</div>
  <table>
    <thead>
      <tr>
        <th>القطاع / الإدارة</th>
        <th>مدير القطاع</th>
        <th>كادر العمل</th>
        <th>إجمالي المعاملات المسندة</th>
      </tr>
    </thead>
    <tbody>
      $deptRowsHtml
    </tbody>
  </table>

  <div class="section-title">عينة من أحدث المعاملات المسجلة</div>
  <table>
    <thead>
      <tr>
        <th>الرقم المرجعي</th>
        <th>موضوع المعاملة</th>
        <th>الجهة المرسلة / العميل</th>
        <th>نوع المعاملة</th>
        <th>حالة المعاملة</th>
      </tr>
    </thead>
    <tbody>
      $recentCorrsHtml
    </tbody>
  </table>

  <div class="footer">
    تم استخراج هذا التقرير تلقائيًا من نظام الفضاء الواسع لإدارة المراسلات. التقرير معتمد رسمياً لأغراض المتابعة الرقابية والتنفيذية.
  </div>
</body>
</html>
    ''';

    printHtmlDossier(html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Color(0xFF0284C7), size: 22),
            SizedBox(width: 10),
            Text(
              'لوحة التقارير والتحليلات التنفيذية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          // فلترة الفترة
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('كافة الفترات')),
                  DropdownMenuItem(value: 'TODAY', child: Text('اليوم')),
                  DropdownMenuItem(value: 'WEEK', child: Text('آخر 7 أيام')),
                  DropdownMenuItem(value: 'MONTH', child: Text('آخر 30 يوماً')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPeriod = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'تحديث البيانات',
            onPressed: _loadReportData,
          ),
          const SizedBox(width: 8),

          // زر الطباعة والتصدير
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: _isLoading ? null : _printReport,
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text(
                'طباعة التقرير التنفيذي / PDF',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة ترحيب وتوضيح
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مؤشرات الأداء العامة وسير العمل في القطاعات',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'بيانات تحليلية مباشرة لحركة الطلبيات، المعاملات، والتكليفات ونسب الالتزام بمهلة SLA.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── شبكة المؤشرات الكلية ───
                  const Text(
                    'المؤشرات الكلية للمعاملات والطلبيات',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildKpiCard(
                            title: 'إجمالي المعاملات والطلبيات',
                            value: '$_totalCorrespondences',
                            icon: Icons.all_inbox_rounded,
                            color: const Color(0xFF0284C7),
                            subtitle: '$_incomingCount طلب وارد من العملاء',
                          ),
                          _buildKpiCard(
                            title: 'قيد التنفيذ والدراسة',
                            value: '$_inProgressCount',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFD97706),
                            subtitle: 'معاملات موزعة على القطاعات',
                          ),
                          _buildKpiCard(
                            title: 'المكتملة والمعتمدة',
                            value: '$_completedCount',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF16A34A),
                            subtitle: 'جاهزة أو تم إرسال ردها',
                          ),
                          _buildKpiCard(
                            title: 'المغلقة والمؤرشفة',
                            value: '$_closedOrArchivedCount',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF64748B),
                            subtitle: 'تم إنهاء معاملتها بالكامل',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ─── مؤشرات المهام والـ SLA ───
                  const Text(
                    'مؤشرات أداء المهام والتكليفات (SLA Compliance)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildKpiCard(
                            title: 'إجمالي التكليفات الصادرة',
                            value: '$_totalTasks',
                            icon: Icons.assignment_outlined,
                            color: const Color(0xFF4F46E5),
                            subtitle: 'مهام وزعت على الموظفين',
                          ),
                          _buildKpiCard(
                            title: 'المهام المنجزة بنجاح',
                            value: '$_doneTasks',
                            icon: Icons.task_alt_rounded,
                            color: const Color(0xFF059669),
                            subtitle: 'تم تسليم تقاريرها من القطاع',
                          ),
                          _buildKpiCard(
                            title: 'المهام المتأخرة عن SLA',
                            value: '$_overdueTasks',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFDC2626),
                            subtitle: 'تجاوزت الموعد النهائي',
                          ),
                          _buildKpiCard(
                            title: 'معدل إنجاز المهام الكلي',
                            value: '${_tasksCompletionRate.toStringAsFixed(1)}%',
                            icon: Icons.pie_chart_outline_rounded,
                            color: const Color(0xFF0891B2),
                            subtitle: 'نسبة المهام المكتملة',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ─── تفصيل القطاعات والإدارات ───
                  Row(
                    children: [
                      const Text(
                        'أداء القطاعات والإدارات التنفيذية',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      Text(
                        'إجمالي الإدارات: ${_departments.length}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('القطاع / الإدارة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('رمز الإدارة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('مدير الإدارة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('عدد الكادر', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المعاملات المسندة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الحالة التشغيلية', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _departments.map((dept) {
                          final name = dept.name;
                          final code = dept.code;
                          final manager = dept.managerName ?? 'غير معين';
                          final usersCount = dept.usersCount;
                          final corrCount = dept.correspondencesCount;

                          return DataRow(cells: [
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.business_rounded, color: Color(0xFF0284C7), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(code, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                              ),
                            ),
                            DataCell(Text(manager, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                            DataCell(Text('$usersCount موظف', style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Text(
                                '$corrCount معاملة',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'نشطة ومفعلة ✅',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
