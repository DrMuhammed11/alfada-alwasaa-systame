import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/admin_user_model.dart';
import 'department_dialog.dart';

class DepartmentsManagementView extends StatefulWidget {
  const DepartmentsManagementView({super.key});

  @override
  State<DepartmentsManagementView> createState() =>
      _DepartmentsManagementViewState();
}

class _DepartmentsManagementViewState
    extends State<DepartmentsManagementView> {
  List<Department> _departments = [];
  List<AdminUser> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';

  List<Department> get _filteredDepts => _searchQuery.isEmpty
      ? _departments
      : _departments
          .where((d) =>
              d.name.contains(_searchQuery) ||
              d.code.contains(_searchQuery.toUpperCase()))
          .toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    // شاشة الإدارة نفسها: تجاوز الكاش دائماً لتظهر التعديلات فوراً
    final deptsRes = await AdminApiService().getDepartments(forceRefresh: true);
    // قائمة الموظفين لاختيار مدير القسم — صفحة موسعة لأنها قائمة دعم
    final usersRes = await AdminApiService().getUsers(page: 1, limit: 200);
    if (mounted) {
      setState(() {
        _departments = deptsRes.items;
        _users = usersRes.items;
        _isLoading = false;
        _hasError = deptsRes.error || usersRes.error;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => DepartmentDialog(users: _users),
    );
    if (res == true) _loadData();
  }

  Future<void> _openEditDialog(Department dept) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) =>
          DepartmentDialog(departmentToEdit: dept, users: _users),
    );
    if (res == true) _loadData();
  }

  Future<void> _confirmDeleteDept(Department dept) async {
    final confirmed = await AppUtils.confirmDelete(
      context,
      title: 'تأكيد حذف القسم',
      message:
          'هل أنت متأكد من حذف القسم \u00ab${dept.name}\u00bb\u061f\nقد يفشل الحذف إذا كان يحتوي على مستخدمين أو معاملات.',
    );
    if (!confirmed || !mounted) return;

    final success = await AdminApiService().deleteDepartment(dept.id);
    if (!mounted) return;
    if (success) {
      AppUtils.showSuccess(context, 'تم حذف القسم بنجاح');
      _loadData();
    } else {
      AppUtils.showError(
          context, 'فشل الحذف (قد يحتوي على مستخدمين أو معاملات)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.corporate_fare_rounded,
                  color: AdminTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text('الهيكل التنظيمي والأقسام',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(AdminTheme.radiusSm),
                ),
                child: Text(
                  '${_departments.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.accent),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add_business_rounded, size: 16),
                label: const Text('إضافة قسم',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: const InputDecoration(
              hintText: 'ابحث باسم القسم أو الكود...',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'جاري تحميل بيانات الأقسام...');
    }
    // حالة الخطأ — تمييز فشل الطلب عن غياب النتائج
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل بيانات الأقسام',
        onRetry: _loadData,
      );
    }
    final depts = _filteredDepts;
    if (depts.isEmpty) {
      return EmptyStateWidget(
        message: _departments.isEmpty
            ? 'لا توجد أقسام مسجلة'
            : 'لا توجد أقسام مطابقة للبحث',
        icon: Icons.corporate_fare_rounded,
        actionLabel: _searchQuery.isNotEmpty ? 'مسح البحث' : null,
        onAction: _searchQuery.isNotEmpty
            ? () => setState(() => _searchQuery = '')
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AdminTheme.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900
              ? 3
              : (constraints.maxWidth >= 600 ? 2 : 1);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio:
                  constraints.maxWidth >= 600 ? 1.8 : 2.4,
            ),
            itemCount: depts.length,
            itemBuilder: (context, index) =>
                _buildDepartmentCard(depts[index]),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentCard(Department d) {
    final colorIndex = d.code.hashCode % 4;
    final colors = [
      AdminTheme.accent, AdminTheme.purple,
      AdminTheme.emerald, AdminTheme.amber,
    ];
    final cardColor = colors[colorIndex.abs()];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AdminTheme.radiusMd)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(
                              AdminTheme.radiusXs),
                        ),
                        child: Text(
                          d.code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: cardColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: AdminTheme.accent),
                        onPressed: () => _openEditDialog(d),
                        tooltip: 'تعديل',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AdminTheme.crimson),
                        onPressed: () => _confirmDeleteDept(d),
                        tooltip: 'حذف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        d.managerName != null
                            ? Icons.person_pin_rounded
                            : Icons.person_off_outlined,
                        size: 13,
                        color: AdminTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          d.managerName != null
                              ? 'المدير: ${d.managerName}'
                              : 'بدون مدير معيّن',
                          style: TextStyle(
                            fontSize: 11,
                            color: d.managerName != null
                                ? AdminTheme.textMuted
                                : AdminTheme.crimson,
                            fontStyle: d.managerName == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _statChip(
                        Icons.people_alt_outlined,
                        '${d.usersCount} موظف',
                        AdminTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.mark_email_read_outlined,
                        '${d.correspondencesCount} معاملة',
                        AdminTheme.emerald,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}
