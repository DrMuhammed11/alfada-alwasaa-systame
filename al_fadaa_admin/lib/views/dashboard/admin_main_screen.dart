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

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // انتهاء الجلسة (فشل تجديد الرمز) → إعادة توجيه فورية لشاشة الدخول بدل حلقات «أعد المحاولة»
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

  /// تغيير كلمة المرور الذاتي — النجاح يعني إبطال الجلسات وإعادة للدخول
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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AdminTheme.primary,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AdminTheme.accent.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.shield_rounded, color: AdminTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'نظام الفضاء الواسع — بوابة الإدارة العليا',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // اسم المستخدم والدور
              if (user != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AdminTheme.accent.withAlpha(40),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(ApiConstants.getRoleName(user.role), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF94A3B8), size: 20),
                tooltip: 'تغيير كلمة المرور',
                onPressed: _openChangePassword,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                tooltip: 'تسجيل الخروج',
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    // الشريط الجانبي للشاشات الكبيرة
                    _buildWideSidebar(sections),
                    // المحتوى
                    Expanded(child: current.view),
                  ],
                )
              : current.view,
          // شريط التنقل السفلي للأجهزة الذكية (Mobile / Android)
          bottomNavigationBar: !isWide
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: AdminTheme.accent,
                  unselectedItemColor: const Color(0xFF64748B),
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  items: sections
                      .map((s) => BottomNavigationBarItem(
                            icon: Icon(s.icon),
                            activeIcon: Icon(s.icon),
                            label: s.navLabel,
                          ))
                      .toList(),
                )
              : null,
        );
      },
    );
  }

  Widget _buildWideSidebar(List<_NavSection> sections) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          for (var i = 0; i < sections.length; i++)
            _buildSidebarItem(i, sections[i].sidebarLabel, sections[i].icon),
          const Spacer(),
          // حالة الاتصال
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'الخادم: متصل ومستقر',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AdminTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}

/// قسم تنقلي في لوحة الإدارة: عنوان علوي، تسمية شريط سفلي، تسمية شريط جانبي، أيقونة، وشاشة
class _NavSection {
  final String title;
  final String navLabel;
  final String sidebarLabel;
  final IconData icon;
  final Widget view;

  const _NavSection(this.title, this.navLabel, this.sidebarLabel, this.icon, this.view);
}
