import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance =>
      _instance ??= TranslationService._();

  TranslationService._();

  Map<String, dynamic>? _translations;
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  Future<void> loadTranslations(String locale) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/locales/$locale/translation.json',
      );
      final Map<String, dynamic> loadedTranslations = json.decode(jsonString);
      
      // Merge with default translations to ensure all keys are available
      _translations = _mergeTranslations(_defaultTranslations, loadedTranslations);
      _currentLocale = locale;
    } catch (e) {
      print('Error loading translation file for $locale: $e');
      // Fallback to English if the locale file doesn't exist
      if (locale != 'en') {
        await loadTranslations('en');
      } else {
        _translations = _defaultTranslations;
      }
    }
  }
  
  Map<String, dynamic> _mergeTranslations(Map<String, dynamic> base, Map<String, dynamic> override) {
    final result = Map<String, dynamic>.from(base);
    
    override.forEach((key, value) {
      if (result.containsKey(key) && result[key] is Map<String, dynamic> && value is Map<String, dynamic>) {
        result[key] = _mergeTranslations(result[key] as Map<String, dynamic>, value as Map<String, dynamic>);
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

  String translate(String key, [Map<String, String>? params]) {
    if (_translations == null) {
      print('Translations not loaded, initializing with default locale...');
      _translations = _defaultTranslations;
    }

    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        print('Translation key not found: $key');
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
      "back": "Back",
    },
    "confirmation": {
      "title": "Language Change Confirmation",
      "message":
          "Are you sure you want to change the language to {languageName}? We are happy to assist you with that.",
      "subtitle": "This will update the entire app interface.",
      "buttons": {"yes": "Yes, Change Language", "no": "Cancel"},
      "success": "Language changed successfully to {languageName}",
      "loading": "Applying language changes...",
      "error": "Failed to change language. Please try again.",
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
      "vi": "Vietnamese",
    },
    "errors": {
      "loadFailed": "Error loading languages",
      "noLanguagesFound": "No languages found",
      "tryAdjustingSearch": "Try adjusting your search query",
      "retry": "Retry",
    },
    "recipients": {
      "screen": {
        "title": "Recipients",
        "subtitle": "Choose who to send money to",
        "back": "Back",
        "search": "Search recipients...",
        "addNew": "Add New Recipient",
        "emptyState": "No recipients yet",
        "emptyDescription": "Add a recipient to start sending money",
      },
      "promo": {
        "title": "Refer & Earn!",
        "subtitle": "Get \$25 for each friend",
        "description":
            "Invite friends and earn money when they make their first transfer",
        "button": "Invite Now",
      },
      "sorting": {
        "recentlyAdded": "Recent",
        "alphabetical": "A-Z",
        "mostUsed": "Most Used",
      },
      "filters": {"favorites": "Favorites"},
      "recipient": {
        "lastSent": "Last sent",
        "never": "Never sent",
        "send": "Send",
      },
    },
    "transaction": {
      "screen": {
        "title": "Transactions",
        "back": "Back",
        "loading": "Loading transactions...",
        "emptyState": "No transactions yet",
        "emptyDescription": "Your transaction history will appear here",
      },
      "filters": {
        "all": "All",
        "sent": "Sent",
        "received": "Received",
        "thisMonth": "This Month",
        "lastMonth": "Last Month",
      },
      "recipient": "Recipient",
      "date": "Date",
      "reference": "Reference",
      "transactionId": "Transaction ID",
      "fee": "Fee",
      "send": "Sent",
      "receive": "Received",
      "actions": {
        "download": "Download Receipt",
        "repeatTransaction": "Send Again",
      },
    },
  };
}
