import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../dialogs/workflow_steps_dialog.dart';
class WorkflowsTab extends StatefulWidget {
  const WorkflowsTab({super.key});
  @override
  State<WorkflowsTab> createState() => WorkflowsTabState();
}

class WorkflowsTabState extends State<WorkflowsTab> with AutomaticKeepAliveClientMixin {
  static const _priorities = {
    'URGENT': 'عاجلة للغاية',
    'HIGH': 'عالية',
    'NORMAL': 'اعتيادية',
    'LOW': 'منخفضة',
  };
  static const _roles = {
    'DEPT_MANAGER': 'مدير قسم',
    'DEPUTY_GM': 'نائب المدير العام',
    'GM': 'المدير العام',
    'ADMIN': 'مدير النظام',
  };
  List<Map<String, dynamic>> _flows = [];
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
    final res = await AdminApiService().getWorkflows();
    if (!mounted) return;
    setState(() {
      _flows = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _edit(Map<String, dynamic> flow) async {
    final priority = (flow['priority'] ?? 'NORMAL').toString();
    final existing = ((flow['steps'] as List?) ?? [])
        .map((s) => (s is Map ? s : Map<String, dynamic>.from(s))['requiredRole'].toString())
        .toList();

    final steps = await showDialog<List<String>>(
      context: context,
      builder: (_) => WorkflowStepsDialog(
        priorityLabel: _priorities[priority] ?? priority,
        initialSteps: existing,
      ),
    );
    if (steps == null || !mounted) return;

    final res = await AdminApiService().updateWorkflow(priority, [
      for (var i = 0; i < steps.length; i++)
        {'level': '${i + 1}', 'requiredRole': steps[i]},
    ]);
    if (!mounted) return;
    final error = res?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم تحديث مسار الاعتماد بنجاح'),
      backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
    ));
    if (error == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل مسارات الاعتماد...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل مسارات الاعتماد',
        onRetry: _load,
      );
    }
    // حالة الفراغ — ودجة موحدة
    if (_flows.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد مسارات اعتماد معرّفة',
        icon: Icons.fact_check_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بانر توضيحي لمسارات الاعتماد
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceInfo,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: AdminTheme.borderInfo),
          ),
          child: const Text(
            'مسار الاعتماد يحدد مستويات الموافقة الإلزامية قبل إرسال الرد، حسب درجة أولوية المراسلة. التعديل يسري على الردود المرفوعة لاحقًا فقط.',
            style: TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.accent),
          ),
        ),
        const SizedBox(height: 12),
        ..._flows.map((flow) {
          final priority = (flow['priority'] ?? '').toString();
          final steps = ((flow['steps'] as List?) ?? []);
          // لون شارة الأولوية
          final priorityColor = priority == 'URGENT'
              ? AdminTheme.crimson
              : (priority == 'HIGH' ? AdminTheme.amber : AdminTheme.accent);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(color: AdminTheme.border),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: Row(
              children: [
                // شارة الأولوية — StatusBadge من app_utils
                StatusBadge(
                  text: _priorities[priority] ?? priority,
                  color: priorityColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps.isEmpty
                        ? 'بدون خطوات'
                        : steps.asMap().entries.map((e) {
                            final s = (e.value is Map
                                ? e.value
                                : Map<String, dynamic>.from(e.value));
                            return 'م${e.key + 1}: ${_roles[s['requiredRole']] ?? s['requiredRole']}';
                          }).join(' ← '),
                    style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.borderDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 17, color: AdminTheme.accent),
                  tooltip: 'تعديل',
                  onPressed: () => _edit(flow),
                ),
              ],
            ),
          );
        }),
      ],
        ),
    );
  }
}

