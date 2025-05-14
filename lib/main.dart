import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/direct_wallet_provider.dart';
import 'providers/metamask_provider.dart';
import 'app.dart';

// Initialize GoogleSignIn at the app level
final GoogleSignIn googleSignIn = GoogleSignIn(
  // The client ID from the provided credentials
  clientId:
      '850808265877-916lji3l3vt73cc6r99d48hhtid53fb1.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

// Method channel for native wallet communication
const MethodChannel walletChannel = MethodChannel(
  'com.flash_transfer_app.wallet_channel',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorObserver = NavigatorObserver();
  // Initialize deep link handling
  initDeepLinkHandling();

  await initApp();
  runApp(
    ProviderScope(
      overrides: [
        // Provide the observer to the app
        navigatorObserverProvider.overrideWithValue(navigatorObserver),
      ],
      child: const FlashTransferApp(),
    ),
  );
}
final navigatorObserverProvider = Provider<NavigatorObserver>((ref) {
  return NavigatorObserver();
});

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
  appLinks.uriLinkStream.listen(
    (Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    },
    onError: (Object error) {
      debugPrint('Deep link error: $error');
    },
  );
}

void _handleDeepLink(Uri uri) {
  debugPrint('Handling deep link: ${uri.toString()}');

  // Access the ProviderContainer to handle the deep link
  // This will be processed when the app is fully initialized
  Future.delayed(Duration.zero, () {
    final container = ProviderScope.containerOf(
      WidgetsBinding.instance.rootElement!,
      listen: false,
    );

    // Debug print all query parameters
    debugPrint('URI query parameters:');
    uri.queryParameters.forEach((key, value) {
      debugPrint('  $key: $value');
    });

    // Check if the deep link is a wallet connection callback
    final isWalletConnection =
        uri.scheme == 'flashtransferapp' ||
        uri.path.contains('connect') ||
        uri.toString().contains('connect');

    if (isWalletConnection) {
      debugPrint('Detected wallet connection callback');

      // Check for Ethereum address patterns in the URI string
      final addressPattern = RegExp(r'0x[a-fA-F0-9]{40}');
      final addressMatch = addressPattern.firstMatch(uri.toString());
      if (addressMatch != null) {
        debugPrint('Ethereum address found in URI: ${addressMatch.group(0)}');
      }

      // Check if this is from MetaMask - very lenient detection to catch different formats
      final isMetaMask =
          uri.toString().toLowerCase().contains('metamask') ||
          uri.scheme == 'metamask' ||
          uri.queryParameters.containsKey('metamask') ||
          uri.host == 'metamask';

      if (isMetaMask) {
        debugPrint('Routing to MetaMask handler');
        // Handle MetaMask specific callbacks
        container.read(metamaskProvider.notifier).handleDeepLink(uri);
      } else {
        debugPrint('Routing to generic wallet handler');
        // Handle other wallet providers
        container.read(directWalletProvider.notifier).handleDeepLink(uri);
      }
    } else {
      debugPrint('Not a wallet connection deep link, ignoring');
    }
  });
}
