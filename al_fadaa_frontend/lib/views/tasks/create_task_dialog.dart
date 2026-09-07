import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../models/user_model.dart';

class CreateTaskDialog extends StatefulWidget {
  final String correspondenceId;
  const CreateTaskDialog({super.key, required this.correspondenceId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  List<Department> _departments = [];
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];

  String? _selectedDeptId; // null = all
  String? _selectedUserId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  bool _isLoadingData = true;

  final List<String> _quickTemplates = [
    'معاينة وفحص الطلب فنيًا',
    'إعداد التسعيرة والعرض المالي',
    'مراجعة قانونية وصياغة رد',
    'تنفيذ وإنجاز خدمة العميل',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final depts = await ApiService().getDepartments();
    final users = await ApiService().getUsers();

    if (!mounted) return;
    setState(() {
      _departments = depts;
      _allUsers = users;
      _updateFilteredUsers();
      _isLoadingData = false;
    });
  }

  void _updateFilteredUsers() {
    if (_selectedDeptId == null || _selectedDeptId!.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((u) => u.department?.id == _selectedDeptId).toList();
      // If no users in department, fall back to all users so user is not stuck
      if (_filteredUsers.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      }
    }

    if (_filteredUsers.isNotEmpty) {
      // Keep existing selection if still valid, otherwise pick first
      if (!_filteredUsers.any((u) => u.id == _selectedUserId)) {
        _selectedUserId = _filteredUsers.first.id;
      }
    } else {
      _selectedUserId = null;
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد المسؤول أو الموظف المكلف')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService().createTask(
      widget.correspondenceId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      assignedToId: _selectedUserId!,
      dueDate: _selectedDueDate?.toIso8601String(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'فشل تكليف القطاع'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingData
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الترويسة
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.domain_add_rounded, color: Color(0xFFD97706), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تكليف قطاع / قسم بالمهمة',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'إحالة وتكليف القطاع المختص بالمعاملة حتى إنجازها ثم الرد على العميل',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 14),

                        // اختيار القطاع / الإدارة
                        DropdownButtonFormField<String?>(
                          value: _selectedDeptId,
                          decoration: InputDecoration(
                            labelText: 'القطاع / الإدارة المختصة',
                            hintText: 'اختر القطاع المعني بالمهمة',
                            prefixIcon: const Icon(Icons.business_rounded, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('جميع القطاعات والأقسام'),
                            ),
                            ..._departments.map((d) {
                              return DropdownMenuItem<String?>(
                                value: d.id,
                                child: Text(d.name),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedDeptId = v;
                              _updateFilteredUsers();
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // اختيار المسؤول أو الموظف المكلف
                        DropdownButtonFormField<String>(
                          value: _selectedUserId,
                          decoration: InputDecoration(
                            labelText: 'المسؤول / الموظف المكلف في القطاع *',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: _filteredUsers.map((u) {
                            final deptName = u.department?.name != null ? ' - ${u.department!.name}' : '';
                            return DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.fullName} (${ApiConstants.getRoleName(u.role)})$deptName'),
                            );
                          }).toList(),
                          validator: (v) => v == null ? 'يرجى اختيار الموظف أو المسؤول' : null,
                          onChanged: (v) => setState(() => _selectedUserId = v),
                        ),
                        const SizedBox(height: 14),

                        // قوالب سريعة لعنوان المهمة
                        const Text(
                          'نماذج سريعة لعنوان التكليف:',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickTemplates.map((tpl) {
                            return ActionChip(
                              label: Text(tpl, style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                setState(() {
                                  _titleController.text = tpl;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // حقل عنوان المهمة
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'عنوان المهمة المطلوب تنفيذها *',
                            hintText: 'مثال: فحص الطلب وإعداد العرض الفني للعميل',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال عنوان المهمة' : null,
                        ),
                        const SizedBox(height: 14),

                        // تفاصيل واشتراطات المهمة
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'تفاصيل واشتراطات التكليف (اختياري)',
                            hintText: 'اكتب التوجيهات أو الملاحظات التي يحتاجها القطاع لإنجاز العمل...',
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // موعد الإنجاز المتوقع
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickDueDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(
                                _selectedDueDate != null
                                    ? 'الموعد: ${_selectedDueDate!.year}/${_selectedDueDate!.month}/${_selectedDueDate!.day}'
                                    : 'تحديد موعد متوقع للإنجاز (اختياري)',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                            if (_selectedDueDate != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                                tooltip: 'إلغاء الموعد',
                                onPressed: () => setState(() => _selectedDueDate = null),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 22),

                        // زر التأكيد
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.assignment_turned_in_rounded, size: 18),
                            label: const Text(
                              'تكليف القطاع والبدء بالمعالجة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
