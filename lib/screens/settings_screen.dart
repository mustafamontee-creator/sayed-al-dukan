import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/strings.dart';
import '../services/auth_service.dart';
import '../services/settings_controller.dart';
import '../services/update_service.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'غير متاح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final auth = context.watch<AuthService>();
    Widget region(String label, bool enabled) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          trailing: enabled
              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
              : Text(context.t('soon')),
        );
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(context.t('language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).colorScheme.primary,
          value: 'ar',
          groupValue: s.lang,
          onChanged: (v) => s.setLang(v!),
          title: Text(context.t('arabic')),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).colorScheme.primary,
          value: 'en',
          groupValue: s.lang,
          onChanged: (v) => s.setLang(v!),
          title: Text(context.t('english')),
        ),
        const Divider(),
        const SizedBox(height: 12),
        Text(context.t('region'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        region(context.t('egypt'), true),
        region(context.t('saudi'), false),
        region(context.t('sudan'), false),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(s.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
          title: Text(s.lang == 'en' ? 'Dark mode' : 'الوضع الداكن'),
          subtitle: Text(s.lang == 'en'
              ? (s.isDarkMode ? 'Enabled' : 'Disabled')
              : (s.isDarkMode ? 'مفعّل' : 'غير مفعّل')),
          trailing: Switch.adaptive(
            value: s.isDarkMode,
            onChanged: s.setDarkMode,
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.refresh_rounded, color: Color(0xFF238653)),
          title: Text(context.t('checkUpdates')),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => UpdateService.checkAndShow(context, showNoUpdate: true),
        ),
        const Divider(),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.support_agent, color: Theme.of(context).colorScheme.onSurface),
          title: Text(s.lang == 'en' ? 'Technical Support' : 'الدعم الفني'),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupportScreen()),
          ),
        ),
        const Divider(),
        const SizedBox(height: 12),
        if (auth.loggedIn)
          OutlinedButton(
            onPressed: () => auth.signOut(),
            child: Text(context.t('logout')),
          ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            s.lang == 'en'
                ? 'Version $_appVersion ($_buildNumber)'
                : 'الإصدار $_appVersion ($_buildNumber)',
            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ]),
    );
  }
}
