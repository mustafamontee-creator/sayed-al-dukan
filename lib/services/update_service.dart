import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_notification_store.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.apkUrl,
  });

  final String versionName;
  final int versionCode;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String apkUrl;

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
  static const manifestUrl =
      'https://raw.githubusercontent.com/mustafamontee-creator/sayed-al-dukan/feature/pro-ui-refresh/app-update.json';

  static Future<void> checkAndNotify() async {
    try {
      final update = await check();
      if (update == null) return;
      await UpdateNotificationStore.saveAvailable(
        versionName: update.versionName,
        versionCode: update.versionCode,
        descriptionAr: update.descriptionAr,
        descriptionEn: update.descriptionEn,
      );
      // The server push is responsible for the system notification. This startup check
      // only stores the latest update as a fallback, avoiding duplicate alerts.
    } catch (_) {
      // Update checks are best-effort and must not block app startup.
    }
  }

  static Future<AppUpdateInfo?> check() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(manifestUrl));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Update manifest request failed: ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid update manifest');
      }
      final update = AppUpdateInfo.fromJson(data);
      final current = await PackageInfo.fromPlatform();
      final installedCode = int.tryParse(current.buildNumber) ?? 0;
      if (update.versionCode <= installedCode || !update.apkUrl.startsWith('https://')) {
        return null;
      }

      // Never announce an update until its release APK is actually reachable.
      final apkRequest = await client.headUrl(Uri.parse(update.apkUrl));
      final apkResponse = await apkRequest.close();
      if (apkResponse.statusCode != HttpStatus.ok) return null;
      return update;
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> checkAndShow(BuildContext context, {bool showNoUpdate = false}) async {
    AppUpdateInfo? update;
    try {
      update = await check();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Could not check for updates. Check your internet connection.'
              : 'تعذر التحقق من التحديثات. تأكد من اتصال الإنترنت وحاول مرة أخرى.',
        )),
      );
      return;
    }
    if (!context.mounted) return;
    final availableUpdate = update;
    if (availableUpdate == null) {
      if (showNoUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'You are using the latest version of Sayed Al-Dukan'
                : 'أنت تستخدم أحدث إصدار من سيد الدكان',
          )),
        );
      }
      return;
    }

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var downloading = false;
        var progress = 0.0;
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(isEnglish ? availableUpdate.titleEn : availableUpdate.titleAr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEnglish ? 'Version ${availableUpdate.versionName}' : 'الإصدار ${availableUpdate.versionName}'),
                const SizedBox(height: 9),
                Text(isEnglish ? availableUpdate.descriptionEn : availableUpdate.descriptionAr),
                if (downloading) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: progress > 0 ? progress : null),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: downloading ? null : () => Navigator.pop(dialogContext),
                child: Text(isEnglish ? 'Later' : 'لاحقاً'),
              ),
              FilledButton(
                onPressed: downloading ? null : () async {
                  if (!availableUpdate.apkUrl.startsWith('https://')) {
                    setDialogState(() => error = isEnglish
                        ? 'The update file is not published yet.'
                        : 'ملف التحديث لم يُنشر بعد.');
                    return;
                  }
                  setDialogState(() { downloading = true; error = null; });
                  File downloadedFile;
                  try {
                    downloadedFile = await _download(availableUpdate.apkUrl, (value) {
                      if (dialogContext.mounted) setDialogState(() => progress = value);
                    });
                  } catch (e) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        downloading = false;
                        error = isEnglish
                            ? 'Download failed: ${_safeError(e)}'
                            : 'فشل تنزيل ملف التحديث: ${_safeError(e)}';
                      });
                    }
                    return;
                  }

                  if (!dialogContext.mounted) return;
                  try {
                    final result = await OpenFilex.open(
                      downloadedFile.path,
                      type: 'application/vnd.android.package-archive',
                    );
                    if (!dialogContext.mounted) return;
                    setDialogState(() {
                      downloading = false;
                      if (result.type != ResultType.done) {
                        error = isEnglish
                            ? 'The update was downloaded, but Android could not open the installer: ${result.message}'
                            : 'تم تنزيل التحديث، لكن تعذر فتح شاشة التثبيت: ${result.message}';
                      }
                    });
                  } catch (e) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        downloading = false;
                        error = isEnglish
                            ? 'The update downloaded, but the installer could not be opened: ${_safeError(e)}'
                            : 'تم تنزيل التحديث، لكن تعذر فتح شاشة التثبيت: ${_safeError(e)}';
                      });
                    }
                  }
                },
                child: downloading
                    ? Text(isEnglish ? 'Downloading…' : 'جارٍ التحميل…')
                    : Text(isEnglish ? 'Update now' : 'تحديث الآن'),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _safeError(Object error) {
    final message = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return message.length > 180 ? '${message.substring(0, 180)}…' : message;
  }

  static Future<File> _download(String url, void Function(double progress) onProgress) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) throw HttpException('APK download failed: ${response.statusCode}');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/sayed-al-dukan-update.apk');
      final sink = file.openWrite();
      var received = 0;
      final total = response.contentLength;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      if (received < 1024 * 1024) {
        await file.delete();
        throw const HttpException('Downloaded APK is incomplete or too small');
      }
      if (total > 0 && received != total) {
        await file.delete();
        throw HttpException('Incomplete APK: received $received of $total bytes');
      }
      return file;
    } finally {
      client.close(force: true);
    }
  }
}
