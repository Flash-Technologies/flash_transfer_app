import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'core/services/storage_service.dart';
import 'presentation/screens/metamask_demo_screen.dart';

class FlashTransferApp extends StatelessWidget {
  const FlashTransferApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // Create route configuration that redirects to MetaMask demo
          final router = ref.watch(routerProvider);

          // For testing, we'll use the MaterialApp.router setup
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
}
