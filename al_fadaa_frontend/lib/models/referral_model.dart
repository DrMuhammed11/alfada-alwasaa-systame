import 'user_model.dart';

class ReferralItem {
  final String id;
  final String actionType;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final User? fromUser;
  final User? toUser;
  final Department? toDepartment;

  ReferralItem({
    required this.id,
    required this.actionType,
    this.notes,
    required this.status,
    required this.createdAt,
    this.fromUser,
    this.toUser,
    this.toDepartment,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] ?? '',
      actionType: json['actionType'] ?? 'للاطلاع',
      notes: json['notes'] ?? json['note'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      fromUser: json['fromUser'] != null ? User.fromJson(json['fromUser']) : (json['from'] != null ? User.fromJson(json['from']) : null),
      toUser: json['toUser'] != null ? User.fromJson(json['toUser']) : (json['to'] != null ? User.fromJson(json['to']) : null),
      toDepartment: json['toDepartment'] != null ? Department.fromJson(json['toDepartment']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
