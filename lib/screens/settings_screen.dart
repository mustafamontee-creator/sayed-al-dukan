import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/strings.dart';
import '../core/format.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../services/settings_controller.dart';
import '../services/update_service.dart';
import 'support_screen.dart';
import '../ui/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _loadedFor;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'غير متاح');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await context.read<Repo>().profile();
      if (!mounted || p == null) return;
      _name.text = (p['full_name'] ?? '') as String;
      _phone.text = (p['contact_phone'] ?? '') as String;
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<Repo>().updateProfile(
          name: _name.text.trim(), contactPhone: _phone.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('saved'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final auth = context.watch<AuthService>();
    if (auth.loggedIn && _loadedFor != auth.user!.id) {
      _loadedFor = auth.user!.id;
      _loadProfile();
    }
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
        const Line(),
        const SizedBox(height: 12),
        if (auth.loggedIn) ...[
          Text(context.t('accountInfo'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (auth.email != null) Text('${context.t('email')}: ${maskEmail(auth.email)}'),
          if (auth.phone != null)
            Text('${context.t('phone')}: ${maskPhone(auth.phone)}', textDirection: TextDirection.ltr),
          const SizedBox(height: 10),
          TextField(controller: _name, decoration: InputDecoration(labelText: context.t('name'))),
          const SizedBox(height: 10),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: context.t('contactPhone'))),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _saveProfile, child: Text(context.t('save'))),
          const SizedBox(height: 12),
          const Line(),
          const SizedBox(height: 12),
        ],
        Text(context.t('region'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        region(context.t('egypt'), true),
        region(context.t('saudi'), false),
        region(context.t('sudan'), false),
        const Line(),
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
        const Line(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.refresh_rounded, color: Color(0xFF238653)),
          title: Text(context.t('checkUpdates')),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => UpdateService.checkAndShow(context, showNoUpdate: true),
        ),
        const Line(),
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
        const Line(),
        const SizedBox(height: 12),
        if (auth.loggedIn)
          OutlinedButton(
            onPressed: () => auth.signOut(),
            child: Text(context.t('logout')),
          ),
        const SizedBox(height: 14),
        Center(
          child: Text(s.lang == 'en' ? 'Version $_appVersion' : 'الإصدار $_appVersion', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
