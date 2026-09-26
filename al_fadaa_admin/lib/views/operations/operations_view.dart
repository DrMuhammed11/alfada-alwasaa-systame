import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_utils.dart';

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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AdminTheme.primary,
                      unselectedLabelColor: AdminTheme.textMuted,
                      indicatorColor: AdminTheme.primary,
                      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                  _OutboxTab(),
                  _WorkflowsTab(),
                  _OrphansTab(),
                  _DelegationsTab(),
                  _BackupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── أدوات مشتركة ───

final DateFormat _dtFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

Color _statusColor(String s) => switch (s) {
      'SENT'   => AdminTheme.emerald,
      'QUEUED' => AdminTheme.amber,
      'PAUSED' => const Color(0xFF8B5CF6),
      'FAILED' => AdminTheme.crimson,
      _        => AdminTheme.textMuted,
    };

String _statusLabel(String s) => switch (s) {
      'SENT'   => 'أُرسلت',
      'QUEUED' => 'بانتظار الإرسال',
      'PAUSED' => 'موقوفة',
      'FAILED' => 'فاشلة نهائيًا',
      _        => s,
    };

// ═══════════ صندوق الصادر ═══════════

class _OutboxTab extends StatefulWidget {
  const _OutboxTab();
  @override
  State<_OutboxTab> createState() => _OutboxTabState();
}

class _OutboxTabState extends State<_OutboxTab> with AutomaticKeepAliveClientMixin {
  static const _kinds = {
    'ALL': 'كل الحالات',
    'QUEUED': 'بانتظار الإرسال',
    'FAILED': 'فاشلة',
    'PAUSED': 'موقوفة',
    'SENT': 'أُرسلت',
  };
  List<Map<String, dynamic>> _items = [];
  String _status = 'ALL';
  int _page = 1, _totalPages = 1, _total = 0;
  bool _isLoading = true, _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getOutbox(status: _status, page: page ?? _page);
    if (!mounted) return;
    setState(() {
      _items = res == null
          ? []
          : ((res['items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
      _total = (res?['total'] as num?)?.toInt() ?? 0;
      _totalPages = (res?['totalPages'] as num?)?.toInt() ?? 1;
      _page = (res?['page'] as num?)?.toInt() ?? 1;
      _isLoading = false;
      _hasError = res == null;
    });
  }

  Future<void> _action(String id, bool retry) async {
    final res = retry
        ? await AdminApiService().retryOutbox(id)
        : await AdminApiService().pauseOutbox(id);
    if (!mounted) return;
    final error = res?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? (retry ? 'أُعيدت جدولة الرسالة للإرسال' : 'أُوقفت إعادة المحاولة')),
      backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // شريط فلتر الحالة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'العدد: $_total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted),
              ),
              const Spacer(),
              ..._kinds.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 11)),
                      selected: _status == e.key,
                      selectedColor: AdminTheme.primary,
                      labelStyle: TextStyle(
                        color: _status == e.key ? Colors.white : AdminTheme.textMuted,
                        fontSize: 11,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(() => _status = e.key);
                        _load(page: 1);
                      },
                    ),
                  )),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => _load(page: 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              // حالة التحميل — ودجة موحدة
              ? const LoadingWidget(message: 'جارٍ تحميل صندوق الصادر...')
              : _hasError
                  // حالة الخطأ — ودجة موحدة
                  ? ErrorStateWidget(
                      message: 'تعذر تحميل صندوق الصادر',
                      onRetry: _load,
                    )
                  : _items.isEmpty
                      // حالة الفراغ — ودجة موحدة
                      ? const EmptyStateWidget(
                          message: 'لا توجد رسائل مطابقة',
                          icon: Icons.outbox_rounded,
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(page: _page),
                          color: AdminTheme.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                            final m = _items[i];
                            final status = (m['status'] ?? '').toString();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                                border: Border.all(color: AdminTheme.border),
                                // ظل موحد من AdminTheme
                                boxShadow: AdminTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(
                                            m['refNumber'] ?? '',
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // شارة حالة الرسالة — StatusBadge من app_utils
                                          StatusBadge(
                                            text: _statusLabel(status),
                                            color: _statusColor(status),
                                          ),
                                          const SizedBox(width: 8),
                                          // شارة عدد المحاولات
                                          StatusBadge(
                                            text: 'محاولة ${m['attempts'] ?? 0}/${m['maxAttempts'] ?? 3}',
                                            color: AdminTheme.textMuted,
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(
                                          'إلى: ${m['to'] ?? '-'}',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                        ),
                                        if ((m['lastError'] ?? '').toString().isNotEmpty)
                                          Text(
                                            'الخطأ: ${m['lastError']}',
                                            style: const TextStyle(fontSize: 10.5, color: AdminTheme.crimson),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (status == 'FAILED' || status == 'PAUSED')
                                    OutlinedButton.icon(
                                      onPressed: () => _action(m['id'], true),
                                      icon: const Icon(Icons.replay_rounded, size: 14),
                                      label: const Text('إعادة', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AdminTheme.primary,
                                        side: const BorderSide(color: AdminTheme.primary),
                                      ),
                                    ),
                                  if (status == 'QUEUED') ...[
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed: () => _action(m['id'], false),
                                      icon: const Icon(Icons.pause_rounded, size: 14),
                                      label: const Text('إيقاف', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF8B5CF6),
                                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              );
                            },
                          ),
                        ),
        ),
        // شريط الترقيم للصادر
        if (!_isLoading && !_hasError && _items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AdminTheme.border)),
            ),
            child: Row(children: [
              Text(
                'الصفحة $_page من $_totalPages',
                style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null,
              ),
            ]),
          ),
      ],
    );
  }
}

// ═══════════ مسارات الاعتماد ═══════════

class _WorkflowsTab extends StatefulWidget {
  const _WorkflowsTab();
  @override
  State<_WorkflowsTab> createState() => _WorkflowsTabState();
}

class _WorkflowsTabState extends State<_WorkflowsTab> with AutomaticKeepAliveClientMixin {
  static const _priorities = {
    'URGENT': 'عاجلة للغاية',
    'HIGH': 'عالية',
    'NORMAL': 'اعتيادية',
    'LOW': 'منخفضة',
  };
  static const _roles = {
    'DEPT_MANAGER': 'مدير قسم',
    'DEPUTY_GM': 'نائب المدير العام',
    'GM': 'المدير العام',
    'ADMIN': 'مدير النظام',
  };
  List<Map<String, dynamic>> _flows = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getWorkflows();
    if (!mounted) return;
    setState(() {
      _flows = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _edit(Map<String, dynamic> flow) async {
    final priority = (flow['priority'] ?? 'NORMAL').toString();
    final existing = ((flow['steps'] as List?) ?? [])
        .map((s) => (s is Map ? s : Map<String, dynamic>.from(s))['requiredRole'].toString())
        .toList();

    final steps = await showDialog<List<String>>(
      context: context,
      builder: (_) => _WorkflowStepsDialog(
        priorityLabel: _priorities[priority] ?? priority,
        initialSteps: existing,
      ),
    );
    if (steps == null || !mounted) return;

    final res = await AdminApiService().updateWorkflow(priority, [
      for (var i = 0; i < steps.length; i++)
        {'level': '${i + 1}', 'requiredRole': steps[i]},
    ]);
    if (!mounted) return;
    final error = res?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم تحديث مسار الاعتماد بنجاح'),
      backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
    ));
    if (error == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل مسارات الاعتماد...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل مسارات الاعتماد',
        onRetry: _load,
      );
    }
    // حالة الفراغ — ودجة موحدة
    if (_flows.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد مسارات اعتماد معرّفة',
        icon: Icons.fact_check_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بانر توضيحي لمسارات الاعتماد
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Text(
            'مسار الاعتماد يحدد مستويات الموافقة الإلزامية قبل إرسال الرد، حسب درجة أولوية المراسلة. التعديل يسري على الردود المرفوعة لاحقًا فقط.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
          ),
        ),
        const SizedBox(height: 12),
        ..._flows.map((flow) {
          final priority = (flow['priority'] ?? '').toString();
          final steps = ((flow['steps'] as List?) ?? []);
          // لون شارة الأولوية
          final priorityColor = priority == 'URGENT'
              ? AdminTheme.crimson
              : (priority == 'HIGH' ? AdminTheme.amber : AdminTheme.accent);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              border: Border.all(color: AdminTheme.border),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: Row(
              children: [
                // شارة الأولوية — StatusBadge من app_utils
                StatusBadge(
                  text: _priorities[priority] ?? priority,
                  color: priorityColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps.isEmpty
                        ? 'بدون خطوات'
                        : steps.asMap().entries.map((e) {
                            final s = (e.value is Map
                                ? e.value
                                : Map<String, dynamic>.from(e.value));
                            return 'م${e.key + 1}: ${_roles[s['requiredRole']] ?? s['requiredRole']}';
                          }).join(' ← '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 17, color: AdminTheme.accent),
                  tooltip: 'تعديل',
                  onPressed: () => _edit(flow),
                ),
              ],
            ),
          );
        }),
      ],
        ),
    );
  }
}

// ═══════════ الكيانات اليتيمة ═══════════

class _OrphansTab extends StatefulWidget {
  const _OrphansTab();
  @override
  State<_OrphansTab> createState() => _OrphansTabState();
}

class _OrphansTabState extends State<_OrphansTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _report;
  bool _isLoading = true, _hasError = false;
  // وقت إتمام آخر فحص ناجح — من الخادم فعلياً لا من لحظة البناء
  DateTime? _lastCheckedAt;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final report = await AdminApiService().getOrphans();
    if (!mounted) return;
    setState(() {
      _report = report;
      _isLoading = false;
      _hasError = report == null;
      if (report != null) _lastCheckedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ فحص الكيانات اليتيمة...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل تقرير الكيانات اليتيمة',
        onRetry: _load,
      );
    }
    final summary = (_report?['summary'] as Map?) ?? {};
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _statCard('إحالات مفتوحة على مراسلات مغلقة', summary['openReferralsCount'], AdminTheme.crimson),
            const SizedBox(width: 10),
            _statCard('تكليفات معلقة على مراسلات مغلقة', summary['pendingTasksCount'], AdminTheme.amber),
            const SizedBox(width: 10),
            _statCard('مسودات ردود على مراسلات مغلقة', summary['draftRepliesCount'], const Color(0xFF8B5CF6)),
          ],
        ),
        const SizedBox(height: 12),
        // بطاقة ملخص النزاهة البنيوية
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (summary['totalOrphans'] ?? 0) == 0
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
              color: (summary['totalOrphans'] ?? 0) == 0
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFFECACA),
            ),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Text(
            (summary['totalOrphans'] ?? 0) == 0
                ? 'لا توجد كيانات يتيمة — سلامة بنيوية كاملة'
                : 'رُصدت ${(summary['totalOrphans'] ?? 0)} كيانات يتيمة تحتاج معالجة يدوية (فتح المراسلة وإتمام دورتها)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (summary['totalOrphans'] ?? 0) == 0 ? AdminTheme.emerald : AdminTheme.crimson,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'آخر فحص: ${_lastCheckedAt != null ? _dtFormat.format(_lastCheckedAt!) : '—'}',
          style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
        ),
      ],
        ),
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
          border: Border.all(color: AdminTheme.border),
          boxShadow: AdminTheme.cardShadow,
        ),
        child: Column(children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted),
          ),
        ]),
      ),
    );
  }
}

// ═══════════ سجل الوكالات ═══════════

class _DelegationsTab extends StatefulWidget {
  const _DelegationsTab();
  @override
  State<_DelegationsTab> createState() => _DelegationsTabState();
}

class _DelegationsTabState extends State<_DelegationsTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getDelegations();
    if (!mounted) return;
    setState(() {
      _items = res.items;
      _isLoading = false;
      _hasError = res.error;
    });
  }

  Future<void> _terminate(Map<String, dynamic> d) async {
    final res = await AdminApiService().terminateDelegation(d['id']);
    if (!mounted) return;
    final error = res?['__error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم إنهاء التفويض'),
      backgroundColor: error != null ? AdminTheme.crimson : AdminTheme.emerald,
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل سجل الوكالات...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل سجل الوكالات',
        onRetry: _load,
      );
    }
    // حالة الفراغ — ودجة موحدة
    if (_items.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد تفويضات مسجلة',
        icon: Icons.swap_horiz_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final d = _items[i];
        final isActive =
            d['isActive'] == true || (d['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(
              color: isActive ? const Color(0xFFA7F3D0) : AdminTheme.border,
            ),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المفوِّض: ${_nameOf(d, 'delegator')} → الوكيل: ${_nameOf(d, 'delegate')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      // شارة حالة التفويض — StatusBadge من app_utils
                      StatusBadge(
                        text: isActive ? 'نشط' : 'منتهٍ',
                        color: isActive ? AdminTheme.emerald : AdminTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      if (d['startsAt'] != null)
                        _metaChip('من: ${_dtFormat.format(DateTime.parse(d['startsAt']).toLocal())}'),
                      const SizedBox(width: 6),
                      if (d['endsAt'] != null)
                        _metaChip('إلى: ${_dtFormat.format(DateTime.parse(d['endsAt']).toLocal())}'),
                    ]),
                  ],
                ),
              ),
              if (isActive)
                OutlinedButton.icon(
                  onPressed: () => _terminate(d),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('إنهاء', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.crimson,
                    side: const BorderSide(color: AdminTheme.crimson),
                  ),
                ),
            ],
          ),
        );
      },
      ),
    );
  }

  String _nameOf(Map<String, dynamic> d, String key) {
    final obj = d[key];
    if (obj is Map) return (obj['name'] ?? '-').toString();
    return (d['${key}Name'] ?? '-').toString();
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusXs),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted)),
    );
  }
}

// ═══════════ النسخ الاحتياطي ═══════════

class _BackupTab extends StatefulWidget {
  const _BackupTab();
  @override
  State<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<_BackupTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _status;
  bool _isLoading = true, _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final s = await AdminApiService().getBackupStatus();
    if (!mounted) return;
    setState(() {
      _status = s;
      _isLoading = false;
      _hasError = s == null;
    });
  }

  String _sizeOf(num bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // حالة التحميل — ودجة موحدة
    if (_isLoading) return const LoadingWidget(message: 'جارٍ تحميل حالة النسخ الاحتياطي...');
    // حالة الخطأ — ودجة موحدة
    if (_hasError) {
      return ErrorStateWidget(
        message: 'تعذر تحميل حالة النسخ الاحتياطي',
        onRetry: _load,
      );
    }
    final files = ((_status?['files'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final enabled = _status?['enabled'] == true;
    final offsite = _status?['offsiteConfigured'] == true;
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // شارات حالة النسخ الاحتياطي — StatusBadge من app_utils
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            StatusBadge(
              text: enabled
                  ? 'النسخ المجدول مفعّل'
                  : 'النسخ المجدول معطّل (BACKUP_ENABLED=false)',
              color: enabled ? AdminTheme.emerald : AdminTheme.crimson,
            ),
            StatusBadge(
              text: offsite
                  ? 'رفع خارجي مضبوط'
                  : 'لا رفع خارجي — القرص المحلي فاني!',
              color: offsite ? AdminTheme.emerald : AdminTheme.crimson,
            ),
            StatusBadge(
              text: 'الاحتفاظ: ${_status?['retentionDays'] ?? 7} يوم',
              color: AdminTheme.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          const EmptyStateWidget(
            message: 'لا توجد نسخ محفوظة محليًا بعد',
            icon: Icons.backup_rounded,
          )
        else
          ...files.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: Border.all(color: AdminTheme.border),
                  boxShadow: AdminTheme.cardShadow,
                ),
                child: Row(children: [
                  const Icon(Icons.archive_rounded, size: 16, color: AdminTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f['name'],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    _sizeOf((f['sizeBytes'] as num?) ?? 0),
                    style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dtFormat.format(DateTime.parse(f['modifiedAt']).toLocal()),
                    style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted),
                  ),
                ]),
              )),
      ],
        ),
    );
  }
}

/// نافذة تحرير مسار الاعتماد: اختيار الأدوار بالتسلسل عبر رقائق مع
/// إعادة ترتيب صريحة (رفع/خفض) — بدل الحقل النصي المفصول بفواصل
class _WorkflowStepsDialog extends StatefulWidget {
  final String priorityLabel;
  final List<String> initialSteps;

  const _WorkflowStepsDialog({required this.priorityLabel, required this.initialSteps});

  @override
  State<_WorkflowStepsDialog> createState() => _WorkflowStepsDialogState();
}

class _WorkflowStepsDialogState extends State<_WorkflowStepsDialog> {
  static const _roles = {
    'DEPT_MANAGER': 'مدير قسم',
    'DEPUTY_GM': 'نائب المدير العام',
    'GM': 'المدير العام',
    'ADMIN': 'مدير النظام',
  };

  late final List<String> _steps;

  @override
  void initState() {
    super.initState();
    // الاحتفاظ بالأدوار المعروفة فقط وبلا تكرار
    _steps = [
      for (final s in widget.initialSteps)
        if (_roles.containsKey(s.trim().toUpperCase()) && !_steps.contains(s.trim().toUpperCase()))
          s.trim().toUpperCase(),
    ];
  }

  void _toggle(String role) {
    setState(() {
      if (_steps.contains(role)) {
        _steps.remove(role);
      } else {
        _steps.add(role);
      }
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _steps.length) return;
    setState(() => _steps.insert(target, _steps.removeAt(index)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'مسار اعتماد: ${widget.priorityLabel}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر أدوار الاعتماد بالتسلسل — الترتيب المذكور هو ترتيب الموافقة (المستوى 1 أولًا):',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            // التسلسل الحالي
            if (_steps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.bgLight,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: const Text(
                  'لم يُختر أي دور بعد — أضف من الأدوار المتاحة أدناه',
                  style: TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                ),
              )
            else
              for (var i = 0; i < _steps.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface2,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Row(
                    children: [
                      StatusBadge(text: 'م${i + 1}', color: AdminTheme.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _roles[_steps[i]] ?? _steps[i],
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 15),
                        tooltip: 'رفع مستوى',
                        visualDensity: VisualDensity.compact,
                        onPressed: i > 0 ? () => _move(i, -1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                        tooltip: 'خفض مستوى',
                        visualDensity: VisualDensity.compact,
                        onPressed: i < _steps.length - 1 ? () => _move(i, 1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 15, color: AdminTheme.crimson),
                        tooltip: 'إزالة من المسار',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _toggle(_steps[i]),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            const Text(
              'الأدوار المتاحة — انقر للإضافة أو الإزالة:',
              style: TextStyle(fontSize: 10.5, color: AdminTheme.textMuted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in _roles.entries)
                  FilterChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    selected: _steps.contains(e.key),
                    onSelected: (_) => _toggle(e.key),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _steps.isEmpty ? null : () => Navigator.pop(context, List<String>.of(_steps)),
          style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
