import 'user_model.dart';

class TaskItem {
  final String id;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? doneAt;
  final User? assignedTo;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.doneAt,
    this.assignedTo,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      doneAt: json['doneAt'] != null ? DateTime.parse(json['doneAt']) : null,
      assignedTo: json['assignedTo'] != null ? User.fromJson(json['assignedTo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
