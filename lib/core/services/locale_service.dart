import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gerer la locale de l'application
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('fr', 'FR');

  Locale get locale => _locale;

  /// Charge la locale sauvegardee
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// Change la locale et la sauvegarde
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}
