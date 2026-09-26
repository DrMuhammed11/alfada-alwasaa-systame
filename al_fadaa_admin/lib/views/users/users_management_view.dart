import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/admin_user_model.dart';
import 'user_dialog.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  static const int _limit = 20;

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<AdminUser> _users = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedRole = 'ALL';
  String _selectedDepartmentId = 'ALL';
  // حالة الترقيم من الخادم
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  // العدد الدقيق لكل دور ضمن الفلاتر الحالية — يأتي من meta الخادم لا من الصفحة المعروضة
  Map<String, int> _roleTotals = const {};

  // أولوية الدور للفرز والترتيب
  static const _rolePriority = {
    'ADMIN': 0, 'GM': 1, 'DEPUTY_GM': 2, 'DEPT_MANAGER': 3, 'EMPLOYEE': 4
  };

  @override
  void initState() {
    super.initState();
    _loadData(page: 1);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // بحث مؤجل (debounce) 300ms
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _loadData(page: 1));
  }

  Future<void> _loadData({int? page}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final effectivePage = page ?? _page;
    final depts = await AdminApiService().getDepartments();
    final res = await AdminApiService().getUsers(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      role: _selectedRole,
      departmentId: _selectedDepartmentId,
      page: effectivePage,
      limit: _limit,
    );
    final roleTotals = await _loadRoleTotals();
    if (!mounted) return;
    // ترتيب حسب الدور
    res.items.sort((a, b) =>
        (_rolePriority[a.role.toUpperCase()] ?? 9)
            .compareTo(_rolePriority[b.role.toUpperCase()] ?? 9));
    setState(() {
      _departments = depts.items;
      _users = res.items;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _roleTotals = roleTotals;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  /// إحصاء دقيق لكل دور ضمن فلاتر البحث والقسم الحالية:
  /// طلبات خفيفة (limit=1) يكفي فيها العدد الكلي القادم من meta
  Future<Map<String, int>> _loadRoleTotals() async {
    const roles = ['ADMIN', 'GM', 'DEPT_MANAGER', 'EMPLOYEE'];
    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    try {
      final pages = await Future.wait(roles.map((r) => AdminApiService().getUsers(
            search: search,
            departmentId: _selectedDepartmentId,
            role: r,
            page: 1,
            limit: 1,
          )));
      return {for (var i = 0; i < roles.length; i++) roles[i]: pages[i].total};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _openCreateDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => UserDialog(departments: _departments),
    );
    if (res == true) _loadData(page: 1);
  }

  Future<void> _openEditDialog(AdminUser user) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) =>
          UserDialog(userToEdit: user, departments: _departments),
    );
    if (res == true) _loadData();
  }

  Future<void> _confirmDeleteUser(AdminUser user) async {
    final confirmed = await AppUtils.confirmDelete(
      context,
      title: 'تأكيد حذف المستخدم',
      message:
          'هل أنت متأكد من حذف الحساب «${user.name}»؟\nلا يمكن التراجع عن هذا الإجراء.',
    );
    if (!confirmed || !mounted) return;

    final success = await AdminApiService().deleteUser(user.id);
    if (!mounted) return;
    if (success) {
      AppUtils.showSuccess(context, 'تم حذف المستخدم بنجاح');
      _loadData();
    } else {
      AppUtils.showError(context, 'فشل حذف المستخدم');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      body: Column(
        children: [
          _buildToolbar(),
          if (!_isLoading && !_hasError) _buildSummaryRow(),
          Expanded(child: _buildBody()),
          // شريط الترقيم الموحد من app_utils
          if (!_isLoading && !_hasError && _users.isNotEmpty)
            PaginationBar(
              currentPage: _page,
              totalPages: _totalPages,
              total: _total,
              isLoading: _isLoading,
              onPageChange: (p) => _loadData(page: p),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // عنوان القسم
              const Icon(Icons.manage_accounts_rounded,
                  color: AdminTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text('إدارة المستخدمين والصلاحيات',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              // عداد النتائج الكلي من الخادم
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminTheme.surface2,
                  borderRadius:
                      BorderRadius.circular(AdminTheme.radiusSm),
                ),
                child: Text(
                  '$_total مستخدم',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              // زر إضافة مستخدم
              FilledButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('إضافة موظف',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // حقل البحث مع debounce
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم أو البريد الإلكتروني...',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    suffixIcon: Icon(Icons.manage_search_rounded,
                        size: 16, color: AdminTheme.textLight),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // فلتر الدور
              _buildDropdown(
                value: _selectedRole,
                items: const {
                  'ALL': 'كافة الأدوار',
                  'ADMIN': 'مدير النظام',
                  'GM': 'المدير العام',
                  'DEPUTY_GM': 'نائب المدير',
                  'DEPT_MANAGER': 'مدراء الإدارات',
                  'EMPLOYEE': 'الموظفون',
                },
                onChanged: (v) {
                  setState(() => _selectedRole = v);
                  _loadData(page: 1);
                },
              ),
              const SizedBox(width: 8),
              // فلتر القسم
              _buildDropdown(
                value: _selectedDepartmentId,
                items: {
                  'ALL': 'كافة الأقسام',
                  for (final d in _departments) d.id: d.name,
                },
                onChanged: (v) {
                  setState(() => _selectedDepartmentId = v);
                  _loadData(page: 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    // الأعداد تأتي من meta الخادم (لكامل النتائج المطابقة لا الصفحة المعروضة)
    final roleStats = [
      ('ADMIN', 'مدير نظام', AdminTheme.crimson),
      ('GM', 'مدير عام', AdminTheme.purple),
      ('DEPT_MANAGER', 'مدير قسم', AdminTheme.accent),
      ('EMPLOYEE', 'موظف', AdminTheme.textMuted),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // إحصاء كل دور له مستخدم واحد على الأقل ضمن الفلاتر الحالية
          ...roleStats
              .where((r) => (_roleTotals[r.$1] ?? 0) > 0)
              .map((r) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: StatusBadge(
                      text: '${r.$2}: ${_roleTotals[r.$1] ?? 0}',
                      color: r.$3,
                    ),
                  )),
          const Spacer(),
          // عرض عدد الحسابات المعطلة إن وجدت — دقيق فقط عندما تُحمّل الصفحة كاملة
          if (_totalPages == 1 && _users.any((u) => !u.isActive))
            StatusBadge(
              text:
                  'معطل: ${_users.where((u) => !u.isActive).length}',
              color: AdminTheme.amber,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'جاري تحميل بيانات الموظفين...');
    }
    // حالة الخطأ — تمييز فشل الطلب عن غياب النتائج
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل قائمة الموظفين',
        onRetry: () => _loadData(),
      );
    }
    if (_users.isEmpty) {
      return EmptyStateWidget(
        message: 'لا يوجد موظفون مطابقون لمعايير البحث',
        icon: Icons.people_outline_rounded,
        actionLabel: 'إعادة تحميل',
        onAction: () => _loadData(page: 1),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: AdminTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) => _buildUserCard(_users[index]),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(
              fontSize: 12,
              color: AdminTheme.textMain,
              fontWeight: FontWeight.w600),
          items: items.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser u) {
    // تحديد لون الدور لكل بطاقة مستخدم
    final Color roleColor = switch (u.role.toUpperCase()) {
      'ADMIN' => AdminTheme.crimson,
      'GM' || 'DEPUTY_GM' => AdminTheme.purple,
      'DEPT_MANAGER' => AdminTheme.accent,
      _ => AdminTheme.textMuted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(
          color: u.isActive
              ? AdminTheme.border
              : AdminTheme.crimson.withAlpha(40),
        ),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // أيقونة الحرف الأول بتدرج لوني حسب الدور
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    roleColor.withAlpha(180),
                    roleColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // البيانات الرئيسية للمستخدم
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // شارة الدور الوظيفي
                      StatusBadge(
                        text: ApiConstants.getRoleName(u.role),
                        color: roleColor,
                      ),
                      const SizedBox(width: 6),
                      // شارة حالة الحساب
                      StatusBadge(
                        text: u.isActive ? 'مفعّل' : 'معطّل',
                        color: u.isActive
                            ? AdminTheme.emerald
                            : AdminTheme.crimson,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // البريد الإلكتروني
                  Text(
                    u.email,
                    style: const TextStyle(
                        fontSize: 12, color: AdminTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // اسم القسم إن وُجد
                      if (u.department != null) ...[
                        const Icon(Icons.apartment_rounded,
                            size: 12, color: AdminTheme.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            u.department!.name,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AdminTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      // عدد الصلاحيات المخصصة
                      const Icon(Icons.vpn_key_rounded,
                          size: 12, color: AdminTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${u.permissions.length} صلاحية',
                        style: const TextStyle(
                            fontSize: 11, color: AdminTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // أزرار التعديل والحذف
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'تعديل الصلاحيات',
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AdminTheme.accent),
                    onPressed: () => _openEditDialog(u),
                  ),
                ),
                Tooltip(
                  message: 'حذف الحساب',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AdminTheme.crimson),
                    onPressed: () => _confirmDeleteUser(u),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
