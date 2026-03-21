import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  String _currentLanguage = _defaultLanguage;
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  bool get isTamil => _currentLanguage == 'ta';
  bool get isEnglish => _currentLanguage == 'en';

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ta': 'தமிழ்',
  };

  // Language display names
  static const Map<String, String> languageDisplayNames = {
    'en': 'English',
    'ta': 'Tamil',
  };

  /// Initialize language service
  static Future<LanguageService> initialize() async {
    final service = LanguageService();
    await service._loadSavedLanguage();
    service._isInitialized = true;
    return service;
  }

  /// Load saved language from storage
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && supportedLanguages.containsKey(savedLanguage)) {
        _currentLanguage = savedLanguage;
      } else {
        // Auto-detect device language
        _currentLanguage = _detectDeviceLanguage();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      _currentLanguage = _defaultLanguage;
    }
  }

  /// Detect device language
  String _detectDeviceLanguage() {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final languageCode = deviceLocale.languageCode;
      
      // Check if device language is supported
      if (supportedLanguages.containsKey(languageCode)) {
        return languageCode;
      }
      
      // Check for Tamil variants
      if (languageCode == 'ta' || deviceLocale.toString().startsWith('ta')) {
        return 'ta';
      }
      
      return _defaultLanguage;
    } catch (e) {
      debugPrint('Error detecting device language: $e');
      return _defaultLanguage;
    }
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }

    if (_currentLanguage == languageCode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      _currentLanguage = languageCode;
      notifyListeners();
      
      debugPrint('Language changed to: ${supportedLanguages[languageCode]}');
    } catch (e) {
      debugPrint('Error saving language: $e');
      throw Exception('Failed to save language preference');
    }
  }

  /// Check if language has been selected before
  Future<bool> hasLanguageBeenSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_languageKey);
    } catch (e) {
      debugPrint('Error checking language selection: $e');
      return false;
    }
  }

  /// Get locale for current language
  Locale get currentLocale => Locale(_currentLanguage);

  /// Get supported locales
  static List<Locale> get supportedLocales {
    return supportedLanguages.keys.map((code) => Locale(code)).toList();
  }

  /// Get language name for display
  String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  /// Get language display name (in English)
  String getLanguageDisplayName(String languageCode) {
    return languageDisplayNames[languageCode] ?? languageCode;
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await changeLanguage(_defaultLanguage);
  }

  /// Clear language preference (for testing)
  Future<void> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      _currentLanguage = _defaultLanguage;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing language preference: $e');
    }
  }
}