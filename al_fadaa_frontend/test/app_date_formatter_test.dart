import 'package:flutter_test/flutter_test.dart';
import 'package:al_fadaa_frontend/core/utils/app_date_formatter.dart';

void main() {
  group('AppDateFormatter Tests', () {
    test('يجب استخراج اسم اليوم والشهر بالعربية بدقة', () {
      // 2026-09-12 هو السبت
      final date = DateTime(2026, 9, 12, 15, 30);
      expect(AppDateFormatter.getWeekdayName(date), 'السبت');
      expect(AppDateFormatter.getMonthName(date), 'سبتمبر');
    });

    test('يجب تنسيق الوقت بنظام 12 ساعة مع الإشارة الصريحة لصباحاً ومساءً', () {
      final morning = DateTime(2026, 9, 12, 3, 37);
      expect(AppDateFormatter.formatTimeShort(morning), '03:37 ص');
      expect(AppDateFormatter.formatTimeLong(morning), '03:37 صباحاً');

      final afternoon = DateTime(2026, 9, 12, 15, 5);
      expect(AppDateFormatter.formatTimeShort(afternoon), '03:05 م');
      expect(AppDateFormatter.formatTimeLong(afternoon), '03:05 مساءً');

      final midnight = DateTime(2026, 9, 12, 0, 0);
      expect(AppDateFormatter.formatTimeShort(midnight), '12:00 ص');

      final noon = DateTime(2026, 9, 12, 12, 0);
      expect(AppDateFormatter.formatTimeShort(noon), '12:00 م');
    });

    test('يجب أن يوضح التاريخ الكامل اسم اليوم واليوم والشهر والسنة والوقت صباحاً/مساءً', () {
      final date = DateTime(2026, 9, 7, 3, 37);
      final formatted = AppDateFormatter.formatFullDateTime(date);
      expect(formatted.contains('سبتمبر'), isTrue);
      expect(formatted.contains('صباحاً'), isTrue);
      expect(formatted.contains('03:37'), isTrue);
    });

    test('يجب أن تحتوي ترويسة الوصول على عبارة وصلت لصندوق البريد', () {
      final date = DateTime(2026, 9, 7, 3, 37);
      final arrival = AppDateFormatter.formatDetailedArrival(date);
      expect(arrival.startsWith('وصلت لصندوق البريد:'), isTrue);
      expect(arrival.contains('03:37'), isTrue);
    });
  });
}
