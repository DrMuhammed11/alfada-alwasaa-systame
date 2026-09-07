import 'user_model.dart';

class ReferralItem {
  final String id;
  final String? note;
  final String status;
  final DateTime createdAt;
  final User? fromUser;
  final User? toUser;
  final DateTime? dueDate;
  final DateTime? answeredAt;

  ReferralItem({
    required this.id,
    this.note,
    this.status = 'OPEN',
    required this.createdAt,
    this.fromUser,
    this.toUser,
    this.dueDate,
    this.answeredAt,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] ?? '',
      note: json['note'] as String?,
      status: json['status'] ?? 'OPEN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      fromUser: json['fromUser'] != null
          ? User.fromJson(json['fromUser'])
          : null,
      toUser: json['toUser'] != null
          ? User.fromJson(json['toUser'])
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (note != null) 'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (answeredAt != null) 'answeredAt': answeredAt!.toIso8601String(),
    };
  }
}
