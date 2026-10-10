import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';
import 'tabs/services_tab.dart';
import 'tabs/sectors_tab.dart';
import 'tabs/projects_tab.dart';
import 'tabs/faqs_tab.dart';
import 'tabs/settings_tab.dart';

/// إدارة محتويات الموقع الإلكتروني: الخدمات، القطاعات، سابقة الأعمال،
/// الأسئلة الشائعة، والإعدادات العامة — بصلاحية إدارة المحتوى (ADMIN)
class SiteContentView extends StatelessWidget {
  const SiteContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AdminTheme.bgLight,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.web_rounded, color: AdminTheme.accent, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'إدارة محتويات الموقع الإلكتروني',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AdminTheme.fontLg),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AdminTheme.primary,
                    unselectedLabelColor: AdminTheme.textMuted,
                    indicatorColor: AdminTheme.primary,
                    labelStyle: const TextStyle(fontSize: AdminTheme.fontBase, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.miscellaneous_services_rounded, size: 16), text: 'الخدمات'),
                      Tab(icon: Icon(Icons.domain_rounded, size: 16), text: 'القطاعات'),
                      Tab(icon: Icon(Icons.emoji_events_rounded, size: 16), text: 'سابقة الأعمال'),
                      Tab(icon: Icon(Icons.quiz_rounded, size: 16), text: 'الأسئلة الشائعة'),
                      Tab(icon: Icon(Icons.tune_rounded, size: 16), text: 'إعدادات عامة'),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  ServicesTab(),
                  SectorsTab(),
                  ProjectsTab(),
                  FaqsTab(),
                  SettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
