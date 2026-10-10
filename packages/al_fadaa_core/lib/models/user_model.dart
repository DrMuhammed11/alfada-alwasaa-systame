import 'department_model.dart';

/// نموذج المستخدم الموحد لتطبيقات الفضاء الواسع
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? employeeNumber;
  final String? departmentId;
  final Department? department;
  final bool isActive;
  final List<String> permissions;
  final DateTime? createdAt;

  // توفير name للتوافق مع كود الإدارة
  String get name => fullName;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.employeeNumber,
    this.departmentId,
    this.department,
    this.isActive = true,
    this.permissions = const [],
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      role: json['role'] ?? 'EMPLOYEE',
      employeeNumber: json['employeeNumber'],
      departmentId: json['departmentId'] ?? json['department']?['id'],
      department: json['department'] != null ? Department.fromJson(json['department']) : null,
      isActive: json['isActive'] ?? true,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'name': fullName,
      'role': role,
      'employeeNumber': employeeNumber,
      'departmentId': departmentId,
      'department': department?.toJson(),
      'isActive': isActive,
      'permissions': permissions,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? employeeNumber,
    String? departmentId,
    Department? department,
    bool? isActive,
    List<String>? permissions,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// اسم بديل لتوافق تطبيق الإدارة القديم
typedef AdminUser = User;
