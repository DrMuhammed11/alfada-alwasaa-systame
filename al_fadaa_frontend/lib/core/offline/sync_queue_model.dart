class SyncQueueItem {
  final String id;
  final String actionType;
  final String endpoint;
  final String httpMethod;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String entityId;
  final String entitySummary;
  int retryCount;
  String status; // PENDING, SYNCING, COMPLETED, FAILED
  String? lastError;

  SyncQueueItem({
    required this.id,
    required this.actionType,
    required this.endpoint,
    required this.httpMethod,
    this.payload = const {},
    required this.createdAt,
    required this.entityId,
    required this.entitySummary,
    this.retryCount = 0,
    this.status = 'PENDING',
    this.lastError,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] ?? '',
      actionType: json['actionType'] ?? '',
      endpoint: json['endpoint'] ?? '',
      httpMethod: json['httpMethod'] ?? 'POST',
      payload: json['payload'] is Map<String, dynamic> ? json['payload'] : {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      entityId: json['entityId'] ?? '',
      entitySummary: json['entitySummary'] ?? '',
      retryCount: json['retryCount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      lastError: json['lastError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'endpoint': endpoint,
      'httpMethod': httpMethod,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'entityId': entityId,
      'entitySummary': entitySummary,
      'retryCount': retryCount,
      'status': status,
      'lastError': lastError,
    };
  }

  SyncQueueItem copyWith({
    String? id,
    String? actionType,
    String? endpoint,
    String? httpMethod,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    String? entityId,
    String? entitySummary,
    int? retryCount,
    String? status,
    String? lastError,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      entityId: entityId ?? this.entityId,
      entitySummary: entitySummary ?? this.entitySummary,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  String get actionTitleArabic {
    switch (actionType) {
      case 'APPROVE_REPLY':
        return 'اعتماد مسودة رد';
      case 'REJECT_REPLY':
        return 'رفض مسودة رد وملاحظات';
      case 'CREATE_REPLY':
        return 'إنشاء مسودة رد جديدة';
      case 'UPDATE_REPLY':
        return 'تعديل مسودة رد';
      case 'SUBMIT_REPLY':
        return 'رفع الرد للاعتماد';
      case 'SEND_REPLY':
        return 'إرسال الرد رسمياً للعميل';
      case 'CLOSE_CORRESPONDENCE':
        return 'إغلاق المعاملة وحفظها';
      case 'ARCHIVE_CORRESPONDENCE':
        return 'أرشفة المعاملة';
      case 'UPDATE_STATUS':
        return 'تحديث حالة المعاملة';
      case 'UPDATE_TASK_STATUS':
        return 'تحديث إنجاز المهمة';
      case 'CREATE_INTERNAL':
        return 'إنشاء خطاب داخلي جديد';
      case 'CREATE_INCOMING':
        return 'تسجيل معاملة واردة';
      default:
        return actionType;
    }
  }
}
