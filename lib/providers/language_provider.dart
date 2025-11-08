import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/language_model.dart';
import '../core/services/translation_service.dart';

// Language state
class LanguageState {
  final List<LanguageModel> availableLanguages;
  final LanguageModel currentLanguage;
  final bool isLoading;
  final String? error;
  final List<LanguageModel> filteredLanguages;
  final String searchQuery;

  const LanguageState({
    required this.availableLanguages,
    required this.currentLanguage,
    this.isLoading = false,
    this.error,
    required this.filteredLanguages,
    this.searchQuery = '',
  });

  LanguageState copyWith({
    List<LanguageModel>? availableLanguages,
    LanguageModel? currentLanguage,
    bool? isLoading,
    String? error,
    List<LanguageModel>? filteredLanguages,
    String? searchQuery,
  }) {
    return LanguageState(
      availableLanguages: availableLanguages ?? this.availableLanguages,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filteredLanguages: filteredLanguages ?? this.filteredLanguages,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Language Provider
class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _languageKey = 'selected_language';

  LanguageNotifier() : super(_initialState) {
    _initializeTranslations();
    _loadSavedLanguage();
  }

  Future<void> _initializeTranslations() async {
    // Ensure English translations are loaded by default
    await TranslationService.instance.loadTranslations('en');
  }

  static final _availableLanguages = [
    const LanguageModel(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flagAsset: 'assets/images/flags/flag_ae.png',
      isRTL: true,
    ),
    const LanguageModel(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flagAsset: 'assets/images/flags/flag_de.png',
    ),
    const LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagAsset: 'assets/images/flags/flag_us.png',
    ),
    const LanguageModel(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flagAsset: 'assets/images/flags/flag_es.png',
    ),
    const LanguageModel(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flagAsset: 'assets/images/flags/flag_fr.png',
    ),
    const LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flagAsset: 'assets/images/flags/flag_in.png',
    ),
    const LanguageModel(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      flagAsset: 'assets/images/flags/flag_nl.png',
    ),
    const LanguageModel(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flagAsset: 'assets/images/flags/flag_pt.png',
    ),
    const LanguageModel(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagAsset: 'assets/images/flags/flag_vn.png',
    ),
  ];

  static final _initialState = LanguageState(
    availableLanguages: _availableLanguages,
    currentLanguage: _availableLanguages.firstWhere(
      (lang) => lang.code == 'en',
      orElse: () => _availableLanguages.first,
    ),
    filteredLanguages: _availableLanguages,
  );

  Future<void> _loadSavedLanguage() async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);

      if (savedLanguageCode != null) {
        final savedLanguage = _availableLanguages.firstWhere(
          (lang) => lang.code == savedLanguageCode,
          orElse: () => _availableLanguages.first,
        );

        // Load translations for the saved language
        await TranslationService.instance.loadTranslations(savedLanguage.code);
        
        state = state.copyWith(
          currentLanguage: savedLanguage,
          isLoading: false,
        );
      } else {
        // If no saved language, load English translations as default
        await TranslationService.instance.loadTranslations('en');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load saved language: $e',
      );
    }
  }

  Future<bool> changeLanguage(LanguageModel language) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);

      // Load translations for the new language
      await TranslationService.instance.loadTranslations(language.code);

      // Update state - this will trigger rebuilds across the app
      state = state.copyWith(currentLanguage: language, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change language: $e',
      );
      return false;
    }
  }

  void searchLanguages(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredLanguages: _availableLanguages,
        searchQuery: '',
      );
      return;
    }

    final filtered =
        _availableLanguages.where((language) {
          return language.name.toLowerCase().contains(query.toLowerCase()) ||
              language.nativeName.toLowerCase().contains(query.toLowerCase()) ||
              language.code.toLowerCase().contains(query.toLowerCase());
        }).toList();

    state = state.copyWith(filteredLanguages: filtered, searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(
      filteredLanguages: _availableLanguages,
      searchQuery: '',
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider instances
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(),
);

// Convenience providers
final currentLanguageProvider = Provider<LanguageModel>((ref) {
  return ref.watch(languageProvider).currentLanguage;
});

final isLanguageLoadingProvider = Provider<bool>((ref) {
  return ref.watch(languageProvider).isLoading;
});


final filteredLanguagesProvider = Provider<List<LanguageModel>>((ref) {
  final languageState = ref.watch(languageProvider);
  final query = languageState.searchQuery.toLowerCase();
  
  if (query.isEmpty) {
    return languageState.availableLanguages;
  }

  return languageState.filteredLanguages.where((language) {
    return language.name.toLowerCase().contains(query) ||
        language.nativeName.toLowerCase().contains(query) ||
        language.code.toLowerCase().contains(query);
  }).toList();
});


final languageErrorProvider = Provider<String?>((ref) {
  return ref.watch(languageProvider).error;
});

// Translation provider that rebuilds when language changes
final translationProvider = Provider<TranslationService>((ref) {
  // Watch language changes to trigger rebuilds
  ref.watch(currentLanguageProvider);
  return TranslationService.instance;
});

// Translation helper provider
final translationHelperProvider = Provider<String Function(String, [Map<String, String>?])>((ref) {
  // Watch language changes to trigger rebuilds
  ref.watch(currentLanguageProvider);
  return TranslationService.instance.translate;
});

// Force reload translations provider (for development/debugging)
final translationReloadProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await TranslationService.instance.forceReloadTranslations();
    // Invalidate the translation provider to trigger rebuilds
    ref.invalidate(translationHelperProvider);
  };
});
