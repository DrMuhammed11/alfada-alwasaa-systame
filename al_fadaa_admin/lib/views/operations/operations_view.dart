import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';

/// شاشة التشغيل الإداري: صندوق البريد الصادر، مسارات الاعتماد،
/// الكيانات اليتيمة، سجل الوكالات، وحالة النسخ الاحتياطي.
class OperationsView extends StatelessWidget {
  const OperationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.settings_suggest_rounded, color: AdminTheme.accent, size: 22),
                  const SizedBox(width: 8),
                  const Text('إدارة التشغيل والرقابة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AdminTheme.primary,
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: AdminTheme.primary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
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
      'SENT' => AdminTheme.emerald,
      'QUEUED' => AdminTheme.amber,
      'PAUSED' => const Color(0xFF8B5CF6),
      'FAILED' => AdminTheme.crimson,
      _ => AdminTheme.textMuted,
    };

String _statusLabel(String s) => switch (s) {
      'SENT' => 'أُرسلت',
      'QUEUED' => 'بانتظار الإرسال',
      'PAUSED' => 'موقوفة',
      'FAILED' => 'فاشلة نهائيًا',
      _ => s,
    };

Widget _badge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

Widget _errorBody(Future<void> Function() retry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: AdminTheme.crimson),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('إعادة المحاولة')),
      ],
    ),
  );
}

// ═══════════ صندوق الصادر ═══════════

class _OutboxTab extends StatefulWidget {
  const _OutboxTab();
  @override
  State<_OutboxTab> createState() => _OutboxTabState();
}

class _OutboxTabState extends State<_OutboxTab> with AutomaticKeepAliveClientMixin {
  static const _kinds = {'ALL': 'كل الحالات', 'QUEUED': 'بانتظار الإرسال', 'FAILED': 'فاشلة', 'PAUSED': 'موقوفة', 'SENT': 'أُرسلت'};
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
    setState(() { _isLoading = true; _hasError = false; });
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text('العدد: $_total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
              const Spacer(),
              ..._kinds.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 11)),
                      selected: _status == e.key,
                      selectedColor: AdminTheme.primary,
                      labelStyle: TextStyle(color: _status == e.key ? Colors.white : const Color(0xFF475569), fontSize: 11),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _status = e.key),
                    ),
                  )),
              IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: () => _load(page: 1)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? _errorBody(() => _load())
                  : _items.isEmpty
                      ? const Center(child: Text('لا توجد رسائل مطابقة', style: TextStyle(color: AdminTheme.textMuted)))
                      : ListView.builder(
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
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(m['refNumber'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                                          const SizedBox(width: 8),
                                          _badge(_statusLabel(status), _statusColor(status)),
                                          const SizedBox(width: 8),
                                          _badge('محاولة ${m['attempts'] ?? 0}/${m['maxAttempts'] ?? 3}', AdminTheme.textMuted),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text('إلى: ${m['to'] ?? '-'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                        if ((m['lastError'] ?? '').toString().isNotEmpty)
                                          Text('الخطأ: ${m['lastError']}', style: const TextStyle(fontSize: 10.5, color: AdminTheme.crimson), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  if (status == 'FAILED' || status == 'PAUSED')
                                    OutlinedButton.icon(
                                      onPressed: () => _action(m['id'], true),
                                      icon: const Icon(Icons.replay_rounded, size: 14),
                                      label: const Text('إعادة', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.primary, side: const BorderSide(color: AdminTheme.primary)),
                                    ),
                                  if (status == 'QUEUED') ...[
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      onPressed: () => _action(m['id'], false),
                                      icon: const Icon(Icons.pause_rounded, size: 14),
                                      label: const Text('إيقاف', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6), side: const BorderSide(color: Color(0xFF8B5CF6))),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
        if (!_isLoading && !_hasError && _items.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(children: [
              Text('الصفحة $_page من $_totalPages', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              const Spacer(),
              IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 18), onPressed: _page > 1 ? () => _load(page: _page - 1) : null),
              IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 18), onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null),
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
  static const _priorities = {'URGENT': 'عاجلة للغاية', 'HIGH': 'عالية', 'NORMAL': 'اعتيادية', 'LOW': 'منخفضة'};
  static const _roles = {'DEPT_MANAGER': 'مدير قسم', 'DEPUTY_GM': 'نائب المدير العام', 'GM': 'المدير العام', 'ADMIN': 'مدير النظام'};
  List<Map<String, dynamic>> _flows = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final flows = await AdminApiService().getWorkflows();
    if (!mounted) return;
    setState(() { _flows = flows; _isLoading = false; });
  }

  Future<void> _edit(Map<String, dynamic> flow) async {
    final priority = (flow['priority'] ?? 'NORMAL').toString();
    final existing = ((flow['steps'] as List?) ?? [])
        .map((s) => (s is Map ? s : Map<String, dynamic>.from(s))['requiredRole'].toString())
        .toList();

    final controller = TextEditingController(text: existing.join(','));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مسار اعتماد: ${_priorities[priority] ?? priority}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أدوار الاعتماد بالتسلسل — مفصولة بفواصل، تبدأ من المستوى 1 ولا تكون أولًا بأدنى من لاحقها:', style: TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'DEPT_MANAGER, GM', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              Text('الأدوار المتاحة: ${_roles.entries.map((e) => e.key).join(' / ')}', style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AdminTheme.primary), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    final steps = controller.text
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => _roles.containsKey(s))
        .toList();
    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أدوار صالحة'), backgroundColor: AdminTheme.crimson));
      return;
    }
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _badge(_priorities[priority] ?? priority, priority == 'URGENT' ? AdminTheme.crimson : (priority == 'HIGH' ? AdminTheme.amber : AdminTheme.accent)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps.isEmpty
                        ? 'بدون خطوات'
                        : steps.asMap().entries.map((e) {
                            final s = (e.value is Map ? e.value : Map<String, dynamic>.from(e.value));
                            return 'م${e.key + 1}: ${_roles[s['requiredRole']] ?? s['requiredRole']}';
                          }).join(' ← '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: AdminTheme.accent), tooltip: 'تعديل', onPressed: () => _edit(flow)),
              ],
            ),
          );
        }),
      ],
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    final report = await AdminApiService().getOrphans();
    if (!mounted) return;
    setState(() { _report = report; _isLoading = false; _hasError = report == null; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return _errorBody(_load);
    final summary = (_report?['summary'] as Map?) ?? {};
    return ListView(
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (summary['totalOrphans'] ?? 0) == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (summary['totalOrphans'] ?? 0) == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
          ),
          child: Text(
            (summary['totalOrphans'] ?? 0) == 0
                ? 'لا توجد كيانات يتيمة — سلامة بنيوية كاملة'
                : 'رُصدت ${(summary['totalOrphans'] ?? 0)} كيانات يتيمة تحتاج معالجة يدوية (فتح المراسلة وإتمام دورتها)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (summary['totalOrphans'] ?? 0) == 0 ? AdminTheme.emerald : AdminTheme.crimson),
          ),
        ),
        const SizedBox(height: 10),
        Text('آخر فحص: ${_dtFormat.format(DateTime.now())}', style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
      ],
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(children: [
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await AdminApiService().getDelegations();
    if (!mounted) return;
    setState(() { _items = items; _isLoading = false; });
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('لا توجد تفويضات مسجلة', style: TextStyle(color: AdminTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final d = _items[i];
        final isActive = d['isActive'] == true || (d['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المفوِّض: ${_nameOf(d, 'delegator')} → الوكيل: ${_nameOf(d, 'delegate')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(children: [
                      _badge(isActive ? 'نشط' : 'منتهٍ', isActive ? AdminTheme.emerald : AdminTheme.textMuted),
                      const SizedBox(width: 6),
                      if (d['startsAt'] != null) _metaChip('من: ${_dtFormat.format(DateTime.parse(d['startsAt']).toLocal())}'),
                      const SizedBox(width: 6),
                      if (d['endsAt'] != null) _metaChip('إلى: ${_dtFormat.format(DateTime.parse(d['endsAt']).toLocal())}'),
                    ]),
                  ],
                ),
              ),
              if (isActive)
                OutlinedButton.icon(
                  onPressed: () => _terminate(d),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('إنهاء', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminTheme.crimson, side: const BorderSide(color: AdminTheme.crimson)),
                ),
            ],
          ),
        );
      },
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
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
    setState(() { _isLoading = true; _hasError = false; });
    final s = await AdminApiService().getBackupStatus();
    if (!mounted) return;
    setState(() { _status = s; _isLoading = false; _hasError = s == null; });
  }

  String _sizeOf(num bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return _errorBody(_load);
    final files = ((_status?['files'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final enabled = _status?['enabled'] == true;
    final offsite = _status?['offsiteConfigured'] == true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _badge(enabled ? 'النسخ المجدول مفعّل' : 'النسخ المجدول معطّل (BACKUP_ENABLED=false)', enabled ? AdminTheme.emerald : AdminTheme.crimson),
            const SizedBox(width: 8),
            _badge(offsite ? 'رفع خارجي مضبوط' : 'لا رفع خارجي — القرص المحلي فاني!', offsite ? AdminTheme.emerald : AdminTheme.crimson),
            const SizedBox(width: 8),
            _badge('الاحتفاظ: ${_status?['retentionDays'] ?? 7} يوم', AdminTheme.textMuted),
          ],
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد نسخ محفوظة محليًا بعد', style: TextStyle(color: AdminTheme.textMuted))))
        else
          ...files.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(children: [
                  const Icon(Icons.archive_rounded, size: 16, color: AdminTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f['name'], style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: Color(0xFF334155)))),
                  Text(_sizeOf((f['sizeBytes'] as num?) ?? 0), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                  const SizedBox(width: 12),
                  Text(_dtFormat.format(DateTime.parse(f['modifiedAt']).toLocal()), style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
                ]),
              )),
      ],
    );
  }
}
