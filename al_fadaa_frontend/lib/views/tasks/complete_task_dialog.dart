import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../models/task_model.dart';

class CompleteTaskDialog extends StatefulWidget {
  final TaskItem task;
  final String? correspondenceId;

  const CompleteTaskDialog({
    super.key,
    required this.task,
    this.correspondenceId,
  });

  @override
  State<CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<CompleteTaskDialog> {
  final _noteController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 15 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حجم الملف يتجاوز الحد المسموح (15MB)'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
          }
          return;
        }
        setState(() {
          _pickedFile = file;
        });
      }
    } catch (e) {
      debugPrint('pickFiles in CompleteTaskDialog error: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final corrId = widget.correspondenceId ?? widget.task.correspondenceId;

    // إذا تم اختيار ملف إثبات/تقرير إنجاز، نرفعه أولاً إلى المراسلة
    if (_pickedFile != null && _pickedFile!.bytes != null && corrId != null && corrId.isNotEmpty) {
      try {
        final uploadRes = await ApiService().uploadCorrespondenceAttachment(
          corrId,
          _pickedFile!.bytes!,
          _pickedFile!.name,
        );
        if (uploadRes['success'] != true) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes['message'] ?? 'فشل رفع مستند الإنجاز إلى المعاملة'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء رفع المستند: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    final res = await ApiService().updateTaskStatus(
      widget.task.id,
      'DONE',
      completionNote: _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'فشل تحديث حالة التكليف'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تأكيد إنجاز المهمة بواسطة القطاع',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            widget.task.title,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // مؤشر مهلة الـ SLA
                if (widget.task.dueDate != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.task.slaBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.task.slaColor.withAlpha(70)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.task.slaIcon, size: 15, color: widget.task.slaColor),
                        const SizedBox(width: 8),
                        Text(
                          'مهلة الإنجاز (SLA): ${widget.task.slaLabel}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: widget.task.slaColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(),
                const SizedBox(height: 12),

                // Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'عند تأكيد الإنجاز، سيتم تسجيل إثباتات الإنجاز وإعادة المعاملة لتكون جاهزة للاعتماد والرد على العميل.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'ملاحظة أو تقرير الإنجاز (اختياري):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل ما تم إنجازه بواسطة القطاع ليظهر في كشف المعاملة والرد...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xFF059669), width: 1.5),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // إرفاق مستند أو تقرير إنجاز (ملفات / PDF / صور / عروض أسعار)
                const Text(
                  'إرفاق إثبات الإنجاز / تقرير فني / عرض سعر (اختياري):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                if (_pickedFile == null) ...[
                  InkWell(
                    onTap: _isLoading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_rounded, size: 20, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text(
                            'اختر ملفاً لإرفاقه (عرض سعر، تقرير فني، إيصال، PDF، صورة)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedFile!.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatFileSize(_pickedFile!.size),
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                          tooltip: 'إلغاء الملف',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _isLoading ? null : () => setState(() => _pickedFile = null),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'تأكيد الإنجاز وإعادة المعاملة للرد',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
