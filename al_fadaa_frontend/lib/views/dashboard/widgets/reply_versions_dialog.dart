import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_service.dart';
import '../../../models/reply_model.dart';

class ReplyVersionsDialog extends StatefulWidget {
  final ReplyItem reply;

  const ReplyVersionsDialog({
    super.key,
    required this.reply,
  });

  @override
  State<ReplyVersionsDialog> createState() => _ReplyVersionsDialogState();
}

class _ReplyVersionsDialogState extends State<ReplyVersionsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<ReplyVersionItem> _versions = [];
  DiffResult? _diffResult;
  bool _isLoadingDiff = false;
  int? _diffV1;
  int? _diffV2;
  ReplyVersionItem? _selectedVersion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVersions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);
    final versions = await ApiService().getReplyVersions(widget.reply.id);
    if (mounted) {
      setState(() {
        _versions = versions;
        _isLoading = false;
        if (versions.isNotEmpty) {
          _selectedVersion = versions.last;
          if (versions.length >= 2) {
            _diffV1 = versions[versions.length - 2].versionNumber;
            _diffV2 = versions.last.versionNumber;
            _loadDiff(_diffV1!, _diffV2!);
          } else {
            _diffV1 = versions.first.versionNumber;
            _diffV2 = versions.first.versionNumber;
          }
        }
      });
    }
  }

  Future<void> _loadDiff(int v1, int v2) async {
    setState(() => _isLoadingDiff = true);
    final diff = await ApiService().getReplyDiff(widget.reply.id, v1: v1, v2: v2);
    if (mounted) {
      setState(() {
        _diffResult = diff;
        _isLoadingDiff = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 850,
        height: 650,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // ─── Header ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'سجل إصدارات الرد والمقارنة السطرية',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withAlpha(180),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'الإصدار الحالي v${widget.reply.version}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'متابعة تطور صياغة مسودة الرد وفروق التعديل بين النسخ المتعاقبة',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Tab Bar ───
            Container(
              color: const Color(0xFFF8FAFC),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'قائمة الإصدارات والنسخ'),
                  Tab(icon: Icon(Icons.difference_outlined, size: 18), text: 'فروق التغييرات (Line Diff)'),
                ],
              ),
            ),

            // ─── Content ───
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVersionsListView(),
                        _buildDiffView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionsListView() {
    if (_versions.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إصدارات مؤرشفة لهذا الرد',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    return Row(
      children: [
        // القائمة الجانبية للإصدارات
        SizedBox(
          width: 280,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
              color: Color(0xFFF8FAFC),
            ),
            child: ListView.separated(
              itemCount: _versions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                final v = _versions[index];
                final isSelected = _selectedVersion?.id == v.id;

                return InkWell(
                  onTap: () => setState(() => _selectedVersion = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'v${v.versionNumber}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                v.reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              v.createdBy?.fullName ?? 'غير محدد',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                            const Spacer(),
                            Text(
                              '${v.createdAt.year}/${v.createdAt.month}/${v.createdAt.day}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // معاينة نص الإصدار المحدد
        Expanded(
          child: _selectedVersion == null
              ? const Center(child: Text('اختر إصداراً لمعاينته'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'نص الإصدار v${_selectedVersion!.versionNumber} — ${_selectedVersion!.reason}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                            tooltip: 'نسخ النص',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _selectedVersion!.body));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ نص الإصدار')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _selectedVersion!.body,
                              style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDiffView() {
    if (_versions.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'يتطلب عرض الفروق وجود نسختين على الأقل من هذا الرد',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // شريط اختيار النسختين للمقارنة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              const Text('مقارنة النسخة: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              DropdownButton<int>(
                value: _diffV1,
                isDense: true,
                items: _versions
                    .map((v) => DropdownMenuItem(value: v.versionNumber, child: Text('v${v.versionNumber} (${v.reason})', style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _diffV1 = val);
                    if (_diffV2 != null) _loadDiff(val, _diffV2!);
                  }
                },
              ),
              const SizedBox(width: 16),
              const Text('مع النسخة: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              DropdownButton<int>(
                value: _diffV2,
                isDense: true,
                items: _versions
                    .map((v) => DropdownMenuItem(value: v.versionNumber, child: Text('v${v.versionNumber} (${v.reason})', style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _diffV2 = val);
                    if (_diffV1 != null) _loadDiff(_diffV1!, val);
                  }
                },
              ),
              const Spacer(),
              // دليل الألوان
              Row(
                children: [
                  Container(width: 10, height: 10, color: const Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  const Text('محذوف (-)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, color: const Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  const Text('مضاف (+)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),

        // عرض أسطر الفرق
        Expanded(
          child: _isLoadingDiff
              ? const Center(child: CircularProgressIndicator())
              : (_diffResult == null || _diffResult!.lines.isEmpty)
                  ? const Center(child: Text('لا توجد فروق نصية بين النسختين المختارتين'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _diffResult!.lines.length,
                      itemBuilder: (context, index) {
                        final line = _diffResult!.lines[index];
                        Color bgColor = Colors.transparent;
                        Color textColor = const Color(0xFF334155);
                        String prefix = '  ';

                        if (line.type == 'added') {
                          bgColor = const Color(0xFFDCFCE7);
                          textColor = const Color(0xFF166534);
                          prefix = '+ ';
                        } else if (line.type == 'removed') {
                          bgColor = const Color(0xFFFEE2E2);
                          textColor = const Color(0xFF991B1B);
                          prefix = '- ';
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prefix,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
