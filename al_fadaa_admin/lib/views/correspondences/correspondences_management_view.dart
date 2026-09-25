import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/correspondence_model.dart';

/// إدارة المراسلات — نطاق الإدارة العليا (كل المراسلات)
/// فلاتر: النوع، الحالة، الأولوية، القسم، بحث نصي — مع ترقيم صفحات وتفاصيل كاملة
class CorrespondencesManagementView extends StatefulWidget {
  const CorrespondencesManagementView({super.key});

  @override
  State<CorrespondencesManagementView> createState() => _CorrespondencesManagementViewState();
}

class _CorrespondencesManagementViewState extends State<CorrespondencesManagementView> {
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
    final depts = await AdminApiService().getDepartments();
    if (mounted) {
      setState(() => _departments = depts.map((d) => (id: d.id, name: d.name)).toList());
    }
    await _load(page: 1);
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
      q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: AdminTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text('إدارة المراسلات — النطاق الكامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text('العدد: $_total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'تحديث القائمة',
                onPressed: () => _load(page: _page),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'ابحث بالموضوع، الرقم المرجعي، أو اسم المرسل...',
                      hintStyle: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      filled: true,
                      fillColor: Color(0xFFF8FAFC),
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
                  label: const Text('مسح الفلاتر', style: TextStyle(fontSize: 11, color: AdminTheme.crimson)),
                  avatar: const Icon(Icons.filter_alt_off_rounded, size: 15, color: AdminTheme.crimson),
                  side: BorderSide(color: AdminTheme.crimson.withAlpha(80)),
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AdminTheme.crimson),
            const SizedBox(height: 10),
            const Text('تعذر تحميل المراسلات من الخادم', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _load(page: _page),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_corrs.isEmpty) {
      return const Center(
        child: Text('لا توجد مراسلات مطابقة للفلاتر المحددة', style: TextStyle(color: AdminTheme.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _corrs.length,
        itemBuilder: (context, index) => _buildCorrCard(_corrs[index]),
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_isLoading || _hasError || _corrs.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            'الصفحة $_page من $_totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'الصفحة السابقة',
            onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'الصفحة التالية',
            onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null,
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
        'INCOMING' => const Color(0xFF0284C7),
        'OUTGOING' => AdminTheme.emerald,
        'INTERNAL' => AdminTheme.purple,
        _ => AdminTheme.textMuted,
      };

  Color _priorityColor(String p) => switch (p) {
        'URGENT' => AdminTheme.crimson,
        'HIGH' => AdminTheme.amber,
        'NORMAL' => AdminTheme.accent,
        _ => AdminTheme.textMuted,
      };

  Color _statusColor(String s) => switch (s) {
        'CLOSED' || 'ARCHIVED' || 'SENT' => AdminTheme.emerald,
        'RECEIVED' || 'UNDER_REVIEW' => AdminTheme.amber,
        _ => AdminTheme.accent,
      };

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCorrCard(CorrListItem c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.isOverdue ? AdminTheme.crimson.withAlpha(90) : const Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDetails(c.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _badge(corrTypeLabel(c.type), _typeColor(c.type)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.refNumber,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _badge(corrStatusLabel(c.status), _statusColor(c.status)),
                  const SizedBox(width: 6),
                  _badge('أولوية: ${priorityLabel(c.priority)}', _priorityColor(c.priority)),
                  const Spacer(),
                  if (c.isOverdue)
                    _badge('متأخرة ${c.overdueDays} يوم', AdminTheme.crimson),
                  Text(
                    _dateFormat.format(c.updatedAt),
                    style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                c.subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (c.senderName != null && c.senderName!.isNotEmpty) ...[
                    const Icon(Icons.person_rounded, size: 13, color: AdminTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(c.senderName!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    const SizedBox(width: 12),
                  ],
                  if (c.departmentName != null) ...[
                    const Icon(Icons.apartment_rounded, size: 13, color: AdminTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(c.departmentName!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  _miniCount(Icons.swap_horiz_rounded, c.referralsCount, 'إحالة'),
                  const SizedBox(width: 10),
                  _miniCount(Icons.assignment_rounded, c.tasksCount, 'تكليف'),
                  const SizedBox(width: 10),
                  _miniCount(Icons.reply_rounded, c.repliesCount, 'رد'),
                  const SizedBox(width: 10),
                  _miniCount(Icons.attach_file_rounded, c.attachmentsCount, 'مرفق'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCount(IconData icon, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AdminTheme.textMuted),
        const SizedBox(width: 2),
        Text('$count $label', style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted)),
      ],
    );
  }

  // ─── نافذة التفاصيل الكاملة ───

  void _showDetails(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: FutureBuilder<CorrDetail?>(
            future: AdminApiService().getCorrespondence(id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final d = snapshot.data;
              if (d == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.error_outline_rounded, color: AdminTheme.crimson, size: 40),
                      SizedBox(height: 10),
                      Text('تعذر تحميل تفاصيل المراسلة'),
                    ],
                  ),
                );
              }
              return SizedBox(
                width: 720,
                height: 640,
                child: Column(
                  children: [
                    // رأس النافذة
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          _badge(corrTypeLabel(d.type), _typeColor(d.type)),
                          const SizedBox(width: 6),
                          Text(
                            d.refNumber,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                          ),
                          const SizedBox(width: 6),
                          _badge(corrStatusLabel(d.status), _statusColor(d.status)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            d.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _badge('أولوية: ${priorityLabel(d.priority)}', _priorityColor(d.priority)),
                              if (d.departmentName != null) _badge('القسم: ${d.departmentName}', AdminTheme.accent),
                              if (d.channel != null && d.channel!.isNotEmpty) _badge('القناة: ${d.channel}', AdminTheme.textMuted),
                              if (d.closedAt != null) _badge('تاريخ الإغلاق: ${DateFormat('yyyy/MM/dd').format(d.closedAt!)}', AdminTheme.emerald),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _sectionTitle('بيانات المرسل', Icons.person_rounded),
                          _infoGrid([
                            ('الاسم', d.senderName ?? '-'),
                            ('البريد', d.senderEmail ?? '-'),
                            ('الهاتف', d.senderPhone ?? '-'),
                            ('سجّلها', d.createdByName ?? '-'),
                            ('تاريخ الاستلام', d.receivedAt != null ? _dateFormat.format(d.receivedAt!) : _dateFormat.format(d.createdAt)),
                            ('تاريخ الإرسال', d.sentAt != null ? _dateFormat.format(d.sentAt!) : '-'),
                          ]),
                          const SizedBox(height: 14),
                          _sectionTitle('نص المراسلة', Icons.description_rounded),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SelectableText(
                              (d.body != null && d.body!.trim().isNotEmpty) ? d.body! : 'لا يوجد نص',
                              style: const TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xFF334155)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionTitle('الإحالات (${d.referrals.length})', Icons.swap_horiz_rounded),
                          if (d.referrals.isEmpty)
                            _emptyHint('لا توجد إحالات')
                          else
                            ...d.referrals.map((r) => _listTile(
                                  icon: Icons.swap_horiz_rounded,
                                  title: '${r.fromName} → ${r.toName}',
                                  subtitle: '${referralStatusLabel(r.status)}'
                                      '${r.dueDate != null ? ' — استحقاق: ${DateFormat('yyyy/MM/dd').format(r.dueDate!)}' : ''}',
                                  extra: r.note,
                                )),
                          const SizedBox(height: 14),
                          _sectionTitle('التكليفات (${d.tasks.length})', Icons.assignment_rounded),
                          if (d.tasks.isEmpty)
                            _emptyHint('لا توجد تكليفات')
                          else
                            ...d.tasks.map((t) => _listTile(
                                  icon: Icons.assignment_rounded,
                                  title: t.title,
                                  subtitle: '${taskStatusLabel(t.status)} — المنفذ: ${t.assignedToName}'
                                      '${t.dueDate != null ? ' — استحقاق: ${DateFormat('yyyy/MM/dd').format(t.dueDate!)}' : ''}',
                                  extra: t.assignedByName.isNotEmpty ? 'كلّفه: ${t.assignedByName}' : null,
                                )),
                          const SizedBox(height: 14),
                          _sectionTitle('الردود (${d.replies.length})', Icons.reply_rounded),
                          if (d.replies.isEmpty)
                            _emptyHint('لا توجد ردود')
                          else
                            ...d.replies.map((r) => _listTile(
                                  icon: Icons.reply_rounded,
                                  title: '${r.authorName} — ${replyStatusLabel(r.status)}',
                                  subtitle: r.body,
                                )),
                          const SizedBox(height: 14),
                          _sectionTitle('المرفقات (${d.attachments.length})', Icons.attach_file_rounded),
                          if (d.attachments.isEmpty)
                            _emptyHint('لا توجد مرفقات')
                          else
                            ...d.attachments.map((a) => _listTile(
                                  icon: Icons.insert_drive_file_rounded,
                                  title: a.fileName,
                                  subtitle: '${a.mimeType} — ${(a.size / 1024).toStringAsFixed(1)} كيلوبايت',
                                )),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminTheme.accent),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _infoGrid(List<(String, String)> pairs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: pairs
            .map((p) => SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$1, style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted, fontWeight: FontWeight.w600)),
                      Text(p.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AdminTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                SelectableText(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.5),
                ),
                if (extra != null && extra.isNotEmpty)
                  Text(extra, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted)),
    );
  }
}
