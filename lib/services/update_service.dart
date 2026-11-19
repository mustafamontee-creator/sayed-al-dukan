import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_notification_store.dart';

class AppUpdateInfo {
  const AppUpdateInfo({required this.versionName, required this.versionCode, required this.titleAr, required this.titleEn, required this.descriptionAr, required this.descriptionEn, required this.apkUrl});
  final String versionName, titleAr, titleEn, descriptionAr, descriptionEn, apkUrl;
  final int versionCode;
  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
    versionName: json['version_name'] as String? ?? '',
    versionCode: (json['version_code'] as num?)?.toInt() ?? 0,
    titleAr: json['title_ar'] as String? ?? 'يتوفر تحديث جديد لسيد الدكان',
    titleEn: json['title_en'] as String? ?? 'A new Sayed Al-Dukan update is available',
    descriptionAr: json['description_ar'] as String? ?? '',
    descriptionEn: json['description_en'] as String? ?? '',
    apkUrl: json['apk_url'] as String? ?? '',
  );
}

class UpdateService {
  static const manifestUrl = 'https://raw.githubusercontent.com/mustafamontee-creator/sayed-al-dukan/feature/pro-ui-refresh/app-update.json';
  static const _installer = MethodChannel('sayed_al_dukan/apk_installer');

  static Future<void> checkAndNotify() async {
    try {
      final update = await check();
      if (update == null) return;
      await UpdateNotificationStore.saveAvailable(versionName: update.versionName, versionCode: update.versionCode, descriptionAr: update.descriptionAr, descriptionEn: update.descriptionEn);
    } catch (_) {}
  }

  static Future<AppUpdateInfo?> check() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(manifestUrl));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) throw HttpException('Manifest HTTP ${response.statusCode}');
      final data = jsonDecode(await response.transform(utf8.decoder).join());
      if (data is! Map<String, dynamic>) throw const FormatException('Invalid update manifest');
      final update = AppUpdateInfo.fromJson(data);
      final current = await PackageInfo.fromPlatform();
      final installedCode = int.tryParse(current.buildNumber) ?? 0;
      if (update.versionCode <= installedCode || !update.apkUrl.startsWith('https://')) return null;
      return update;
    } finally {
      client.close(force: true);
    }
  }

  static Future<File> _download(AppUpdateInfo update, void Function(double) progress) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sayed-dukan-update-${update.versionCode}.apk');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final request = await client.getUrl(Uri.parse(update.apkUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'SayedAlDukanUpdater');
      final response = await request.close().timeout(const Duration(seconds: 40));
      if (response.statusCode != HttpStatus.ok) throw HttpException('Download HTTP ${response.statusCode}');
      final total = response.contentLength;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.timeout(const Duration(seconds: 60))) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) progress(received / total);
        }
        await sink.flush();
      } finally { await sink.close(); }
      if (await file.length() < 1024 * 1024) throw const FormatException('Downloaded file is too small');
      final raf = await file.open();
      final magic = await raf.read(4);
      await raf.close();
      if (magic.length != 4 || magic[0] != 0x50 || magic[1] != 0x4b) throw const FormatException('Downloaded file is not a valid APK');
      return file;
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    } finally { client.close(force: true); }
  }

  static Future<void> checkAndShow(BuildContext context, {bool showNoUpdate = false}) async {
    AppUpdateInfo? update;
    try { update = await check(); } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Could not check for updates. Check your internet connection.' : 'تعذر التحقق من التحديثات. تأكد من اتصال الإنترنت وحاول مرة أخرى.')));
      return;
    }
    if (!context.mounted) return;
    final available = update;
    if (available == null) {
      if (showNoUpdate) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'You are using the latest version of Sayed Al-Dukan' : 'أنت تستخدم أحدث إصدار من سيد الدكان')));
      return;
    }
    final en = Localizations.localeOf(context).languageCode == 'en';
    await showDialog<void>(context: context, builder: (dialogContext) {
      var downloading = false; double progress = 0; String? error;
      return StatefulBuilder(builder: (dialogContext, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(en ? available.titleEn : available.titleAr),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(en ? 'Version ${available.versionName}' : 'الإصدار ${available.versionName}'),
          const SizedBox(height: 9), Text(en ? available.descriptionEn : available.descriptionAr),
          if (downloading) ...[const SizedBox(height: 14), LinearProgressIndicator(value: progress > 0 ? progress : null), const SizedBox(height: 6), Text('${(progress * 100).round()}%')],
          if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: Colors.red))],
        ]),
        actions: [
          TextButton(onPressed: downloading ? null : () => Navigator.pop(dialogContext), child: Text(en ? 'Later' : 'لاحقاً')),
          FilledButton(onPressed: downloading ? null : () async {
            setState(() { downloading = true; error = null; progress = 0; });
            try {
              final file = await _download(available, (p) { if (dialogContext.mounted) setState(() => progress = p); });
              await _installer.invokeMethod<bool>('installApk', {'path': file.path});
              if (dialogContext.mounted) setState(() { downloading = false; });
            } catch (e) {
              if (dialogContext.mounted) setState(() { downloading = false; error = en ? 'Update installation could not be started. ${e.toString()}' : 'تعذر بدء تثبيت التحديث. ${e.toString()}'; });
            }
          }, child: Text(downloading ? (en ? 'Downloading…' : 'جارٍ التحميل…') : (en ? 'Update now' : 'تحديث الآن'))),
        ],
      ));
    });
  }
}
