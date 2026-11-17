import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(context.t('notifications')),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none, size: 54, color: AppColors.black),
              const SizedBox(height: 14),
              Text(
                context.t('noNotifications'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
