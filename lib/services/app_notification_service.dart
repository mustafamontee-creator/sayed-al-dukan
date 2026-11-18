import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({required Future<void> Function() onUpdateTap}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'app_update') {
          onUpdateTap();
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'app_updates',
      'تحديثات سيد الدكان',
      description: 'إشعارات توفر تحديثات جديدة للتطبيق',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showUpdate({
    String? title,
    String? body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'app_updates',
        'تحديثات سيد الدكان',
        channelDescription: 'إشعارات توفر تحديثات جديدة للتطبيق',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      1401,
      title?.trim().isNotEmpty == true
          ? title
          : 'يتوفر تحديث جديد لسيد الدكان',
      body?.trim().isNotEmpty == true
          ? body
          : 'اضغط هنا لمعرفة تفاصيل التحديث',
      details,
      payload: 'app_update',
    );
  }
}
