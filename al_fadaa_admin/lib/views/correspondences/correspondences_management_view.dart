import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/correspondence_model.dart';

/// إدارة المراسلات — نطاق الإدارة العليا (كل المراسلات)
/// فلاتر: النوع، الحالة، الأولوية، القسم، بحث نصي — مع ترقيم صفحات وتفاصيل كاملة
class CorrespondencesManagementView extends StatefulWidget {
  const CorrespondencesManagementView({super.key});

  @override
  State<CorrespondencesManagementView> createState() =>
      _CorrespondencesManagementViewState();
}

class _CorrespondencesManagementViewState
    extends State<CorrespondencesManagementView> {
  static const int _limit = 20;

  final _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  List<CorrListItem> _corrs = [];
  List<({String id, String name})> _departments = [];
  bool _isLoading = true;
  bool _hasError = false;

  String _type = 'ALL';
  String _status = 'ALL';
  String _priority = 'ALL';
  String _departmentId = 'ALL';
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _type != 'ALL' ||
      _status != 'ALL' ||
      _priority != 'ALL' ||
      _departmentId != 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    // الأقسام وأول صفحة بالتوازي — الأقسام لعناصر الفلترة فقط فلا تحجب القائمة
    final deptsFuture = AdminApiService().getDepartments();
    final pageFuture = _load(page: 1);
    final deptsRes = await deptsFuture;
    if (mounted) {
      setState(
          () => _departments = deptsRes.items.map((d) => (id: d.id, name: d.name)).toList());
    }
    await pageFuture;
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getCorrespondences(
      type: _type,
      status: _status,
      priority: _priority,
      departmentId: _departmentId,
      q: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      page: page,
      limit: _limit,
    );
    if (!mounted) return;
    setState(() {
      _corrs = res.items;
      _hasError = res.error;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _isLoading = false;
    });
  }

  Future<void> _clearFilters() async {
    setState(() {
      _searchController.clear();
      _type = 'ALL';
      _status = 'ALL';
      _priority = 'ALL';
      _departmentId = 'ALL';
    });
    _load(page: 1);
  }

  // ─── ألوان النوع ───
  Color _typeColor(String type) => switch (type) {
        'INCOMING' => const Color(0xFF0284C7),
        'OUTGOING' => AdminTheme.emerald,
        'INTERNAL' => AdminTheme.purple,
        _ => AdminTheme.textMuted,
      };

  // ─── أيقونة النوع ───
  IconData _typeIcon(String type) => switch (type) {
        'INCOMING' => Icons.south_west_rounded,
        'OUTGOING' => Icons.north_east_rounded,
        'INTERNAL' => Icons.sync_alt_rounded,
        _ => Icons.mail_rounded,
      };

  // ─── ألوان الأولوية ───
  Color _priorityColor(String p) => switch (p) {
        'URGENT' => AdminTheme.crimson,
        'HIGH' => AdminTheme.amber,
        'NORMAL' => AdminTheme.accent,
        _ => AdminTheme.textMuted,
      };

  // ─── أيقونة الأولوية ───
  IconData _priorityIcon(String p) => switch (p) {
        'URGENT' => Icons.priority_high_rounded,
        'HIGH' => Icons.keyboard_double_arrow_up_rounded,
        'NORMAL' => Icons.remove_rounded,
        _ => Icons.keyboard_double_arrow_down_rounded,
      };

  // ─── ألوان الحالة ───
  Color _statusColor(String s) => switch (s) {
        'CLOSED' || 'ARCHIVED' || 'SENT' => AdminTheme.emerald,
        'RECEIVED' || 'UNDER_REVIEW' => AdminTheme.amber,
        _ => AdminTheme.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
          // شريط ترقيم الصفحات — يُخفى أثناء التحميل أو الخطأ أو إذا لا توجد سجلات
          if (!_isLoading && !_hasError && _corrs.isNotEmpty)
            PaginationBar(
              currentPage: _page,
              totalPages: _totalPages,
              total: _total,
              isLoading: _isLoading,
              onPageChange: (p) => _load(page: p),
            ),
        ],
      ),
    );
  }

  // ─── شريط الفلاتر والبحث ───
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AdminTheme.cardBg,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── سطر العنوان والعداد ───
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withAlpha(18),
                  borderRadius:
                      BorderRadius.circular(AdminTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AdminTheme.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'إدارة المراسلات — النطاق الكامل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AdminTheme.textMain,
                ),
              ),
              const Spacer(),
              // عداد الإجمالي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.surface2,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Text(
                  'الإجمالي: $_total',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'تحديث القائمة',
                onPressed: () => _load(page: _page),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ─── حقل البحث + فلتر النوع ───
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                          'ابحث بالموضوع، الرقم المرجعي، أو اسم المرسل...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AdminTheme.textLight),
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 17),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AdminTheme.radiusSm),
                      ),
                      filled: true,
                      fillColor: AdminTheme.bgLight,
                    ),
                    onSubmitted: (_) => _load(page: 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _type,
                items: const {
                  'ALL': 'كل الأنواع',
                  'INCOMING': 'وارد',
                  'OUTGOING': 'صادر',
                  'INTERNAL': 'داخلي',
                },
                onChanged: (v) {
                  setState(() => _type = v);
                  _load(page: 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ─── فلاتر الحالة / الأولوية / القسم ───
          Row(
            children: [
              _buildDropdown(
                value: _status,
                items: const {
                  'ALL': 'كل الحالات',
                  'RECEIVED': 'مستلمة',
                  'UNDER_REVIEW': 'قيد الدراسة',
                  'REFERRED': 'محالة',
                  'IN_PROGRESS': 'جاري إعداد الرد',
                  'PENDING_APPROVAL': 'بانتظار الاعتماد',
                  'SENT': 'أُرسلت للعميل',
                  'CLOSED': 'مغلقة',
                  'ARCHIVED': 'مؤرشفة',
                },
                onChanged: (v) {
                  setState(() => _status = v);
                  _load(page: 1);
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _priority,
                items: const {
                  'ALL': 'كل الأولويات',
                  'URGENT': 'عاجلة للغاية',
                  'HIGH': 'عالية',
                  'NORMAL': 'اعتيادية',
                  'LOW': 'منخفضة',
                },
                onChanged: (v) {
                  setState(() => _priority = v);
                  _load(page: 1);
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                value: _departmentId,
                items: {
                  'ALL': 'كل الأقسام',
                  for (final d in _departments) d.id: d.name,
                },
                onChanged: (v) {
                  setState(() => _departmentId = v);
                  _load(page: 1);
                },
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text(
                    'مسح الفلاتر',
                    style: TextStyle(fontSize: 11, color: AdminTheme.crimson),
                  ),
                  avatar: const Icon(Icons.filter_alt_off_rounded,
                      size: 14, color: AdminTheme.crimson),
                  side: BorderSide(color: AdminTheme.crimson.withAlpha(80)),
                  backgroundColor: AdminTheme.crimson.withAlpha(10),
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── قائمة منسدلة موحدة ───
  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
            fontWeight: FontWeight.w600,
          ),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  // ─── جسم القائمة ───
  Widget _buildBody() {
    // حالة التحميل
    if (_isLoading) {
      return const LoadingWidget(message: 'جارٍ تحميل المراسلات…');
    }
    // حالة الخطأ
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل المراسلات من الخادم',
        onRetry: () => _load(page: _page),
      );
    }
    // حالة القائمة الفارغة
    if (_corrs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.mark_email_unread_outlined,
        message: 'لا توجد مراسلات مطابقة للفلاتر المحددة',
        actionLabel: _hasActiveFilters ? 'مسح الفلاتر' : null,
        onAction: _hasActiveFilters ? _clearFilters : null,
      );
    }
    // قائمة المراسلات
    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      color: AdminTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _corrs.length,
        itemBuilder: (context, index) => _buildCorrCard(_corrs[index]),
      ),
    );
  }

  // ─── بطاقة مراسلة واحدة ───
  Widget _buildCorrCard(CorrListItem c) {
    final isOverdue = c.isOverdue;
    final priorityColor = _priorityColor(c.priority);
    final typeColor = _typeColor(c.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(
          color: isOverdue
              ? AdminTheme.crimson.withAlpha(100)
              : AdminTheme.border,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          onTap: () => _showDetails(c.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── سطر العلامات ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // شارة نوع المراسلة مع أيقونة
                    StatusBadge(
                      text: corrTypeLabel(c.type),
                      color: typeColor,
                    ),
                    const SizedBox(width: 6),
                    // رقم المرجعي
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface2,
                        borderRadius:
                            BorderRadius.circular(AdminTheme.radiusXs),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: Text(
                        c.refNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // شارة الحالة
                    StatusBadge(
                      text: corrStatusLabel(c.status),
                      color: _statusColor(c.status),
                    ),
                    const Spacer(),
                    // شارة التأخير (إن وُجدت)
                    if (isOverdue) ...[
                      StatusBadge(
                        text: 'متأخرة ${c.overdueDays} يوم',
                        color: AdminTheme.crimson,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // تاريخ آخر تحديث
                    Text(
                      _dateFormat.format(c.updatedAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ─── سطر الموضوع ───
                Text(
                  c.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AdminTheme.textMain,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // ─── خط فاصل خفيف ───
                const Divider(height: 1, color: AdminTheme.border),
                const SizedBox(height: 8),
                // ─── سطر المعلومات التفصيلية ───
                Row(
                  children: [
                    // أيقونة الأولوية مع النص
                    Icon(
                      _priorityIcon(c.priority),
                      size: 13,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 3),
                    StatusBadge(
                      text: priorityLabel(c.priority),
                      color: priorityColor,
                      fontSize: 10,
                    ),
                    const SizedBox(width: 10),
                    // اسم المرسل
                    if (c.senderName != null &&
                        c.senderName!.isNotEmpty) ...[
                      const Icon(Icons.person_rounded,
                          size: 13, color: AdminTheme.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          c.senderName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // اسم القسم
                    if (c.departmentName != null) ...[
                      const Icon(Icons.apartment_rounded,
                          size: 13, color: AdminTheme.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          c.departmentName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // عدادات الإحالات / التكليفات / الردود / المرفقات
                    _miniCount(
                        Icons.swap_horiz_rounded, c.referralsCount, 'إحالة'),
                    const SizedBox(width: 8),
                    _miniCount(
                        Icons.assignment_rounded, c.tasksCount, 'تكليف'),
                    const SizedBox(width: 8),
                    _miniCount(Icons.reply_rounded, c.repliesCount, 'رد'),
                    const SizedBox(width: 8),
                    _miniCount(
                        Icons.attach_file_rounded, c.attachmentsCount, 'مرفق'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── عداد صغير للإحالات / التكليفات / إلخ ───
  Widget _miniCount(IconData icon, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AdminTheme.textLight),
        const SizedBox(width: 2),
        Text(
          '$count $label',
          style: const TextStyle(fontSize: 10, color: AdminTheme.textLight),
        ),
      ],
    );
  }

  // ─── نافذة التفاصيل الكاملة ───

  void _showDetails(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<CorrDetail?>(
            future: AdminApiService().getCorrespondence(id),
            builder: (context, snapshot) {
              // حالة التحميل داخل النافذة
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 400,
                  height: 260,
                  child: LoadingWidget(message: 'جارٍ تحميل تفاصيل المراسلة…'),
                );
              }
              final d = snapshot.data;
              // حالة الخطأ داخل النافذة
              if (d == null) {
                return SizedBox(
                  width: 400,
                  height: 260,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminTheme.crimson.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded,
                            color: AdminTheme.crimson, size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل تفاصيل المراسلة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              }

              // ─── محتوى نافذة التفاصيل ───
              return SizedBox(
                width: 740,
                height: 660,
                child: Column(
                  children: [
                    // ─── رأس النافذة ───
                    _buildDialogHeader(ctx, d),
                    // ─── جسم النافذة القابل للتمرير ───
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          // موضوع المراسلة
                          Text(
                            d.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AdminTheme.textMain,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // شارات الأولوية / القسم / القناة / تاريخ الإغلاق
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _priorityBadgeRow(d.priority),
                              if (d.departmentName != null)
                                StatusBadge(
                                  text: 'القسم: ${d.departmentName}',
                                  color: AdminTheme.accent,
                                ),
                              if (d.channel != null &&
                                  d.channel!.isNotEmpty)
                                StatusBadge(
                                  text: 'القناة: ${d.channel}',
                                  color: AdminTheme.textMuted,
                                ),
                              if (d.closedAt != null)
                                StatusBadge(
                                  text:
                                      'أُغلقت: ${DateFormat('yyyy/MM/dd').format(d.closedAt!)}',
                                  color: AdminTheme.emerald,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ─── بيانات المرسل ───
                          _sectionTitle('بيانات المرسل', Icons.person_rounded),
                          _infoGrid([
                            ('الاسم', d.senderName ?? '-'),
                            ('البريد الإلكتروني', d.senderEmail ?? '-'),
                            ('الهاتف', d.senderPhone ?? '-'),
                            ('سجّلها', d.createdByName ?? '-'),
                            (
                              'تاريخ الاستلام',
                              d.receivedAt != null
                                  ? _dateFormat.format(d.receivedAt!)
                                  : _dateFormat.format(d.createdAt)
                            ),
                            (
                              'تاريخ الإرسال',
                              d.sentAt != null
                                  ? _dateFormat.format(d.sentAt!)
                                  : '-'
                            ),
                          ]),
                          const SizedBox(height: 16),
                          // ─── نص المراسلة ───
                          _sectionTitle(
                              'نص المراسلة', Icons.description_rounded),
                          _bodyBox(d.body),
                          const SizedBox(height: 16),
                          // ─── الإحالات ───
                          _sectionTitle(
                            'الإحالات (${d.referrals.length})',
                            Icons.swap_horiz_rounded,
                          ),
                          if (d.referrals.isEmpty)
                            _emptyHint('لا توجد إحالات')
                          else
                            ...d.referrals.map((r) => _listTile(
                                  icon: Icons.swap_horiz_rounded,
                                  iconColor: AdminTheme.accent,
                                  title: '${r.fromName} → ${r.toName}',
                                  subtitle: referralStatusLabel(r.status) +
                                      (r.dueDate != null
                                          ? ' — استحقاق: ${DateFormat('yyyy/MM/dd').format(r.dueDate!)}'
                                          : ''),
                                  extra: r.note,
                                )),
                          const SizedBox(height: 16),
                          // ─── التكليفات ───
                          _sectionTitle(
                            'التكليفات (${d.tasks.length})',
                            Icons.assignment_rounded,
                          ),
                          if (d.tasks.isEmpty)
                            _emptyHint('لا توجد تكليفات')
                          else
                            ...d.tasks.map((t) => _listTile(
                                  icon: Icons.assignment_rounded,
                                  iconColor: AdminTheme.purple,
                                  title: t.title,
                                  subtitle: '${taskStatusLabel(t.status)} — المنفذ: ${t.assignedToName}' +
                                      (t.dueDate != null
                                          ? ' — استحقاق: ${DateFormat('yyyy/MM/dd').format(t.dueDate!)}'
                                          : ''),
                                  extra: t.assignedByName.isNotEmpty
                                      ? 'كلّفه: ${t.assignedByName}'
                                      : null,
                                )),
                          const SizedBox(height: 16),
                          // ─── الردود ───
                          _sectionTitle(
                            'الردود (${d.replies.length})',
                            Icons.reply_rounded,
                          ),
                          if (d.replies.isEmpty)
                            _emptyHint('لا توجد ردود')
                          else
                            ...d.replies.map((r) => _listTile(
                                  icon: Icons.reply_rounded,
                                  iconColor: AdminTheme.emerald,
                                  title:
                                      '${r.authorName} — ${replyStatusLabel(r.status)}',
                                  subtitle: r.body,
                                )),
                          const SizedBox(height: 16),
                          // ─── المرفقات ───
                          _sectionTitle(
                            'المرفقات (${d.attachments.length})',
                            Icons.attach_file_rounded,
                          ),
                          if (d.attachments.isEmpty)
                            _emptyHint('لا توجد مرفقات')
                          else
                            ...d.attachments.map((a) => _listTile(
                                  icon: Icons.insert_drive_file_rounded,
                                  iconColor: AdminTheme.amber,
                                  title: a.fileName,
                                  subtitle:
                                      '${a.mimeType} — ${(a.size / 1024).toStringAsFixed(1)} كيلوبايت',
                                )),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── رأس نافذة التفاصيل ───
  Widget _buildDialogHeader(BuildContext ctx, CorrDetail d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AdminTheme.surface2,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: [
          // أيقونة النوع
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _typeColor(d.type).withAlpha(18),
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
            ),
            child: Icon(_typeIcon(d.type),
                size: 16, color: _typeColor(d.type)),
          ),
          const SizedBox(width: 8),
          // شارة النوع
          StatusBadge(
            text: corrTypeLabel(d.type),
            color: _typeColor(d.type),
          ),
          const SizedBox(width: 8),
          // الرقم المرجعي
          Text(
            d.refNumber,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AdminTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          // شارة الحالة
          StatusBadge(
            text: corrStatusLabel(d.status),
            color: _statusColor(d.status),
          ),
          const Spacer(),
          // زر الإغلاق
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // ─── شارة أولوية مع أيقونة ───
  Widget _priorityBadgeRow(String priority) {
    final color = _priorityColor(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_priorityIcon(priority), size: 13, color: color),
        const SizedBox(width: 3),
        StatusBadge(text: 'أولوية: ${priorityLabel(priority)}', color: color),
      ],
    );
  }

  // ─── عنوان قسم في النافذة ───
  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AdminTheme.accent.withAlpha(15),
              borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
            ),
            child: Icon(icon, size: 14, color: AdminTheme.accent),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AdminTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  // ─── شبكة بيانات الجهة المُرسِلة ───
  Widget _infoGrid(List<(String, String)> pairs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 10,
        children: pairs
            .map((p) => SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.$1,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AdminTheme.textLight,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.$2,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── صندوق نص المراسلة ───
  Widget _bodyBox(String? body) {
    final text = (body != null && body.trim().isNotEmpty) ? body : 'لا يوجد نص';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.7,
          color: AdminTheme.textMain,
        ),
      ),
    );
  }

  // ─── صف عنصر في قوائم الإحالات / التكليفات / الردود / المرفقات ───
  Widget _listTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(15),
              borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AdminTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                if (extra != null && extra.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    extra,
                    style: const TextStyle(
                        fontSize: 10.5, color: AdminTheme.textLight),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── نص تلميح فراغ ───
  Widget _emptyHint(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surface2,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined,
              size: 14, color: AdminTheme.textLight),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
                fontSize: 11.5, color: AdminTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
