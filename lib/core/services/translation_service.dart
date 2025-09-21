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
      // List of translation files to load
      final List<String> translationFiles = [
        'translation.json',
        'invite.json',
        'privacy.json',
        'contacts.json',
        'crypto-payment.json',
        'crypto.json',
        'findLocation.json',
        'footer.json',
        'history.json',
        'language.json',
        'mobile.json',
        'navigation.json',
        'pending.json',
        'profileDropdown.json',
        'receiver.json',
        'recipients.json',
        'review.json',
        'send-crypto.json',
        'send.json',
        'storeLocation.json',
        'testimonials.json',
        'track.json',
        'transaction.json',
        'transactionDetails.json',
      ];

      Map<String, dynamic> allTranslations = Map<String, dynamic>.from(_defaultTranslations);
      
      // Load each translation file and merge
      for (String fileName in translationFiles) {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/locales/$locale/$fileName',
          );
          final Map<String, dynamic> fileTranslations = json.decode(jsonString);
          
          // Extract the base name without extension to use as the key
          final String baseKey = fileName.replaceAll('.json', '');
          
          // For main translation.json, merge directly
          if (baseKey == 'translation') {
            allTranslations = _mergeTranslations(allTranslations, fileTranslations);
          } else {
            // For other files, add them under their base key
            allTranslations[baseKey] = fileTranslations;
          }
        } catch (e) {
          print('Could not load translation file $fileName for $locale: $e');
          // Continue loading other files
        }
      }
      
      _translations = allTranslations;
      _currentLocale = locale;
    } catch (e) {
      print('Error loading translation files for $locale: $e');
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
    "invite": {
      "screen": {
        "title": "Invite Friends & Get Bonus",
        "subtitle": "Invite your friends to join and earn exclusive bonuses for every referral!",
        "description": "Share Flash Transfer with friends and family. You both get rewards when they make their first transaction.",
        "back": "Back"
      },
      "actions": {
        "invite": "Invite",
        "share": "Share",
        "copyLink": "Copy Link"
      }
    },
    "privacy": {
      "screen": {
        "title": "Privacy Policy",
        "subtitle": "Your privacy and data protection information",
        "back": "Back",
        "search": "Search in policy",
        "readingProgress": "Reading Progress"
      },
      "sections": {
        "introduction": {
          "title": "Introduction",
          "content": "At Flash Transfer, we respect your privacy. This Privacy Policy outlines how we collect, use, and protect your personal information."
        }
      }
    },
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
