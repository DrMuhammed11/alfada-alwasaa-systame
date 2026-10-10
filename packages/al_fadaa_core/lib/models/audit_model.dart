/// نموذج سجل التدقيق الموحد (Audit Log) متوافق مع نظام التدقيق المشفر في الخادم
class AuditLogItem {
  final String id;
  final String action;
  final String summary;
  final String? userName;
  final String? userEmail;
  final String? ipAddress;
  final String? previousHash;
  final String? recordHash;
  final DateTime createdAt;
  final Map<String, dynamic>? details;

  AuditLogItem({
    required this.id,
    required this.action,
    required this.summary,
    this.userName,
    this.userEmail,
    this.ipAddress,
    this.previousHash,
    this.recordHash,
    required this.createdAt,
    this.details,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final rawDetails = json['metadata'] ?? json['details'];
    return AuditLogItem(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      summary: json['summary'] ?? rawDetails?.toString() ?? '',
      userName: user?['name'] ?? user?['fullName'] ?? 'النظام',
      userEmail: user?['email'],
      ipAddress: json['ipAddress'],
      previousHash: json['previousHash'],
      recordHash: json['recordHash'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      details: rawDetails is Map<String, dynamic> ? rawDetails : null,
    );
  }
}

class AuditIntegrityReport {
  final bool isTamperFree;
  final int totalVerified;
  final int totalRecords;
  final String chainStatus;
  final String verifiedUntil;
  final String details;
  final String? brokenRecordId;

  AuditIntegrityReport({
    required this.isTamperFree,
    required this.totalVerified,
    this.totalRecords = 0,
    required this.chainStatus,
    required this.verifiedUntil,
    required this.details,
    this.brokenRecordId,
  });

  factory AuditIntegrityReport.fromJson(Map<String, dynamic> json) {
    return AuditIntegrityReport(
      isTamperFree: json['isTamperFree'] ?? false,
      totalVerified: json['totalVerified'] ?? 0,
      totalRecords: json['totalRecords'] ?? 0,
      chainStatus: json['chainStatus'] ?? 'UNKNOWN',
      verifiedUntil: json['verifiedUntil'] ?? '',
      details: json['details'] ?? '',
      brokenRecordId: json['brokenRecordId'],
    );
  }
}

class AuditLogsPage {
  final List<AuditLogItem> items;
  final int page;
  final int totalPages;
  final int total;
  final bool error;

  AuditLogsPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.error = false,
  });
}
