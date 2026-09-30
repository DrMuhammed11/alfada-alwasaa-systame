import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/app_utils.dart';
import '../../models/correspondence_model.dart';
import 'corr_style.dart';
import 'correspondence_chat_screen.dart';

/// إدارة المراسلات — نمط محادثات واتساب
/// كل مراسلة جذرية هي «محادثة»: رسائل البريد الواردة من نفس البريد
/// والردود الصادرة المرسلة للعميل تُجمَّع تحت الجذر في الخادم (parentId)
/// فتعرض القائمة المحادثات وفتحها يعرض السلسلة كاملة بفقاعات دردشة
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
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<CorrListItem> _corrs = [];
  List<({String id, String name})> _departments = [];
  bool _isLoading = true; // التحميل الأول الكامل
  bool _isLoadingMore = false; // تحميل الصفحة التالية
  bool _hasError = false;

  String _type = 'ALL';
  String _status = 'ALL';
  String _priority = 'ALL';
  String _departmentId = 'ALL';
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    // تمرير لا نهائي بنمط واتساب: الاقتراب من نهاية القائمة يجلب الصفحة التالية
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _type != 'ALL' ||
      _status != 'ALL' ||
      _priority != 'ALL' ||
      _departmentId != 'ALL';

  Future<void> _loadInitial() async {
    // الأقسام وأول صفحة بالتوازي — الأقسام لعناصر الفلترة فقط فلا تحجب القائمة
    final deptsFuture = AdminApiService().getDepartments();
    await _loadPage(1, resetList: true);
    final deptsRes = await deptsFuture;
    if (mounted) {
      setState(() =>
          _departments = deptsRes.items.map((d) => (id: d.id, name: d.name)).toList());
    }
  }

  /// تحديث صامت يحفظ موضع التمرير — بعد العودة من الدردشة أو السحب للتحديث
  Future<void> _refreshSilently() async {
    final res = await AdminApiService().getCorrespondences(
      type: _type,
      status: _status,
      priority: _priority,
      departmentId: _departmentId,
      q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      page: 1,
      limit: _limit,
    );
    if (!mounted || res.error) return;
    setState(() {
      _corrs = res.items;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
    });
  }

  Future<void> _loadPage(int page, {required bool resetList}) async {
    if (resetList) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    final res = await AdminApiService().getCorrespondences(
      type: _type,
      status: _status,
      priority: _priority,
      departmentId: _departmentId,
      q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      page: page,
      limit: _limit,
    );
    if (!mounted) return;
    setState(() {
      if (res.error) {
        _hasError = resetList || _corrs.isEmpty;
      } else {
        _corrs = resetList ? res.items : [..._corrs, ...res.items];
        _page = res.page;
        _totalPages = res.totalPages;
        _total = res.total;
      }
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || _hasError) return;
    if (_page >= _totalPages) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_page + 1, resetList: false);
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadPage(1, resetList: true);
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
    await _loadPage(1, resetList: true);
  }

  void _applyFilter(void Function() apply) {
    apply();
    _loadPage(1, resetList: true);
  }

  // ─── ألوان دلالية مشتركة من CorrStyle ───
  Color _statusColor(String s) => CorrStyle.statusColor(s);
  Color _typeColor(String t) => CorrStyle.typeColor(t);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── شريط العنوان والبحث والفلاتر ───
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AdminTheme.primary,
        border: Border(bottom: BorderSide(color: AdminTheme.borderDark)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── العنوان والعداد والتحديث ───
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.forum_rounded,
                    color: Colors.white, size: AdminTheme.iconMd),
                const SizedBox(width: 8),
                const Text(
                  'المراسلات — المحادثات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AdminTheme.fontLg,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(28),
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusSm),
                  ),
                  child: Text(
                    AppFormatters.number(_total),
                    style: const TextStyle(
                      fontSize: AdminTheme.fontSm,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      size: AdminTheme.iconSm, color: Colors.white),
                  tooltip: 'تحديث القائمة',
                  onPressed: _refreshSilently,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ─── البحث ───
            SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _loadPage(1, resetList: true),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                    fontSize: AdminTheme.fontMd, color: AdminTheme.textMain),
                decoration: InputDecoration(
                  hintText:
                      'ابحث بالموضوع، الرقم المرجعي، أو اسم المرسل...',
                  hintStyle: const TextStyle(
                      fontSize: AdminTheme.fontBase,
                      color: AdminTheme.textLight),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: AdminTheme.iconSm, color: AdminTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: AdminTheme.iconSm,
                              color: AdminTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _loadPage(1, resetList: true);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AdminTheme.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ─── فلاتر أفقية قابلة للتمرير (مناسبة للهاتف) ───
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterDropdown(
                      value: _type,
                      items: const {
                        'ALL': 'كل الأنواع',
                        'INCOMING': 'وارد',
                        'OUTGOING': 'صادر',
                        'INTERNAL': 'داخلي',
                      },
                      onChanged: (v) =>
                          _applyFilter(() => _type = v),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterDropdown(
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
                      onChanged: (v) =>
                          _applyFilter(() => _status = v),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterDropdown(
                      value: _priority,
                      items: const {
                        'ALL': 'كل الأولويات',
                        'URGENT': 'عاجلة للغاية',
                        'HIGH': 'عالية',
                        'NORMAL': 'اعتيادية',
                        'LOW': 'منخفضة',
                      },
                      onChanged: (v) =>
                          _applyFilter(() => _priority = v),
                    ),
                    const SizedBox(width: 6),
                    _buildFilterDropdown(
                      value: _departmentId,
                      items: {
                        'ALL': 'كل الأقسام',
                        for (final d in _departments) d.id: d.name,
                      },
                      onChanged: (v) =>
                          _applyFilter(() => _departmentId = v),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('مسح الفلاتر',
                            style: TextStyle(
                                fontSize: AdminTheme.fontSm,
                                color: AdminTheme.crimson)),
                        avatar: const Icon(Icons.filter_alt_off_rounded,
                            size: AdminTheme.iconXs,
                            color: AdminTheme.crimson),
                        side:
                            BorderSide(color: AdminTheme.crimson.withAlpha(90)),
                        backgroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        onPressed: _clearFilters,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── قائمة منسدلة مضغوطة داخل الشريط الداكن ───
  Widget _buildFilterDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontSize: AdminTheme.fontSm,
            color: AdminTheme.textMain,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: AdminTheme.iconSm, color: AdminTheme.textMuted),
          items: items.entries
              .map((e) => DropdownMenuItem(
                  value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  // ─── جسم قائمة المحادثات ───
  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'جارٍ تحميل المحادثات…');
    }
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل المراسلات من الخادم',
        onRetry: () => _loadPage(1, resetList: true),
      );
    }
    if (_corrs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.forum_outlined,
        message: 'لا توجد محادثات مطابقة للفلاتر المحددة',
        actionLabel: _hasActiveFilters ? 'مسح الفلاتر' : null,
        onAction: _hasActiveFilters ? _clearFilters : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshSilently,
      color: AdminTheme.accent,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _corrs.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(
            height: 1, thickness: 0.5, indent: 68, color: AdminTheme.border),
        itemBuilder: (context, index) {
          if (index >= _corrs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          return _buildConversationTile(_corrs[index]);
        },
      ),
    );
  }

  // ─── بلاطة محادثة واحدة — نمط واتساب ───
  Widget _buildConversationTile(CorrListItem c) {
    final statusColor = _statusColor(c.status);
    final typeColor = _typeColor(c.type);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openConversation(c),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── الصورة الرمزية ───
              CorrStyle.avatar(
                name: c.senderName,
                seed: c.senderEmail ?? c.senderName ?? c.refNumber,
              ),
              const SizedBox(width: 10),
              // ─── المحتوى ثلاثي الأسطر ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم + الوقت
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (c.senderName?.trim().isNotEmpty == true)
                                ? c.senderName!
                                : 'جهة غير مسجلة',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AdminTheme.fontLg,
                              color: AdminTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          CorrStyle.smartTime(c.updatedAt),
                          style: TextStyle(
                            fontSize: AdminTheme.fontXs,
                            fontWeight: FontWeight.w600,
                            color:
                                statusColor == AdminTheme.emerald ? statusColor : AdminTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // الموضوع + حالة المعاملة
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.subject,
                            style: const TextStyle(
                              fontSize: AdminTheme.fontBase,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.textHeading,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusDot(c.status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // معاينة آخر رسالة + شارات العدّادات
                    Row(
                      children: [
                        if (c.isOverdue) ...[
                          Icon(Icons.alarm_rounded,
                              size: AdminTheme.iconXs,
                              color: AdminTheme.crimson),
                          const SizedBox(width: 3),
                          Text(
                            'متأخرة ${AppFormatters.number(c.overdueDays)} يوم',
                            style: const TextStyle(
                              fontSize: AdminTheme.fontXs,
                              fontWeight: FontWeight.bold,
                              color: AdminTheme.crimson),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            c.lastMessagePreview.isEmpty
                                ? '(بدون نص)'
                                : c.lastMessagePreview,
                            style: const TextStyle(
                              fontSize: AdminTheme.fontSm,
                              color: AdminTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // شارة نوع المحادثة
                        Icon(
                          switch (c.type) {
                            'INCOMING' => Icons.call_received_rounded,
                            'OUTGOING' => Icons.call_made_rounded,
                            _ => Icons.sync_alt_rounded,
                          },
                          size: AdminTheme.iconXs,
                          color: typeColor,
                        ),
                        if (c.attachmentsCount > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.attach_file_rounded,
                              size: AdminTheme.iconXs,
                              color: AdminTheme.textLight),
                        ],
                        // عدد رسائل المحادثة (1 + التعقيبات)
                        if (c.childrenCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AdminTheme.accent.withAlpha(20),
                              borderRadius: BorderRadius.circular(
                                  AdminTheme.radiusSm),
                            ),
                            child: Text(
                              '+${AppFormatters.number(c.childrenCount)}',
                              style: const TextStyle(
                                fontSize: AdminTheme.fontXs,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// نقطة حالة المعاملة مع التسمية — تلخيص دائري صغير بدل شارات مربعة
  Widget _statusDot(String status, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          corrStatusLabel(status),
          style: TextStyle(
              fontSize: AdminTheme.fontXs,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ],
    );
  }

  // ─── فتح محادثة ───
  Future<void> _openConversation(CorrListItem c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CorrespondenceChatScreen(conversation: c),
      ),
    );
    // بعد العودة: تحديث صامت — قد تكون تغيرت حالة المحادثة أو وصلت رسائل
    if (mounted) _refreshSilently();
  }
}
