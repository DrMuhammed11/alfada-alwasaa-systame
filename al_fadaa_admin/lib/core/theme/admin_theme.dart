import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // الألوان الأساسية للوحة التحكم الإدارية
  static const Color primary = Color(0xFF0F172A); // Deep Navy
  static const Color primaryDark = Color(0xFF0B1120);
  static const Color slate = Color(0xFF1E293B);
  static const Color accent = Color(0xFF0284C7); // Cobalt Blue
  static const Color emerald = Color(0xFF10B981); // Positive / Success
  static const Color amber = Color(0xFFF59E0B); // Warning / SLA
  static const Color crimson = Color(0xFFEF4444); // Danger / Overdue
  static const Color purple = Color(0xFF8B5CF6); // Permissions / Roles
  static const Color bgLight = Color(0xFFF8FAFC); // Clean dashboard background
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.notoSansArabicTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        surface: cardBg,
        error: crimson,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansArabic(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }
}
