import 'package:flutter/material.dart';
import '../../../core/network/admin_api_service.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../operations_helpers.dart';

class OutboxTab extends StatefulWidget {
  const OutboxTab({super.key});
  @override
  State<OutboxTab> createState() => OutboxTabState();
}

class OutboxTabState extends State<OutboxTab> with AutomaticKeepAliveClientMixin {
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
                style: const TextStyle(fontSize: AdminTheme.fontBase, fontWeight: FontWeight.bold, color: AdminTheme.textMuted),
              ),
              const Spacer(),
              ..._kinds.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: AdminTheme.fontSm)),
                      selected: _status == e.key,
                      selectedColor: AdminTheme.primary,
                      labelStyle: TextStyle(
                        color: _status == e.key ? Colors.white : AdminTheme.textMuted,
                        fontSize: AdminTheme.fontSm,
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
                                              fontSize: AdminTheme.fontBase,
                                              color: AdminTheme.borderDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // شارة حالة الرسالة — StatusBadge من app_utils
                                          StatusBadge(
                                            text: opStatusLabel(status),
                                            color: opStatusColor(status),
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
                                          style: const TextStyle(fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted),
                                        ),
                                        if ((m['lastError'] ?? '').toString().isNotEmpty)
                                          Text(
                                            'الخطأ: ${m['lastError']}',
                                            style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.crimson),
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
                                      label: const Text('إعادة', style: TextStyle(fontSize: AdminTheme.fontSm)),
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
                                      label: const Text('إيقاف', style: TextStyle(fontSize: AdminTheme.fontSm)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AdminTheme.purple,
                                        side: const BorderSide(color: AdminTheme.purple),
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
                style: const TextStyle(fontSize: AdminTheme.fontSm, color: AdminTheme.textMuted),
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

