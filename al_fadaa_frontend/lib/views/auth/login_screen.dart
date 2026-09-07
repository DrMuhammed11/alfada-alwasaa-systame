import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/page_transitions.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: ApiConstants.defaultPassword);
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.text = ApiConstants.demoAccounts['GM']!;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin([String? email, String? password]) async {
    final targetEmail = email ?? _emailController.text.trim();
    final targetPassword = password ?? _passwordController.text.trim();

    if (targetEmail.isEmpty || targetPassword.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Map<String, dynamic> result;
    try {
      result = await ApiService().login(targetEmail, targetPassword);
    } catch (e) {
      result = {
        'success': false,
        'message': 'تعذر الاتصال بالخادم المحلي (تأكد من تشغيل الخادم Backend على منفذ 3000)',
      };
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        EnterprisePageRoute(page: DashboardScreen(user: result['user'])),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'خطأ في بيانات الدخول';
      });
    }
  }

  void _quickSwitch(String roleKey) {
    final email = ApiConstants.demoAccounts[roleKey];
    if (email != null) {
      _emailController.text = email;
      _passwordController.text = ApiConstants.defaultPassword;
      _handleLogin(email, ApiConstants.defaultPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // شعار المنظومة
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(50),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'شركة الفضاء الواسع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'نظام إدارة المراسلات والمعاملات المؤسسي',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // حقل البريد
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني المؤسسي',
                            hintText: 'name@al-fadaa.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // حقل كلمة المرور
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // زر الدخول
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleLogin(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'تسجيل الدخول إلى النظام',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'تسجيل دخول تجريبي سريع بحسب الدور',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // أزرار سريعة بدون إيموجي — مع أيقونات ناقلية دقيقة
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _QuickRoleChip(label: 'المدير العام', roleKey: 'GM', icon: Icons.account_balance_rounded, color: const Color(0xFF0284C7), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'أدمن النظام', roleKey: 'ADMIN', icon: Icons.admin_panel_settings_rounded, color: const Color(0xFF7C3AED), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'نائب المدير', roleKey: 'DEPUTY_GM', icon: Icons.military_tech_rounded, color: const Color(0xFF2563EB), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'مدير إدارة', roleKey: 'DEPT_MANAGER', icon: Icons.business_center_rounded, color: const Color(0xFF0D9488), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'المالية', roleKey: 'FINANCE', icon: Icons.payments_outlined, color: const Color(0xFF059669), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'الاستقبال', roleKey: 'RECEPTION', icon: Icons.desk_rounded, color: const Color(0xFFD97706), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'خدمة العملاء', roleKey: 'CUSTOMER_SERVICE', icon: Icons.support_agent_rounded, color: const Color(0xFFEA580C), onSelect: _quickSwitch),
                            _QuickRoleChip(label: 'موظف تنفيذي', roleKey: 'EMPLOYEE', icon: Icons.badge_outlined, color: const Color(0xFF475569), onSelect: _quickSwitch),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickRoleChip extends StatelessWidget {
  final String label;
  final String roleKey;
  final IconData icon;
  final Color color;
  final Function(String) onSelect;

  const _QuickRoleChip({
    required this.label,
    required this.roleKey,
    required this.icon,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(roleKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
