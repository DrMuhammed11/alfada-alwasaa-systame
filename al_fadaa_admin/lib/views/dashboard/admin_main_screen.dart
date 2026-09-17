import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/session_manager.dart';
import '../../core/theme/admin_theme.dart';
import '../analytics/analytics_dashboard_view.dart';
import '../audit/audit_system_view.dart';
import '../auth/admin_login_screen.dart';
import '../departments/departments_management_view.dart';
import '../users/users_management_view.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    AnalyticsDashboardView(),
    UsersManagementView(),
    DepartmentsManagementView(),
    AuditSystemView(),
  ];

  final List<String> _titles = const [
    'لوحة الإحصائيات والتحليلات',
    'إدارة المستخدمين والصلاحيات',
    'إدارة الهيكل التنظيمي والأقسام',
    'سجل التدقيق والرقابة الأمنية',
  ];

  Future<void> _handleLogout() async {
    await SessionManager().clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;

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
                      _titles[_selectedIndex],
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
                    _buildWideSidebar(),
                    // المحتوى
                    Expanded(child: _views[_selectedIndex]),
                  ],
                )
              : _views[_selectedIndex],
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
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics_outlined),
                      activeIcon: Icon(Icons.analytics_rounded),
                      label: 'الإحصائيات',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.manage_accounts_outlined),
                      activeIcon: Icon(Icons.manage_accounts_rounded),
                      label: 'المستخدمين',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.corporate_fare_outlined),
                      activeIcon: Icon(Icons.corporate_fare_rounded),
                      label: 'الأقسام',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.security_outlined),
                      activeIcon: Icon(Icons.security_rounded),
                      label: 'التدقيق',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildWideSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSidebarItem(0, 'الإحصائيات والتحليلات', Icons.analytics_rounded),
          _buildSidebarItem(1, 'الموظفون والصلاحيات', Icons.manage_accounts_rounded),
          _buildSidebarItem(2, 'الأقسام والقطاعات', Icons.corporate_fare_rounded),
          _buildSidebarItem(3, 'سجل التدقيق والرقابة', Icons.security_rounded),
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
