import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAudit() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ApiService().getAuditLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_searchFilter.isEmpty) return _logs;
    return _logs.where((l) {
      final summary = (l['summary'] ?? l['details'] ?? '').toString().toLowerCase();
      final action = (l['action'] ?? '').toString().toLowerCase();
      final user = (l['user']?['name'] ?? l['user']?['fullName'] ?? '').toString().toLowerCase();
      final q = _searchFilter.toLowerCase();
      return summary.contains(q) || action.contains(q) || user.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    tooltip: 'العودة للوحة المراسلات',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withAlpha(40),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأمان والرقابة الإدارية',
                        style: TextStyle(color: Colors.white70, fontSize: AppTheme.fontXs, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'سجل التدقيق وتتبع العمليات (Audit Logs)',
                        style: TextStyle(color: Colors.white, fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    tooltip: 'تحديث السجل',
                    onPressed: _loadAudit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            radius: const Radius.circular(4),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // بطاقات سريعة لملخص العمليات
                _buildMetricsRow(),
                const SizedBox(height: 16),

                // شريط تصفية السجل
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            onChanged: (v) => setState(() => _searchFilter = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'بحث باسم المستخدم، الإجراء، أو التفاصيل...',
                              hintStyle: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textTertiary),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiary),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              filled: true,
                              fillColor: AppTheme.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: const BorderSide(color: AppTheme.borderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: const BorderSide(color: AppTheme.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                              ),
                            ),
                            style: const TextStyle(fontSize: AppTheme.fontBase),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إجمالي السجلات: ${filtered.length}',
                        style: const TextStyle(fontSize: AppTheme.fontSm, fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ترويسة الجدول
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 130, child: Text('نوع الإجراء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontXs, color: AppTheme.textMuted))),
                      SizedBox(width: 160, child: Text('المستخدم والصفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontXs, color: AppTheme.textMuted))),
                      Expanded(child: Text('البيان وتفاصيل الحركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontXs, color: AppTheme.textMuted))),
                      SizedBox(width: 140, child: Text('التوقيت والتاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontXs, color: AppTheme.textMuted))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // محتوى السجل
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 14),
                          Text('جارِ جلب سجلات التدقيق والأمان...', style: TextStyle(color: AppTheme.textTertiary, fontSize: AppTheme.fontBase)),
                        ],
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.security_outlined, size: 52, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text('لا توجد سجلات مطابقة', style: TextStyle(fontSize: AppTheme.fontMd, color: AppTheme.textTertiary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((item) => _AuditRowWidget(item: item)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final total = _logs.length;
    final creates = _logs.where((l) => (l['action'] ?? '').toString().contains('CREATE')).length;
    final updates = _logs.where((l) => (l['action'] ?? '').toString().contains('UPDATE') || (l['action'] ?? '').toString().contains('STATUS')).length;
    final workflows = _logs.where((l) => ['REFER', 'ASSIGN', 'APPROVE', 'SUBMIT', 'REJECT', 'SEND'].contains(l['action'])).length;

    return Row(
      children: [
        _buildMetricItem('إجمالي الحركات', '$total', Icons.history_rounded, AppTheme.info),
        const SizedBox(width: 12),
        _buildMetricItem('عمليات الإنشاء والوارد', '$creates', Icons.add_circle_outline_rounded, AppTheme.emerald),
        const SizedBox(width: 12),
        _buildMetricItem('التعديلات والتحديثات', '$updates', Icons.edit_note_rounded, const Color(0xFFD97706)),
        const SizedBox(width: 12),
        _buildMetricItem('إجراءات دورة العمل والاعتماد', '$workflows', Icons.verified_user_outlined, const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildMetricItem(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: AppTheme.fontXxl, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditRowWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  const _AuditRowWidget({required this.item});

  @override
  State<_AuditRowWidget> createState() => _AuditRowWidgetState();
}

class _AuditRowWidgetState extends State<_AuditRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final action = (widget.item['action'] ?? 'ACTION').toString();
    final userObj = widget.item['user'];
    final String user = userObj != null
        ? ((userObj['name'] ?? userObj['fullName'] ?? 'مستخدم').toString())
        : 'النظام الآلي';
    final String userRole = userObj != null
        ? ((userObj['role'] ?? 'SYSTEM').toString())
        : 'SYSTEM';
    final String details = (widget.item['summary'] ?? widget.item['details'] ?? '-').toString();
    final String dateStr = widget.item['createdAt'] != null
        ? widget.item['createdAt'].toString().replaceAll('T', ' ').split('.')[0]
        : '-';

    Color actionColor = AppTheme.textTertiary;
    if (action.contains('CREATE')) actionColor = AppTheme.emerald;
    if (action.contains('APPROVE') || action.contains('SEND')) actionColor = AppTheme.info;
    if (action.contains('REJECT')) actionColor = AppTheme.crimson;
    if (action.contains('REFER') || action.contains('ASSIGN')) actionColor = const Color(0xFF7C3AED);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _isHovered ? actionColor.withAlpha(120) : AppTheme.borderLight,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? actionColor.withAlpha(15) : const Color(0x04000000),
              blurRadius: _isHovered ? 6 : 2,
              offset: Offset(0, _isHovered ? 2 : 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // نوع الإجراء
            SizedBox(
              width: 130,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      border: Border.all(color: actionColor.withAlpha(40)),
                    ),
                    child: Text(
                      action,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontXs,
                        color: actionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // المستخدم
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontBase)),
                  Text(userRole, style: const TextStyle(color: AppTheme.textTertiary, fontSize: AppTheme.fontXs)),
                ],
              ),
            ),

            // التفاصيل
            Expanded(
              child: Text(
                details.toString(),
                style: const TextStyle(fontSize: AppTheme.fontBase, color: AppTheme.textHeading),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // التاريخ
            SizedBox(
              width: 140,
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
