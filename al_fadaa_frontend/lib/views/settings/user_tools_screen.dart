import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/page_transitions.dart';
import '../delegation/delegations_screen.dart';
import 'overdue_screen.dart';
import 'change_password_dialog.dart';
import '../notifications/notifications_center_screen.dart';

/// بوابة أدوات المستخدم: الإشعارات، الوكالات، المتأخرات، كلمة المرور —
/// شاشات كانت مبنية في الخادم لكن بلا مدخل واجهة.
class UserToolsScreen extends StatelessWidget {
  final User user;
  final bool isAdminOrGM;
  const UserToolsScreen({super.key, required this.user, required this.isAdminOrGM});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('أدوات الحساب والرقابة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.notifications_active_rounded,
            title: 'مركز الإشعارات',
            subtitle: 'كل إشعاراتك مع الترقيم والفلترة ووسم المقروء',
            onTap: () => Navigator.push(context, EnterprisePageRoute(page: const NotificationsCenterScreen())),
          ),
          _tile(
            context,
            icon: Icons.trending_down_rounded,
            title: 'قائمة المتأخرات (SLA)',
            subtitle: 'المهام والإحالات التي تجاوزت موعد الاستحقاق',
            onTap: () => Navigator.push(context, EnterprisePageRoute(page: const OverdueScreen())),
          ),
          if (isAdminOrGM)
            _tile(
              context,
              icon: Icons.swap_horiz_rounded,
              title: 'الوكالات (التفويض)',
              subtitle: 'وكيلك أثناء غيابك والوكالات الممنوحة لك',
              onTap: () => Navigator.push(context, EnterprisePageRoute(page: DelegationsScreen(user: user, canCreate: isAdminOrGM))),
            ),
          _tile(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'تغيير كلمة المرور',
            subtitle: 'يُبطل كل جلساتك الأخرى فورًا — حماية إلزامية دورية',
            onTap: () => showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog()),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.secondary.withAlpha(70)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_left_rounded, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
