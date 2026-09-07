import 'package:flutter/material.dart';
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
  final String? correspondenceId;
  final String? correspondenceRef;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.doneAt,
    this.assignedTo,
    this.correspondenceId,
    this.correspondenceRef,
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
      correspondenceId: json['correspondenceId'] ?? json['correspondence']?['id'],
      correspondenceRef: json['correspondenceRef'] ?? json['correspondence']?['refNumber'],
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
      'correspondenceId': correspondenceId,
      'correspondenceRef': correspondenceRef,
    };
  }

  // ─── مؤشرات وحسابات مهلة الإنجاز SLA ───

  bool get isDone => status == 'DONE';

  bool get isCancelled => status == 'CANCELLED';

  bool get isOverdue {
    if (isDone || isCancelled || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isApproachingDeadline {
    if (isDone || isCancelled || dueDate == null || isOverdue) return false;
    final diff = dueDate!.difference(DateTime.now());
    return diff.inHours <= 24 && diff.inHours >= 0;
  }

  String get slaLabel {
    if (isDone) return 'منجزة ✅';
    if (isCancelled) return 'ملغاة ❌';
    if (dueDate == null) return 'بدون مهلة محددة';

    final now = DateTime.now();
    if (isOverdue) {
      final diff = now.difference(dueDate!);
      if (diff.inDays > 0) {
        return 'متأخرة منذ ${diff.inDays} يوم ⚠️';
      } else if (diff.inHours > 0) {
        return 'متأخرة منذ ${diff.inHours} ساعة ⚠️';
      } else {
        return 'متأخرة عن المهلة ⚠️';
      }
    }

    final diff = dueDate!.difference(now);
    if (diff.inDays > 1) {
      return 'ضمن المهلة (متبقي ${diff.inDays} يوم) 🟢';
    } else if (diff.inDays == 1) {
      return 'ضمن المهلة (متبقي يوم واحد) 🟢';
    } else if (diff.inHours > 0) {
      return 'أوشكت على الانتهاء (متبقي ${diff.inHours} ساعة) ⏳';
    } else {
      final minutes = diff.inMinutes > 0 ? diff.inMinutes : 1;
      return 'أوشكت على الانتهاء (متبقي $minutes دقيقة) ⏳';
    }
  }

  Color get slaColor {
    if (isDone) return const Color(0xFF16A34A);
    if (isCancelled) return const Color(0xFF64748B);
    if (dueDate == null) return const Color(0xFF64748B);
    if (isOverdue) return const Color(0xFFDC2626);
    if (isApproachingDeadline) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  Color get slaBgColor {
    return slaColor.withAlpha(25);
  }

  IconData get slaIcon {
    if (isDone) return Icons.check_circle_rounded;
    if (isCancelled) return Icons.cancel_outlined;
    if (dueDate == null) return Icons.schedule_rounded;
    if (isOverdue) return Icons.warning_amber_rounded;
    if (isApproachingDeadline) return Icons.hourglass_top_rounded;
    return Icons.timer_outlined;
  }
}
