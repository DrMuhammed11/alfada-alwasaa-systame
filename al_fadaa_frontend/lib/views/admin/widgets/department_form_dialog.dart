import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../models/user_model.dart';

class DepartmentFormDialog extends StatefulWidget {
  final Department? department;
  final List<User> availableUsers;
  final VoidCallback onSaved;

  const DepartmentFormDialog({
    super.key,
    this.department,
    required this.availableUsers,
    required this.onSaved,
  });

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  String? _selectedManagerId;
  bool _isLoading = false;

  bool get isEdit => widget.department != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name ?? '');
    _codeController = TextEditingController(text: widget.department?.code ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final code = _codeController.text.trim().toUpperCase();

      final res = isEdit
          ? await ApiService().updateDepartment(
              widget.department!.id,
              name: name,
              code: code,
              managerId: _selectedManagerId,
            )
          : await ApiService().createDepartment(
              name: name,
              code: code,
              managerId: _selectedManagerId,
            );

      if (mounted) {
        if (res['success'] == true) {
          Navigator.pop(context);
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'تم تحديث بيانات القطاع بنجاح' : 'تمت إضافة القطاع بنجاح'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'فشلت العملية'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded, color: const Color(0xFF0F172A)),
          const SizedBox(width: 8),
          Text(isEdit ? 'تعديل بيانات القطاع' : 'إضافة قطاع / قسم جديد', style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القطاع / الإدارة *',
                  hintText: 'مثال: القسم الهندسي، إدارة العمليات',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.corporate_fare_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم القطاع' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'رمز القطاع (باللغة الإنجليزية) *',
                  hintText: 'مثال: ENG, OPS, FIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال رمز القطاع' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedManagerId,
                decoration: const InputDecoration(
                  labelText: 'مدير القطاع (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_pin_rounded),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('بدون تعيين مدير حالياً', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                  ...widget.availableUsers.map((u) => DropdownMenuItem<String>(
                        value: u.id,
                        child: Text('${u.fullName} (${u.role})'),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedManagerId = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'حفظ التعديلات' : 'إضافة القطاع'),
        ),
      ],
    );
  }
}
