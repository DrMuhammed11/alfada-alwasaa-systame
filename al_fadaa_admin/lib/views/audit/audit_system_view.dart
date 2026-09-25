import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/audit_model.dart';

/// تسميات عربية لأنواع أحداث التدقيق — يجب أن تطابق enum AuditAction في الخادم
const Map<String, String> kAuditActionLabels = {
  'LOGIN': 'تسجيل دخول',
  'CREATE': 'إنشاء',
  'UPDATE': 'تعديل',
  'DEACTIVATE': 'تعطيل حساب',
  'REFER': 'إحالة',
  'ASSIGN': 'تكليف',
  'SUBMIT': 'رفع للاعتماد',
  'APPROVE': 'اعتماد',
  'REJECT': 'رفض',
  'SEND': 'إرسال',
  'CLOSE': 'إغلاق',
  'ARCHIVE': 'أرشفة',
  'UPLOAD': 'رفع مرفق',
  'DELETE': 'حذف مرفق',
  'DOWNLOAD': 'تنزيل مرفق',
};

class AuditSystemView extends StatefulWidget {
  const AuditSystemView({super.key});

  @override
  State<AuditSystemView> createState() => _AuditSystemViewState();
}

class _AuditSystemViewState extends State<AuditSystemView> {
  static const int _limit = 25;

  final _searchController = TextEditingController();
  List<AuditLogItem> _logs = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isActionRunning = false;
  bool _isCheckingIntegrity = false;
  AuditIntegrityReport? _integrityReport;
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  // الفلاتر الخدمية (تنفَّذ في الخادم) وحالة الترقيم
  String _selectedAction = 'ALL';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedAction != 'ALL' ||
      _fromDate != null ||
      _toDate != null;

  @override
  void initState() {
    super.initState();
    _loadLogs(page: 1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// جلب السجل من الخادم بالفلاتر الحالية — البحث النصي نفّذه الخادم عبر q
  Future<void> _loadLogs({required int page}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final res = await AdminApiService().getAuditLogs(
      q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      action: _selectedAction,
      from: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
      to: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
      page: page,
      limit: _limit,
    );
    if (!mounted) return;
    setState(() {
      _logs = res.items;
      _hasError = res.error;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
      _isLoading = false;
    });
  }

  Future<void> _checkIntegrity() async {
    setState(() => _isCheckingIntegrity = true);
    final report = await AdminApiService().verifyAuditIntegrity();
    if (!mounted) return;
    setState(() {
      _isCheckingIntegrity = false;
      _integrityReport = report;
    });

    if (report != null) {
      final partial = report.totalRecords > 0 && report.totalVerified < report.totalRecords;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            report.isTamperFree
                ? (partial
                    ? 'فحص النزاهة سليم: آخر ${report.totalVerified} سجلًا من أصل ${report.totalRecords} — أعد الفحص بنطاق أوسع لتغطية الأقدم'
                    : 'اكتمل فحص النزاهة بنجاح: السلسلة التشفيرية متطابقة وسليمة 100%')
                : 'تحذير أمني: تم رصد انقطاع أو تلاعب في سلسلة التدقيق!',
          ),
          backgroundColor: report.isTamperFree ? AdminTheme.emerald : AdminTheme.crimson,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إتمام فحص النزاهة التشفيرية'),
          backgroundColor: AdminTheme.crimson,
        ),
      );
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
    _loadLogs(page: _page);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? now) : (_toDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
    _loadLogs(page: 1);
  }

  Future<void> _clearFilters() async {
    setState(() {
      _searchController.clear();
      _selectedAction = 'ALL';
      _fromDate = null;
      _toDate = null;
    });
    _loadLogs(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildToolbar(),
          // بطاقة تقرير فحص النزاهة الرقمية
          if (_integrityReport != null) _buildIntegrityBanner(_integrityReport!),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط أدوات النظام
          Row(
            children: [
              const Icon(Icons.security_rounded, color: AdminTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text('سجل التدقيق والرقابة الأمنية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              // زر فحص النزاهة الرقمية المشفرة
              FilledButton.icon(
                onPressed: _isCheckingIntegrity ? null : _checkIntegrity,
                icon: _isCheckingIntegrity
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user_rounded, size: 16),
                label: const Text('فحص النزاهة الرقمية (SHA-256)', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
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
                onPressed: () => _loadLogs(page: _page),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // البحث النصي (ينفَّذ في الخادم) + فلتر نوع الحدث
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجل بالإجراء، اسم المستخدم، البصمة، أو العنوان...',
                      hintStyle: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onSubmitted: (_) => _loadLogs(page: 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionDropdown(),
            ],
          ),
          const SizedBox(height: 8),
          // فلتر النطاق الزمني + مسح الفلاتر + العدد الكلي
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AdminTheme.textMuted),
              const SizedBox(width: 6),
              _buildDateChip(isFrom: true),
              const SizedBox(width: 8),
              _buildDateChip(isFrom: false),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('مسح الفلاتر', style: TextStyle(fontSize: 11, color: AdminTheme.crimson)),
                  avatar: const Icon(Icons.filter_alt_off_rounded, size: 15, color: AdminTheme.crimson),
                  side: BorderSide(color: AdminTheme.crimson.withAlpha(80)),
                  onPressed: _clearFilters,
                ),
              ],
              const Spacer(),
              Text(
                'إجمالي السجلات: $_total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionDropdown() {
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
          value: _selectedAction,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          items: [
            const DropdownMenuItem(value: 'ALL', child: Text('كل أنواع الأحداث')),
            ...kAuditActionLabels.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedAction = val);
              _loadLogs(page: 1);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateChip({required bool isFrom}) {
    final date = isFrom ? _fromDate : _toDate;
    final label = date == null
        ? (isFrom ? 'من تاريخ' : 'إلى تاريخ')
        : '${isFrom ? 'من' : 'إلى'}: ${DateFormat('yyyy/MM/dd').format(date)}';
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(
        isFrom ? Icons.event_rounded : Icons.event_available_rounded,
        size: 15,
        color: date != null ? AdminTheme.accent : AdminTheme.textMuted,
      ),
      onPressed: () => _pickDate(isFrom: isFrom),
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
            const Text('تعذر تحميل سجل التدقيق من الخادم', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _loadLogs(page: _page),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد سجلات تدقيق مطابقة للفلاتر المحددة',
          style: TextStyle(color: AdminTheme.textMuted),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadLogs(page: _page),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final item = _logs[index];
          return _buildLogCard(item);
        },
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_isLoading || _hasError || _logs.isEmpty) return const SizedBox.shrink();
    final canPrev = _page > 1;
    final canNext = _page < _totalPages;
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
            onPressed: canPrev ? () => _loadLogs(page: _page - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'الصفحة التالية',
            onPressed: canNext ? () => _loadLogs(page: _page + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityBanner(AuditIntegrityReport report) {
    final isOk = report.isTamperFree;
    final bannerColor = isOk ? AdminTheme.emerald : AdminTheme.crimson;
    final bgLight = isOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final borderLight = isOk ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
              color: bannerColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOk
                          ? 'سلسلة التدقيق التشفيرية سليمة وغير قابلة للتلاعب 100%'
                          : 'تحذير أمني: تم رصد انقطاع أو تلاعب في سجل التدقيق!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: bannerColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bannerColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.chainStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: bannerColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report.details,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      report.totalRecords > report.totalVerified
                          ? 'التغطية: ${report.totalVerified} من أصل ${report.totalRecords} سجل (الأحدث)'
                          : 'عدد السجلات المفحوصة: ${report.totalVerified}',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                    ),
                    Text(
                      'خوارزمية الإثبات: SHA-256 Merkle Chain',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                    if (report.brokenRecordId != null)
                      Text(
                        'السجل المنقطع: ${report.brokenRecordId}',
                        style: const TextStyle(fontSize: 11, color: AdminTheme.crimson, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AdminTheme.textMuted),
            tooltip: 'إغلاق التقرير',
            onPressed: () => setState(() => _integrityReport = null),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showAuditDetails(item),
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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.ipAddress != null)
                          Text(
                            'IP: ${item.ipAddress}',
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AdminTheme.textMuted),
                          ),
                        if (item.recordHash != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fingerprint_rounded, size: 11, color: AdminTheme.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'SHA-256: ${item.recordHash!.length > 12 ? "${item.recordHash!.substring(0, 12)}..." : item.recordHash}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.previousHash != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link_rounded, size: 11, color: AdminTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Prev: ${item.previousHash!.length > 10 ? "${item.previousHash!.substring(0, 10)}..." : item.previousHash}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: AdminTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  void _showAuditDetails(AuditLogItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.fingerprint_rounded, color: AdminTheme.primary),
            const SizedBox(width: 8),
            const Text('تفاصيل حدث التدقيق والإثبات التشفيري', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailTile('معرف السجل (UUID)', item.id),
                _detailTile('الإجراء (Action)', item.action),
                _detailTile('المستخدم', '${item.userName ?? "النظام"} (${item.userEmail ?? "-"})'),
                _detailTile('عنوان IP', item.ipAddress ?? 'غير متوفر'),
                _detailTile('وقت التنفيذ', _dateFormat.format(item.createdAt)),
                _detailTile('البيان والملخص', item.summary),
                const Divider(height: 20),
                const Text('الأدلة التشفيرية (Tamper-Proof Proofs):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                _hashBox('بصمة السجل الحالي (recordHash):', item.recordHash ?? 'غير متوفر (سجل قديم قبل التشفير)'),
                const SizedBox(height: 6),
                _hashBox('بصمة السجل السابق (previousHash):', item.previousHash ?? 'الجذر التأسيسي (GENESIS RECORD)'),
                if (item.details != null && item.details!.isNotEmpty) ...[
                  const Divider(height: 20),
                  const Text('البيانات الوصفية الإضافية (Metadata):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item.details.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  Widget _hashBox(String title, String hash) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          SelectableText(
            hash,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AdminTheme.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
