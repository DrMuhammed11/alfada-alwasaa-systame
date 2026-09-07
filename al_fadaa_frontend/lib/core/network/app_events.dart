import 'dart:async';

/// ناقل أحداث مركزي بسيط يربط بين الشبكة والشاشات المختلفة دون تعقيد
class AppEvents {
  static final AppEvents _instance = AppEvents._internal();
  factory AppEvents() => _instance;
  AppEvents._internal();

  final _sessionExpiredController = StreamController<String>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _refreshBellController = StreamController<void>.broadcast();
  final _refreshCorrespondencesController = StreamController<void>.broadcast();

  bool isSseConnected = false;

  /// بث إشعار انتهاء الجلسة (401 متتالي)
  Stream<String> get onSessionExpired => _sessionExpiredController.stream;
  void triggerSessionExpired(String message) {
    _sessionExpiredController.add(message);
  }

  /// بث وصول إشعار حي من SSE
  Stream<Map<String, dynamic>> get onNotificationReceived => _notificationController.stream;
  void emitNotification(Map<String, dynamic> data) {
    _notificationController.add(data);
  }

  /// طلب إعادة جلب بيانات الجرس
  Stream<void> get onRefreshBell => _refreshBellController.stream;
  void triggerBellRefresh() {
    _refreshBellController.add(null);
  }

  /// طلب تحديث قائمة المراسلات
  Stream<void> get onRefreshCorrespondences => _refreshCorrespondencesController.stream;
  void triggerCorrespondencesRefresh() {
    _refreshCorrespondencesController.add(null);
  }
}
