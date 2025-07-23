import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, swahili, french }

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get locale => _getLocale();

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageIndex = prefs.getInt(_languageKey) ?? 0;
    _currentLanguage = AppLanguage.values[languageIndex];
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, language.index);

    notifyListeners();
  }

  Locale _getLocale() {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return const Locale('en', 'US');
      case AppLanguage.swahili:
        return const Locale('sw', 'KE');
      case AppLanguage.french:
        return const Locale('fr', 'FR');
    }
  }

  String getLanguageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.swahili:
        return 'Swahili';
      case AppLanguage.french:
        return 'French';
    }
  }

  String getLanguageNativeName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.swahili:
        return 'Kiswahili';
      case AppLanguage.french:
        return 'Français';
    }
  }
}