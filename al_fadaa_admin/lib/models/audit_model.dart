class AuditLogItem {
  final String id;
  final String action;
  final String summary;
  final String? userName;
  final String? userEmail;
  final String? ipAddress;
  final DateTime createdAt;
  final Map<String, dynamic>? details;

  AuditLogItem({
    required this.id,
    required this.action,
    required this.summary,
    this.userName,
    this.userEmail,
    this.ipAddress,
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
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
      details: json['details'] is Map<String, dynamic> ? json['details'] : null,
    );
  }
}
