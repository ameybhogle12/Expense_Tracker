import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'themeMode';
  final Box _settingsBox = Hive.box('settings_v1');

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void loadTheme() {
    final String? themeString = _settingsBox.get(_themeKey);
    if (themeString != null) {
      _themeMode = _parseThemeMode(themeString);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _settingsBox.put(_themeKey, mode.name);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String themeName) {
    return ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.system,
    );
  }
}
