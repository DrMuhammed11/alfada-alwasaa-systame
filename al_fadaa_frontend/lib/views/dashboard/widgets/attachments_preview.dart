import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
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

  static bool isImage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);
  }

  static bool isPdf(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final imageAttachments = attachments.where((a) => isImage(a.fileName)).toList();
    final docAttachments = attachments.where((a) => !isImage(a.fileName)).toList();

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
          const SizedBox(height: 10),

          // 1. معرض الصور المرئية (إن وجدت)
          if (imageAttachments.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: imageAttachments.map((att) {
                final isDownloading = downloadingAttachmentIds.contains(att.id);
                return _ImageThumbnailCard(
                  attachment: att,
                  isDownloading: isDownloading,
                  onDownload: () => onDownloadAttachment(att),
                );
              }).toList(),
            ),
            if (docAttachments.isNotEmpty) const SizedBox(height: 12),
          ],

          // 2. بطاقات المستندات وملفات الـ PDF
          if (docAttachments.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docAttachments.map((att) {
                final isDownloading = downloadingAttachmentIds.contains(att.id);
                final pdf = isPdf(att.fileName);
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
                      const SizedBox(width: 6),
                      if (pdf)
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF0284C7)),
                          tooltip: 'فتح / معاينة في تبويب جديد',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => ApiService().viewAttachment(att.id, att.fileName, att.mimeType),
                        ),
                      if (pdf) const SizedBox(width: 4),
                      isDownloading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF475569)),
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
        return AppTheme.crimson;
      case 'doc':
      case 'docx':
        return AppTheme.accent;
      case 'xls':
      case 'xlsx':
        return AppTheme.emerald;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return AppTheme.amber;
      default:
        return AppTheme.textMuted;
    }
  }
}

class _ImageThumbnailCard extends StatefulWidget {
  final AttachmentItem attachment;
  final bool isDownloading;
  final VoidCallback onDownload;

  const _ImageThumbnailCard({
    required this.attachment,
    required this.isDownloading,
    required this.onDownload,
  });

  @override
  State<_ImageThumbnailCard> createState() => _ImageThumbnailCardState();
}

class _ImageThumbnailCardState extends State<_ImageThumbnailCard> {
  Uint8List? _bytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await ApiService().getAttachmentBytes(widget.attachment.id);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _showFullImage(BuildContext context) {
    if (_bytes == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.attachment.fileName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    widget.attachment.formattedSize,
                    style: const TextStyle(color: AppTheme.textOnLight, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    tooltip: 'تحميل الصورة',
                    onPressed: widget.onDownload,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: Colors.black,
                constraints: const BoxConstraints(maxHeight: 600, maxWidth: 900),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      _bytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _bytes != null ? () => _showFullImage(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 180,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_hasError || _bytes == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_rounded, size: 24, color: AppTheme.textOnLight),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  widget.attachment.fileName,
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.memory(
                          _bytes!,
                          fit: BoxFit.cover,
                        )),
            ),

            // شريط شفاف سفلي لمعلومات الملف وزر التحميل
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xCC0F172A),
                      Color(0x800F172A),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.attachment.fileName,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.attachment.formattedSize,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      tooltip: 'تحميل',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDownload,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
