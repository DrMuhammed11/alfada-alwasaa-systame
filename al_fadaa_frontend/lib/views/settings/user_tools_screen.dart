import 'package:flutter/material.dart';
import '../../../core/network/app_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/page_transitions.dart';
import '../delegation/delegations_screen.dart';
import 'overdue_screen.dart';
import 'change_password_dialog.dart';
import '../notifications/notifications_center_screen.dart';
import '../admin/audit_screen.dart';
import '../admin/executive_reports_screen.dart';
import '../admin/organization_management_screen.dart';

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
        title: const Text('أدوات الحساب والرقابة', style: TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.notifications_active_rounded,
            title: 'مركز الإشعارات',
            subtitle: 'كل إشعاراتك مع الترقيم والفلترة ووسم المقروء',
            onTap: () async {
              // فتح المعاملة من الإشعار يوجَّه عبر AppEvents للوحة التحكم
              // وتُغلق شاشة الأدوات مع المركز ليجد المستخدم المعاملة محدَّدة في اللوحة
              String? openedId;
              await Navigator.push(
                context,
                EnterprisePageRoute(
                  page: NotificationsCenterScreen(
                    onOpenCorrespondence: (id) {
                      openedId = id;
                      AppEvents().triggerOpenCorrespondence(id);
                    },
                  ),
                ),
              );
              if (openedId != null && context.mounted) Navigator.of(context).pop();
            },
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
          // ─── الوحدة الإدارية — ADMIN/GM فقط ───
          // شاشات مبنية بمدخل API كامل لكنها كانت بلا مدخل واجهة
          if (isAdminOrGM) ...[
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.corporate_fare_rounded,
              title: 'إدارة المستخدمين والأقسام',
              subtitle: 'إنشاء الحسابات وتعيين الأدوار والأقسام وتفعيلها',
              onTap: () => Navigator.push(
                context,
                EnterprisePageRoute(page: OrganizationManagementScreen(currentUser: user)),
              ),
            ),
            _tile(
              context,
              icon: Icons.query_stats_rounded,
              title: 'التقارير التنفيذية',
              subtitle: 'مؤشرات الأداء وحجم المعاملات وأداء الأقسام',
              onTap: () => Navigator.push(
                context,
                EnterprisePageRoute(page: ExecutiveReportsScreen(currentUser: user)),
              ),
            ),
            _tile(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'سجل التدقيق',
              subtitle: 'سلسلة الأحداث الموثقة بالهاش لكل ما يجري في النظام',
              onTap: () => Navigator.push(context, EnterprisePageRoute(page: AuditScreen())),
            ),
          ],
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.secondary.withAlpha(70)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.accent.withAlpha(30), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: AppTheme.fontMd, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textTertiary)),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
