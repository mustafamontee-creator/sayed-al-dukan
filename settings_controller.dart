import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._p)
      : lang = _p.getString('lang') ?? 'ar',
        region = _p.getString('region') ?? 'EG';
  final SharedPreferences _p;
  String lang;
  String region;

  Locale get locale => Locale(lang);

  Future<void> setLang(String l) async {
    lang = l;
    await _p.setString('lang', l);
    notifyListeners();
  }
}
