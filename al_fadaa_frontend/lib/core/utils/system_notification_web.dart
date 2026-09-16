// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> requestNotificationPermissionImpl() async {
  try {
    if (!html.Notification.supported) return false;
    if (html.Notification.permission == 'granted') return true;
    if (html.Notification.permission == 'denied') return false;

    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  } catch (_) {
    return false;
  }
}

void showSystemNotificationImpl({
  required String title,
  required String body,
  String? payload,
}) {
  try {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;

    final notif = html.Notification(
      title,
      body: body,
      icon: '/favicon.png',
    );

    notif.onClick.listen((_) {
      try {
        notif.close();
      } catch (_) {}
    });
  } catch (_) {}
}
