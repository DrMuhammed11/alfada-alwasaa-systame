import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';

class CorrespondenceLineageDialog extends StatefulWidget {
  final String correspondenceId;
  final Function(String id)? onSelectCorrespondence;

  const CorrespondenceLineageDialog({
    super.key,
    required this.correspondenceId,
    this.onSelectCorrespondence,
  });

  @override
  State<CorrespondenceLineageDialog> createState() => _CorrespondenceLineageDialogState();
}

class _CorrespondenceLineageDialogState extends State<CorrespondenceLineageDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _lineageData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLineage();
  }

  Future<void> _loadLineage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService().getCorrespondenceLineage(widget.correspondenceId);
    if (!mounted) return;

    if (res != null) {
      setState(() {
        _lineageData = res;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'تعذر استرجاع شجرة المعاملة من الخادم';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط العنوان العلوي
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_tree_rounded, color: AppTheme.accent, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شجرة أنساب المعاملة والترابط البياني',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text(
                      'تتبع تسلسل المحادثات والتفرعات وحوكمة الإغلاق المترابط',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'تحديث الشجرة',
                  onPressed: _loadLineage,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // المحتوى
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('جاري فحص وتجميع شجرة المعاملات...', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.crimson),
                              const SizedBox(height: 12),
                              Text(_errorMessage!),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadLineage, child: const Text('إعادة المحاولة')),
                            ],
                          ),
                        )
                      : _buildLineageContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineageContent() {
    final metrics = _lineageData!['metrics'] as Map<String, dynamic>? ?? {};
    final cascadingClosure = _lineageData!['cascadingClosure'] as Map<String, dynamic>? ?? {};
    final canClose = cascadingClosure['canClose'] as bool? ?? false;
    final blockingReasons = (cascadingClosure['blockingReasons'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final tree = _lineageData!['tree'] as Map<String, dynamic>?;

    return Column(
      children: [
        // 1. بطاقة مؤشر حوكمة الإغلاق المترابط (Cascading Closure Safeguard)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: canClose ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: canClose ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                canClose ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                color: canClose ? const Color(0xFF059669) : const Color(0xFFDC2626),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canClose
                          ? 'المعاملة مؤهلة للإغلاق الآمن ✅'
                          : 'المعاملة محجوبة عن الإغلاق المترابط (حماية الالتزامات المؤسسية) 🔒',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: canClose ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (canClose)
                      const Text(
                        'كافة التفرعات والمعاملات التابعة والمهام والإحالات منجزة بالكامل، لا يوجد أي عمل معلق.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                      )
                    else ...[
                      const Text(
                        'لا يمكن إغلاق هذه المعاملة حالياً لوجود التزامات معلقة تتطلب الإنجاز أولاً:',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      ...blockingReasons.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. شريط المؤشرات الإحصائية للسلسلة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge('المعاملات في السلسلة', '${metrics['totalNodes'] ?? 1}', Icons.layers_outlined),
              _buildStatBadge('إحالات مفتوحة', '${metrics['openReferralsCount'] ?? 0}', Icons.reply_all_rounded),
              _buildStatBadge('مهام جارية', '${metrics['activeTasksCount'] ?? 0}', Icons.assignment_late_outlined),
              _buildStatBadge('مسودات ردود', '${metrics['draftRepliesCount'] ?? 0}', Icons.edit_document),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. عرض شجرة العلاقات الهرمية التفاعلية
        Expanded(
          child: tree == null
              ? const Center(child: Text('لا توجد بيانات شجرية'))
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: _buildTreeNode(tree, 0),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String count, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> node, int depth) {
    final nodeId = node['id']?.toString() ?? '';
    final isCurrent = nodeId == widget.correspondenceId;
    final children = (node['children'] as List?)?.map((c) => c as Map<String, dynamic>).toList() ?? [];

    final refNumber = node['refNumber']?.toString() ?? '';
    final subject = node['subject']?.toString() ?? '';
    final type = node['type']?.toString() ?? 'INCOMING';
    final status = node['status']?.toString() ?? '';
    final department = node['department']?['name']?.toString();
    final referralsCount = (node['referrals'] as List?)?.length ?? 0;
    final tasksCount = (node['tasks'] as List?)?.length ?? 0;
    final repliesCount = (node['replies'] as List?)?.length ?? 0;

    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'INCOMING':
        typeColor = const Color(0xFF0284C7);
        typeLabel = 'وارد';
        break;
      case 'OUTGOING':
        typeColor = const Color(0xFF16A34A);
        typeLabel = 'صادر';
        break;
      case 'INTERNAL':
        typeColor = const Color(0xFF9333EA);
        typeLabel = 'داخلي';
        break;
      default:
        typeColor = const Color(0xFF64748B);
        typeLabel = type;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: depth * 24.0, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (depth > 0)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 12),
                  child: Icon(Icons.subdirectory_arrow_left_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              Expanded(
                child: InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(context);
                          if (widget.onSelectCorrespondence != null) {
                            widget.onSelectCorrespondence!(nodeId);
                          }
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.accent.withAlpha(15) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? AppTheme.accent : const Color(0xFFE2E8F0),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              refNumber,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'المعاملة الحالية',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subject,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (department != null) ...[
                              const Icon(Icons.corporate_fare_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(department, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(width: 12),
                            ],
                            if (referralsCount > 0) ...[
                              const Icon(Icons.reply_all_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text('$referralsCount إحالة', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(width: 10),
                            ],
                            if (tasksCount > 0) ...[
                              const Icon(Icons.task_alt_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text('$tasksCount مهام', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(width: 10),
                            ],
                            if (repliesCount > 0) ...[
                              const Icon(Icons.comment_outlined, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text('$repliesCount ردود', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                            if (!isCurrent) ...[
                              const Spacer(),
                              const Text('فتح المعاملة ⬅', style: TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // الأبناء المتفرعون
        ...children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
}
