import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._p)
      : lang = _p.getString('lang') ?? 'ar',
        region = _p.getString('region') ?? 'EG',
        isDarkMode = _p.getBool('dark_mode') ?? false;
  final SharedPreferences _p;
  String lang;
  String region;
  bool isDarkMode;

  Locale get locale => Locale(lang);

  Future<void> setLang(String l) async {
    lang = l;
    await _p.setString('lang', l);
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    isDarkMode = enabled;
    await _p.setBool('dark_mode', enabled);
    notifyListeners();
  }
}
