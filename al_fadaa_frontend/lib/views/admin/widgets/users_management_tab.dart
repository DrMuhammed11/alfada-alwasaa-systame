import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../models/user_model.dart';
import 'user_form_dialog.dart';
import '../../../core/theme/app_theme.dart';

class UsersManagementTab extends StatefulWidget {
  final List<Department> departments;
  final VoidCallback onDataChanged;

  const UsersManagementTab({
    super.key,
    required this.departments,
    required this.onDataChanged,
  });

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  List<User> _users = [];
  bool _isLoading = true;
  String _search = '';
  String _selectedRole = 'ALL';
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getUsersPaginated(
        role: _selectedRole != 'ALL' ? _selectedRole : null,
        departmentId: _selectedDeptId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _users = res['data'] as List<User>;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openUserDialog([User? user]) {
    showDialog(
      context: context,
      builder: (_) => UserFormDialog(
        user: user,
        departments: widget.departments,
        onSaved: () {
          _fetchUsers();
          widget.onDataChanged();
        },
      ),
    );
  }

  Future<void> _toggleDeactivate(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isActive ? 'تعطيل حساب الموظف' : 'تفعيل حساب الموظف'),
        content: Text(user.isActive
            ? 'هل أنت متأكد من تعطيل حساب ${user.fullName}؟ لن يتمكن من تسجيل الدخول حتى إعادة تفعيله.'
            : 'هل تريد إعادة تفعيل حساب ${user.fullName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? AppTheme.crimson : AppTheme.emerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService().updateUser(user.id, isActive: !user.isActive);
      if (res['success'] == true) {
        _fetchUsers();
        widget.onDataChanged();
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppTheme.crimson;
      case 'GM': return const Color(0xFF7C3AED);
      case 'DEPUTY_GM': return AppTheme.info;
      case 'DEPT_MANAGER': return AppTheme.emerald;
      default: return AppTheme.textTertiary;
    }
  }

  String _getRoleArabic(String role) {
    switch (role) {
      case 'ADMIN': return 'مسؤول النظام';
      case 'GM': return 'المدير العام';
      case 'DEPUTY_GM': return 'نائب المدير العام';
      case 'DEPT_MANAGER': return 'مدير قطاع';
      default: return 'موظف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final match = u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.employeeNumber != null && u.employeeNumber!.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // شريط التحكم والبحث وإضافة موظف
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، البريد، أو الرقم الوظيفي...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('جميع الأدوار')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('مسؤولو النظام')),
                    DropdownMenuItem(value: 'GM', child: Text('المدير العام')),
                    DropdownMenuItem(value: 'DEPUTY_GM', child: Text('نواب المدير العام')),
                    DropdownMenuItem(value: 'DEPT_MANAGER', child: Text('مدراء القطاعات')),
                    DropdownMenuItem(value: 'EMPLOYEE', child: Text('الموظفون')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                      _fetchUsers();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('إضافة موظف جديد'),
                onPressed: () => _openUserDialog(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // قائمة الموظفين
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('لا يوجد موظفون مطابقون للشروط', style: TextStyle(color: AppTheme.textTertiary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final roleColor = _getRoleColor(user.role);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: roleColor.withAlpha(25),
                                child: Text(
                                  user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: AppTheme.fontLg),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontMd)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withAlpha(20),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                            border: Border.all(color: roleColor.withAlpha(60)),
                                          ),
                                          child: Text(_getRoleArabic(user.role),
                                              style: TextStyle(color: roleColor, fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold)),
                                        ),
                                        if (user.employeeNumber != null) ...[
                                          const SizedBox(width: 8),
                                          Text('#${user.employeeNumber}', style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary)),
                                        ],
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user.isActive ? AppTheme.surfaceSuccess : AppTheme.surfaceDanger,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                          ),
                                          child: Text(
                                            user.isActive ? 'نشط' : 'معطل',
                                            style: TextStyle(
                                              color: user.isActive ? AppTheme.emerald : AppTheme.crimson,
                                              fontSize: AppTheme.fontXs,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(user.email, style: TextStyle(fontSize: AppTheme.fontSm, color: Colors.grey.shade600)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.corporate_fare_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(user.department?.name ?? 'بدون قطاع', style: TextStyle(fontSize: AppTheme.fontSm, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.manage_accounts_rounded, size: 20, color: AppTheme.info),
                                    tooltip: 'تعديل الدور والصلاحيات والبيانات',
                                    onPressed: () => _openUserDialog(user),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                      size: 20,
                                      color: user.isActive ? AppTheme.crimson : AppTheme.emerald,
                                    ),
                                    tooltip: user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                                    onPressed: () => _toggleDeactivate(user),
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
