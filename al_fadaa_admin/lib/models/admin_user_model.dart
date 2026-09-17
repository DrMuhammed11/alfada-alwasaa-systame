class Department {
  final String id;
  final String name;
  final String code;
  final String? managerId;
  final String? managerName;
  final int usersCount;
  final int correspondencesCount;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.managerId,
    this.managerName,
    this.usersCount = 0,
    this.correspondencesCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      managerId: json['managerId'],
      managerName: json['manager']?['name'],
      usersCount: json['_count']?['users'] ?? 0,
      correspondencesCount: json['_count']?['correspondences'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (managerId != null) 'managerId': managerId,
    };
  }
}

class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? departmentId;
  final Department? department;
  final List<String> permissions;
  final DateTime? createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.departmentId,
    this.department,
    this.permissions = const [],
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] is List) {
      perms = (json['permissions'] as List).map((p) => p.toString()).toList();
    }

    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'EMPLOYEE',
      isActive: json['isActive'] ?? true,
      departmentId: json['departmentId'],
      department: json['department'] != null ? Department.fromJson(json['department']) : null,
      permissions: perms,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'departmentId': departmentId,
      'permissions': permissions,
    };
  }

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isGM => role.toUpperCase() == 'GM';
  bool get hasAdminPrivilege => isAdmin || isGM;
}
