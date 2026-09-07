import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Design System: Swiss Modernism 2.0 (Dense / Dashboard) ───
  static const Color primary = Color(0xFF0F172A);        // Navy — Primary
  static const Color onPrimary = Color(0xFFFFFFFF);       // White on primary
  static const Color secondary = Color(0xFF334155);       // Slate — Secondary
  static const Color accent = Color(0xFF0369A1);          // Corporate Blue — CTA / Accent
  static const Color emerald = Color(0xFF10B981);         // Success
  static const Color amber = Color(0xFFF59E0B);           // Warning
  static const Color crimson = Color(0xFFDC2626);         // Destructive / Urgent
  static const Color purple = Color(0xFF8B5CF6);          // Referral / Special

  static const Color backgroundLight = Color(0xFFF8FAFC); // Page background
  static const Color cardLight = Colors.white;             // Card surface
  static const Color borderLight = Color(0xFFE2E8F0);     // Border
  static const Color muted = Color(0xFFE8ECF1);           // Muted background
  static const Color textDark = Color(0xFF020617);         // Foreground text
  static const Color textMuted = Color(0xFF64748B);        // Secondary text
  static const Color ring = Color(0xFF0F172A);             // Focus ring

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.notoSansArabicTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        surface: cardLight,
        error: crimson,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansArabic(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.notoSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        labelStyle: GoogleFonts.notoSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStateProperty.all(
          const Color(0xFF94A3B8).withAlpha(120),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Priority color helper
  static Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return crimson;
      case 'HIGH':
        return amber;
      case 'NORMAL':
        return accent;
      case 'LOW':
        return textMuted;
      default:
        return textMuted;
    }
  }

  // Status color helper
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return const Color(0xFF3B82F6);
      case 'UNDER_REVIEW':
        return amber;
      case 'REFERRED':
        return purple;
      case 'IN_PROGRESS':
        return accent;
      case 'PENDING_APPROVAL':
        return const Color(0xFFF97316);
      case 'APPROVED':
        return emerald;
      case 'SENT':
        return const Color(0xFF06B6D4);
      case 'CLOSED':
        return const Color(0xFF475569);
      case 'ARCHIVED':
        return textMuted;
      default:
        return textMuted;
    }
  }
}
