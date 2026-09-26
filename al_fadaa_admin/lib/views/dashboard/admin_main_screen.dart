import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/session_manager.dart';
import '../../core/theme/admin_theme.dart';
import '../analytics/analytics_dashboard_view.dart';
import '../audit/audit_system_view.dart';
import '../auth/admin_login_screen.dart';
import '../content/site_content_view.dart';
import '../correspondences/correspondences_management_view.dart';
import '../departments/departments_management_view.dart';
import '../operations/operations_view.dart';
import '../settings/change_password_dialog.dart';
import '../users/users_management_view.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  late final AnimationController _sidebarController;
  late final Animation<double> _sidebarAnim;

  @override
  void initState() {
    super.initState();
    // تهيئة تحريك الشريط الجانبي
    _sidebarController = AnimationController(
      vsync: this,
      duration: AdminTheme.medium,
      value: 1.0,
    );
    _sidebarAnim = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );
    // انتهاء الجلسة → إعادة توجيه فورية لشاشة الدخول
    SessionManager().sessionExpiredTick.addListener(_onSessionExpired);
  }

  void _onSessionExpired() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    SessionManager().sessionExpiredTick.removeListener(_onSessionExpired);
    _sidebarController.dispose();
    super.dispose();
  }

  /// بناء الأقسام حسب الدور: إدارة المحتوى والتشغيل متاحة لمدير النظام فقط
  List<_NavSection> _sections(String? role) {
    final isSuperAdmin = role == 'ADMIN';
    return [
      _NavSection('لوحة الإحصائيات والتحليلات', 'الإحصائيات', 'الإحصائيات والتحليلات', Icons.analytics_rounded, const AnalyticsDashboardView()),
      _NavSection('إدارة المراسلات', 'المراسلات', 'المراسلات — النطاق الكامل', Icons.mark_email_unread_rounded, const CorrespondencesManagementView()),
      _NavSection('إدارة المستخدمين والصلاحيات', 'المستخدمين', 'الموظفون والصلاحيات', Icons.manage_accounts_rounded, const UsersManagementView()),
      _NavSection('إدارة الهيكل التنظيمي والأقسام', 'الأقسام', 'الأقسام والقطاعات', Icons.corporate_fare_rounded, const DepartmentsManagementView()),
      if (isSuperAdmin)
        _NavSection('محتويات الموقع الإلكتروني', 'المحتوى', 'محتوى الموقع الإلكتروني', Icons.web_rounded, const SiteContentView()),
      if (isSuperAdmin)
        _NavSection('إدارة التشغيل والرقابة', 'التشغيل', 'التشغيل: الصادر، الاعتماد، اليتامى، الوكالات، النسخ', Icons.settings_suggest_rounded, const OperationsView()),
      _NavSection('سجل التدقيق والرقابة الأمنية', 'التدقيق', 'سجل التدقيق والرقابة', Icons.security_rounded, const AuditSystemView()),
    ];
  }

  /// تغيير كلمة المرور الذاتي
  Future<void> _openChangePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      await SessionManager().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _handleLogout() async {
    // خروج كامل: إبطال رمز التحديث في الخادم ثم مسح الجلسة المحلية
    await SessionManager().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
    if (_sidebarCollapsed) {
      _sidebarController.reverse();
    } else {
      _sidebarController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final sections = _sections(user?.role);
    // حماية من بقاء فهرس خارج النطاق بعد تغيّر الدور
    if (_selectedIndex >= sections.length) _selectedIndex = sections.length - 1;
    final current = sections[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Scaffold(
          backgroundColor: AdminTheme.bgLight,
          appBar: _buildAppBar(current, user, isWide),
          body: isWide
              ? Row(
                  children: [
                    // الشريط الجانبي المتحرك
                    SizeTransition(
                      sizeFactor: _sidebarAnim,
                      axis: Axis.horizontal,
                      child: _buildWideSidebar(sections),
                    ),
                    // حد فاصل قابل للسحب
                    if (!_sidebarCollapsed)
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: Container(
                          width: 1,
                          color: AdminTheme.borderDark,
                        ),
                      ),
                    // المحتوى الرئيسي
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AdminTheme.fast,
                        child: KeyedSubtree(
                          key: ValueKey(_selectedIndex),
                          child: current.view,
                        ),
                      ),
                    ),
                  ],
                )
              : current.view,
          bottomNavigationBar: !isWide
              ? _buildBottomNav(sections)
              : null,
          // زر طي الشريط الجانبي (WIDE فقط)
          floatingActionButton: isWide
              ? FloatingActionButton.small(
                  onPressed: _toggleSidebar,
                  backgroundColor: AdminTheme.slate,
                  foregroundColor: Colors.white70,
                  elevation: 0,
                  tooltip:
                      _sidebarCollapsed ? 'إظهار القائمة' : 'طي القائمة',
                  child: AnimatedRotation(
                    turns: _sidebarCollapsed ? 0.5 : 0,
                    duration: AdminTheme.medium,
                    child: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      _NavSection current, dynamic user, bool isWide) {
    return AppBar(
      backgroundColor: AdminTheme.primary,
      elevation: 0,
      title: Row(
        children: [
          // أيقونة الدرع مع تدرج
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AdminTheme.accentGradient,
              borderRadius:
                  BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'نظام الفضاء الواسع — بوابة الإدارة العليا',
                  style: TextStyle(
                      fontSize: 10,
                      color: AdminTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (user != null) _buildUserInfo(user),
        // زر تغيير كلمة المرور
        Tooltip(
          message: 'تغيير كلمة المرور',
          child: IconButton(
            icon: const Icon(Icons.lock_reset_rounded,
                color: AdminTheme.textLight, size: 19),
            onPressed: _openChangePassword,
          ),
        ),
        // زر الخروج
        Tooltip(
          message: 'تسجيل الخروج',
          child: IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AdminTheme.crimson, size: 19),
            onPressed: _handleLogout,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildUserInfo(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // صورة رمزية بتدرج
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AdminTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                ApiConstants.getRoleName(user.role),
                style: const TextStyle(
                    fontSize: 10, color: AdminTheme.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideSidebar(List<_NavSection> sections) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AdminTheme.primary,
        border: Border(left: BorderSide(color: AdminTheme.borderDark)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // عنوان القائمة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.menu_rounded,
                    size: 14, color: AdminTheme.textLight),
                const SizedBox(width: 6),
                const Text(
                  'قائمة التنقل',
                  style: TextStyle(
                      fontSize: 10,
                      color: AdminTheme.textLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < sections.length; i++)
            _buildSidebarItem(i, sections[i]),
          const Spacer(),
          // مؤشر حالة الخادم
          _buildServerStatus(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, _NavSection section) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: AdminTheme.fast,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AdminTheme.accent
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
      ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: AdminTheme.fast,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
          ),
          child: Icon(
            section.icon,
            color: isSelected
                ? Colors.white
                : const Color(0xFF94A3B8),
            size: 18,
          ),
        ),
        title: Text(
          section.sidebarLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm)),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildServerStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.slate,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.borderDark),
      ),
      child: Row(
        children: [
          // مؤشر نبضي
          _PulsingDot(color: AdminTheme.emerald),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخادم: متصل',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'API v1 • آمن',
                  style: TextStyle(
                      color: AdminTheme.textLight, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(List<_NavSection> sections) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AdminTheme.accent,
        unselectedItemColor: AdminTheme.textMuted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: sections
            .map((s) => BottomNavigationBarItem(
                  icon: Icon(s.icon, size: 20),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AdminTheme.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(
                          AdminTheme.radiusXs),
                    ),
                    child: Icon(s.icon,
                        size: 20, color: AdminTheme.accent),
                  ),
                  label: s.navLabel,
                ))
            .toList(),
      ),
    );
  }
}

/// نقطة نبضية متحركة
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha(80),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// قسم تنقلي في لوحة الإدارة
class _NavSection {
  final String title;
  final String navLabel;
  final String sidebarLabel;
  final IconData icon;
  final Widget view;

  const _NavSection(
      this.title, this.navLabel, this.sidebarLabel, this.icon, this.view);
}
