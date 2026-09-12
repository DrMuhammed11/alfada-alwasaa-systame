/// منسق التواريخ والأوقات العربي الدقيق لنظام الفضاء الواسع
/// يعرض اليوم والساعة والدقيقة وصباحاً/مساءً بشكل صريح دون أي صيغ نسبية مبهمة
class AppDateFormatter {
  static const List<String> _weekdaysArabic = [
    'الاثنين', // 1
    'الثلاثاء', // 2
    'الأربعاء', // 3
    'الخميس',  // 4
    'الجمعة',  // 5
    'السبت',   // 6
    'الأحد',   // 7
  ];

  static const List<String> _monthsArabic = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// الحصول على اسم اليوم بالعربية (الأحد، الاثنين، ...)
  static String getWeekdayName(DateTime date) {
    final local = date.toLocal();
    final idx = local.weekday - 1;
    if (idx >= 0 && idx < _weekdaysArabic.length) {
      return _weekdaysArabic[idx];
    }
    return '';
  }

  /// الحصول على اسم الشهر بالعربية (يناير، فبراير، ...)
  static String getMonthName(DateTime date) {
    final local = date.toLocal();
    final idx = local.month - 1;
    if (idx >= 0 && idx < _monthsArabic.length) {
      return _monthsArabic[idx];
    }
    return '';
  }

  /// تنسيق الوقت بنظام 12 ساعة مدمج: "03:37 ص" أو "08:15 م"
  static String formatTimeShort(DateTime date) {
    final local = date.toLocal();
    int hour12 = local.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'ص' : 'م';
    return '$hourStr:$minuteStr $period';
  }

  /// تنسيق الوقت بنظام 12 ساعة كامل: "03:37 صباحاً" أو "08:15 مساءً"
  static String formatTimeLong(DateTime date) {
    final local = date.toLocal();
    int hour12 = local.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'صباحاً' : 'مساءً';
    return '$hourStr:$minuteStr $period';
  }

  /// تنسيق القوائم المختصرة (Master List Item):
  /// - اليوم: "اليوم 03:01 م"
  /// - أمس: "أمس (الجمعة) 10:20 ص"
  /// - قبل يومين أو أكثر هذا العام: "الأحد 07/09 03:37 ص"
  /// - سنوات سابقة: "07/09/2025 03:37 ص"
  static String formatListDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(targetDay).inDays;
    final timeStr = formatTimeShort(local);

    if (diffDays == 0) {
      return 'اليوم $timeStr';
    } else if (diffDays == 1) {
      return 'أمس (${getWeekdayName(local)}) $timeStr';
    } else if (diffDays > 1 && diffDays < 7) {
      final dayName = getWeekdayName(local);
      final dayPad = local.day.toString().padLeft(2, '0');
      final monthPad = local.month.toString().padLeft(2, '0');
      return '$dayName $dayPad/$monthPad $timeStr';
    } else if (local.year == now.year) {
      final dayName = getWeekdayName(local);
      final dayPad = local.day.toString().padLeft(2, '0');
      final monthPad = local.month.toString().padLeft(2, '0');
      return '$dayName $dayPad/$monthPad $timeStr';
    } else {
      final dayPad = local.day.toString().padLeft(2, '0');
      final monthPad = local.month.toString().padLeft(2, '0');
      return '$dayPad/$monthPad/${local.year} $timeStr';
    }
  }

  /// تنسيق مفصل وشامل لبطاقة الرسالة (Message Card):
  /// - اليوم: "اليوم — الساعة 03:01 مساءً"
  /// - أمس: "أمس (الجمعة) — الساعة 10:20 صباحاً"
  /// - تاريخ أقدم: "الأحد، 7 سبتمبر 2026 — الساعة 03:37 صباحاً"
  static String formatFullDateTime(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(targetDay).inDays;
    final timeStr = formatTimeLong(local);

    if (diffDays == 0) {
      return 'اليوم — الساعة $timeStr';
    } else if (diffDays == 1) {
      return 'أمس (${getWeekdayName(local)}) — الساعة $timeStr';
    } else {
      final dayName = getWeekdayName(local);
      final monthName = getMonthName(local);
      return '$dayName، ${local.day} $monthName ${local.year} — الساعة $timeStr';
    }
  }

  /// تنسيق مميز لترويسة المحادثة العلوية يوضح وقت الوصول لصندوق البريد بدقة
  static String formatDetailedArrival(DateTime date) {
    return 'وصلت لصندوق البريد: ${formatFullDateTime(date)}';
  }
}
