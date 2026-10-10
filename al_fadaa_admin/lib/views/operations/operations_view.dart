import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';
import 'tabs/outbox_tab.dart';
import 'tabs/workflows_tab.dart';
import 'tabs/orphans_tab.dart';
import 'tabs/delegations_tab.dart';
import 'tabs/backup_tab.dart';

/// شاشة التشغيل الإداري: صندوق البريد الصادر، مسارات الاعتماد،
/// الكيانات اليتيمة، سجل الوكالات، وحالة النسخ الاحتياطي.
class OperationsView extends StatelessWidget {
  const OperationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AdminTheme.bgLight,
        body: Column(
          children: [
            // رأس شريط التبويب بخلفية محسَّنة
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AdminTheme.border)),
              ),
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.settings_suggest_rounded, color: AdminTheme.accent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'إدارة التشغيل والرقابة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: AdminTheme.fontLg),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AdminTheme.primary,
                      unselectedLabelColor: AdminTheme.textMuted,
                      indicatorColor: AdminTheme.primary,
                      labelStyle: TextStyle(fontSize: AdminTheme.fontBase, fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(icon: Icon(Icons.outbox_rounded, size: 16), text: 'صندوق الصادر'),
                        Tab(icon: Icon(Icons.fact_check_rounded, size: 16), text: 'مسارات الاعتماد'),
                        Tab(icon: Icon(Icons.link_off_rounded, size: 16), text: 'الكيانات اليتيمة'),
                        Tab(icon: Icon(Icons.swap_horiz_rounded, size: 16), text: 'سجل الوكالات'),
                        Tab(icon: Icon(Icons.backup_rounded, size: 16), text: 'النسخ الاحتياطي'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  OutboxTab(),
                  WorkflowsTab(),
                  OrphansTab(),
                  DelegationsTab(),
                  BackupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
