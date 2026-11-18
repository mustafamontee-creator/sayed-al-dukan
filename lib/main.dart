import 'dart:io';

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
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/repo.dart';
import 'services/settings_controller.dart';
import 'services/update_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isAndroid) {
    await Firebase.initializeApp();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  }
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  final repo = Repo(prefs);
  final cart = CartService(prefs)..repo = repo;
  await cart.load();
  final auth = AuthService()..onSignedIn = cart.mergeFromServer;
  auth.init();

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
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.subscribeToTopic('app_updates');

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data['type'] == 'app_update') {
        final context = SayedApp.navigatorKey.currentContext;
        if (context != null) {
          await UpdateService.checkAndShow(context);
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (message.data['type'] == 'app_update') {
        final context = SayedApp.navigatorKey.currentContext;
        if (context != null) {
          await UpdateService.checkAndShow(context);
        }
      }
    });
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage?.data['type'] == 'app_update') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = SayedApp.navigatorKey.currentContext;
        if (context != null) UpdateService.checkAndShow(context);
      });
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
      home: const SplashScreen(),
    );
  }
}
