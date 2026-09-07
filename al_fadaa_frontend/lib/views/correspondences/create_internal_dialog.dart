import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';

class CreateInternalDialog extends StatefulWidget {
  const CreateInternalDialog({super.key});

  @override
  State<CreateInternalDialog> createState() => _CreateInternalDialogState();
}

class _CreateInternalDialogState extends State<CreateInternalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();

  String _priority = 'NORMAL';
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await ApiService().createInternal(
      subject: _subjectController.text.trim(),
      body: _contentController.text.trim(),
      priority: _priority,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل إنشاء الخطاب الداخلي')),
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
                          color: const Color(0xFF059669).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF059669), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إنشاء خطاب داخلي / تعميم',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'إصدار تعميم أو مذكرة داخلية في النظام',
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
                      labelText: 'موضوع الخطاب / المذكرة *',
                      hintText: 'مثال: تعميم بشأن الإجازات السنوية',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال الموضوع' : null,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
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
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'نص الخطاب / المذكرة الداخلية *',
                      hintText: 'اكتب نص المذكرة أو التوجيه هنا بالتفصيل (5 أحرف على الأقل)...',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال نص الخطاب';
                      if (v.trim().length < 5) return 'نص الخطاب قصير جدًا (5 أحرف على الأقل)';
                      return null;
                    },
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
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text('إصدار وحفظ الخطاب الداخلي', style: TextStyle(fontWeight: FontWeight.bold)),
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

