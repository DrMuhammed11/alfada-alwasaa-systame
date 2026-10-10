import 'package:flutter/material.dart';
import 'package:al_fadaa_core/al_fadaa_core.dart';
import '../theme/app_theme.dart';

/// شارة حالة موحّدة تعتمد على StatusPill من al_fadaa_core
class AppStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const AppStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  /// شارة بلون حالة مراسلة
  factory AppStatusPill.status(String status, {String? label}) {
    final color = AppTheme.getStatusColor(status);
    return AppStatusPill(label: label ?? status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: label,
      color: color,
      filled: filled,
    );
  }
}
