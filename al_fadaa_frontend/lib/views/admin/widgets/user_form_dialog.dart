import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../models/user_model.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;
  final List<Department> departments;
  final VoidCallback onSaved;

  const UserFormDialog({
    super.key,
    this.user,
    required this.departments,
    required this.onSaved,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _empNumberCtrl;
  late String _selectedRole;
  String? _selectedDeptId;
  late bool _isActive;
  bool _isLoading = false;

  bool get isEdit => widget.user != null;

  static const Map<String, List<String>> rolePermissions = {
    'ADMIN': ['إدارة الموظفين والحسابات', 'إدارة القطاعات والأقسام', 'سجل التدقيق والأمان', 'الاطلاع على جميع المراسلات'],
    'GM': ['الاعتماد النهائي للمراسلات', 'إرسال الردود الرسمية للعملاء', 'إحالة وتكليف القطاعات', 'إدارة الموظفين والقطاعات', 'الاطلاع الشامل وسجل التدقيق'],
    'DEPUTY_GM': ['اعتماد الردود بتفويض الإدارة', 'إرسال الردود بالتوكيل', 'إحالة المراسلات وتكليف الموظفين', 'الاطلاع على جميع المراسلات'],
    'DEPT_MANAGER': ['تكليف موظفي القطاع بالمهام', 'إحالة المعاملات داخلياً', 'مراجعة مسودات الردود', 'متابعة إنجاز مهام القطاع'],
    'EMPLOYEE': ['إعداد وصياغة مسودات الردود', 'رفع الردود للاعتماد', 'تنفيذ المهام والتكليفات المسندة'],
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _passwordCtrl = TextEditingController();
    _jobTitleCtrl = TextEditingController();
    _empNumberCtrl = TextEditingController(text: widget.user?.employeeNumber ?? '');
    _selectedRole = widget.user?.role ?? 'EMPLOYEE';
    _selectedDeptId = widget.user?.department?.id;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _jobTitleCtrl.dispose();
    _empNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final jobTitle = _jobTitleCtrl.text.trim();
      final empNumber = _empNumberCtrl.text.trim();

      final res = isEdit
          ? await ApiService().updateUser(
              widget.user!.id,
              name: name,
              email: email,
              password: password.isNotEmpty ? password : null,
              role: _selectedRole,
              departmentId: _selectedDeptId,
              jobTitle: jobTitle.isNotEmpty ? jobTitle : null,
              employeeNumber: empNumber.isNotEmpty ? empNumber : null,
              isActive: _isActive,
            )
          : await ApiService().createUser(
              name: name,
              email: email,
              password: password,
              role: _selectedRole,
              departmentId: _selectedDeptId,
              jobTitle: jobTitle.isNotEmpty ? jobTitle : null,
              employeeNumber: empNumber.isNotEmpty ? empNumber : null,
            );

      if (mounted) {
        if (res['success'] == true) {
          Navigator.pop(context);
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'تم تحديث بيانات وصلاحيات الموظف' : 'تمت إضافة الموظف بنجاح'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'فشلت العملية'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = rolePermissions[_selectedRole] ?? [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEdit ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded, color: const Color(0xFF0F172A)),
          const SizedBox(width: 8),
          Text(isEdit ? 'تعديل بيانات وصلاحيات الموظف' : 'إضافة موظف جديد وتعيين صلاحياته', style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم الكامل *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _empNumberCtrl,
                        decoration: const InputDecoration(labelText: 'الرقم الوظيفي', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني المؤسسي *', border: OutlineInputBorder()),
                        validator: (v) => v == null || !v.contains('@') ? 'بريد غير صالح' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit ? 'كلمة المرور (اتركها فارغة للإبقاء)' : 'كلمة المرور المؤقتة *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (!isEdit && (v == null || v.length < 6)) ? '6 أحرف على الأقل' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'الدور المؤسسي والصلاحية *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'EMPLOYEE', child: Text('موظف (EMPLOYEE)')),
                          DropdownMenuItem(value: 'DEPT_MANAGER', child: Text('مدير قسم/قطاع (DEPT_MANAGER)')),
                          DropdownMenuItem(value: 'DEPUTY_GM', child: Text('نائب المدير العام (DEPUTY_GM)')),
                          DropdownMenuItem(value: 'GM', child: Text('المدير العام (GM)')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('مسؤول النظام (ADMIN)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDeptId,
                        decoration: const InputDecoration(labelText: 'القطاع / القسم', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون قطاع محدد')),
                          ...widget.departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedDeptId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // معاينة الصلاحيات الممنوحة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF0F172A)),
                          const SizedBox(width: 6),
                          Text('الصلاحيات الممنوحة لدور ($_selectedRole):',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: permissions
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                      const SizedBox(width: 4),
                                      Text(p, style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('حالة الحساب نشط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(_isActive ? 'الحساب مفعّل ويمكنه تسجيل الدخول' : 'الحساب معطّل مؤقتًا', style: const TextStyle(fontSize: 11)),
                    value: _isActive,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'حفظ الصلاحيات والبيانات' : 'إضافة الموظف ومنح الصلاحيات'),
        ),
      ],
    );
  }
}
