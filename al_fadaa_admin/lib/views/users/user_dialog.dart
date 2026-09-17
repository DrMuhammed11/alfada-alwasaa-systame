import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_user_model.dart';

class UserDialog extends StatefulWidget {
  final AdminUser? userToEdit;
  final List<Department> departments;

  const UserDialog({
    super.key,
    this.userToEdit,
    required this.departments,
  });

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  late String _role;
  String? _departmentId;
  late bool _isActive;
  late Set<String> _permissions;
  bool _isSaving = false;

  final List<Map<String, String>> _availablePermissions = [
    {'key': 'CORRESPONDENCE_CREATE', 'name': 'إنشاء المراسلات والوارد'},
    {'key': 'CORRESPONDENCE_VIEW', 'name': 'استعراض وقراءة المعاملات'},
    {'key': 'CORRESPONDENCE_EDIT', 'name': 'تعديل المعاملات'},
    {'key': 'REFERRAL_CREATE', 'name': 'إحالة وتوجيه المعاملات'},
    {'key': 'TASK_CREATE', 'name': 'إسناد وتكليف المهام'},
    {'key': 'TASK_COMPLETE', 'name': 'إنجاز واعتماد المهام'},
    {'key': 'REPLY_CREATE', 'name': 'صياغة وإعداد الردود'},
    {'key': 'REPLY_APPROVE', 'name': 'اعتماد ومصادقة الردود'},
    {'key': 'ARCHIVE_ACCESS', 'name': 'أرشفة واسترجاع الأرشيف'},
    {'key': 'AUDIT_VIEW', 'name': 'الاطلاع على سجلات التدقيق والأمان'},
    {'key': 'USER_MANAGE', 'name': 'إدارة الموظفين وتعديل الصلاحيات'},
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'EMPLOYEE';
    _departmentId = u?.departmentId;
    _isActive = u?.isActive ?? true;
    _permissions = u != null ? Set.from(u.permissions) : {'CORRESPONDENCE_VIEW', 'CORRESPONDENCE_CREATE'};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final isEdit = widget.userToEdit != null;

    Map<String, dynamic> res;
    if (isEdit) {
      res = await AdminApiService().updateUser(
        widget.userToEdit!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        departmentId: _departmentId ?? 'NONE',
        isActive: _isActive,
        permissions: _permissions.toList(),
      );
    } else {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور مطلوبة لإضافة موظف جديد')),
        );
        setState(() => _isSaving = false);
        return;
      }
      res = await AdminApiService().createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        departmentId: _departmentId,
        permissions: _permissions.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشلت العملية'), backgroundColor: AdminTheme.crimson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.userToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                    color: AdminTheme.accent,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'تعديل بيانات وصلاحيات الموظف' : 'إضافة موظف ومستخدم جديد',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم الكامل
                      const Text('الاسم الكامل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'مثال: م. أحمد محمد',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 14),

                      // البريد الإلكتروني
                      const Text('البريد الإلكتروني', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'name@al-fadaa.com',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || !v.contains('@') ? 'البريد الإلكتروني غير صالح' : null,
                      ),
                      const SizedBox(height: 14),

                      // كلمة المرور
                      if (!isEdit) ...[
                        const Text('كلمة المرور الابتدائية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'كلمة مرور قوية (8 خانات على الأقل)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // الصف: الدور الوظيفي + القسم
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المسمى / الدور الوظيفي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _role,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'ADMIN', child: Text('مدير النظام (Admin)')),
                                    DropdownMenuItem(value: 'GM', child: Text('المدير العام (GM)')),
                                    DropdownMenuItem(value: 'DEPUTY_GM', child: Text('نائب المدير العام')),
                                    DropdownMenuItem(value: 'DEPT_MANAGER', child: Text('مدير إدارة / قطاع')),
                                    DropdownMenuItem(value: 'EMPLOYEE', child: Text('موظف تنفيذي')),
                                  ],
                                  onChanged: (val) => setState(() => _role = val ?? 'EMPLOYEE'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('القسم / الإدارة التابع لها', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String?>(
                                  value: _departmentId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('بدون قسم محدد')),
                                    ...widget.departments.map(
                                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                                    ),
                                  ],
                                  onChanged: (val) => setState(() => _departmentId = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // حالة الحساب (نشط / معطل)
                      if (isEdit) ...[
                        SwitchListTile(
                          title: const Text('حساب نشط ومفعل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('يمكن للحساب تسجيل الدخول واستقبال التكليفات', style: TextStyle(fontSize: 11)),
                          value: _isActive,
                          activeColor: AdminTheme.emerald,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // الصلاحيات الدقيقة
                      const Text('الصلاحيات الدقيقة الممنوحة (Granular Permissions)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: _availablePermissions.map((perm) {
                            final isChecked = _permissions.contains(perm['key']);
                            return FilterChip(
                              label: Text(perm['name']!, style: const TextStyle(fontSize: 11)),
                              selected: isChecked,
                              selectedColor: AdminTheme.accent.withAlpha(30),
                              checkmarkColor: AdminTheme.accent,
                              labelStyle: TextStyle(
                                color: isChecked ? AdminTheme.accent : const Color(0xFF475569),
                                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _permissions.add(perm['key']!);
                                  } else {
                                    _permissions.remove(perm['key']!);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // أزرار الحفظ والإلغاء
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة المستخدم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
