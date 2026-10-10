import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// نظام الهوية البصرية والتصميم الموحد لشركة الفضاء الواسع
/// مستخرج ومطابق 100% لموقع الويب والسيرفر الرسمي (Next.js & NestJS)
class BrandTheme {
  // ─── 1. الألوان المؤسسية الرسمية (Brand Colors) ───
  static const Color navyPrimary   = Color(0xFF0A3453); // الكحلي المؤسسي الرئيسي
  static const Color navyDeep      = Color(0xFF072A44); // كحلي عميق
  static const Color navyDarker    = Color(0xFF051E31); // كحلي غامق
  static const Color goldAccent    = Color(0xFFC6954A); // الذهبي الرسمي
  static const Color goldLight     = Color(0xFFDCB26B); // ذهبي فاتح
  static const Color goldSoft      = Color(0xFFF3E5CF); // ذهبي ناعم للأسطح
  static const Color mist          = Color(0xFFF2F6F9); // خلفية الصفحات الرسمية
  static const Color cardSurface   = Colors.white;       // أسطح البطاقات
  static const Color borderLight   = Color(0xFFE2E8F0); // حدود البطاقات والعناصر
  static const Color borderSubtle  = Color(0xFFCBD5E1); // حدود بارزة

  // ─── نصوص متوافقة مع معايير التباين WCAG AA ───
  static const Color textDark      = Color(0xFF051E31); // النص الرئيسي
  static const Color textHeading   = Color(0xFF0A3453); // نصوص العناوين
  static const Color textMuted     = Color(0xFF475569); // نصوص ثانوية
  static const Color textTertiary  = Color(0xFF64748B); // نصوص فرعية وتواريخ
  static const Color textOnPrimary = Colors.white;

  // ─── الألوان الدلالية وحالات المعاملات (Semantic Status Colors) ───
  static const Color emerald       = Color(0xFF059669); // نجاح / منجز
  static const Color surfaceSuccess= Color(0xFFECFDF5);
  static const Color borderSuccess = Color(0xFFA7F3D0);

  static const Color amber         = Color(0xFFD97706); // تحذير / قيد المعالجة
  static const Color surfaceWarning= Color(0xFFFFFBEB);
  static const Color borderWarning = Color(0xFFFDE68A);

  static const Color crimson       = Color(0xFFDC2626); // عاجل / متأخر / ملغي
  static const Color surfaceDanger = Color(0xFFFEF2F2);
  static const Color borderDanger  = Color(0xFFFECACA);

  static const Color sky           = Color(0xFF0284C7); // معلومات / وارد جديد
  static const Color surfaceInfo   = Color(0xFFE0F2FE);
  static const Color borderInfo    = Color(0xFFBAE6FD);

  static const Color purple        = Color(0xFF7C3AED); // إحالات / مهام خاصة
  static const Color surfacePurple = Color(0xFFF5F3FF);
  static const Color borderPurple  = Color(0xFFDDD6FE);

  // ─── التدرجات اللونية الفاخرة (Brand Gradients) ───
  static const LinearGradient headerGradient = LinearGradient(
    colors: [navyPrimary, navyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardSubtleGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFBFD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── الظلال الموحدة (Consistent Shadows) ───
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: navyPrimary.withAlpha(10),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: navyPrimary.withAlpha(20),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get dialogShadow => [
    BoxShadow(
      color: navyDarker.withAlpha(50),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  // ─── مقاييس المسافات والحواف (Metrics & Radii) ───
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // ─── توليد ثيم التطبيق الكامل مع خط Cairo ───
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: navyPrimary,
      scaffoldBackgroundColor: mist,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: navyPrimary,
        onPrimary: Colors.white,
        secondary: goldAccent,
        onSecondary: Colors.white,
        surface: cardSurface,
        onSurface: textDark,
        error: crimson,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navyPrimary,
          side: const BorderSide(color: borderSubtle, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: goldAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: crimson),
        ),
        labelStyle: GoogleFonts.cairo(color: textMuted, fontSize: 13),
        hintStyle: GoogleFonts.cairo(color: textTertiary, fontSize: 13),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textHeading),
        titleMedium: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: textHeading),
        bodyLarge: GoogleFonts.cairo(fontSize: 14, color: textDark),
        bodyMedium: GoogleFonts.cairo(fontSize: 13, color: textMuted),
        bodySmall: GoogleFonts.cairo(fontSize: 11, color: textTertiary),
      ),
    );
  }
}
