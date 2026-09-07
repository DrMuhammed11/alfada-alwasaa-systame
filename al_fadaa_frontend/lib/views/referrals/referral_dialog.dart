import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../models/user_model.dart';

class ReferralDialog extends StatefulWidget {
  final String correspondenceId;
  const ReferralDialog({super.key, required this.correspondenceId});

  @override
  State<ReferralDialog> createState() => _ReferralDialogState();
}

class _ReferralDialogState extends State<ReferralDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  String? _selectedUserId;
  DateTime? _dueDate;
  List<User> _users = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService().getUsers();
    setState(() {
      _users = users.where((u) => u.isActive && (u.role == 'DEPUTY_GM' || u.role == 'DEPT_MANAGER')).toList();
      if (_users.isEmpty) {
        // إذا لم يكن هناك مدراء محددين، نعرض كل المستخدمين النشطين كإجراء بديل
        _users = users.where((u) => u.isActive).toList();
      }
      if (_users.isNotEmpty) {
        _selectedUserId = _users.first.id;
      }
      _isLoadingUsers = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المسؤول المحال إليه')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService().referCorrespondence(
      widget.correspondenceId,
      toUserId: _selectedUserId!,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      dueDate: _dueDate?.toIso8601String(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل إجراء الإحالة')),
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ترويسة
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF7C3AED), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إحالة وتوجيه المراسلة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'إحالة المراسلة لنائب المدير العام أو مدير الإدارة المختصة',
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
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  if (_isLoadingUsers)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedUserId,
                      decoration: const InputDecoration(labelText: 'المحال إليه (المسؤول / المدير) *'),
                      items: _users.map((u) {
                        final dept = u.department != null ? ' - ${u.department!.name}' : '';
                        return DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.fullName} (${ApiConstants.getRoleName(u.role)}$dept)'),
                        );
                      }).toList(),
                      validator: (v) => v == null || v.isEmpty ? 'يرجى اختيار المحال إليه' : null,
                      onChanged: (v) => setState(() => _selectedUserId = v),
                    ),
                  const SizedBox(height: 14),

                  // تاريخ الاستحقاق (اختياري)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dueDate == null
                          ? 'تحديد موعد نهائي للإنجاز (اختياري)'
                          : 'الموعد النهائي: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _dueDate == null ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                        fontWeight: _dueDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.red),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF7C3AED)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.add(const Duration(days: 3)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة وتوجيه الإحالة (اختياري)',
                      hintText: 'مثال: للدراسة وإعداد الرد المطلوب...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text('تأكيد وإرسال الإحالة', style: TextStyle(fontWeight: FontWeight.bold)),
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

