// نماذج المراسلات للوحة الإدارة — مطابقة لمخرجات وحدة correspondences في الخادم

class CorrListItem {
  final String id;
  final String refNumber;
  final String type; // INCOMING / OUTGOING / INTERNAL
  final String subject;
  final String priority; // LOW / NORMAL / HIGH / URGENT
  final String status; // RECEIVED / ... / ARCHIVED
  final String? senderName;
  final String? departmentName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOverdue;
  final int overdueDays;
  final int referralsCount;
  final int tasksCount;
  final int repliesCount;
  final int attachmentsCount;
  final String? latestChildBody;

  CorrListItem({
    required this.id,
    required this.refNumber,
    required this.type,
    required this.subject,
    required this.priority,
    required this.status,
    this.senderName,
    this.departmentName,
    required this.createdAt,
    required this.updatedAt,
    this.isOverdue = false,
    this.overdueDays = 0,
    this.referralsCount = 0,
    this.tasksCount = 0,
    this.repliesCount = 0,
    this.attachmentsCount = 0,
    this.latestChildBody,
  });

  factory CorrListItem.fromJson(Map<String, dynamic> json) {
    return CorrListItem(
      id: json['id'] ?? '',
      refNumber: json['refNumber'] ?? '',
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      priority: json['priority'] ?? 'NORMAL',
      status: json['status'] ?? '',
      senderName: json['senderName'],
      departmentName: json['department']?['name'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isOverdue: json['isOverdue'] == true,
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
      referralsCount: json['_count']?['referrals'] ?? 0,
      tasksCount: json['_count']?['tasks'] ?? 0,
      repliesCount: json['_count']?['replies'] ?? 0,
      attachmentsCount: json['_count']?['attachments'] ?? 0,
      latestChildBody: (json['children'] as List?)?.isNotEmpty == true
          ? (json['children'].first['body']?.toString())
          : null,
    );
  }
}

class CorrPersonBrief {
  final String name;
  CorrPersonBrief({required this.name});
  factory CorrPersonBrief.fromJson(dynamic json) =>
      CorrPersonBrief(name: json is Map ? (json['name'] ?? '') : '');
}

class CorrReferral {
  final String id;
  final String? note;
  final String status;
  final DateTime? dueDate;
  final String fromName;
  final String toName;
  CorrReferral({
    required this.id,
    this.note,
    required this.status,
    this.dueDate,
    required this.fromName,
    required this.toName,
  });

  factory CorrReferral.fromJson(Map<String, dynamic> json) => CorrReferral(
        id: json['id'] ?? '',
        note: json['note'],
        status: json['status'] ?? 'OPEN',
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
        fromName: json['fromUser']?['name'] ?? '-',
        toName: json['toUser']?['name'] ?? '-',
      );
}

class CorrTask {
  final String id;
  final String title;
  final String status;
  final DateTime? dueDate;
  final String assignedToName;
  final String assignedByName;
  CorrTask({
    required this.id,
    required this.title,
    required this.status,
    this.dueDate,
    required this.assignedToName,
    required this.assignedByName,
  });

  factory CorrTask.fromJson(Map<String, dynamic> json) => CorrTask(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        status: json['status'] ?? 'PENDING',
        dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
        assignedToName: json['assignedTo']?['name'] ?? '-',
        assignedByName: json['assignedBy']?['name'] ?? '-',
      );
}

class CorrReply {
  final String id;
  final String body;
  final String status;
  final String authorName;
  final DateTime createdAt;
  CorrReply({
    required this.id,
    required this.body,
    required this.status,
    required this.authorName,
    required this.createdAt,
  });

  factory CorrReply.fromJson(Map<String, dynamic> json) => CorrReply(
        id: json['id'] ?? '',
        body: json['body'] ?? '',
        status: json['status'] ?? 'DRAFT',
        authorName: json['author']?['name'] ?? '-',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class CorrAttachment {
  final String id;
  final String fileName;
  final String mimeType;
  final int size;
  CorrAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.size,
  });

  factory CorrAttachment.fromJson(Map<String, dynamic> json) => CorrAttachment(
        id: json['id'] ?? '',
        fileName: json['fileName'] ?? '',
        mimeType: json['mimeType'] ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

class CorrDetail {
  final String id;
  final String refNumber;
  final String type;
  final String subject;
  final String? body;
  final String priority;
  final String status;
  final String? senderName;
  final String? senderEmail;
  final String? senderPhone;
  final String? channel;
  final String? departmentName;
  final String? createdByName;
  final DateTime? receivedAt;
  final DateTime? sentAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final List<CorrReferral> referrals;
  final List<CorrTask> tasks;
  final List<CorrReply> replies;
  final List<CorrAttachment> attachments;

  CorrDetail({
    required this.id,
    required this.refNumber,
    required this.type,
    required this.subject,
    this.body,
    required this.priority,
    required this.status,
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    this.channel,
    this.departmentName,
    this.createdByName,
    this.receivedAt,
    this.sentAt,
    this.closedAt,
    required this.createdAt,
    required this.referrals,
    required this.tasks,
    required this.replies,
    required this.attachments,
  });

  factory CorrDetail.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) from) =>
        raw is List ? raw.map((e) => from(Map<String, dynamic>.from(e))).toList() : [];

    return CorrDetail(
      id: json['id'] ?? '',
      refNumber: json['refNumber'] ?? '',
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'],
      priority: json['priority'] ?? 'NORMAL',
      status: json['status'] ?? '',
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      senderPhone: json['senderPhone'],
      channel: json['channel'],
      departmentName: json['department']?['name'],
      createdByName: json['createdBy']?['name'],
      receivedAt: json['receivedAt'] != null ? DateTime.tryParse(json['receivedAt']) : null,
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.tryParse(json['closedAt']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      referrals: parseList(json['referrals'], CorrReferral.fromJson),
      tasks: parseList(json['tasks'], CorrTask.fromJson),
      replies: parseList(json['replies'], CorrReply.fromJson),
      attachments: parseList(json['attachments'], CorrAttachment.fromJson),
    );
  }
}

// ─── تسميات عربية للقيم المعيارية ───

String corrTypeLabel(String v) => switch (v) {
      'INCOMING' => 'وارد',
      'OUTGOING' => 'صادر',
      'INTERNAL' => 'داخلي',
      _ => v,
    };

String corrStatusLabel(String v) => switch (v) {
      'RECEIVED' => 'مستلمة',
      'UNDER_REVIEW' => 'قيد الدراسة',
      'REFERRED' => 'محالة',
      'IN_PROGRESS' => 'جاري إعداد الرد',
      'PENDING_APPROVAL' => 'بانتظار الاعتماد',
      'APPROVED' => 'معتمدة',
      'SENT' => 'أُرسلت للعميل',
      'CLOSED' => 'مغلقة',
      'ARCHIVED' => 'مؤرشفة',
      _ => v,
    };

String priorityLabel(String v) => switch (v) {
      'LOW' => 'منخفضة',
      'NORMAL' => 'اعتيادية',
      'HIGH' => 'عالية',
      'URGENT' => 'عاجلة للغاية',
      _ => v,
    };

String taskStatusLabel(String v) => switch (v) {
      'PENDING' => 'جديد',
      'IN_PROGRESS' => 'جاري التنفيذ',
      'SUBMITTED' => 'تم التسليم',
      'DONE' => 'منجز',
      'CANCELLED' => 'ملغى',
      _ => v,
    };

String referralStatusLabel(String v) => switch (v) {
      'OPEN' => 'قيد المعالجة',
      'ANSWERED' => 'تم الرد عليها',
      'CLOSED' => 'مغلقة',
      _ => v,
    };

String replyStatusLabel(String v) => switch (v) {
      'DRAFT' => 'مسودة',
      'SUBMITTED' => 'مرفوعة للاعتماد',
      'APPROVED' => 'معتمدة',
      'REJECTED' => 'مرفوضة',
      _ => v,
    };
