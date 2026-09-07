import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/download_helper.dart';
import '../../../models/correspondence_model.dart';

class WorkDossierDialog extends StatelessWidget {
  final Correspondence item;
  final Function(AttachmentItem) onDownloadAttachment;

  const WorkDossierDialog({
    super.key,
    required this.item,
    required this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    // تجميع كافة المرفقات التابعة للمعاملة
    final List<AttachmentItem> allAttachments = [];
    allAttachments.addAll(item.attachments);
    for (final child in item.children) {
      allAttachments.addAll(child.attachments);
    }
    for (final reply in item.replies) {
      allAttachments.addAll(reply.attachments);
    }

    final priorityColor = AppTheme.getPriorityColor(item.priority);
    final statusColor = AppTheme.getStatusColor(item.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 960,
        height: 780,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // ─── ترويسة النافذة الرسمية ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'شركة الفضاء الواسع — كشف إنجاز وسجل المعاملة الكامل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'رقم الطلبية الموحد: ${item.serialNumber}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: item.serialNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ رقم الطلبية')),
                                );
                              },
                              child: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // زر طباعة الكشف وحفظ كـ PDF
                  ElevatedButton.icon(
                    onPressed: () => _printOrSaveDossier(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text(
                      'طباعة الكشف / حفظ كـ PDF',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── محتوى الكشف التفاعلي الكامل ───
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // 1. بطاقة البيانات الأساسية للطلبية
                    _buildSectionHeader('📌 البيانات الأساسية للطلبية / المعاملة', Icons.info_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildMetaItem('موضوع الطلب', item.subject, isBold: true)),
                              Expanded(child: _buildMetaItem('العميل / الجهة', item.senderName ?? 'عميل خارجي')),
                              Expanded(child: _buildMetaItem('البريد الإلكتروني', item.senderEmail ?? '-')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetaBadge(
                                  'الحالة الحالية',
                                  ApiConstants.getStatusLabel(item.status),
                                  statusColor,
                                ),
                              ),
                              Expanded(
                                child: _buildMetaBadge(
                                  'الأولوية',
                                  ApiConstants.getPriorityLabel(item.priority),
                                  priorityColor,
                                ),
                              ),
                              Expanded(child: _buildMetaItem('القسم المعني', item.department?.name ?? 'الإدارة العامة')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildMetaItem('تاريخ الاستلام', _formatDateTime(item.receivedAt ?? item.createdAt))),
                              Expanded(
                                child: _buildMetaItem(
                                  'تاريخ الإنجاز والإغلاق',
                                  item.closedAt != null ? _formatDateTime(item.closedAt!) : 'قيد المعالجة',
                                ),
                              ),
                              Expanded(child: _buildMetaItem('إجمالي المرفقات المتبادلة', '${allAttachments.length} ملف')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. سجل مهام وتكليفات القطاعات
                    _buildSectionHeader('🏢 تكليفات القطاعات وإنجاز الأعمال', Icons.domain_verification_rounded),
                    const SizedBox(height: 10),
                    if (item.tasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text(
                              'تمت معالجة وإنجاز الطلب مباشرة عبر الإدارة العامة (لا توجد تكليفات لقطاعات فرعية).',
                              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      )
                    else
                      ...item.tasks.map((t) => _buildTaskCard(t)),

                    const SizedBox(height: 24),

                    // 3. السجل الزمني التام للمراسلات والردود
                    _buildSectionHeader('💬 السجل الزمني للمراسلات والردود المتبادلة', Icons.chat_rounded),
                    const SizedBox(height: 10),
                    _buildMessageTimelineCard(
                      title: 'الرسالة الواردة الأساسية من العميل',
                      sender: item.senderName ?? item.senderEmail ?? 'العميل',
                      date: item.receivedAt ?? item.createdAt,
                      body: item.body ?? 'لا يوجد نص',
                      isClient: true,
                    ),
                    for (final child in item.children)
                      if (child.sourceReplyId == null)
                        _buildMessageTimelineCard(
                          title: 'تعقيب إضافي من العميل',
                          sender: child.senderName ?? (item.senderName ?? 'العميل'),
                          date: child.createdAt,
                          body: child.body ?? 'لا يوجد نص',
                          isClient: true,
                        ),
                    for (final reply in item.replies)
                      _buildMessageTimelineCard(
                        title: reply.status == 'SENT'
                            ? 'رد رسمي صادر تم إرساله للعميل بالبريد'
                            : (reply.status == 'APPROVED' ? 'رد معتمد جاهز للإرسال' : 'مسودة رد داخلية'),
                        sender: reply.author?.fullName ?? 'شركة الفضاء الواسع',
                        date: reply.createdAt,
                        body: reply.body,
                        isClient: false,
                        isOfficialReply: reply.status == 'SENT',
                      ),

                    const SizedBox(height: 24),

                    // 4. جدول المرفقات المتبادلة الكامل
                    _buildSectionHeader('📎 فهرس كافة المرفقات المتبادلة (${allAttachments.length})', Icons.attach_file_rounded),
                    const SizedBox(height: 10),
                    if (allAttachments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('لا توجد مرفقات مرتبطة بهذه المعاملة.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: allAttachments.map((att) => _buildAttachmentRow(att)).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ─── تذييل النافذة ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'وثيقة عمل رسمية موثقة بسجل التدقيق لنظام شركة الفضاء الواسع.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E293B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetaBadge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    final isDone = task.status == 'DONE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                size: 18,
                color: isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المهمة: ${task.title}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDone ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task.slaBgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: task.slaColor.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(task.slaIcon, size: 13, color: task.slaColor),
                    const SizedBox(width: 4),
                    Text(
                      task.slaLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: task.slaColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'المسؤول المكلف: ${task.assignedTo?.fullName ?? 'القطاع'}  |  تاريخ التكليف: ${_formatDateTime(task.createdAt)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          if (task.description != null && task.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                task.description!.trim(),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageTimelineCard({
    required String title,
    required String sender,
    required DateTime date,
    required String body,
    required bool isClient,
    bool isOfficialReply = false,
  }) {
    final borderColor = isOfficialReply
        ? const Color(0xFF10B981)
        : (isClient ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0));
    final bgColor = isOfficialReply
        ? const Color(0xFFF0FDF4)
        : (isClient ? const Color(0xFFF8FAFC) : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOfficialReply
                  ? const Color(0xFFDCFCE7)
                  : (isClient ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isClient ? Icons.person_rounded : Icons.business_rounded,
                  size: 15,
                  color: isClient ? const Color(0xFF0284C7) : const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isClient ? const Color(0xFF0369A1) : const Color(0xFF047857),
                  ),
                ),
                const Spacer(),
                Text(
                  '$sender  •  ${_formatDateTime(date)}',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              body,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(AttachmentItem att) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.fileName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'الحجم: ${(att.size / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            onPressed: () => onDownloadAttachment(att),
            icon: const Icon(Icons.download_rounded, size: 14),
            label: const Text('تنزيل', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _printOrSaveDossier(BuildContext context) {
    final html = _generatePrintableHtml();
    printHtmlDossier(html);
  }

  String _generatePrintableHtml() {
    final allAttachments = <AttachmentItem>[];
    allAttachments.addAll(item.attachments);
    for (final child in item.children) {
      allAttachments.addAll(child.attachments);
    }
    for (final reply in item.replies) {
      allAttachments.addAll(reply.attachments);
    }

    final tasksHtml = item.tasks.isEmpty
        ? '<p style="color:#666;font-size:13px;">تمت معالجة وإنجاز الطلب مباشرة عبر الإدارة العامة.</p>'
        : item.tasks.map((t) => '''
          <div style="border:1px solid #ddd;padding:10px;margin-bottom:8px;border-radius:6px;background:#fafafa;">
            <strong>المهمة:</strong> ${t.title} <br/>
            <strong>المكلف:</strong> ${t.assignedTo?.fullName ?? 'القطاع'} | 
            <strong>الحالة:</strong> ${t.status == 'DONE' ? 'تم الإنجاز بنجاح ✅' : 'قيد التنفيذ'} | 
            <strong>تاريخ التكليف:</strong> ${_formatDateTime(t.createdAt)}
            ${t.description != null ? '<p style="margin:6px 0 0 0;font-size:12px;color:#333;">${t.description}</p>' : ''}
          </div>
        ''').join();

    final messagesHtml = StringBuffer();
    messagesHtml.write('''
      <div style="border:1px solid #0284c7;padding:12px;margin-bottom:10px;border-radius:6px;background:#f0f9ff;">
        <strong>الرسالة الأصلية من العميل:</strong> ${item.senderName ?? item.senderEmail ?? ''} (${_formatDateTime(item.receivedAt ?? item.createdAt)})
        <p style="white-space:pre-wrap;margin-top:6px;font-size:13px;">${item.body ?? ''}</p>
      </div>
    ''');
    for (final child in item.children) {
      if (child.sourceReplyId == null) {
        messagesHtml.write('''
          <div style="border:1px solid #0284c7;padding:12px;margin-bottom:10px;border-radius:6px;background:#f0f9ff;">
            <strong>تعقيب من العميل:</strong> ${child.senderName ?? 'العميل'} (${_formatDateTime(child.createdAt)})
            <p style="white-space:pre-wrap;margin-top:6px;font-size:13px;">${child.body ?? ''}</p>
          </div>
        ''');
      }
    }
    for (final reply in item.replies) {
      messagesHtml.write('''
        <div style="border:1px solid #059669;padding:12px;margin-bottom:10px;border-radius:6px;background:#f0fdf4;">
          <strong>${reply.status == 'SENT' ? 'رد رسمي صادر للعميل' : 'مسودة رد'}:</strong> ${reply.author?.fullName ?? 'شركة الفضاء الواسع'} (${_formatDateTime(reply.createdAt)})
          <p style="white-space:pre-wrap;margin-top:6px;font-size:13px;">${reply.body}</p>
        </div>
      ''');
    }

    final attachmentsHtml = allAttachments.isEmpty
        ? '<p style="color:#666;font-size:13px;">لا توجد مرفقات.</p>'
        : '<ul style="font-size:13px;color:#333;">${allAttachments.map((a) => '<li>${a.fileName} (${(a.size / 1024).toStringAsFixed(1)} KB)</li>').join()}</ul>';

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>كشف إنجاز وسجل المعاملة الكامل — ${item.serialNumber}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Cairo", Tahoma, sans-serif; direction: rtl; margin: 30px; color: #1e293b; }
    .header { text-align: center; border-bottom: 2px solid #0f172a; padding-bottom: 15px; margin-bottom: 20px; }
    .header h1 { margin: 0; font-size: 20px; color: #0f172a; }
    .header p { margin: 5px 0 0 0; color: #64748b; font-size: 13px; }
    .ref-badge { display: inline-block; background: #0f172a; color: #fff; padding: 4px 12px; border-radius: 4px; font-weight: bold; margin-top: 8px; font-size: 14px; }
    table.meta-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 13px; }
    table.meta-table td { padding: 8px 12px; border: 1px solid #e2e8f0; }
    table.meta-table td.label { background: #f8fafc; font-weight: bold; width: 18%; color: #475569; }
    h2 { font-size: 15px; border-bottom: 1.5px solid #cbd5e1; padding-bottom: 6px; margin-top: 24px; color: #0f172a; }
    .footer { margin-top: 40px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 10px; }
    @media print {
      body { margin: 15mm; }
      @page { size: A4; margin: 10mm; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>شركة الفضاء الواسع للتجارة والمقاولات</h1>
    <p>نظام إدارة المراسلات والعمليات — كشف إنجاز وسجل المعاملة الكامل</p>
    <div class="ref-badge">رقم المعاملة: ${item.serialNumber}</div>
  </div>

  <h2>📌 بيانات المعاملة الأساسية</h2>
  <table class="meta-table">
    <tr>
      <td class="label">الموضوع</td>
      <td colspan="3"><strong>${item.subject}</strong></td>
    </tr>
    <tr>
      <td class="label">العميل / الجهة</td>
      <td>${item.senderName ?? 'عميل خارجي'}</td>
      <td class="label">البريد الإلكتروني</td>
      <td>${item.senderEmail ?? '-'}</td>
    </tr>
    <tr>
      <td class="label">الحالة النهائية</td>
      <td>${ApiConstants.getStatusLabel(item.status)}</td>
      <td class="label">الأولوية</td>
      <td>${ApiConstants.getPriorityLabel(item.priority)}</td>
    </tr>
    <tr>
      <td class="label">تاريخ الاستلام</td>
      <td>${_formatDateTime(item.receivedAt ?? item.createdAt)}</td>
      <td class="label">تاريخ الإغلاق</td>
      <td>${item.closedAt != null ? _formatDateTime(item.closedAt!) : 'قيد المعالجة'}</td>
    </tr>
  </table>

  <h2>🏢 تكليفات القطاعات وإنجاز الأعمال</h2>
  $tasksHtml

  <h2>💬 سجل المراسلات والردود الزمني</h2>
  ${messagesHtml.toString()}

  <h2>📎 فهرس المرفقات المتبادلة</h2>
  $attachmentsHtml

  <div class="footer">
    تم استخراج هذا الكشف آلياً من نظام شركة الفضاء الواسع • رقم المعاملة الموحد: ${item.serialNumber} • تاريخ الطباعة: ${_formatDateTime(DateTime.now())}
  </div>
</body>
</html>
''';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
