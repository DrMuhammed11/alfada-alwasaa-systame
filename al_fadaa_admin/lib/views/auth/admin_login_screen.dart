import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../dashboard/admin_main_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // تهيئة التحريك النبضي للشعار
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // التعبئة التلقائية في وضع العرض التجريبي الصريح (DEMO_MODE=true)
    if (ApiConstants.isDemoMode && ApiConstants.demoPassword.isNotEmpty) {
      _emailController.text = ApiConstants.demoAccounts.first;
      _passwordController.text = ApiConstants.demoPassword;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AdminApiService().login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminMainScreen()),
      );
    } else {
      setState(() => _errorMessage = res['message'] ?? 'فشل تسجيل الدخول');
    }
  }

  void _quickFill(String email) {
    if (!ApiConstants.isDemoMode || ApiConstants.demoPassword.isEmpty) return;
    setState(() {
      _emailController.text = email;
      _passwordController.text = ApiConstants.demoPassword;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      body: Stack(
        children: [
          // خلفية زخرفية
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          // المحتوى
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // الشعار المتحرك بتأثير النبضة
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AdminTheme.accentGradient,
              shape: BoxShape.circle,
              boxShadow: AdminTheme.accentGlow,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'شركة الفضاء الواسع',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AdminTheme.accent.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminTheme.accent.withAlpha(60)),
          ),
          child: const Text(
            'بوابة الإدارة والرقابة العليا (Admin Portal)',
            style: TextStyle(fontSize: 12, color: AdminTheme.accentLight),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminTheme.slate,
        borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
        border: Border.all(color: AdminTheme.borderDark),
        boxShadow: AdminTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رسالة الخطأ مع زر الإغلاق
          if (_errorMessage != null) ...[
            _buildErrorBox(_errorMessage!),
            const SizedBox(height: 20),
          ],

          // تسمية وحقل البريد الإلكتروني
          _buildFieldLabel('البريد الإلكتروني المؤسسي'),
          const SizedBox(height: 7),
          _buildEmailField(),
          const SizedBox(height: 18),

          // تسمية وحقل كلمة المرور
          _buildFieldLabel('كلمة المرور'),
          const SizedBox(height: 7),
          _buildPasswordField(),
          const SizedBox(height: 26),

          // زر الدخول مع حالة التحميل
          _buildLoginButton(),

          // أزرار الدخول السريع في وضع العرض التجريبي
          if (ApiConstants.isDemoMode && ApiConstants.demoPassword.isNotEmpty)
            _buildDemoAccounts(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _passwordFocus.requestFocus(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.mail_outline_rounded,
            color: AdminTheme.textLight, size: 19),
        hintText: 'name@al-fadaa.com',
        fillColor: AdminTheme.primaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      // إرسال النموذج عند الضغط على Enter في حقل كلمة المرور
      onSubmitted: (_) => _isLoading ? null : _handleLogin(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AdminTheme.textLight, size: 19),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AdminTheme.textLight,
            size: 19,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        fillColor: AdminTheme.primaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 48,
      child: AnimatedSwitcher(
        duration: AdminTheme.fast,
        child: _isLoading
            ? Container(
                key: const ValueKey('loading'),
                decoration: BoxDecoration(
                  gradient: AdminTheme.accentGradient,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              )
            : Container(
                key: const ValueKey('login'),
                decoration: BoxDecoration(
                  gradient: AdminTheme.accentGradient,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  boxShadow: AdminTheme.accentGlow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleLogin,
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusMd),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'دخول لوحة التحكم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return AnimatedContainer(
      duration: AdminTheme.fast,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.crimson.withAlpha(25),
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.crimson.withAlpha(100)),
      ),
      child: Row(
        children: [
          // أيقونة الخطأ
          const Icon(Icons.error_outline_rounded,
              color: AdminTheme.crimson, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12.5, height: 1.4),
            ),
          ),
          // زر إغلاق رسالة الخطأ
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AdminTheme.textLight, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: Divider(color: AdminTheme.borderDark)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'حسابات التجربة',
                style: TextStyle(color: AdminTheme.textLight, fontSize: 11),
              ),
            ),
            Expanded(child: Divider(color: AdminTheme.borderDark)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildDemoChip(
              'مدير النظام (Admin)',
              'admin@al-fadaa.com',
              AdminTheme.accent,
            ),
            _buildDemoChip(
              'المدير العام (GM)',
              'gm@al-fadaa.com',
              AdminTheme.emerald,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoChip(String label, String email, Color color) {
    return InkWell(
      onTap: () => _quickFill(email),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسام شبكة الخلفية الزخرفية
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    // رسم الخطوط الأفقية
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // رسم الخطوط العمودية
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // رسم البقعة الضوئية الخفيفة في المنتصف
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0284C7).withAlpha(30),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: size.height,
        ),
      );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
