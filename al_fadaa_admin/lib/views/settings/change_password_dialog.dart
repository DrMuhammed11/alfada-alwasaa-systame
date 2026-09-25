import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';

/// تغيير كلمة المرور الذاتي — يستدعي PATCH /auth/password
/// الذي يبطل كل الجلسات الأخرى ويلزم بإعادة تسجيل الدخول.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String? _validateStrong(String? v) {
    final p = v ?? '';
    if (p.length < 10) return 'كلمة المرور 10 خانات فأكثر';
    if (!p.contains(RegExp(r'[A-Z]'))) return 'يلزم حرف لاتيني كبير (A-Z)';
    if (!p.contains(RegExp(r'[a-z]'))) return 'يلزم حرف لاتيني صغير (a-z)';
    if (!p.contains(RegExp(r'[0-9]'))) return 'يلزم رقم (0-9)';
    if (!p.contains(RegExp(r'[^A-Za-z0-9]'))) return 'يلزم رمز خاص مثل !@#';
    return null;
  }

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = _validateStrong(_newPass.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_newPass.text != _confirm.text) {
      setState(() => _error = 'تأكيد كلمة المرور غير مطابق');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final res = await AdminApiService().changeMyPassword(_current.text, _newPass.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res['success'] == true) {
      // الجلسات أُبطلت في الخادم — يعيد true للمنادي ليخرّج المستخدم لشاشة الدخول
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = res['message'] ?? 'فشل تغيير كلمة المرور');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'سيتم إبطال كل جلساتك الأخرى ويلزم تسجيل الدخول من جديد بكلمة المرور الجديدة.',
                style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة (10 خانات + أحرف + رقم + رمز)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', border: OutlineInputBorder(), isDense: true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 11.5, color: AdminTheme.crimson, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset_rounded, size: 16),
          label: const Text('تغيير وإبطال الجلسات'),
          style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
        ),
      ],
    );
  }
}
