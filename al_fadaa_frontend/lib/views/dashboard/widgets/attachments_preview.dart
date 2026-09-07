import 'package:flutter/material.dart';
import '../../../models/attachment_model.dart';

class AttachmentsPreview extends StatelessWidget {
  final List<AttachmentItem> attachments;
  final Set<String> downloadingAttachmentIds;
  final Function(AttachmentItem) onDownloadAttachment;

  const AttachmentsPreview({
    super.key,
    required this.attachments,
    required this.downloadingAttachmentIds,
    required this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'المرفقات (${attachments.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((att) {
              final isDownloading = downloadingAttachmentIds.contains(att.id);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getAttachmentIcon(att.fileName),
                      size: 16,
                      color: getAttachmentColor(att.fileName),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        att.fileName,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${att.formattedSize})',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    isDownloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0284C7)),
                            tooltip: 'تحميل المرفق',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onDownloadAttachment(att),
                          ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static IconData getAttachmentIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color getAttachmentColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF059669);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }
}
