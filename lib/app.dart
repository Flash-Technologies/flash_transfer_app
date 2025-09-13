import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/facebook_service.dart';
import 'core/services/translation_service.dart';
import 'providers/auth_provider.dart';

class FlashTransferApp extends StatelessWidget {
  const FlashTransferApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // Initialize auth provider early
          ref.watch(authProvider);
          final router = ref.watch(routerProvider);

          return MaterialApp.router(
            title: 'Flash Transfer',
            theme: appTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
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
  
  // Initialize Translation Service
  await TranslationService.instance.loadTranslations('en');
}
