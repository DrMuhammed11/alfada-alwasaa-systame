import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../models/user_model.dart';
import '../../admin/audit_screen.dart';
import '../../admin/executive_reports_screen.dart';
import '../../correspondences/create_incoming_dialog.dart';
import '../../correspondences/create_internal_dialog.dart';
import '../../notifications/notifications_bell.dart';

class DashboardSidebar extends StatelessWidget {
  final User user;
  final bool isAdminOrGM;
  final bool isCollapsed;
  final String selectedNav;
  final int totalCount;
  final int incomingCount;
  final int internalCount;
  final int outgoingCount;
  final int myTasksCount;
  final bool isSyncing;
  final AnimationController syncIconController;
  final VoidCallback onToggleCollapse;
  final Function(String) onSelectNav;
  final Function(String) onOpenCorrespondence;
  final VoidCallback onRefresh;
  final VoidCallback onSyncMail;
  final VoidCallback onLogout;

  const DashboardSidebar({
    super.key,
    required this.user,
    required this.isAdminOrGM,
    required this.isCollapsed,
    required this.selectedNav,
    required this.totalCount,
    required this.incomingCount,
    required this.internalCount,
    required this.outgoingCount,
    this.myTasksCount = 0,
    required this.isSyncing,
    required this.syncIconController,
    required this.onToggleCollapse,
    required this.onSelectNav,
    required this.onOpenCorrespondence,
    required this.onRefresh,
    required this.onSyncMail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الشريط الجانبي مع زر التكبير/التصغير
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 14,
              vertical: isCollapsed ? 12 : 16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: isCollapsed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          tooltip: 'توسيع القائمة',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onToggleCollapse,
                        ),
                        const SizedBox(height: 12),
                        NotificationsBell(
                          onNotificationTap: onOpenCorrespondence,
                          iconColor: const Color(0xFF94A3B8),
                          iconSize: 18,
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.mark_email_unread_rounded, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'شركة الفضاء الواسع',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'نظام المراسلات المؤسسي',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      NotificationsBell(
                        onNotificationTap: onOpenCorrespondence,
                        iconColor: const Color(0xFF94A3B8),
                        iconSize: 18,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                        tooltip: 'تصغير القائمة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onToggleCollapse,
                      ),
                    ],
                  ),
          ),

          // أزرار العمليات السريعة
          Padding(
            padding: EdgeInsets.all(isCollapsed ? 8 : 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await showDialog<bool>(
                        context: context,
                        builder: (_) => const CreateIncomingDialog(),
                      );
                      if (res == true) onRefresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: isCollapsed
                        ? const Tooltip(
                            message: 'وارد جديد',
                            child: Icon(Icons.add_rounded, size: 18),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('وارد جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => const CreateInternalDialog(),
                        );
                        if (res == true) onRefresh();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.description_outlined, size: 15, color: Color(0xFF94A3B8)),
                      label: const Text('خطاب داخلي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 4 : 8),
              children: [
                _buildTile(
                  title: 'كل المعاملات',
                  icon: Icons.all_inbox_rounded,
                  count: totalCount,
                  isSelected: selectedNav == 'ALL',
                  onTap: () => onSelectNav('ALL'),
                ),
                _buildTile(
                  title: 'الوارد العام',
                  icon: Icons.move_to_inbox_rounded,
                  count: incomingCount,
                  isSelected: selectedNav == 'INCOMING',
                  onTap: () => onSelectNav('INCOMING'),
                ),
                _buildTile(
                  title: 'الخطابات الداخلية',
                  icon: Icons.description_outlined,
                  count: internalCount,
                  isSelected: selectedNav == 'INTERNAL',
                  onTap: () => onSelectNav('INTERNAL'),
                ),
                _buildTile(
                  title: 'المراسلات الصادرة',
                  icon: Icons.outbox_rounded,
                  count: outgoingCount,
                  isSelected: selectedNav == 'OUTGOING',
                  onTap: () => onSelectNav('OUTGOING'),
                ),
                _buildTile(
                  title: 'مهام قطاعي',
                  icon: Icons.assignment_turned_in_rounded,
                  count: myTasksCount > 0 ? myTasksCount : null,
                  isSelected: selectedNav == 'MY_TASKS',
                  onTap: () => onSelectNav('MY_TASKS'),
                ),

                if (isAdminOrGM) ...[
                  const SizedBox(height: 12),
                  if (!isCollapsed)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        'الإدارة والرقابة',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  _buildTile(
                    title: 'التقارير ومؤشرات الأداء',
                    icon: Icons.analytics_rounded,
                    isSelected: false,
                    onTap: () => Navigator.push(
                      context,
                      EnterprisePageRoute(page: ExecutiveReportsScreen(currentUser: user)),
                    ),
                  ),
                  _buildTile(
                    title: 'سجل التدقيق والأمان',
                    icon: Icons.security_rounded,
                    isSelected: false,
                    onTap: () => Navigator.push(context, EnterprisePageRoute(page: const AuditScreen())),
                  ),
                ],
              ],
            ),
          ),

          // شريط الاتصال والمزامنة
          Container(
            padding: EdgeInsets.all(isCollapsed ? 6 : 10),
            margin: EdgeInsets.all(isCollapsed ? 6 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: isCollapsed
                ? Center(
                    child: IconButton(
                      icon: AnimatedBuilder(
                        animation: syncIconController,
                        builder: (_, child) => Transform.rotate(
                          angle: syncIconController.value * 6.2832,
                          child: child,
                        ),
                        child: const Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                      ),
                      tooltip: 'مزامنة فورية',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isSyncing ? null : onSyncMail,
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'خادم البريد: متصل',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: AnimatedBuilder(
                          animation: syncIconController,
                          builder: (_, child) => Transform.rotate(
                            angle: syncIconController.value * 6.2832,
                            child: child,
                          ),
                          child: const Icon(Icons.sync_rounded, color: Colors.white70, size: 16),
                        ),
                        tooltip: 'مزامنة فورية',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isSyncing ? null : onSyncMail,
                      ),
                    ],
                  ),
          ),

          // بطاقة المستخدم
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 6 : 12,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: isCollapsed
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: '${user.fullName}\n(${ApiConstants.getRoleName(user.role)})',
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.accent,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 17),
                          tooltip: 'تسجيل الخروج',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onLogout,
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppTheme.accent,
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              ApiConstants.getRoleName(user.role),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
                        tooltip: 'تسجيل الخروج',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onLogout,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (isCollapsed) {
      return Tooltip(
        message: '$title ${count != null ? "($count)" : ""}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent.withAlpha(40) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.accent : const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      selected: isSelected,
      selectedTileColor: AppTheme.accent.withAlpha(35),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? AppTheme.accent : const Color(0xFF94A3B8),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: count != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
