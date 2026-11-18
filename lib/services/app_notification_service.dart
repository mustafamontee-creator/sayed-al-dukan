import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  AppNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    required Future<void> Function() onUpdateTap,
    bool handleLaunchDetails = true,
  }) async {
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

    if (handleLaunchDetails) {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true &&
          launch?.notificationResponse?.payload == 'app_update') {
        await onUpdateTap();
      }
    }
  }

  static Future<void> showUpdate({
    String? body,
  }) async {
    final detailsText = body?.trim().isNotEmpty == true
        ? body!.trim()
        : 'توجد تحسينات وإصلاحات جديدة. افتح صفحة الإشعارات داخل التطبيق لمعرفة التفاصيل.';
    const notificationTitle = 'متوفر تحديث جديد';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'app_updates',
        'تحديثات سيد الدكان',
        channelDescription: 'إشعارات توفر تحديثات جديدة للتطبيق',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          detailsText,
          contentTitle: notificationTitle,
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      1401,
      notificationTitle,
      null,
      details,
      payload: 'app_update',
    );
  }
}
