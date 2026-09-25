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
  bool _isSaving = false;

  /// سياسة كلمة المرور مطابقة لتحقق الخادم: 10 خانات فأكثر مع حرف كبير وصغير ورقم ورمز
  String? _validatePassword(String? v) {
    final password = v ?? '';
    if (password.isEmpty) return null; // اختياري (في التعديل)
    if (password.length < 10) return 'كلمة المرور 10 خانات فأكثر';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'يلزم حرف لاتيني كبير (A-Z)';
    if (!password.contains(RegExp(r'[a-z]'))) return 'يلزم حرف لاتيني صغير (a-z)';
    if (!password.contains(RegExp(r'[0-9]'))) return 'يلزم رقم (0-9)';
    if (!password.contains(RegExp(r'[^A-Za-z0-9]'))) return 'يلزم رمز خاص مثل !@#';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _nameController = TextEditingController(text: u?.name ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _role = u?.role ?? 'EMPLOYEE';
    _departmentId = u?.departmentId;
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _errorMessageOf(Map<String, dynamic> res) {
    final msg = res['message'];
    if (msg is List) return msg.join(' — ');
    if (msg != null) return msg.toString();
    return 'فشلت العملية';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final isEdit = widget.userToEdit != null;
    final newPassword = _passwordController.text;

    Map<String, dynamic> res;
    if (isEdit) {
      // إعادة تعيين كلمة المرور اختيارية في التعديل — تُرسل فقط عند إدخالها
      res = await AdminApiService().updateUser(
        widget.userToEdit!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        departmentId: _departmentId ?? 'NONE',
        isActive: _isActive,
        password: newPassword.isEmpty ? null : newPassword,
      );
    } else {
      res = await AdminApiService().createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: newPassword,
        role: _role,
        departmentId: _departmentId,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessageOf(res)), backgroundColor: AdminTheme.crimson),
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
                    isEdit ? 'تعديل بيانات الموظف' : 'إضافة موظف ومستخدم جديد',
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
                      Text(
                        isEdit ? 'إعادة تعيين كلمة المرور (اختياري)' : 'كلمة المرور الابتدائية',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: isEdit ? _validatePassword : (v) => _validatePassword(v) ?? ((v ?? '').isEmpty ? 'كلمة المرور مطلوبة' : null),
                        decoration: InputDecoration(
                          hintText: isEdit ? 'اتركه فارغًا للإبقاء على كلمة المرور الحالية' : '10 خانات فأكثر مع حرف كبير وصغير ورقم ورمز',
                          helperText: 'الصلاحيات مشتقة تلقائيًا من الدور الوظيفي — تُدار من مصفوفة الصلاحيات المركزية',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),

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
                          subtitle: const Text('التعطيل يُبطل جلسات المستخدم فورًا', style: TextStyle(fontSize: 11)),
                          value: _isActive,
                          activeColor: AdminTheme.emerald,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                        const SizedBox(height: 14),
                      ],
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
