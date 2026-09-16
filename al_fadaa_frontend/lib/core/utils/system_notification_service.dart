import 'system_notification_stub.dart'
    if (dart.library.html) 'system_notification_web.dart'
    if (dart.library.io) 'system_notification_io.dart';

/// خدمة إشعارات النظام الموحدة (System / Desktop Notifications)
/// تتيح إرسال تنبيهات سطح المكتب والمتصفح للموظف حتى عند تصغير نافذة التطبيق.
class SystemNotificationService {
  static final SystemNotificationService _instance = SystemNotificationService._internal();
  factory SystemNotificationService() => _instance;
  SystemNotificationService._internal();

  bool _hasRequested = false;

  /// طلب إذن إرسال الإشعارات من المستخدم
  Future<bool> requestPermission() async {
    if (_hasRequested) return true;
    _hasRequested = true;
    return await requestNotificationPermissionImpl();
  }

  /// إظهار إشعار على مستوى النظام / المتصفح
  void showNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    showSystemNotificationImpl(
      title: title,
      body: body,
      payload: payload,
    );
  }
}
