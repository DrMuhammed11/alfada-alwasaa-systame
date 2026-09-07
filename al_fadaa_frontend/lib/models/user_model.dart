class Department {
  final String id;
  final String name;
  final String code;
  final String? managerName;
  final int usersCount;
  final int correspondencesCount;

  Department({
    required this.id,
    required this.name,
    required this.code,
    this.managerName,
    this.usersCount = 0,
    this.correspondencesCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
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
      'managerName': managerName,
      'usersCount': usersCount,
      'correspondencesCount': correspondencesCount,
    };
  }
}

class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? employeeNumber;
  final Department? department;
  final bool isActive;

  String get name => fullName;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.employeeNumber,
    this.department,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['name'] ?? json['fullName'] ?? json['email'] ?? '',
      role: json['role'] ?? 'EMPLOYEE',
      employeeNumber: json['employeeNumber'],
      department: json['department'] != null ? Department.fromJson(json['department']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'employeeNumber': employeeNumber,
      'department': department?.toJson(),
      'isActive': isActive,
    };
  }
}
