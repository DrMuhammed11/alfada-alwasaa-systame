import 'user_model.dart';
import 'attachment_model.dart';

class ReplyItem {
  final String id;
  final String? authorId;
  final String body;
  final String status; // DRAFT, SUBMITTED, APPROVED, REJECTED, SENT
  final bool isApproved;
  final String? reviewNote;
  final DateTime createdAt;
  final User? author;
  final User? reviewedBy;
  final User? approvedBy;
  final String? sourceReplyId;
  final List<AttachmentItem> attachments;

  ReplyItem({
    required this.id,
    this.authorId,
    required this.body,
    required this.status,
    required this.isApproved,
    this.reviewNote,
    required this.createdAt,
    this.author,
    this.reviewedBy,
    this.approvedBy,
    this.sourceReplyId,
    this.attachments = const [],
  });

  factory ReplyItem.fromJson(Map<String, dynamic> json) {
    return ReplyItem(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? json['author']?['id'],
      body: json['body'] ?? '',
      status: json['status'] ?? 'DRAFT',
      isApproved: json['status'] == 'APPROVED',
      reviewNote: json['reviewNote'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      author: json['author'] != null ? User.fromJson(json['author']) : null,
      reviewedBy: json['reviewedBy'] != null ? User.fromJson(json['reviewedBy']) : null,
      approvedBy: json['approvedBy'] != null ? User.fromJson(json['approvedBy']) : null,
      sourceReplyId: json['sourceReplyId'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => AttachmentItem.fromJson(a)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'status': status,
      'isApproved': isApproved,
      'reviewNote': reviewNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
