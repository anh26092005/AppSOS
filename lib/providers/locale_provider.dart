import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey) ?? 'vi';
      AppStrings.setLocale(savedLocale);
      notifyListeners();
    } catch (e) {
      print('Error loading locale: $e');
    }
  }

  String get currentLocale => AppStrings.locale;

  Future<void> changeLocale(String newLocale) async {
    if (AppStrings.locale == newLocale) return;
    
    try {
      AppStrings.setLocale(newLocale);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale);
      debugPrint('✅ Locale changed to: $newLocale');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving locale: $e');
    }
  }
}
