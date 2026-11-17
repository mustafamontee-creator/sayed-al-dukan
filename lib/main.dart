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
}

class SayedApp extends StatelessWidget {
  const SayedApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سيد الدكان',
      locale: s.locale, // Arabic => RTL, English => LTR automatically
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
