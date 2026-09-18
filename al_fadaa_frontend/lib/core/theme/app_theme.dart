import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Design System: Swiss Modernism 2.0 (WCAG AA Compliant) ───
  static const Color primary = Color(0xFF0F172A);        // Navy — Primary
  static const Color onPrimary = Color(0xFFFFFFFF);       // White on primary
  static const Color secondary = Color(0xFF334155);       // Slate — Secondary
  static const Color accent = Color(0xFF0369A1);          // Corporate Blue — CTA / Accent
  static const Color emerald = Color(0xFF10B981);         // Success
  static const Color amber = Color(0xFFB45309);           // Warning — أغمق لتحقيق التباين
  static const Color crimson = Color(0xFFDC2626);         // Destructive / Urgent
  static const Color purple = Color(0xFF8B5CF6);          // Referral / Special

  static const Color backgroundLight = Color(0xFFF8FAFC); // Page background
  static const Color cardLight = Colors.white;             // Card surface
  static const Color borderLight = Color(0xFFE2E8F0);     // Border
  static const Color muted = Color(0xFFE8ECF1);           // Muted background

  // ✅ تباين AA: 7.4:1 على backgroundLight
  static const Color textDark = Color(0xFF020617);         // Foreground text
  static const Color textMuted = Color(0xFF475569);        // ✅ رفعنا من #64748B إلى #475569 (7.4:1)
  static const Color textTertiary = Color(0xFF64748B);      // ✅ جديد — للنصوص الثانوية فقط على خلفيات فاتحة

  // ✅ تباين AA: 4.6:1 على أبيض
  static const Color textOnLight = Color(0xFF64748B);      // للـ timestamps (سابقاً #94A3B8)

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
          textOnLight.withAlpha(120),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
      extensions: const [
        AppElevation.light,
        AppSpacing(),
        AppTextScale(),
      ],
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

  // Referral status color helper
  static Color getReferralStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFF7C3AED);
      case 'ANSWERED':
        return const Color(0xFF0284C7);
      case 'CLOSED':
        return textMuted;
      default:
        return textMuted;
    }
  }
}

// ─── Elevation Tokens (نظام ظلال موحّد) ───
class AppElevation extends ThemeExtension<AppElevation> {
  final List<BoxShadow> e1; // subtle (cards, inputs focus)
  final List<BoxShadow> e2; // raised (popovers, dropdowns)
  final List<BoxShadow> e3; // floating (dialogs, banners)
  final List<BoxShadow> e4; // modal (modals, sheets)

  const AppElevation({
    required this.e1,
    required this.e2,
    required this.e3,
    required this.e4,
  });

  static const AppElevation light = AppElevation(
    e1: [
      BoxShadow(
        color: Color(0x0A000000), // 4% opacity
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    e2: [
      BoxShadow(
        color: Color(0x14000000), // 8% opacity
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    e3: [
      BoxShadow(
        color: Color(0x1F000000), // 12% opacity
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    e4: [
      BoxShadow(
        color: Color(0x29000000), // 16% opacity
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  @override
  AppElevation copyWith({
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
    List<BoxShadow>? e4,
  }) {
    return AppElevation(
      e1: e1 ?? this.e1,
      e2: e2 ?? this.e2,
      e3: e3 ?? this.e3,
      e4: e4 ?? this.e4,
    );
  }

  @override
  AppElevation lerp(ThemeExtension<AppElevation>? other, double t) {
    if (other is! AppElevation) return this;
    return this;
  }
}

// ─── Spacing Scale (نظام مسافات موحّد) ───
class AppSpacing extends ThemeExtension<AppSpacing> {
  final double xs;  // 4
  final double sm;  // 8
  final double md;  // 12
  final double lg;  // 16
  final double xl;  // 24
  final double xxl; // 32
  final double xxxl; // 48

  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.xxxl = 48,
  });

  @override
  AppSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl, double? xxl, double? xxxl}) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) => this;
}

// ─── Type Scale (نظام أحجام خطوط موحّد) ───
class AppTextScale extends ThemeExtension<AppTextScale> {
  final double xs;   // 11
  final double sm;   // 12
  final double base; // 13
  final double lg;   // 15
  final double xl;   // 18
  final double xxl;  // 22
  final double xxxl; // 28

  const AppTextScale({
    this.xs = 11,
    this.sm = 12,
    this.base = 13,
    this.lg = 15,
    this.xl = 18,
    this.xxl = 22,
    this.xxxl = 28,
  });

  @override
  AppTextScale copyWith({double? xs, double? sm, double? base, double? lg, double? xl, double? xxl, double? xxxl}) {
    return AppTextScale(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      base: base ?? this.base,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  AppTextScale lerp(ThemeExtension<AppTextScale>? other, double t) => this;
}
