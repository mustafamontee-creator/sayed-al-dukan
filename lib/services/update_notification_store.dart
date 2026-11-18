import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateNotificationStore {
  UpdateNotificationStore._();

  static const _updateKey = 'latest_update_notification';
  static const _lastAnnouncedKey = 'last_announced_update_version_code';
  static const _unreadKey = 'has_unread_update_notification';
  static final ValueNotifier<bool> unread = ValueNotifier<bool>(false);
  static bool pendingOpenNotifications = false;

  static Future<void> refreshUnread() async {
    final prefs = await SharedPreferences.getInstance();
    unread.value = prefs.getBool(_unreadKey) ?? false;
  }

  // Save update details discovered by the startup manifest check without
  // consuming the one-time FCM announcement for this version.
  static Future<bool> saveAvailable({
    required String versionName,
    required int versionCode,
    required String descriptionAr,
    required String descriptionEn,
  }) async {
    if (versionName.isEmpty || versionCode < 1) return false;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_updateKey);
    var storedVersion = 0;
    if (raw != null && raw.isNotEmpty) {
      try {
        final value = jsonDecode(raw);
        if (value is Map) {
          storedVersion = (value['version_code'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}
    }
    if (versionCode <= storedVersion) return false;
    await _persist(
      prefs,
      versionName: versionName,
      versionCode: versionCode,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
    );
    return true;
  }

  // FCM uses this method. It returns true only for the first push received
  // for a version, so the system notification is displayed once.
  static Future<bool> save({
    required String versionName,
    required int versionCode,
    required String descriptionAr,
    required String descriptionEn,
  }) async {
    if (versionName.isEmpty || versionCode < 1) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastAnnouncedKey) ?? 0;
    if (versionCode <= last) return false;

    await _persist(
      prefs,
      versionName: versionName,
      versionCode: versionCode,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
    );
    await prefs.setInt(_lastAnnouncedKey, versionCode);
    return true;
  }

  static Future<void> _persist(
    SharedPreferences prefs, {
    required String versionName,
    required int versionCode,
    required String descriptionAr,
    required String descriptionEn,
  }) async {
    final item = <String, dynamic>{
      'version_name': versionName,
      'version_code': versionCode,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'created_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_updateKey, jsonEncode(item));
    await prefs.setBool(_unreadKey, true);
    unread.value = true;
  }

  static Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_updateKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) return value;
    } catch (_) {}
    return null;
  }

  static Future<bool> hasUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_unreadKey) ?? false;
    unread.value = value;
    return value;
  }

  static Future<void> markRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unreadKey, false);
    unread.value = false;
  }
}
