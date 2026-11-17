import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://www.instagram.com/msvux/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.support_agent, size: 48),
            const SizedBox(height: 12),
            const Text('محتاج مساعدة؟', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('لو واجهتك مشكلة في التطبيق أو عندك استفسار بخصوص طلبك، تواصل مع المطوّر عبر حساب إنستغرام التالي.'),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openInstagram,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('@msvux'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const Spacer(),
            const Center(child: Text('سيد الدكان', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue))),
          ]),
        ),
      ),
    );
  }
}
