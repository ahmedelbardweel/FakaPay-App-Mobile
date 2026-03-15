import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('ar', '');
  
  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'ar';
    _locale = Locale(langCode, '');
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _locale = Locale(langCode, '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    notifyListeners();
  }

  bool get isArabic => _locale.languageCode == 'ar';
}
