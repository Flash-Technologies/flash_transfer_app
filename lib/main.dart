import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/direct_wallet_provider.dart';
import 'app.dart';

// Initialize GoogleSignIn at the app level
final GoogleSignIn googleSignIn = GoogleSignIn(
  // The client ID from the provided credentials
  clientId:
      '850808265877-916lji3l3vt73cc6r99d48hhtid53fb1.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

// Method channel for native wallet communication
const MethodChannel walletChannel = MethodChannel('com.flash_transfer_app.wallet_channel');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize deep link handling
  initDeepLinkHandling();
  
  await initApp();
  runApp(const ProviderScope(child: FlashTransferApp()));
}

void initDeepLinkHandling() {
  // Set up method channel handler for deep links coming from native code
  walletChannel.setMethodCallHandler((call) async {
    if (call.method == 'handleDeepLink') {
      final uriString = call.arguments as String;
      if (uriString.isNotEmpty) {
        final uri = Uri.parse(uriString);
        _handleDeepLink(uri);
      }
    }
  });
  
  // Set up App Links (modern replacement for uni_links)
  final appLinks = AppLinks();
  
  // Handle app links when app is started from a link
  appLinks.getInitialAppLink().then((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });
  
  // Handle app links while app is running
  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  }, onError: (Object error) {
    debugPrint('Deep link error: $error');
  });
}

void _handleDeepLink(Uri uri) {
  debugPrint('Handling deep link: $uri');
  
  // Access the ProviderContainer to handle the deep link
  // This will be processed when the app is fully initialized
  Future.delayed(Duration.zero, () {
    final container = ProviderScope.containerOf(
      WidgetsBinding.instance.rootElement!,
      listen: false,
    );
    
    // If the URI relates to wallet connection, process it
    if (uri.scheme == 'flashtransferapp' || uri.path.contains('connect')) {
      container.read(directWalletProvider.notifier).handleDeepLink(uri);
    }
  });
}