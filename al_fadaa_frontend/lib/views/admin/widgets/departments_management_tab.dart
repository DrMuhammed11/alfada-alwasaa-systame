import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../models/user_model.dart';
import 'department_form_dialog.dart';
import '../../../core/theme/app_theme.dart';

class DepartmentsManagementTab extends StatelessWidget {
  final List<Department> departments;
  final List<User> users;
  final bool isLoading;
  final VoidCallback onRefresh;

  const DepartmentsManagementTab({
    super.key,
    required this.departments,
    required this.users,
    required this.isLoading,
    required this.onRefresh,
  });

  void _openDepartmentDialog(BuildContext context, [Department? dept]) {
    showDialog(
      context: context,
      builder: (_) => DepartmentFormDialog(
        department: dept,
        availableUsers: users,
        onSaved: onRefresh,
      ),
    );
  }

  Future<void> _deleteDepartment(BuildContext context, Department dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القطاع / الإدارة'),
        content: Text('هل أنت متأكد من حذف قطاع «${dept.name}»؟ لا يمكن حذف القطاع إذا كان يحتوي على موظفين.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService().deleteDepartment(dept.id);
      if (context.mounted) {
        if (res['success'] == true) {
          onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف القطاع بنجاح'), backgroundColor: AppTheme.emerald),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'فشل حذف القطاع'), backgroundColor: AppTheme.crimson),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط العنوان وزر الإضافة
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.corporate_fare_rounded, size: 22, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'القطاعات والإدارات التنظيمية (${departments.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontMd),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('إضافة قطاع جديد'),
                onPressed: () => _openDepartmentDialog(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // قائمة القطاعات
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : departments.isEmpty
                  ? const Center(child: Text('لا توجد قطاعات مسجلة حالياً', style: TextStyle(color: AppTheme.textTertiary)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: 140,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: departments.length,
                      itemBuilder: (context, index) {
                        final dept = departments[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.borderLight),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withAlpha(15),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                    ),
                                    child: Text(
                                      dept.code,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSm, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dept.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontMd),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textTertiary),
                                    tooltip: 'تعديل القطاع',
                                    onPressed: () => _openDepartmentDialog(context, dept),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.crimson),
                                    tooltip: 'حذف القطاع',
                                    onPressed: () => _deleteDepartment(context, dept),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded, size: 16, color: AppTheme.textTertiary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dept.managerName != null ? 'المدير: ${dept.managerName}' : 'بدون مدير معين',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSm,
                                        color: dept.managerName != null ? AppTheme.secondary : AppTheme.textTertiary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    ),
                                    child: Text(
                                      '${dept.usersCount} موظف',
                                      style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
