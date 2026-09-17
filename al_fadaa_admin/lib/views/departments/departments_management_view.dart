import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_user_model.dart';
import 'department_dialog.dart';

class DepartmentsManagementView extends StatefulWidget {
  const DepartmentsManagementView({super.key});

  @override
  State<DepartmentsManagementView> createState() => _DepartmentsManagementViewState();
}

class _DepartmentsManagementViewState extends State<DepartmentsManagementView> {
  List<Department> _departments = [];
  List<AdminUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final depts = await AdminApiService().getDepartments();
    final users = await AdminApiService().getUsers();
    if (mounted) {
      setState(() {
        _departments = depts;
        _users = users;
        _isLoading = false;
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
      builder: (_) => DepartmentDialog(departmentToEdit: dept, users: _users),
    );
    if (res == true) _loadData();
  }

  Future<void> _confirmDelete(Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف القسم'),
        content: Text('هل أنت متأكد من حذف القسم "${dept.name}"؟'),
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

    if (confirmed == true) {
      final success = await AdminApiService().deleteDepartment(dept.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف القسم بنجاح')));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف القسم (قد يحتوي على مستخدمين أو معاملات)'), backgroundColor: AdminTheme.crimson),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // شريط الرأس وزر الإضافة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.corporate_fare_rounded, color: AdminTheme.accent, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'الهيكل التنظيمي والأقسام',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: Text('${_departments.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة قسم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // قائمة أو شبكة الأقسام
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _departments.isEmpty
                    ? const Center(child: Text('لا توجد أقسام مسجلة', style: TextStyle(color: AdminTheme.textMuted)))
                    : LayoutBuilder(
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
                              childAspectRatio: constraints.maxWidth >= 600 ? 1.7 : 2.2,
                            ),
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final d = _departments[index];
                              return _buildDepartmentCard(d);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Department d) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // العنوان والكود وزر التعديل
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AdminTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AdminTheme.accent),
                  onPressed: () => _openEditDialog(d),
                  tooltip: 'تعديل',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AdminTheme.crimson),
                  onPressed: () => _confirmDelete(d),
                  tooltip: 'حذف',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // المدير المعين
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 15, color: AdminTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    d.managerName != null ? 'المدير: ${d.managerName}' : 'بدون مدير معين',
                    style: TextStyle(
                      fontSize: 12,
                      color: d.managerName != null ? const Color(0xFF334155) : AdminTheme.textMuted,
                      fontStyle: d.managerName == null ? FontStyle.italic : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // إحصائيات سريعة للقسم
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 14, color: AdminTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${d.usersCount} موظف', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
                  Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 14, color: AdminTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${d.correspondencesCount} معاملة', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
