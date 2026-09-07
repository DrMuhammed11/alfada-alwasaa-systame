class Department {
  final String id;
  final String name;
  final String code;

  Department({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
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
