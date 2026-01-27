import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gerer la locale de l'application
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const List<String> _supportedLanguages = ['fr', 'en'];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Charge la locale sauvegardee, ou detecte la langue du systeme au premier lancement
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);

    if (savedCode != null) {
      _locale = Locale(savedCode);
    } else {
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      final systemLang = systemLocale.languageCode;
      _locale = _supportedLanguages.contains(systemLang)
          ? Locale(systemLang)
          : const Locale('en');
    }
    notifyListeners();
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
