import 'user_model.dart';
import 'attachment_model.dart';

class ReplyItem {
  final String id;
  final String? authorId;
  final String content;
  final String status; // DRAFT, SUBMITTED, APPROVED, REJECTED, SENT
  final bool isApproved;
  final String? rejectionReason;
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
    required this.content,
    required this.status,
    required this.isApproved,
    this.rejectionReason,
    this.reviewNote,
    required this.createdAt,
    this.author,
    this.reviewedBy,
    this.approvedBy,
    this.sourceReplyId,
    this.attachments = const [],
  });

  factory ReplyItem.fromJson(Map<String, dynamic> json) {
    final rNote = json['reviewNote'] ?? json['rejectionReason'] ?? json['rejectionNote'];
    return ReplyItem(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? json['author']?['id'] ?? json['createdById'] ?? json['createdBy']?['id'],
      content: json['body'] ?? json['content'] ?? '',
      status: json['status'] ?? 'DRAFT',
      isApproved: json['status'] == 'APPROVED' || json['isApproved'] == true,
      rejectionReason: rNote,
      reviewNote: rNote,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      author: json['author'] != null ? User.fromJson(json['author']) : (json['createdBy'] != null ? User.fromJson(json['createdBy']) : null),
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
      'content': content,
      'status': status,
      'isApproved': isApproved,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
