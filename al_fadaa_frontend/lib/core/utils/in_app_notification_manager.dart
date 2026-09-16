import 'dart:async';
import 'package:flutter/material.dart';
import '../network/app_events.dart';
import '../../views/notifications/in_app_notification_banner.dart';
import 'system_notification_service.dart';

/// مدير التنبيهات المنبثقة التفاعلية (In-App Notification Manager)
/// يستمع لأحداث البث الحي SSE ويعرض الشريط العائم في أعلى أي شاشة نشطة،
/// بالإضافة لإطلاق إشعار النظام/المتصفح عند الحاجة.
class InAppNotificationManager {
  static final InAppNotificationManager _instance = InAppNotificationManager._internal();
  factory InAppNotificationManager() => _instance;
  InAppNotificationManager._internal();

  StreamSubscription<Map<String, dynamic>>? _subscription;
  OverlayEntry? _currentOverlay;
  Function(String entityId)? onNotificationAction;

  /// بدء الاستماع لأحداث الإشعارات اللحظية
  void init({
    required GlobalKey<NavigatorState> navigatorKey,
    Function(String entityId)? onAction,
  }) {
    onNotificationAction = onAction;
    _subscription?.cancel();

    _subscription = AppEvents().onNotificationReceived.listen((data) {
      _handleIncomingNotification(navigatorKey, data);
    });
  }

  void _handleIncomingNotification(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] as String? ?? 'إشعار جديد في نظام المراسلات';
    final body = data['body'] as String? ?? '';
    final entityId = data['entityId'] as String?;

    // 1. إطلاق إشعار المتصفح / النظام لتنبيه الموظف حتى لو كان التطبيق في الخلفية
    SystemNotificationService().showNotification(
      title: title,
      body: body,
      payload: entityId,
    );

    // 2. إظهار الشريط العائم أعلى الشاشة الحالية
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    dismissCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: InAppNotificationBanner(
              notification: data,
              onDismiss: () {
                if (_currentOverlay == entry) {
                  dismissCurrent();
                }
              },
              onTap: (targetEntityId) {
                dismissCurrent();
                if (onNotificationAction != null) {
                  onNotificationAction!(targetEntityId);
                }
              },
            ),
          ),
        ),
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  /// إخفاء الشريط الحالي
  void dismissCurrent() {
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay?.remove();
    }
    _currentOverlay = null;
  }

  /// إيقاف الاستماع وتنظيف الموارد
  void dispose() {
    dismissCurrent();
    _subscription?.cancel();
    _subscription = null;
  }
}
