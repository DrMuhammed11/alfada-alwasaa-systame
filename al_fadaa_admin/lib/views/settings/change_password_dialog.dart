import 'package:flutter/material.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';

/// تغيير كلمة المرور الذاتي
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _error;

  int get _strength {
    final p = _newPass.text;
    if (p.length < 4) return 0;
    int s = 0;
    if (p.length >= 10) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[a-z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s;
  }

  Color get _strengthColor {
    return switch (_strength) {
      0 || 1 => AdminTheme.crimson,
      2 => AdminTheme.amber,
      3 => const Color(0xFFEAB308),
      _ => AdminTheme.emerald,
    };
  }

  String get _strengthLabel {
    return switch (_strength) {
      0 || 1 => 'ضعيفة جداً',
      2 => 'ضعيفة',
      3 => 'متوسطة',
      _ => 'قوية',
    };
  }

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await AdminApiService()
        .changeMyPassword(_current.text, _newPass.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() =>
          _error = res['message'] ?? 'فشل تغيير كلمة المرور');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded, color: AdminTheme.accent, size: 22),
          SizedBox(width: 8),
          Text('تغيير كلمة المرور',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(AdminTheme.radiusSm),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF1E40AF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إبطال كل جلساتك الأخرى ويلزم تسجيل الدخول من جديد.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _current,
              label: 'كلمة المرور الحالية',
              show: _showCurrent,
              onToggle: () =>
                  setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _newPass,
              label: 'كلمة المرور الجديدة (10 خانات + أحرف + رقم + رمز)',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              onChanged: (_) => setState(() {}),
            ),
            if (_newPass.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          AdminTheme.radiusSm),
                      child: LinearProgressIndicator(
                        value: _strength / 5,
                        minHeight: 4,
                        backgroundColor: AdminTheme.border,
                        valueColor: AlwaysStoppedAnimation(
                            _strengthColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _strengthLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: _strengthColor,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _confirm,
              label: 'تأكيد كلمة المرور الجديدة',
              show: _showConfirm,
              onToggle: () =>
                  setState(() => _showConfirm = !_showConfirm),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.crimson.withAlpha(15),
                  borderRadius:
                      BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(
                      color: AdminTheme.crimson.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AdminTheme.crimson, size: 15),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AdminTheme.crimson,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset_rounded, size: 16),
          label: const Text('تغيير وإبطال الجلسات'),
          style: FilledButton.styleFrom(
              backgroundColor: AdminTheme.primary),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(
            show
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AdminTheme.textMuted,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
