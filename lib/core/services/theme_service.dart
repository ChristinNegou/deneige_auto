import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Theme clair ou sombre de l'application, choisi dans les parametres.
/// Le choix est garde sur l'appareil et applique des le lancement.
class ThemeService extends ChangeNotifier {
  static const String _darkKey = 'app_dark_theme';

  bool _dark = false;

  bool get isDark => _dark;

  /// Charge le choix enregistre (clair par defaut).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apply(prefs.getBool(_darkKey) ?? false);
  }

  /// Change de theme, l'enregistre et previent l'app pour qu'elle se redessine.
  Future<void> setDark(bool dark) async {
    if (_dark == dark) return;
    _apply(dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, dark);
  }

  void _apply(bool dark) {
    _dark = dark;
    AppTheme.usePalette(dark ? AppPalette.dark : AppPalette.light);
    notifyListeners();
  }
}
