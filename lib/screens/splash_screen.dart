import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../services/update_service.dart';
import '../services/update_notification_store.dart';
import 'notifications_screen.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _continueToApp();
    });
  }

  Future<void> _continueToApp() async {
    await UpdateService.checkAndNotify();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const Shell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    if (UpdateNotificationStore.pendingOpenNotifications) {
      UpdateNotificationStore.pendingOpenNotifications = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/logo.jpeg',
                width: MediaQuery.of(context).size.width * 0.78),
            const SizedBox(height: 16),
            Text(context.t('welcome'),
                style: const TextStyle(
                    color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
