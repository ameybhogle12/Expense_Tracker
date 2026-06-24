import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final box = Hive.box('settings_v1');
    final languageCode = box.get('languageCode');
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      _locale = null; // Follow system default
      final box = Hive.box('settings_v1');
      await box.delete('languageCode');
    } else {
      _locale = locale;
      final box = Hive.box('settings_v1');
      await box.put('languageCode', locale.languageCode);
    }
    notifyListeners();
  }
}
