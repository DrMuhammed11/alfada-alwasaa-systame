import 'user_model.dart';
import 'attachment_model.dart';

class ApprovalStepItem {
  final String id;
  final int stepOrder;
  final String requiredRole;
  final String status; // PENDING, APPROVED, REJECTED, SKIPPED
  final String? decisionNote;
  final String? decidedById;
  final User? decidedBy;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  ApprovalStepItem({
    required this.id,
    required this.stepOrder,
    required this.requiredRole,
    required this.status,
    this.decisionNote,
    this.decidedById,
    this.decidedBy,
    this.decidedAt,
    this.createdAt,
  });

  factory ApprovalStepItem.fromJson(Map<String, dynamic> json) {
    return ApprovalStepItem(
      id: json['id'] ?? '',
      stepOrder: json['stepOrder'] ?? 1,
      requiredRole: json['requiredRole'] ?? '',
      status: json['status'] ?? 'PENDING',
      decisionNote: json['decisionNote'],
      decidedById: json['decidedById'],
      decidedBy: json['decidedBy'] != null ? User.fromJson(json['decidedBy']) : null,
      decidedAt: json['decidedAt'] != null ? DateTime.parse(json['decidedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepOrder': stepOrder,
      'requiredRole': requiredRole,
      'status': status,
      'decisionNote': decisionNote,
      'decidedById': decidedById,
      'decidedAt': decidedAt?.toIso8601String(),
    };
  }
}

class ReplyVersionItem {
  final String id;
  final String replyId;
  final int versionNumber;
  final String body;
  final String statusAtSnapshot;
  final String reason;
  final String? createdById;
  final User? createdBy;
  final DateTime createdAt;

  ReplyVersionItem({
    required this.id,
    required this.replyId,
    required this.versionNumber,
    required this.body,
    required this.statusAtSnapshot,
    required this.reason,
    this.createdById,
    this.createdBy,
    required this.createdAt,
  });

  factory ReplyVersionItem.fromJson(Map<String, dynamic> json) {
    return ReplyVersionItem(
      id: json['id'] ?? '',
      replyId: json['replyId'] ?? '',
      versionNumber: json['versionNumber'] ?? 1,
      body: json['body'] ?? '',
      statusAtSnapshot: json['statusAtSnapshot'] ?? 'DRAFT',
      reason: json['reason'] ?? '',
      createdById: json['createdById'],
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class DiffLineItem {
  final String type; // 'added', 'removed', 'unchanged'
  final String text;

  DiffLineItem({required this.type, required this.text});

  factory DiffLineItem.fromJson(Map<String, dynamic> json) {
    return DiffLineItem(
      type: json['type'] ?? 'unchanged',
      text: json['text'] ?? '',
    );
  }
}

class DiffResult {
  final int v1;
  final int v2;
  final List<DiffLineItem> lines;

  DiffResult({required this.v1, required this.v2, required this.lines});

  factory DiffResult.fromJson(Map<String, dynamic> json) {
    return DiffResult(
      v1: json['v1'] ?? 1,
      v2: json['v2'] ?? 2,
      lines: json['lines'] != null
          ? (json['lines'] as List).map((l) => DiffLineItem.fromJson(l)).toList()
          : [],
    );
  }
}

class ReplyItem {
  final String id;
  final String? authorId;
  final String body;
  final String status; // DRAFT, SUBMITTED, APPROVED, REJECTED, SENT
  final int version;
  final bool isApproved;
  final String? reviewNote;
  final DateTime createdAt;
  final User? author;
  final User? reviewedBy;
  final User? approvedBy;
  final String? sourceReplyId;
  final List<AttachmentItem> attachments;
  final List<ApprovalStepItem> approvalSteps;

  ReplyItem({
    required this.id,
    this.authorId,
    required this.body,
    required this.status,
    this.version = 1,
    required this.isApproved,
    this.reviewNote,
    required this.createdAt,
    this.author,
    this.reviewedBy,
    this.approvedBy,
    this.sourceReplyId,
    this.attachments = const [],
    this.approvalSteps = const [],
  });

  factory ReplyItem.fromJson(Map<String, dynamic> json) {
    return ReplyItem(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? json['author']?['id'],
      body: json['body'] ?? '',
      status: json['status'] ?? 'DRAFT',
      version: json['version'] ?? 1,
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
      approvalSteps: json['approvalSteps'] != null
          ? (json['approvalSteps'] as List).map((s) => ApprovalStepItem.fromJson(s)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'status': status,
      'version': version,
      'isApproved': isApproved,
      'reviewNote': reviewNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
