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
    return AuditLogItem(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      summary: json['summary'] ?? json['details']?.toString() ?? '',
      userName: user?['name'] ?? user?['fullName'] ?? 'النظام',
      userEmail: user?['email'],
      ipAddress: json['ipAddress'],
      previousHash: json['previousHash'],
      recordHash: json['recordHash'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
      details: json['details'] is Map<String, dynamic> ? json['details'] : null,
    );
  }
}

class AuditIntegrityReport {
  final bool isTamperFree;
  final int totalVerified;
  final String chainStatus;
  final String verifiedUntil;
  final String details;
  final String? brokenRecordId;

  AuditIntegrityReport({
    required this.isTamperFree,
    required this.totalVerified,
    required this.chainStatus,
    required this.verifiedUntil,
    required this.details,
    this.brokenRecordId,
  });

  factory AuditIntegrityReport.fromJson(Map<String, dynamic> json) {
    return AuditIntegrityReport(
      isTamperFree: json['isTamperFree'] ?? false,
      totalVerified: json['totalVerified'] ?? 0,
      chainStatus: json['chainStatus'] ?? 'UNKNOWN',
      verifiedUntil: json['verifiedUntil'] ?? '',
      details: json['details'] ?? '',
      brokenRecordId: json['brokenRecordId'],
    );
  }
}
