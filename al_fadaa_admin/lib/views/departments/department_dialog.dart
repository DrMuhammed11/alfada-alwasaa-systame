import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_user_model.dart';

class DepartmentDialog extends StatefulWidget {
  final Department? departmentToEdit;
  final List<AdminUser> users;

  const DepartmentDialog({
    super.key,
    this.departmentToEdit,
    required this.users,
  });

  @override
  State<DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  String? _managerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.departmentToEdit;
    _nameController = TextEditingController(text: d?.name ?? '');
    _codeController = TextEditingController(text: d?.code ?? '');
    _managerId = d?.managerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final isEdit = widget.departmentToEdit != null;

    Map<String, dynamic> res;
    if (isEdit) {
      res = await AdminApiService().updateDepartment(
        widget.departmentToEdit!.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        managerId: _managerId ?? 'NONE',
      );
    } else {
      res = await AdminApiService().createDepartment(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        managerId: _managerId,
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
    final isEdit = widget.departmentToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded,
                    color: AdminTheme.accent,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'تعديل بيانات القسم والقطاع' : 'إضافة قسم / قطاع جديد',
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

              // اسم القسم
              const Text('اسم القسم / الإدارة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'مثال: إدارة الشؤون القانونية',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم القسم مطلوب' : null,
              ),
              const SizedBox(height: 14),

              // كود القسم
              const Text('رمز القسم (Code)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'مثال: LEGAL أو FIN أو HR',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'رمز القسم مطلوب' : null,
              ),
              const SizedBox(height: 14),

              // تعيين مدير القسم
              const Text('مدير القسم المعين', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                value: _managerId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('بدون مدير معين')),
                  ...widget.users.map(
                    (u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.email})')),
                  ),
                ],
                onChanged: (val) => setState(() => _managerId = val),
              ),
              const SizedBox(height: 24),

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
                    label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة القسم'),
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
