import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/facebook_service.dart';
import 'core/services/translation_service.dart';
import 'core/localization/app_localization_delegate.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

class FlashTransferApp extends StatelessWidget {
  const FlashTransferApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // Initialize auth provider early
          ref.watch(authProvider);
          // Watch language provider to trigger rebuilds when language changes
          ref.watch(languageProvider);
          final currentLanguage = ref.watch(currentLanguageProvider);
          final router = ref.watch(routerProvider);

          return MaterialApp.router(
            title: 'Flash Transfer',
            theme: appTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            // Set locale based on current language
            locale: Locale(currentLanguage.code),
            // Add localization delegates
            localizationsDelegates: const [
              AppLocalizationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Support all our available languages
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('de'),
              Locale('es'),
              Locale('fr'),
              Locale('hi'),
              Locale('nl'),
              Locale('pt'),
              Locale('vi'),
            ],
            builder: (context, child) {
              // Ensure proper safe area handling across the entire app
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Ensure padding is respected for system UI
                  padding: MediaQuery.of(context).padding,
                ),
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> initApp() async {
  // Initialize services
  await StorageService.init();

  // Initialize Facebook SDK
  await FacebookService.initialize();
  
  // Initialize Translation Service with default language
  await TranslationService.instance.loadTranslations('en');
}
