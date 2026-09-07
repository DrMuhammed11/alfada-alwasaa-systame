import 'user_model.dart';

class AttachmentItem {
  final String id;
  final String fileName;
  final String? storedName;
  final String? mimeType;
  final int size;
  final DateTime createdAt;
  final String? correspondenceId;
  final String? replyId;
  final User? uploadedBy;

  AttachmentItem({
    required this.id,
    required this.fileName,
    this.storedName,
    this.mimeType,
    required this.size,
    required this.createdAt,
    this.correspondenceId,
    this.replyId,
    this.uploadedBy,
  });

  String get formattedSize {
    if (size <= 0) return '0 B';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? 'مرفق',
      storedName: json['storedName'],
      mimeType: json['mimeType'],
      size: json['size'] is int ? json['size'] : int.tryParse('${json['size']}') ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      correspondenceId: json['correspondenceId'],
      replyId: json['replyId'],
      uploadedBy: json['uploadedBy'] != null ? User.fromJson(json['uploadedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'size': size,
      'mimeType': mimeType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
