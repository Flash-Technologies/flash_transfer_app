import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._();
  
  TranslationService._();

  Map<String, dynamic>? _translations;
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  Future<void> loadTranslations(String locale) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/locales/$locale/language.json');
      _translations = json.decode(jsonString);
      _currentLocale = locale;
    } catch (e) {
      // Fallback to English if the locale file doesn't exist
      if (locale != 'en') {
        await loadTranslations('en');
      } else {
        _translations = _defaultTranslations;
      }
    }
  }

  String translate(String key, [Map<String, String>? params]) {
    if (_translations == null) return key;

    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }

    String result = value.toString();

    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }

  // Default translations as fallback
  static const Map<String, dynamic> _defaultTranslations = {
    "screen": {
      "title": "Language",
      "searchPlaceholder": "Search Language",
      "back": "Back"
    },
    "confirmation": {
      "title": "Language Change Confirmation",
      "message": "Are you sure you want to change the language to {languageName}? We are happy to assist you with that.",
      "subtitle": "This will update the entire app interface.",
      "buttons": {
        "yes": "Yes, Change Language",
        "no": "Cancel"
      },
      "success": "Language changed successfully to {languageName}",
      "loading": "Applying language changes...",
      "error": "Failed to change language. Please try again."
    },
    "languages": {
      "ar": "Arabic",
      "de": "German", 
      "en": "English",
      "es": "Spanish",
      "fr": "French",
      "hi": "Hindi",
      "nl": "Dutch",
      "pt": "Portuguese",
      "vi": "Vietnamese"
    },
    "errors": {
      "loadFailed": "Error loading languages",
      "noLanguagesFound": "No languages found",
      "tryAdjustingSearch": "Try adjusting your search query",
      "retry": "Retry"
    }
  };
}