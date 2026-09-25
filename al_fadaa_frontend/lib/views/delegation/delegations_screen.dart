import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';

/// شاشة الوكالات (التفويض): وكيلك أثناء غيابك + الوكالات الممنوحة لك،
/// مع إنشاء وكالة جديدة (لمن يملك إدارة المستخدمين) وإنهاء مبكر.
class DelegationsScreen extends StatefulWidget {
  final User user;
  final bool canCreate;
  const DelegationsScreen({super.key, required this.user, required this.canCreate});

  @override
  State<DelegationsScreen> createState() => _DelegationsScreenState();
}

class _DelegationsScreenState extends State<DelegationsScreen> {
  List<Map<String, dynamic>> _grantedByMe = [];
  List<Map<String, dynamic>> _grantedToMe = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final mine = await ApiService().getMyDelegations();
    final forMe = await ApiService().getDelegationsForMe();
    if (!mounted) return;
    setState(() {
      _grantedByMe = mine;
      _grantedToMe = forMe;
      _isLoading = false;
    });
  }

  Future<void> _create() async {
    final users = await ApiService().getUsers();
    if (!mounted) return;
    final candidates = users.where((u) => u.id != widget.user.id && u.isActive).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد موظفون متاحون للتفويض'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    User? picked;
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 7));
    final note = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('وكالة جديدة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الوكيل (ينوب عنك في الاعتماد والإشعارات أثناء الغياب):',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                DropdownButtonFormField<User>(
                  value: picked,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: candidates
                      .map((u) => DropdownMenuItem(value: u, child: Text('${u.fullName} (${u.role})', style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setDialog(() => picked = v),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_rounded, size: 15),
                      label: Text('من: ${start.year}/${start.month}/${start.day}', style: const TextStyle(fontSize: 11)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: start,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setDialog(() => start = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_rounded, size: 15),
                      label: Text('إلى: ${end.year}/${end.month}/${end.day}', style: const TextStyle(fontSize: 11)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: end.isAfter(start) ? end : start.add(const Duration(days: 1)),
                          firstDate: start,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setDialog(() => end = d);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'السبب (اختياري)', border: OutlineInputBorder(), isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: picked == null ? null : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('إنشاء الوكالة'),
            ),
          ],
        ),
      ),
    );

    if (created != true || picked == null || !mounted) return;
    final res = await ApiService().createDelegation(
      delegateId: picked!.id,
      startDate: start,
      endDate: end,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true ? 'تم إنشاء الوكالة بنجاح' : (res['message'] ?? 'فشل إنشاء الوكالة')),
      backgroundColor: res['success'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
    ));
    if (res['success'] == true) _load();
  }

  Future<void> _terminate(String id) async {
    final res = await ApiService().terminateDelegation(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true ? 'تم إنهاء الوكالة' : 'فشل إنهاء الوكالة'),
      backgroundColor: res['success'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('الوكالات (التفويض)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (widget.canCreate)
            IconButton(icon: const Icon(Icons.add_rounded, color: Colors.white), tooltip: 'وكالة جديدة', onPressed: _create),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('وكالات منحتها (${_grantedByMe.length})'),
                if (_grantedByMe.isEmpty)
                  _empty('لم تمنح وكالات — أنشئ واحدة قبل إجازتك')
                else
                  ..._grantedByMe.map(_card),
                const SizedBox(height: 14),
                _sectionTitle('وكالات ممنوحة لك (${_grantedToMe.length})'),
                if (_grantedToMe.isEmpty)
                  _empty('لا توجد وكالات ممنوحة لك حاليًا')
                else
                  ..._grantedToMe.map(_card),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      );

  Widget _empty(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.secondary.withAlpha(70)),
        ),
        child: Text(t, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
      );

  Widget _card(Map<String, dynamic> d) {
    final isActive = d['isActive'] == true || (d['status'] ?? '').toString().toUpperCase() == 'ACTIVE';
    final delegate = d['delegate'] is Map ? d['delegate']['name'] : (d['delegateName'] ?? '-');
    final delegator = d['delegator'] is Map ? d['delegator']['name'] : (d['delegatorName'] ?? '-');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : AppTheme.secondary.withAlpha(70)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'من: $delegator ← إلى: $delegate',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'من ${_fmt(d['startsAt'])} إلى ${_fmt(d['endsAt'])}'
                  '${(d['reason'] ?? '').toString().isNotEmpty ? ' — ${d['reason']}' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8)).withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(isActive ? 'نشطة' : 'منتهية',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF059669) : const Color(0xFF64748B))),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
              tooltip: 'إنهاء مبكر',
              onPressed: () => _terminate(d['id']),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '-';
    return '${d.year}/${d.month}/${d.day}';
  }
}
