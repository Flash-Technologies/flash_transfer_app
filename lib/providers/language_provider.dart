import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../core/models/language_model.dart';

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
    _loadSavedLanguage();
  }

  static final _availableLanguages = [
    const LanguageModel(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flagAsset:
          'assets/images/completeCountry.png',  
      isRTL: true,
    ),
    const LanguageModel(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flagAsset:
          'assets/images/completeCountry.png',  
    ),
    const LanguageModel(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagAsset:
          'assets/images/completeCountry.png',  
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

        state = state.copyWith(
          currentLanguage: savedLanguage,
          isLoading: false,
        );
      } else {
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

      // Update state
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
  return ref.watch(languageProvider).filteredLanguages;
});

final languageErrorProvider = Provider<String?>((ref) {
  return ref.watch(languageProvider).error;
});
