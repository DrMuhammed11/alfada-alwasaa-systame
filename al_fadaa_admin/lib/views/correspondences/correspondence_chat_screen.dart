import 'package:flutter/material.dart';

import '../../core/network/admin_api_service.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/app_utils.dart';
import '../../models/correspondence_model.dart';
import 'corr_style.dart';

/// شاشة المحادثة — نمط واتساب لسلسلة مراسلة واحدة
/// تعرض الرسائل الواردة من العميل (نفس البريد) والردود الصادرة المرسلة إليه
/// بفقاعات دردشة متعاكسة، مع أحداث النظام (الإحالات والتكليفات والردود الداخلية)
/// كبسولات مركزية بين الرسائل حسب الترتيب الزمني
class CorrespondenceChatScreen extends StatefulWidget {
  final CorrListItem conversation;

  const CorrespondenceChatScreen({super.key, required this.conversation});

  @override
  State<CorrespondenceChatScreen> createState() =>
      _CorrespondenceChatScreenState();
}

class _CorrespondenceChatScreenState extends State<CorrespondenceChatScreen> {
  CorrDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _jumpedToBottom = false;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _jumpedToBottom = false;
    final d = await AdminApiService().getCorrespondence(widget.conversation.id);
    if (!mounted) return;
    if (d == null) {
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل سلسلة المحادثة من الخادم';
      });
      return;
    }
    setState(() {
      _detail = d;
      _loading = false;
    });
    // فتح المحادثة على آخر رسالة — نمط تطبيقات الدردشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && !_jumpedToBottom) {
        _jumpedToBottom = true;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ─── بناء الخط الزمني الموحد ───

  List<_TimelineEntry> _buildTimeline(CorrDetail d) {
    final events = <_TimelineEntry>[];

    // الرسالة الأصلية (جذر المحادثة)
    events.add(_TimelineEntry(
      timestamp: d.receivedAt ?? d.sentAt ?? d.createdAt,
      kind: _EntryKind.message,
      message: CorrThreadMessage(
        id: d.id,
        refNumber: d.refNumber,
        subject: d.subject,
        body: d.body,
        type: d.type,
        status: d.status,
        senderName: d.senderName,
        senderEmail: d.senderEmail,
        receivedAt: d.receivedAt,
        sentAt: d.sentAt,
        createdAt: d.createdAt,
        attachments: d.attachments,
      ),
    ));

    // التعقيبات: رسائل البريد الواردة من نفس البريد + الردود الصادرة المرسلة للعميل
    // مع أحفاد الجذر: ردود قديمة أُلصقت تحت ابن قبل توحيد التعليق على الجذر
    for (final c in d.children) {
      events.add(_TimelineEntry(
        timestamp: c.displayTime,
        kind: _EntryKind.message,
        message: c,
      ));
      for (final g in c.children) {
        events.add(_TimelineEntry(
          timestamp: g.displayTime,
          kind: _EntryKind.message,
          message: g,
        ));
      }
    }

    // الإحالات — أحداث نظام
    for (final r in d.referrals) {
      events.add(_TimelineEntry(
        timestamp: r.createdAt ?? d.createdAt,
        kind: _EntryKind.referral,
        referral: r,
      ));
    }

    // التكليفات — أحداث نظام
    for (final t in d.tasks) {
      events.add(_TimelineEntry(
        timestamp: t.createdAt ?? d.createdAt,
        kind: _EntryKind.task,
        task: t,
      ));
    }

    // الردود الداخلية من فريق العمل — كلها تظهر حسب حالتها:
    // الرد الذي أُرسل فعلًا للعميل يظهر ضمن التعقيبات كرسالة صادرة (OUTGOING)
    // مرتبطة بسجل الرد عبر sourceReplyId فنُخفي النسخة المكررة هنا،
    // وما لم يُرسل بعد (مسودة/بانتظار الاعتماد/معتمد/مرفوض) يظهر كملاحظة داخلية
    final sentReplyIds = {
      for (final c in d.children) ...[
        if (c.sourceReplyId != null) c.sourceReplyId!,
        for (final g in c.children)
          if (g.sourceReplyId != null) g.sourceReplyId!,
      ],
    };
    for (final r in d.replies) {
      if (sentReplyIds.contains(r.id)) continue;
      events.add(_TimelineEntry(
        timestamp: r.createdAt,
        kind: _EntryKind.internalReply,
        reply: r,
      ));
    }

    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // إدراج فواصل الأيام بين الأحداث المتغيرة اليوم
    final timeline = <_TimelineEntry>[];
    DateTime? lastDay;
    for (final e in events) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      if (lastDay == null || day != lastDay) {
        timeline.add(_TimelineEntry(timestamp: e.timestamp, kind: _EntryKind.dayDivider));
        lastDay = day;
      }
      timeline.add(e);
    }
    return timeline;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    return Scaffold(
      backgroundColor: AdminTheme.chatBg,
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CorrStyle.avatar(
              name: c.senderName,
              seed: c.senderEmail ?? c.senderName ?? c.refNumber,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (c.senderName?.trim().isNotEmpty == true)
                        ? c.senderName!
                        : 'جهة غير مسجلة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AdminTheme.fontLg,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${c.refNumber} • ${corrTypeLabel(c.type)} • ${corrStatusLabel(c.status)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: AdminTheme.fontXs,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_detail != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: AdminTheme.iconMd),
              tooltip: 'تفاصيل المحادثة',
              onPressed: _openDetailsSheet,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: AdminTheme.iconMd),
            tooltip: 'تحديث',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildFooterBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingWidget(message: 'جارٍ تحميل سلسلة المحادثة…');
    }
    if (_error != null || _detail == null) {
      return ErrorStateWidget(message: _error ?? 'خطأ غير متوقع', onRetry: _load);
    }
    final timeline = _buildTimeline(_detail!);

    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // قيد عرض الفقاعة: 82% على الهاتف وبحد أقصى 620 على الشاشات الواسعة
          final bubbleMaxWidth =
              (constraints.maxWidth * 0.82).clamp(240.0, 620.0);
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final e = timeline[index];
              switch (e.kind) {
                case _EntryKind.dayDivider:
                  return _buildDayDivider(e.timestamp);
                case _EntryKind.message:
                  return _buildMessageBubble(e.message!, bubbleMaxWidth);
                case _EntryKind.referral:
                  return _buildReferralPill(e.referral!);
                case _EntryKind.task:
                  return _buildTaskPill(e.task!);
                case _EntryKind.internalReply:
                  return _buildInternalReplyNote(e.reply!);
              }
            },
          );
        },
      ),
    );
  }

  // ─── فاصل يوم بنمط واتساب ───
  Widget _buildDayDivider(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Text(
            CorrStyle.daySeparatorLabel(dt),
            style: const TextStyle(
              fontSize: AdminTheme.fontSm,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ─── فقاعة رسالة ───
  Widget _buildMessageBubble(CorrThreadMessage m, double maxWidth) {
    final isIncoming = m.isIncoming;
    final sentOk = m.status.toUpperCase() == 'SENT' ||
        m.status.toUpperCase() == 'CLOSED' ||
        m.status.toUpperCase() == 'APPROVED';

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // الواردة بيضاء والصادرة زرقاء فاتحة — تمييز الاتجاه فوراً
        color: isIncoming ? Colors.white : AdminTheme.surfaceInfo,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AdminTheme.radiusLg),
          topRight: const Radius.circular(AdminTheme.radiusLg),
          bottomLeft: Radius.circular(isIncoming ? AdminTheme.radiusXs : AdminTheme.radiusLg),
          bottomRight: Radius.circular(isIncoming ? AdminTheme.radiusLg : AdminTheme.radiusXs),
        ),
        border: Border.all(
          color: isIncoming ? AdminTheme.border : AdminTheme.borderInfo,
        ),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // اسم المرسل / جهة الإرسال
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: AdminTheme.iconXs,
                color: CorrStyle.typeColor(m.type),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isIncoming
                      ? (m.senderName?.trim().isNotEmpty == true
                          ? m.senderName!
                          : 'العميل')
                      // الصادر: اسم الشركة القادم من الخادم أو تسمية افتراضية
                      : (m.senderName?.trim().isNotEmpty == true
                          ? m.senderName!
                          : 'الرد الصادر'),
                  style: TextStyle(
                    fontSize: AdminTheme.fontSm,
                    fontWeight: FontWeight.bold,
                    color: CorrStyle.typeColor(m.type),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // نص الرسالة
          if (m.body != null && m.body!.trim().isNotEmpty)
            SelectableText(
              m.body!,
              style: const TextStyle(
                fontSize: AdminTheme.fontMd,
                height: 1.6,
                color: AdminTheme.textMain,
              ),
            ),
          // مرفقات الرسالة
          if (m.attachments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.attachments.map(_attachmentChip).toList(),
            ),
          ],
          const SizedBox(height: 4),
          // التذييل: الرقم المرجعي + الوقت + علامة الإرسال
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.refNumber,
                style: const TextStyle(
                  fontSize: AdminTheme.fontXs,
                  fontFamily: 'monospace',
                  color: AdminTheme.textLight,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppFormatters.timeOnly(m.displayTime),
                style: const TextStyle(
                  fontSize: AdminTheme.fontXs,
                  color: AdminTheme.textLight,
                ),
              ),
              if (!isIncoming) ...[
                const SizedBox(width: 3),
                Icon(
                  sentOk ? Icons.done_all_rounded : Icons.done_rounded,
                  size: AdminTheme.iconSm - 2,
                  color: sentOk ? AdminTheme.accent : AdminTheme.textLight,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // الواردة من الجهة (بداية السطر = يمين في RTL) والصادرة عند النهاية
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isIncoming
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: bubble,
      ),
    );
  }

  // ─── شريحة مرفق داخل الفقاعة ───
  Widget _attachmentChip(CorrAttachment a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminTheme.surface2,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded,
              size: AdminTheme.iconXs, color: AdminTheme.amber),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              a.fileName,
              style: const TextStyle(
                  fontSize: AdminTheme.fontXs,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            AppFormatters.fileSize(a.size),
            style: const TextStyle(
                fontSize: AdminTheme.fontXs, color: AdminTheme.textLight),
          ),
        ],
      ),
    );
  }

  // ─── كبسولة حدث نظام: الإحالة ───
  Widget _buildReferralPill(CorrReferral r) {
    return _systemPill(
      icon: Icons.swap_horiz_rounded,
      color: AdminTheme.accent,
      lines: [
        'أُحيلت من ${r.fromName} إلى ${r.toName}',
        referralStatusLabel(r.status) +
            (r.dueDate != null ? ' — استحقاق: ${AppFormatters.dateOnly(r.dueDate!)}' : ''),
        if (r.note != null && r.note!.trim().isNotEmpty) r.note!,
      ],
      time: r.createdAt,
    );
  }

  // ─── كبسولة حدث نظام: التكليف ───
  Widget _buildTaskPill(CorrTask t) {
    return _systemPill(
      icon: Icons.assignment_rounded,
      color: AdminTheme.purple,
      lines: [
        'تكليف: ${t.title}',
        'المنفذ: ${t.assignedToName} — ${taskStatusLabel(t.status)}',
        if (t.dueDate != null) 'استحقاق: ${AppFormatters.dateOnly(t.dueDate!)}',
      ],
      time: t.createdAt,
    );
  }

  // ─── ملاحظة رد داخلي لم يُرسل للعميل بعد ───
  Widget _buildInternalReplyNote(CorrReply r) {
    // تسمية تعكس الحالة بدقة: مسودة / مرفوعة للاعتماد / معتمد بانتظار الإرسال / مرفوض
    final label = switch (r.status.toUpperCase()) {
      'DRAFT' => 'مسودة رد داخلي',
      'SUBMITTED' => 'رد داخلي — مرفوع للاعتماد',
      'APPROVED' => 'رد معتمد — بانتظار الإرسال للعميل',
      'REJECTED' => 'رد مرفوض',
      _ => 'رد داخلي (${replyStatusLabel(r.status)})',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWarning,
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            border: Border.all(color: AdminTheme.borderWarning),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded,
                      size: AdminTheme.iconXs, color: AdminTheme.amber),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '$label — ${r.authorName}',
                      style: const TextStyle(
                        fontSize: AdminTheme.fontSm,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.amber,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                r.body,
                style: const TextStyle(
                  fontSize: AdminTheme.fontMd,
                  height: 1.6,
                  color: AdminTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.timeOnly(r.createdAt),
                style: const TextStyle(
                    fontSize: AdminTheme.fontXs, color: AdminTheme.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── كبسولة نظام مركزية موحدة ───
  Widget _systemPill({
    required IconData icon,
    required Color color,
    required List<String> lines,
    DateTime? time,
  }) {
    final text = lines
        .where((l) => l.trim().isNotEmpty)
        .join('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            border: Border.all(color: AdminTheme.border),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: AdminTheme.iconXs, color: color),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: AdminTheme.fontSm,
                        height: 1.5,
                        color: AdminTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (time != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    AppFormatters.timeOnly(time),
                    style: const TextStyle(
                        fontSize: AdminTheme.fontXs,
                        color: AdminTheme.textLight),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── شريط سفلي: حالة المعاملة والعدادات والتفاصيل ───
  Widget _buildFooterBar() {
    final d = _detail;
    final c = widget.conversation;
    final statusColor = CorrStyle.statusColor(d?.status ?? c.status);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                corrStatusLabel(d?.status ?? c.status),
                style: TextStyle(
                  fontSize: AdminTheme.fontSm,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'إحالات ${AppFormatters.number(c.referralsCount)} • تكليفات ${AppFormatters.number(c.tasksCount)} • ردود ${AppFormatters.number(c.repliesCount)} • مرفقات ${AppFormatters.number(c.attachmentsCount)}',
                  style: const TextStyle(
                      fontSize: AdminTheme.fontXs, color: AdminTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _detail == null ? null : _openDetailsSheet,
                icon: const Icon(Icons.folder_open_rounded,
                    size: AdminTheme.iconSm),
                label: const Text('التفاصيل',
                    style: TextStyle(fontSize: AdminTheme.fontSm)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ورقة التفاصيل الكاملة (بيانات المرسل والإحالات والتكليفات) ───
  void _openDetailsSheet() {
    final d = _detail;
    if (d == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AdminTheme.radiusXl)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                // العنوان
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تفاصيل المحادثة',
                        style: TextStyle(
                            fontSize: AdminTheme.fontTitle,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: AdminTheme.iconMd),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  d.subject,
                  style: const TextStyle(
                    fontSize: AdminTheme.fontLg,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: AdminTheme.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusBadge(
                        text: '${d.refNumber}', color: AdminTheme.textMuted),
                    StatusBadge(
                        text: 'أولوية: ${priorityLabel(d.priority)}',
                        color: AdminTheme.crimson),
                    StatusBadge(
                        text: corrStatusLabel(d.status),
                        color: CorrStyle.statusColor(d.status)),
                    if (d.departmentName != null)
                      StatusBadge(
                          text: 'القسم: ${d.departmentName}',
                          color: AdminTheme.accent),
                    if (d.channel != null && d.channel!.isNotEmpty)
                      StatusBadge(
                          text: 'القناة: ${d.channel}',
                          color: AdminTheme.textMuted),
                    if (d.closedAt != null)
                      StatusBadge(
                          text:
                              'أُغلقت: ${AppFormatters.dateOnly(d.closedAt!)}',
                          color: AdminTheme.emerald),
                  ],
                ),
                const SizedBox(height: 16),
                // بيانات المرسل
                _sheetSection(
                  title: 'بيانات المرسل',
                  icon: Icons.person_rounded,
                  child: _infoGrid(d),
                ),
                const SizedBox(height: 14),
                // الإحالات
                _sheetSection(
                  title: 'الإحالات (${d.referrals.length})',
                  icon: Icons.swap_horiz_rounded,
                  child: d.referrals.isEmpty
                      ? _emptyHint('لا توجد إحالات')
                      : Column(
                          children: d.referrals
                              .map((r) => _sheetRow(
                                    icon: Icons.swap_horiz_rounded,
                                    color: AdminTheme.accent,
                                    title: '${r.fromName} → ${r.toName}',
                                    subtitle:
                                        '${referralStatusLabel(r.status)}${r.dueDate != null ? ' — استحقاق: ${AppFormatters.dateOnly(r.dueDate!)}' : ''}',
                                    extra: r.note,
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 14),
                // التكليفات
                _sheetSection(
                  title: 'التكليفات (${d.tasks.length})',
                  icon: Icons.assignment_rounded,
                  child: d.tasks.isEmpty
                      ? _emptyHint('لا توجد تكليفات')
                      : Column(
                          children: d.tasks
                              .map((t) => _sheetRow(
                                    icon: Icons.assignment_rounded,
                                    color: AdminTheme.purple,
                                    title: t.title,
                                    subtitle:
                                        '${taskStatusLabel(t.status)} — المنفذ: ${t.assignedToName}',
                                    extra: t.assignedByName.isNotEmpty
                                        ? 'كلّفه: ${t.assignedByName}'
                                        : null,
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 14),
                // الردود الداخلية
                _sheetSection(
                  title: 'الردود الداخلية (${d.replies.length})',
                  icon: Icons.reply_rounded,
                  child: d.replies.isEmpty
                      ? _emptyHint('لا توجد ردود داخلية')
                      : Column(
                          children: d.replies
                              .map((r) => _sheetRow(
                                    icon: Icons.reply_rounded,
                                    color: AdminTheme.emerald,
                                    title:
                                        '${r.authorName} — ${replyStatusLabel(r.status)}',
                                    subtitle: r.body,
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 14),
                // المرفقات
                _sheetSection(
                  title: 'المرفقات (${d.attachments.length})',
                  icon: Icons.attach_file_rounded,
                  child: d.attachments.isEmpty
                      ? _emptyHint('لا توجد مرفقات')
                      : Column(
                          children: d.attachments
                              .map((a) => _sheetRow(
                                    icon: Icons.insert_drive_file_rounded,
                                    color: AdminTheme.amber,
                                    title: a.fileName,
                                    subtitle:
                                        '${a.mimeType} — ${AppFormatters.fileSize(a.size)}',
                                  ))
                              .toList(),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.bgLight,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AdminTheme.iconSm, color: AdminTheme.accent),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AdminTheme.fontMd)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoGrid(CorrDetail d) {
    final pairs = <(String, String)>[
      ('الاسم', d.senderName ?? '-'),
      ('البريد الإلكتروني', d.senderEmail ?? '-'),
      ('الهاتف', d.senderPhone ?? '-'),
      ('سجّلها', d.createdByName ?? '-'),
      (
        'تاريخ الاستلام',
        d.receivedAt != null ? AppFormatters.dateTime(d.receivedAt!) : '-'
      ),
      (
        'تاريخ الإرسال',
        d.sentAt != null ? AppFormatters.dateTime(d.sentAt!) : '-'
      ),
    ];
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: pairs
          .map((p) => SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$1,
                      style: const TextStyle(
                        fontSize: AdminTheme.fontXs,
                        color: AdminTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      p.$2,
                      style: const TextStyle(
                        fontSize: AdminTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _sheetRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AdminTheme.iconSm, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: AdminTheme.fontBase,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                SelectableText(
                  subtitle,
                  style: const TextStyle(
                      fontSize: AdminTheme.fontBase,
                      color: AdminTheme.textMuted,
                      height: 1.5),
                ),
                if (extra != null && extra.isNotEmpty)
                  Text(extra,
                      style: const TextStyle(
                          fontSize: AdminTheme.fontSm,
                          color: AdminTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Row(
      children: [
        const Icon(Icons.inbox_outlined, size: AdminTheme.iconXs, color: AdminTheme.textLight),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: AdminTheme.fontBase, color: AdminTheme.textMuted)),
      ],
    );
  }
}

/// نوع حدث في الخط الزمني
enum _EntryKind { dayDivider, message, referral, task, internalReply }

/// حدث موحد في الخط الزمني للمحادثة
class _TimelineEntry {
  final DateTime timestamp;
  final _EntryKind kind;
  final CorrThreadMessage? message;
  final CorrReferral? referral;
  final CorrTask? task;
  final CorrReply? reply;

  _TimelineEntry({
    required this.timestamp,
    required this.kind,
    this.message,
    this.referral,
    this.task,
    this.reply,
  });
}
