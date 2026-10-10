import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';

final DateFormat opDateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

Color opStatusColor(String s) => switch (s) {
      'SENT'   => AdminTheme.emerald,
      'QUEUED' => AdminTheme.amber,
      'PAUSED' => AdminTheme.purple,
      'FAILED' => AdminTheme.crimson,
      _        => AdminTheme.textMuted,
    };

String opStatusLabel(String s) => switch (s) {
      'SENT'   => 'أُرسلت',
      'QUEUED' => 'بانتظار الإرسال',
      'PAUSED' => 'موقوفة',
      'FAILED' => 'فاشلة نهائيًا',
      _        => s,
    };
