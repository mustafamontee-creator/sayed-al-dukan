import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/app_notification_service.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/repo.dart';
import 'services/settings_controller.dart';
import 'services/update_notification_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isAndroid) {
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp();
    await AppNotificationService.initialize(onUpdateTap: () async {}, handleLaunchDetails: false);
    final isNew = await _saveUpdateMessage(message);
    if (isNew) {
      await AppNotificationService.showUpdate(
        body: (message.data['description_ar'] ?? '').toString(),
      );
    }
  }
}

Future<bool> _saveUpdateMessage(RemoteMessage message) async {
  if (message.data['type'] != 'app_update') return false;
  try {
    return await UpdateNotificationStore.save(
      versionName: (message.data['version_name'] ?? '').toString(),
      versionCode: int.tryParse((message.data['version_code'] ?? '').toString()) ?? 0,
      descriptionAr: (message.data['description_ar'] ?? '').toString(),
      descriptionEn: (message.data['description_en'] ?? '').toString(),
    );
  } catch (error) {
    debugPrint('Could not save update notification: $error');
    return false;
  }
}

Future<void> _openNotifications() async {
  final navigator = SayedApp.navigatorKey.currentState;
  if (navigator == null) {
    UpdateNotificationStore.pendingOpenNotifications = true;
    return;
  }
  await UpdateNotificationStore.markRead();
  navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  }
  final prefs = await SharedPreferences.getInstance();
  await UpdateNotificationStore.refreshUnread();
  final settings = SettingsController(prefs);
  final repo = Repo(prefs);
  final cart = CartService(prefs)..repo = repo;
  await cart.load();
  final auth = AuthService()..onSignedIn = cart.mergeFromServer;
  auth.init();

  await AppNotificationService.initialize(onUpdateTap: _openNotifications);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: auth),
      Provider.value(value: repo),
    ],
    child: const SayedApp(),
  ));

  // FCM is enabled for Android only. No Analytics SDK is added.
  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.subscribeToTopic('app_updates');

      FirebaseMessaging.onMessage.listen((message) async {
        final isNew = await _saveUpdateMessage(message);
        if (isNew) {
          await AppNotificationService.showUpdate(
            body: (message.data['description_ar'] ?? '').toString(),
          );
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        if (message.data['type'] == 'app_update') {
          await _saveUpdateMessage(message);
          await _openNotifications();
        }
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage?.data['type'] == 'app_update') {
        await _saveUpdateMessage(initialMessage!);
        UpdateNotificationStore.pendingOpenNotifications = true;
      }
    } catch (error) {
      // Push setup is optional; it must never prevent the app from opening.
      debugPrint('Push notification setup failed: $error');
    }
  }
}

class SayedApp extends StatelessWidget {
  const SayedApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'سيد الدكان',
      locale: s.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(s.lang),
      darkTheme: buildDarkTheme(s.lang),
      themeMode: s.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
