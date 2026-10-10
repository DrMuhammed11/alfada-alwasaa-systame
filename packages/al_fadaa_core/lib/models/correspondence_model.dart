import 'department_model.dart';
import 'user_model.dart';
import 'referral_model.dart';
import 'task_model.dart';
import 'attachment_model.dart';
import 'reply_model.dart';

export 'department_model.dart';
export 'user_model.dart';
export 'referral_model.dart';
export 'task_model.dart';
export 'attachment_model.dart';
export 'reply_model.dart';

/// نموذج المعاملة/المراسلة الموحد لتطبيقات الفضاء الواسع — متوافق مع خادم NestJS
class Correspondence {
  final String id;
  final String refNumber;
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
  final DateTime? updatedAt;
  final DateTime? receivedAt;
  final DateTime? sentAt;
  final DateTime? closedAt;
  final Department? department;
  final String? departmentName;
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
  final int referralsCount;
  final int tasksCount;
  final int attachmentsCount;
  final List<AttachmentItem> attachments;
  final bool isOverdue;
  final int overdueDays;
  final String? latestChildBody;

  // توفير serialNumber للتوافق التام مع الشاشات القديمة
  String get serialNumber => refNumber;

  Correspondence({
    required this.id,
    required this.refNumber,
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
    this.updatedAt,
    this.receivedAt,
    this.sentAt,
    this.closedAt,
    this.department,
    this.departmentName,
    this.createdBy,
    this.parentId,
    this.parent,
    this.messageId,
    this.sourceReplyId,
    this.referrals = const [],
    this.tasks = const [],
    this.replies = const [],
    this.children = const [],
    this.childrenCount = 0,
    this.repliesCount = 0,
    this.referralsCount = 0,
    this.tasksCount = 0,
    this.attachmentsCount = 0,
    this.attachments = const [],
    this.isOverdue = false,
    this.overdueDays = 0,
    this.latestChildBody,
  });

  factory Correspondence.fromJson(Map<String, dynamic> json) {
    // استخراج رقم القيد سواء سُمي refNumber أو serialNumber
    final extractedRef = json['refNumber'] ?? json['serialNumber'] ?? '';

    // معالجة الأقسام سواء كائن أو اسم نصي
    Department? dept;
    String? deptName;
    if (json['department'] is Map) {
      dept = Department.fromJson(json['department']);
      deptName = dept.name;
    } else if (json['department'] is String) {
      deptName = json['department'];
    } else if (json['departmentName'] is String) {
      deptName = json['departmentName'];
    }

    final referralsList = (json['referrals'] as List<dynamic>?)
            ?.map((e) => ReferralItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final tasksList = (json['tasks'] as List<dynamic>?)
            ?.map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final repliesList = (json['replies'] as List<dynamic>?)
            ?.map((e) => ReplyItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final attachmentsList = (json['attachments'] as List<dynamic>?)
            ?.map((e) => AttachmentItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final childrenList = (json['children'] as List<dynamic>?)
            ?.map((e) => Correspondence.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return Correspondence(
      id: json['id'] ?? '',
      refNumber: extractedRef,
      subject: json['subject'] ?? '',
      type: json['type'] ?? 'INCOMING',
      status: json['status'] ?? 'RECEIVED',
      priority: json['priority'] ?? 'NORMAL',
      channel: json['channel'],
      body: json['body'],
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      senderPhone: json['senderPhone'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'].toString())
          : null,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      department: dept,
      departmentName: deptName,
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy']) : null,
      parentId: json['parentId'],
      parent: json['parent'] != null ? Correspondence.fromJson(json['parent']) : null,
      messageId: json['messageId'],
      sourceReplyId: json['sourceReplyId'],
      referrals: referralsList,
      tasks: tasksList,
      replies: repliesList,
      children: childrenList,
      childrenCount: json['childrenCount'] ?? json['_count']?['children'] ?? childrenList.length,
      repliesCount: json['repliesCount'] ?? json['_count']?['replies'] ?? repliesList.length,
      referralsCount: json['referralsCount'] ?? json['_count']?['referrals'] ?? referralsList.length,
      tasksCount: json['tasksCount'] ?? json['_count']?['tasks'] ?? tasksList.length,
      attachmentsCount: json['attachmentsCount'] ?? json['_count']?['attachments'] ?? attachmentsList.length,
      attachments: attachmentsList,
      isOverdue: json['isOverdue'] ?? false,
      overdueDays: json['overdueDays'] ?? 0,
      latestChildBody: json['latestChildBody'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refNumber': refNumber,
      'serialNumber': refNumber,
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
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
      if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      if (department != null) 'department': department!.toJson(),
      'departmentName': departmentName,
      'parentId': parentId,
      'isOverdue': isOverdue,
      'overdueDays': overdueDays,
    };
  }
}

/// اسم بديل لتوافق القوائم السريعة في لوحة الإدارة
typedef CorrListItem = Correspondence;
