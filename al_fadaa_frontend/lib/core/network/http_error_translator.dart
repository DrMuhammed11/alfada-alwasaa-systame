import 'dart:convert';

/// مترجم موحد لأخطاء HTTP والواجهة الخلفية إلى رسائل عربية واضحة ومفهومة للمستخدم
class HttpErrorTranslator {
  /// استخراج نص الخطأ العربي من جسم الاستجابة أو رمز الحالة
  static String extractErrorMessage(
    dynamic body, [
    String fallback = 'حدث خطأ في الخادم',
    int? statusCode,
  ]) {
    if (statusCode == 401) {
      return 'انتهت الجلسة، يرجى تسجيل الدخول مجددًا';
    }
    if (statusCode == 403) {
      return 'ليس لديك الصلاحية الكافية لتنفيذ هذا الإجراء';
    }
    if (statusCode == 404) {
      return 'العنصر المطلوب غير موجود أو تم حذفه';
    }
    if (statusCode == 503) {
      return 'الخدمة غير متوفرة حالياً، يرجى المحاولة بعد قليل';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'حدث خطأ داخلي في الخادم، يرجى مراجعة إدارة النظام';
    }

    if (body == null) return fallback;

    try {
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is Map) {
        if (decoded['statusCode'] == 401 || decoded['message'] == 'Unauthorized') {
          return 'انتهت الجلسة، يرجى تسجيل الدخول مجددًا';
        }
        final msg = decoded['message'];
        if (msg is List) {
          return msg.map((m) => m.toString()).join('، ');
        } else if (msg is String && msg.trim().isNotEmpty) {
          return msg.trim();
        }
        final err = decoded['error'];
        if (err is String && err.trim().isNotEmpty) return err.trim();
      }
    } catch (_) {}

    return fallback;
  }
}
