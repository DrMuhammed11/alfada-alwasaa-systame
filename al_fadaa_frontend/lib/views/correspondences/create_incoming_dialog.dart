import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';

class CreateIncomingDialog extends StatefulWidget {
  const CreateIncomingDialog({super.key});

  @override
  State<CreateIncomingDialog> createState() => _CreateIncomingDialogState();
}

class _CreateIncomingDialogState extends State<CreateIncomingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _bodyController = TextEditingController();

  String _priority = 'NORMAL';
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _senderNameController.dispose();
    _senderEmailController.dispose();
    _senderPhoneController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await ApiService().createIncoming(
      subject: _subjectController.text.trim(),
      senderName: _senderNameController.text.trim(),
      senderEmail: _senderEmailController.text.trim(),
      senderPhone: _senderPhoneController.text.trim(),
      body: _bodyController.text.trim(),
      priority: _priority,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل تسجيل المراسلة الواردة')),
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ترويسة النافذة
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.move_to_inbox_rounded, color: Color(0xFF0284C7), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تسجيل مراسلة واردة جديدة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'إدخال بريد أو معاملة واردة لبريد الشركة الموحد',
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

                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'موضوع المراسلة *',
                      hintText: 'مثال: طلب عرض سعر لأعمال المقاولات',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال الموضوع' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _senderNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المرسل (الجهة أو العميل) *',
                            hintText: 'شركة الأفق / م. فلان',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المرسل' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _senderEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'بريد المرسل (للردود)',
                            hintText: 'client@example.com',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _senderPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'هاتف المرسل (اختياري)',
                            hintText: '+966...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: const InputDecoration(labelText: 'درجة الأهمية'),
                          items: const [
                            DropdownMenuItem(value: 'LOW', child: Text('عادي')),
                            DropdownMenuItem(value: 'NORMAL', child: Text('مهم')),
                            DropdownMenuItem(value: 'HIGH', child: Text('عاجل')),
                            DropdownMenuItem(value: 'URGENT', child: Text('عاجل جدًا')),
                          ],
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'محتوى الرسالة / نص المراسلة (اختياري)',
                      hintText: 'تفاصيل ما ورد في الخطاب أو البريد...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('تسجيل وحفظ المراسلة', style: TextStyle(fontWeight: FontWeight.bold)),
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
