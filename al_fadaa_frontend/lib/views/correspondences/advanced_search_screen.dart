import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/correspondence_model.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/app_max_width.dart';

/// شاشة البحث المتقدم والأرشيف لمراسلات المؤسسة
class AdvancedSearchScreen extends StatefulWidget {
  final User? currentUser;
  final Function(String id)? onOpenCorrespondence;

  const AdvancedSearchScreen({
    super.key,
    this.currentUser,
    this.onOpenCorrespondence,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // فلاتر البحث
  String _selectedType = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedPriority = 'ALL';
  String _selectedDepartmentId = 'ALL';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasAttachmentsOnly = false;
  bool _isFiltersExpanded = true;

  // البيانات
  List<Department> _departments = [];
  List<Correspondence> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final depts = await ApiService().getDepartments();
      if (mounted) {
        setState(() => _departments = depts);
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  Future<void> _executeSearch({bool resetPage = true}) async {
    if (_isLoading || _isLoadingMore) return;

    if (resetPage) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasSearched = true;
      });
    }

    final fromStr = _fromDate != null ? _fromDate!.toIso8601String().split('T')[0] : null;
    final toStr = _toDate != null ? _toDate!.toIso8601String().split('T')[0] : null;

    final res = await ApiService().searchCorrespondences(
      q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      departmentId: _selectedDepartmentId,
      from: fromStr,
      to: toStr,
      hasAttachments: _hasAttachmentsOnly ? true : null,
      page: resetPage ? 1 : _currentPage,
      limit: 20,
    );

    if (!mounted) return;

    final items = res['data'] as List<Correspondence>? ?? [];
    final meta = res['meta'] as Map<String, dynamic>? ?? {};

    setState(() {
      if (resetPage) {
        _results = items;
        _isLoading = false;
      } else {
        _results.addAll(items);
        _isLoadingMore = false;
      }
      _totalCount = meta['total'] ?? items.length;
      _totalPages = meta['totalPages'] ?? 1;
      _currentPage = meta['page'] ?? (resetPage ? 1 : _currentPage);
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _executeSearch(resetPage: false);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'ALL';
      _selectedStatus = 'ALL';
      _selectedPriority = 'ALL';
      _selectedDepartmentId = 'ALL';
      _fromDate = null;
      _toDate = null;
      _hasAttachmentsOnly = false;
    });
    _executeSearch(resetPage: true);
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_fromDate ?? now)
        : (_toDate ?? (_fromDate ?? now));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.manage_search_rounded, size: 24),
            SizedBox(width: 10),
            Text('البحث المتقدم والأرشيف'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFiltersExpanded ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: Colors.white,
            ),
            tooltip: _isFiltersExpanded ? 'إخفاء الفلاتر' : 'إظهار الفلاتر',
            onPressed: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'إعادة البحث',
            onPressed: () => _executeSearch(resetPage: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة الفلاتر
          if (_isFiltersExpanded) _buildFiltersPanel(),

          // شريط إحصائية النتائج
          _buildResultsHeader(),

          // قائمة النتائج
          Expanded(child: AppMaxWidth(child: _buildResultsList())),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط البحث النصي
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث في العنوان، المحتوى، رقم القيد، أو جهة الإرسال...',
                      hintStyle: const TextStyle(fontSize: AppTheme.fontBase, color: AppTheme.textTertiary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _executeSearch(resetPage: true),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _executeSearch(resetPage: true),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('بحث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(80, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // صف القوائم المنسدلة
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // نوع المعاملة
              _buildDropdown(
                label: 'النوع',
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('كافة الأنواع')),
                  DropdownMenuItem(value: 'INCOMING', child: Text('وارد')),
                  DropdownMenuItem(value: 'OUTGOING', child: Text('صادر')),
                  DropdownMenuItem(value: 'INTERNAL', child: Text('داخلي')),
                ],
                onChanged: (val) => setState(() => _selectedType = val ?? 'ALL'),
              ),

              // الحالة
              _buildDropdown(
                label: 'الحالة',
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('كافة الحالات')),
                  DropdownMenuItem(value: 'RECEIVED', child: Text('مستلمة')),
                  DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('قيد المراجعة')),
                  DropdownMenuItem(value: 'REFERRED', child: Text('محالة')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('قيد المعالجة')),
                  DropdownMenuItem(value: 'PENDING_APPROVAL', child: Text('بانتظار الاعتماد')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('معتمدة')),
                  DropdownMenuItem(value: 'SENT', child: Text('مرسلة')),
                  DropdownMenuItem(value: 'CLOSED', child: Text('مغلقة')),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('مؤرشفة')),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val ?? 'ALL'),
              ),

              // الأولوية
              _buildDropdown(
                label: 'الأولوية',
                value: _selectedPriority,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('كافة الأولويات')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('عادية')),
                  DropdownMenuItem(value: 'URGENT', child: Text('عاجلة')),
                  DropdownMenuItem(value: 'LOW', child: Text('منخفضة')),
                  DropdownMenuItem(value: 'HIGH', child: Text('عالية')),
                ],
                onChanged: (val) => setState(() => _selectedPriority = val ?? 'ALL'),
              ),

              // القسم
              _buildDepartmentDropdown(),

              // أزرار التواريخ
              _buildDateButton(
                label: _fromDate != null ? 'من: ${_dateFormat.format(_fromDate!)}' : 'من تاريخ',
                isSelected: _fromDate != null,
                onTap: () => _pickDate(true),
                onClear: _fromDate != null ? () => setState(() => _fromDate = null) : null,
              ),
              _buildDateButton(
                label: _toDate != null ? 'إلى: ${_dateFormat.format(_toDate!)}' : 'إلى تاريخ',
                isSelected: _toDate != null,
                onTap: () => _pickDate(false),
                onClear: _toDate != null ? () => setState(() => _toDate = null) : null,
              ),

              // فلتر المرفقات
              FilterChip(
                selected: _hasAttachmentsOnly,
                label: const Text('مع مرفقات فقط', style: TextStyle(fontSize: AppTheme.fontSm)),
                avatar: Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: _hasAttachmentsOnly ? Colors.white : AppTheme.textTertiary,
                ),
                selectedColor: AppTheme.accent,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _hasAttachmentsOnly ? Colors.white : AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                onSelected: (val) => setState(() => _hasAttachmentsOnly = val),
              ),

              // زر تصفير الفلاتر
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 16, color: AppTheme.textTertiary),
                label: const Text('إعادة ضبط', style: TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textTertiary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textTertiary),
          style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textHeading, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'ALL', child: Text('كافة الأقسام')),
      ..._departments.map(
        (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
      ),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDepartmentId,
          items: items,
          onChanged: (val) => setState(() => _selectedDepartmentId = val ?? 'ALL'),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textTertiary),
          style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textHeading, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withAlpha(25) : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isSelected ? AppTheme.accent : AppTheme.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSm,
                color: isSelected ? AppTheme.accent : AppTheme.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF1F5F9),
      child: Row(
        children: [
          const Icon(Icons.list_alt_rounded, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 8),
          Text(
            _hasSearched
                ? 'نتائج البحث: تم العثور على $_totalCount معاملة'
                : 'أدخل كلمات البحث أو حدد الفلاتر ثم اضغط "بحث"',
            style: const TextStyle(
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
            ),
          ),
          const Spacer(),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('جاري البحث والفرز في الأرشيف...', style: TextStyle(color: AppTheme.textTertiary)),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, size: 48, color: AppTheme.accent),
            ),
            const SizedBox(height: 16),
            const Text(
              'محرك البحث المتقدم في المعاملات والأرشيف',
              style: TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك البحث برقم القيد، الموضوع، اسم الجهة، الأقسام، أو نطاق التواريخ',
              style: TextStyle(fontSize: AppTheme.fontBase, color: AppTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text(
              'لم يتم العثور على معاملات مطابقة',
              style: TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 6),
            const Text(
              'جرّب تعديل كلمات البحث أو تخفيف محددات الفلاتر',
              style: TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة تعيين الفلاتر'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _results.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = _results[index];
        return _buildCorrespondenceCard(item);
      },
    );
  }

  Widget _buildCorrespondenceCard(Correspondence item) {
    Color typeColor;
    String typeText;
    switch (item.type) {
      case 'INCOMING':
        typeColor = AppTheme.info;
        typeText = 'وارد';
        break;
      case 'OUTGOING':
        typeColor = AppTheme.emerald;
        typeText = 'صادر';
        break;
      case 'INTERNAL':
        typeColor = const Color(0xFF9333EA);
        typeText = 'داخلي';
        break;
      default:
        typeColor = AppTheme.textTertiary;
        typeText = item.type;
    }

    Color priorityColor;
    String priorityText;
    switch (item.priority) {
      case 'URGENT':
        priorityColor = AppTheme.crimson;
        priorityText = 'عاجل';
        break;
      case 'HIGH':
        priorityColor = const Color(0xFFEA580C);
        priorityText = 'مهم';
        break;
      case 'LOW':
        priorityColor = AppTheme.textTertiary;
        priorityText = 'عادي';
        break;
      default:
        priorityColor = AppTheme.info;
        priorityText = 'عادي';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _handleItemTap(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: رقم القيد والشارات
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      border: Border.all(color: typeColor.withAlpha(80)),
                    ),
                    child: Text(
                      typeText,
                      style: TextStyle(color: typeColor, fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Text(
                      priorityText,
                      style: TextStyle(color: priorityColor, fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.serialNumber.isNotEmpty ? item.serialNumber : 'بدون رقم قيد',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppTheme.fontSm,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  // التاريخ
                  Text(
                    _dateFormat.format(item.createdAt),
                    style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // العنوان
              Text(
                item.subject,
                style: const TextStyle(
                  fontSize: AppTheme.fontMd,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (item.body != null && item.body!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.body!,
                  style: const TextStyle(fontSize: AppTheme.fontSm, color: AppTheme.textTertiary, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // شريط البيانات السفلية
              Row(
                children: [
                  if (item.senderName != null && item.senderName!.isNotEmpty) ...[
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.senderName!,
                        style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else if (item.department != null) ...[
                    const Icon(Icons.corporate_fare_rounded, size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.department!.name,
                        style: const TextStyle(fontSize: AppTheme.fontXs, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (item.attachments.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 13, color: AppTheme.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            '${item.attachments.length}',
                            style: const TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.repliesCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply_rounded, size: 13, color: AppTheme.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            '${item.repliesCount}',
                            style: const TextStyle(fontSize: AppTheme.fontXs, fontWeight: FontWeight.bold, color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemTap(Correspondence item) {
    if (widget.onOpenCorrespondence != null) {
      widget.onOpenCorrespondence!(item.id);
      Navigator.pop(context);
    } else {
      _showDetailSheet(item);
    }
  }

  void _showDetailSheet(Correspondence item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.subject,
                    style: const TextStyle(fontSize: AppTheme.fontLg, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'رقم القيد: ${item.serialNumber} | التاريخ: ${_dateFormat.format(item.createdAt)}',
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: AppTheme.fontSm),
            ),
            const Divider(height: 24),
            if (item.body != null && item.body!.isNotEmpty) ...[
              const Text(
                'نص المعاملة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontBase),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  item.body!,
                  style: const TextStyle(fontSize: AppTheme.fontBase, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onOpenCorrespondence != null) {
                    widget.onOpenCorrespondence!(item.id);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: const Text('فتح في لوحة المراسلات الرئيسية'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
