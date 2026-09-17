import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_user_model.dart';
import 'user_dialog.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  final _searchController = TextEditingController();
  List<AdminUser> _users = [];
  List<Department> _departments = [];
  bool _isLoading = true;

  String _selectedRole = 'ALL';
  String _selectedDepartmentId = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final depts = await AdminApiService().getDepartments();
    final users = await AdminApiService().getUsers(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      role: _selectedRole,
      departmentId: _selectedDepartmentId,
    );

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
      builder: (_) => UserDialog(departments: _departments),
    );
    if (res == true) _loadData();
  }

  Future<void> _openEditDialog(AdminUser user) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => UserDialog(userToEdit: user, departments: _departments),
    );
    if (res == true) _loadData();
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف الحساب "${user.name}"؟ لا يمكن التراجع عن هذا الإجراء.'),
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
      final success = await AdminApiService().deleteUser(user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم بنجاح')));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف المستخدم'), backgroundColor: AdminTheme.crimson),
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
          // شريط العمليات والبحث العلوي
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // حقل البحث النصي
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ابحث بالاسم أو البريد الإلكتروني...',
                            hintStyle: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          onSubmitted: (_) => _loadData(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _loadData,
                      tooltip: 'بحث',
                    ),
                    const SizedBox(width: 8),
                    // زر إضافة مستخدم
                    ElevatedButton.icon(
                      onPressed: _openCreateDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('إضافة موظف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // فلاتر المسمى والقسم
                Row(
                  children: [
                    // فلتر الدور
                    _buildFilterDropdown(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('كافة الأدوار')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('مدير النظام')),
                        DropdownMenuItem(value: 'GM', child: Text('المدير العام')),
                        DropdownMenuItem(value: 'DEPT_MANAGER', child: Text('مدراء الإدارات')),
                        DropdownMenuItem(value: 'EMPLOYEE', child: Text('الموظفون')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRole = val);
                          _loadData();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // فلتر القسم
                    _buildFilterDropdown(
                      value: _selectedDepartmentId,
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('كافة الأقسام')),
                        ..._departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDepartmentId = val);
                          _loadData();
                        }
                      },
                    ),
                    const Spacer(),
                    Text('العدد: ${_users.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المستخدمين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('لا يوجد موظفون مطابقون لمعايير البحث', style: TextStyle(color: AdminTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          return _buildUserCard(u);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser u) {
    Color roleColor;
    switch (u.role.toUpperCase()) {
      case 'ADMIN':
        roleColor = AdminTheme.crimson;
        break;
      case 'GM':
      case 'DEPUTY_GM':
        roleColor = AdminTheme.purple;
        break;
      case 'DEPT_MANAGER':
        roleColor = AdminTheme.accent;
        break;
      default:
        roleColor = AdminTheme.textMuted;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // الأيقونة أو الصورة الرمزية
            CircleAvatar(
              backgroundColor: roleColor.withAlpha(25),
              child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : '؟',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),

            // البيانات الرئيسية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      // شارة الدور
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ApiConstants.getRoleName(u.role),
                          style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // حالة الحساب
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (u.isActive ? AdminTheme.emerald : AdminTheme.crimson).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          u.isActive ? 'مفعل' : 'معطل',
                          style: TextStyle(
                            color: u.isActive ? AdminTheme.emerald : AdminTheme.crimson,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(u.email, style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (u.department != null) ...[
                        const Icon(Icons.apartment_rounded, size: 13, color: AdminTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(u.department!.name, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.vpn_key_rounded, size: 13, color: AdminTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${u.permissions.length} صلاحيات', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    ],
                  ),
                ],
              ),
            ),

            // أزرار العمليات
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AdminTheme.accent),
              tooltip: 'تعديل الصلاحيات',
              onPressed: () => _openEditDialog(u),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AdminTheme.crimson),
              tooltip: 'حذف',
              onPressed: () => _confirmDelete(u),
            ),
          ],
        ),
      ),
    );
  }
}
