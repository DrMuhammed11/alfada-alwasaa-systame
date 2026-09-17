import 'user_model.dart';
import 'referral_model.dart';
import 'task_model.dart';
import 'attachment_model.dart';
import 'reply_model.dart';

export 'referral_model.dart';
export 'task_model.dart';
export 'attachment_model.dart';
export 'reply_model.dart';

class Correspondence {
  final String id;
  final String serialNumber;
  final String subject;
  final String type; // INCOMING, OUTGOING, INTERNAL
  final String status; // RECEIVED, UNDER_REVIEW, REFERRED, IN_PROGRESS, PENDING_APPROVAL, APPROVED, SENT, CLOSED, ARCHIVED
  final String priority; // LOW, NORMAL, HIGH, URGENT
  final String? channel;
  final String? body;
  final String? senderName;
  final String? senderEmail;
  final String? senderPhone;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final DateTime? sentAt;
  final DateTime? closedAt;
  final Department? department;
  final User? createdBy;
  final String? parentId;
  final Correspondence? parent;
  final String? messageId;
  final String? sourceReplyId;
  final List<ReferralItem> referrals;
  final List<TaskItem> tasks;
  final List<ReplyItem> replies;
  final List<Correspondence> children;
  final int childrenCount;
  final int repliesCount;
  final List<AttachmentItem> attachments;
  final bool isOverdue;
  final int overdueDays;

  Correspondence({
    required this.id,
    required this.serialNumber,
    required this.subject,
    required this.type,
    required this.status,
    required this.priority,
    this.channel,
    this.body,
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    required this.createdAt,
    this.receivedAt,
    this.sentAt,
    this.closedAt,
    this.department,
    this.createdBy,
    this.parentId,
    this.parent,
    this.messageId,
    this.sourceReplyId,
    this.referrals = const [],
    this.tasks = const [],
    this.replies = const [],
    this.children = const [],
    this.attachments = const [],
    this.childrenCount = 0,
    this.repliesCount = 0,
    this.isOverdue = false,
    this.overdueDays = 0,
  });

  factory Correspondence.fromJson(Map<String, dynamic> json) {
    return Correspondence(
      id: json['id'] ?? '',
      serialNumber: json['refNumber'] ?? '',
      subject: json['subject'] ?? 'بدون عنوان',
      type: json['type'] ?? 'INCOMING',
      status: json['status'] ?? 'RECEIVED',
      priority: json['priority'] ?? 'NORMAL',
      channel: json['channel'] ?? 'EMAIL',
      body: json['body'],
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      senderPhone: json['senderPhone'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      receivedAt: json['receivedAt'] != null ? DateTime.parse(json['receivedAt']) : null,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      department: json['department'] != null ? Department.fromJson(json['department']) : null,
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy']) : null,
      parentId: json['parentId'],
      parent: json['parent'] != null ? Correspondence.fromJson(json['parent']) : null,
      messageId: json['messageId'],
      sourceReplyId: json['sourceReplyId'],
      isOverdue: json['isOverdue'] as bool? ?? false,
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
      referrals: json['referrals'] != null
          ? (json['referrals'] as List).map((i) => ReferralItem.fromJson(i)).toList()
          : [],
      tasks: json['tasks'] != null
          ? (json['tasks'] as List).map((i) => TaskItem.fromJson(i)).toList()
          : [],
      replies: json['replies'] != null
          ? (json['replies'] as List).map((i) => ReplyItem.fromJson(i)).toList()
          : [],
      children: json['children'] != null
          ? (json['children'] as List).map((i) => Correspondence.fromJson(i)).toList()
          : [],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => AttachmentItem.fromJson(a)).toList()
          : [],
      childrenCount: json['_count']?['children'] ?? (json['children'] != null ? (json['children'] as List).length : 0),
      repliesCount: json['_count']?['replies'] ?? (json['replies'] != null ? (json['replies'] as List).length : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refNumber': serialNumber,
      'subject': subject,
      'type': type,
      'status': status,
      'priority': priority,
      'channel': channel,
      'body': body,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderPhone': senderPhone,
      'createdAt': createdAt.toIso8601String(),
      'receivedAt': receivedAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'department': department?.toJson(),
      'createdBy': createdBy?.toJson(),
      'parentId': parentId,
      'parent': parent?.toJson(),
      'messageId': messageId,
      'sourceReplyId': sourceReplyId,
      'isOverdue': isOverdue,
      'overdueDays': overdueDays,
      'referrals': referrals.map((r) => r.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'children': children.map((c) => c.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      '_count': {
        'children': childrenCount,
        'replies': repliesCount,
      },
    };
  }

  Correspondence copyWith({
    String? id,
    String? serialNumber,
    String? subject,
    String? type,
    String? status,
    String? priority,
    String? channel,
    String? body,
    String? senderName,
    String? senderEmail,
    String? senderPhone,
    DateTime? createdAt,
    DateTime? receivedAt,
    DateTime? sentAt,
    DateTime? closedAt,
    Department? department,
    User? createdBy,
    String? parentId,
    Correspondence? parent,
    String? messageId,
    String? sourceReplyId,
    List<ReferralItem>? referrals,
    List<TaskItem>? tasks,
    List<ReplyItem>? replies,
    List<Correspondence>? children,
    int? childrenCount,
    int? repliesCount,
    List<AttachmentItem>? attachments,
    bool? isOverdue,
    int? overdueDays,
  }) {
    return Correspondence(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      channel: channel ?? this.channel,
      body: body ?? this.body,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhone: senderPhone ?? this.senderPhone,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      sentAt: sentAt ?? this.sentAt,
      closedAt: closedAt ?? this.closedAt,
      department: department ?? this.department,
      createdBy: createdBy ?? this.createdBy,
      parentId: parentId ?? this.parentId,
      parent: parent ?? this.parent,
      messageId: messageId ?? this.messageId,
      sourceReplyId: sourceReplyId ?? this.sourceReplyId,
      referrals: referrals ?? this.referrals,
      tasks: tasks ?? this.tasks,
      replies: replies ?? this.replies,
      children: children ?? this.children,
      childrenCount: childrenCount ?? this.childrenCount,
      repliesCount: repliesCount ?? this.repliesCount,
      attachments: attachments ?? this.attachments,
      isOverdue: isOverdue ?? this.isOverdue,
      overdueDays: overdueDays ?? this.overdueDays,
    );
  }
}
