import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/audit_model.dart';

class AuditSystemView extends StatefulWidget {
  const AuditSystemView({super.key});

  @override
  State<AuditSystemView> createState() => _AuditSystemViewState();
}

class _AuditSystemViewState extends State<AuditSystemView> {
  final _searchController = TextEditingController();
  List<AuditLogItem> _logs = [];
  bool _isLoading = true;
  bool _isActionRunning = false;
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await AdminApiService().getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _resendMails() async {
    setState(() => _isActionRunning = true);
    final res = await AdminApiService().resendFailedMails();
    if (!mounted) return;
    setState(() => _isActionRunning = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'تم تنفيذ الأمر'),
        backgroundColor: res['success'] == true ? AdminTheme.emerald : AdminTheme.crimson,
      ),
    );
    _loadLogs();
  }

  List<AuditLogItem> get _filteredLogs {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _logs;
    return _logs.where((l) {
      return l.action.toLowerCase().contains(q) ||
          l.summary.toLowerCase().contains(q) ||
          (l.userName != null && l.userName!.toLowerCase().contains(q)) ||
          (l.ipAddress != null && l.ipAddress!.contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // شريط أدوات النظام والبحث
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AdminTheme.accent, size: 22),
                    const SizedBox(width: 8),
                    const Text('سجل التدقيق والرقابة الأمنية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    // زر إعادة إرسال البريد المعلق
                    OutlinedButton.icon(
                      onPressed: _isActionRunning ? null : _resendMails,
                      icon: _isActionRunning
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.forward_to_inbox_rounded, size: 16),
                      label: const Text('إعادة إرسال البريد المعلق', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.primary,
                        side: const BorderSide(color: AdminTheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'تحديث السجل',
                      onPressed: _loadLogs,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // حقل تصفية السجل
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجل بالإجراء، اسم المستخدم، أو العنوان...',
                      hintStyle: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),

          // قائمة أحداث التدقيق
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('لا توجد سجلات تدقيق مطابقة', style: TextStyle(color: AdminTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildLogCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLogItem item) {
    Color actionColor;
    if (item.action.contains('LOGIN') || item.action.contains('AUTH')) {
      actionColor = AdminTheme.purple;
    } else if (item.action.contains('CREATE') || item.action.contains('APPROVE')) {
      actionColor = AdminTheme.emerald;
    } else if (item.action.contains('DELETE') || item.action.contains('FAIL')) {
      actionColor = AdminTheme.crimson;
    } else if (item.action.contains('UPDATE') || item.action.contains('EDIT')) {
      actionColor = AdminTheme.amber;
    } else {
      actionColor = AdminTheme.accent;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: actionColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.history_edu_rounded, size: 18, color: actionColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.action,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: actionColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.userName ?? 'النظام',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        _dateFormat.format(item.createdAt),
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.summary,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                  if (item.ipAddress != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'IP: ${item.ipAddress}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AdminTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
