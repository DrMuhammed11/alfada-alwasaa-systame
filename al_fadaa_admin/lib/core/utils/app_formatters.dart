import 'package:intl/intl.dart';

/// أدوات التنسيق والترجمة العربية الموحّدة
/// يُستخدم عبر جميع الشاشات بدلاً من تكرار DateFormat و switch في كل مكان
class AppFormatters {
  AppFormatters._();

  // صيغ التاريخ والوقت العربية
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
  static final _dateOnlyFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final _timeOnlyFormat = DateFormat('HH:mm', 'ar');
  static final _shortDateFormat = DateFormat('MM/dd', 'ar');
  static final _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// تنسيق التاريخ والوقت معاً
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());

  /// تنسيق التاريخ فقط
  static String dateOnly(DateTime dt) => _dateOnlyFormat.format(dt.toLocal());

  /// تنسيق الوقت فقط
  static String timeOnly(DateTime dt) => _timeOnlyFormat.format(dt.toLocal());

  /// تنسيق مختصر (يوم/شهر)
  static String shortDate(DateTime dt) => _shortDateFormat.format(dt.toLocal());

  /// تنسيق للإرسال للـ API
  static String apiDate(DateTime dt) => _apiDateFormat.format(dt);

  /// تنسيق نسبة مئوية
  static String percentage(double value, {int decimals = 0}) =>
      '${value.toStringAsFixed(decimals)}%';

  /// حجم الملف
  static String fileSize(num bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} ميغ';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} ك.بايت';
    return '$bytes بايت';
  }

  /// الأولوية بالعربية
  static String priorityLabel(String priority) => switch (priority.toUpperCase()) {
        'URGENT' => 'عاجل جداً',
        'HIGH' => 'أولوية عالية',
        'NORMAL' => 'اعتيادية',
        'LOW' => 'منخفضة',
        _ => priority,
      };

  /// لون الأولوية
  static String priorityColor(String priority) => switch (priority.toUpperCase()) {
        'URGENT' => 'crimson',
        'HIGH' => 'amber',
        'NORMAL' => 'accent',
        _ => 'muted',
      };

  /// حالة المراسلة بالعربية
  static String correspondenceStatus(String status) => switch (status.toUpperCase()) {
        'PENDING' => 'معلّقة',
        'IN_PROGRESS' => 'قيد المعالجة',
        'AWAITING_APPROVAL' => 'بانتظار الاعتماد',
        'APPROVED' => 'معتمدة',
        'REJECTED' => 'مرفوضة',
        'CLOSED' => 'مغلقة',
        'ARCHIVED' => 'مؤرشفة',
        _ => status,
      };

  /// نوع المراسلة بالعربية
  static String correspondenceType(String type) => switch (type.toUpperCase()) {
        'INCOMING' => 'وارد',
        'OUTGOING' => 'صادر',
        'INTERNAL' => 'داخلي',
        _ => type,
      };

  /// حالة البريد الصادر بالعربية
  static String outboxStatus(String status) => switch (status.toUpperCase()) {
        'SENT' => 'أُرسلت',
        'QUEUED' => 'بانتظار الإرسال',
        'PAUSED' => 'موقوفة',
        'FAILED' => 'فاشلة',
        _ => status,
      };

  /// الدور الوظيفي المختصر
  static String roleShort(String role) => switch (role.toUpperCase()) {
        'ADMIN' => 'مشرف',
        'GM' => 'م.عام',
        'DEPUTY_GM' => 'نائب م.ع',
        'DEPT_MANAGER' => 'مدير قسم',
        'EMPLOYEE' => 'موظف',
        _ => role,
      };

  /// تقصير UUID للعرض
  static String shortUuid(String uuid) =>
      uuid.length > 8 ? uuid.substring(0, 8).toUpperCase() : uuid.toUpperCase();

  /// تقصير hash التشفير للعرض
  static String shortHash(String hash) =>
      hash.length > 12 ? '${hash.substring(0, 12)}...' : hash;
}
