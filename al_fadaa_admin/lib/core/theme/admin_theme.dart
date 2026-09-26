import 'package:flutter/material.dart';

/// نظام الثيم الموحد للوحة إدارة الفضاء الواسع
/// يدعم: الوضع الفاتح + تدرجات لونية + مؤقتات الرسوم + ظلال موحدة
class AdminTheme {
  static const String fontFamily = 'Noto Sans Arabic';

  // ─── الألوان الأساسية ───
  static const Color primary      = Color(0xFF0F172A);
  static const Color primaryDark  = Color(0xFF0B1120);
  static const Color slate        = Color(0xFF1E293B);
  static const Color accent       = Color(0xFF0284C7);
  static const Color accentLight  = Color(0xFF38BDF8);
  static const Color emerald      = Color(0xFF10B981);
  static const Color amber        = Color(0xFFF59E0B);
  static const Color crimson      = Color(0xFFEF4444);
  static const Color purple       = Color(0xFF8B5CF6);
  static const Color bgLight      = Color(0xFFF8FAFC);
  static const Color cardBg       = Colors.white;
  static const Color border       = Color(0xFFE2E8F0);
  static const Color borderDark   = Color(0xFF334155);
  static const Color textMain     = Color(0xFF0F172A);
  static const Color textMuted    = Color(0xFF64748B);
  static const Color textLight    = Color(0xFF94A3B8);
  static const Color surface2     = Color(0xFFF1F5F9);

  // ─── التدرجات اللونية ───
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── الظلال الموحدة ───
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withAlpha(8),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withAlpha(15),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: accent.withAlpha(40),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── مؤقتات الرسوم المتحركة ───
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow   = Duration(milliseconds: 450);

  // ─── نصف قطر الزوايا ───
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
          fontFamily: fontFamily,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgLight,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: cardBg,
        error: crimson,
        onSurface: textMain,
        outline: border,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.black.withAlpha(40),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: crimson),
        ),
        hintStyle: const TextStyle(color: textLight, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 11, fontFamily: fontFamily),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        side: const BorderSide(color: border),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: slate,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: fontFamily, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        elevation: 8,
        titleTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: textMain),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: slate,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: fontFamily),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 12),
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surface2),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFFF8FAFC);
          return Colors.white;
        }),
        headingTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: textMain,
        ),
        dataTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12, color: textMain),
        horizontalMargin: 14,
        columnSpacing: 20,
        dividerThickness: 1,
      ),
    );
  }
}
