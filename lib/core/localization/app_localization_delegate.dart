import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Custom localization delegate that integrates with our TranslationService
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support the languages we have translations for
    return ['en', 'ar', 'de', 'es', 'fr', 'hi', 'nl', 'pt', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

/// App localizations class that works with our TranslationService
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<void> load() async {
    // Load translations using our existing TranslationService
    await TranslationService.instance.loadTranslations(locale.languageCode);
  }

  String translate(String key, [Map<String, String>? params]) {
    return TranslationService.instance.translate(key, params);
  }
}