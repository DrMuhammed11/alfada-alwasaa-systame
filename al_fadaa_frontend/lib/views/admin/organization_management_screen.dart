import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../models/user_model.dart';
import 'widgets/departments_management_tab.dart';
import 'widgets/users_management_tab.dart';

class OrganizationManagementScreen extends StatefulWidget {
  final User currentUser;
  const OrganizationManagementScreen({super.key, required this.currentUser});

  @override
  State<OrganizationManagementScreen> createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends State<OrganizationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Department> _departments = [];
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final deptsFuture = ApiService().getDepartments();
      final usersFuture = ApiService().getUsers();
      final results = await Future.wait([deptsFuture, usersFuture]);
      if (mounted) {
        setState(() {
          _departments = results[0] as List<Department>;
          _users = results[1] as List<User>;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = _users.where((u) => u.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.corporate_fare_rounded, size: 22, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'الهيكل المؤسسي — إدارة الموظفين والقطاعات والصلاحيات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.people_alt_rounded, size: 18),
              text: 'الموظفون والصلاحيات (${_users.length})',
            ),
            Tab(
              icon: const Icon(Icons.apartment_rounded, size: 18),
              text: 'القطاعات والإدارات (${_departments.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط إحصائي سريع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                _buildStatItem('إجمالي الموظفين', '${_users.length}', Icons.badge_outlined),
                const SizedBox(width: 24),
                _buildStatItem('الحسابات النشطة', '$activeUsers', Icons.verified_user_outlined, color: const Color(0xFF10B981)),
                const SizedBox(width: 24),
                _buildStatItem('القطاعات المسجلة', '${_departments.length}', Icons.account_tree_outlined),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                  tooltip: 'تحديث البيانات',
                  onPressed: _loadAll,
                ),
              ],
            ),
          ),

          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UsersManagementTab(
                  departments: _departments,
                  onDataChanged: _loadAll,
                ),
                DepartmentsManagementTab(
                  departments: _departments,
                  users: _users,
                  isLoading: _isLoading,
                  onRefresh: _loadAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
