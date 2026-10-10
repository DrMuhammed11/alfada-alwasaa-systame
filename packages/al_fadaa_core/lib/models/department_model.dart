/// نموذج القسم الموحد
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
      managerName: json['manager']?['name'] ?? json['managerName'],
      usersCount: json['_count']?['users'] ?? json['usersCount'] ?? 0,
      correspondencesCount: json['_count']?['correspondences'] ?? json['correspondencesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      if (managerId != null) 'managerId': managerId,
      if (managerName != null) 'managerName': managerName,
      'usersCount': usersCount,
      'correspondencesCount': correspondencesCount,
    };
  }
}
