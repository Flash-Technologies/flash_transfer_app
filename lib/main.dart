import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'providers/direct_wallet_provider.dart';
import 'providers/metamask_provider.dart';
import 'app.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  signInOption: SignInOption.standard,
  serverClientId:
      '247313278717-rp6st2neucptvl0u3iqj5ihgsarjp9gc.apps.googleusercontent.com',
  forceCodeForRefreshToken: true,
);

const MethodChannel walletChannel = MethodChannel(
  'com.flash_transfer_app.wallet_channel',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorObserver = NavigatorObserver();
  initDeepLinkHandling();

  await initApp();
  runApp(
    ProviderScope(
      overrides: [
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
  walletChannel.setMethodCallHandler((call) async {
    if (call.method == 'handleDeepLink') {
      final uriString = call.arguments as String;
      if (uriString.isNotEmpty) {
        final uri = Uri.parse(uriString);
        _handleDeepLink(uri);
      }
    }
  });

  final appLinks = AppLinks();

  appLinks.getInitialAppLink().then((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });

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
  debugPrint('🔗 Enhanced deep link handler: ${uri.toString()}');
  debugPrint('📋 Scheme: ${uri.scheme}');
  debugPrint('📋 Host: ${uri.host}');
  debugPrint('📋 Path: ${uri.path}');
  debugPrint('📋 Query: ${uri.query}');
  debugPrint('📋 Fragment: ${uri.fragment}');

  // Access the ProviderContainer to handle the deep link
  Future.delayed(Duration.zero, () {
    try {
      final container = ProviderScope.containerOf(
        WidgetsBinding.instance.rootElement!,
        listen: false,
      );

      // Enhanced wallet connection detection
      final isWalletConnection = _isWalletConnectionDeepLink(uri);

      if (isWalletConnection) {
        debugPrint('✅ Detected wallet connection callback');
        
        // Log all available data for debugging
        _logWalletDeepLinkData(uri);

        // Determine wallet provider type with enhanced detection
        final walletProvider = _identifyWalletProvider(uri);
        debugPrint('🔍 Identified wallet provider: $walletProvider');

        // Route to appropriate handler based on wallet type
        switch (walletProvider) {
          case 'metamask':
            debugPrint('🦊 Routing to MetaMask handler');
            container.read(metamaskProvider.notifier).handleDeepLink(uri);
            break;
            
          case 'trust':
          case 'phantom':
          case 'coinbase':
          case 'binance':
          case 'rainbow':
          case 'generic':
          default:
            debugPrint('🔗 Routing to enhanced direct wallet handler');
            container.read(directWalletProvider.notifier).handleDeepLink(uri);
            break;
        }
      } else {
        debugPrint('ℹ️ Not a wallet connection deep link');
        // Handle other types of deep links here if needed
        _handleOtherDeepLinks(uri, container);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error in deep link handler: $e');
      debugPrint('📜 Stack trace: $stackTrace');
    }
  });
}

bool _isWalletConnectionDeepLink(Uri uri) {
  // Enhanced detection logic
  final uriString = uri.toString().toLowerCase();
  
  // Direct scheme matches
  final walletSchemes = [
    'flashtransferapp', 'metamask', 'trust', 'phantom', 
    'cbwallet', 'bnc', 'rainbow', 'zengo', 'argent', 'imtokenv2'
  ];
  
  if (walletSchemes.contains(uri.scheme.toLowerCase())) {
    return true;
  }
  
  // HTTPS callbacks with wallet-specific paths
  if (uri.scheme == 'https' && uri.host.contains('flashtransfer')) {
    if (uri.path.contains('connect') || uri.path.contains('wallet')) {
      return true;
    }
  }
  
  // Query parameter indicators
  final walletIndicators = [
    'address', 'wallet_address', 'account', 'signature',
    'wallet', 'connect', 'callback', 'metamask', 'trust'
  ];
  
  for (final indicator in walletIndicators) {
    if (uri.queryParameters.containsKey(indicator) || 
        uriString.contains(indicator)) {
      return true;
    }
  }
  
  // Address pattern detection
  final addressPatterns = [
    RegExp(r'0x[a-fA-F0-9]{40}'), // Ethereum
    RegExp(r'[1-9A-HJ-NP-Za-km-z]{32,44}'), // Solana/Bitcoin
  ];
  
  for (final pattern in addressPatterns) {
    if (pattern.hasMatch(uriString)) {
      return true;
    }
  }
  
  return false;
}

String _identifyWalletProvider(Uri uri) {
  final uriString = uri.toString().toLowerCase();
  
  // Direct scheme identification
  if (uri.scheme == 'metamask') return 'metamask';
  if (uri.scheme == 'trust') return 'trust';
  if (uri.scheme == 'phantom') return 'phantom';
  if (uri.scheme == 'cbwallet') return 'coinbase';
  if (uri.scheme == 'bnc') return 'binance';
  if (uri.scheme == 'rainbow') return 'rainbow';
  
  // Content-based identification
  if (uriString.contains('metamask')) return 'metamask';
  if (uriString.contains('trust')) return 'trust';
  if (uriString.contains('phantom')) return 'phantom';
  if (uriString.contains('coinbase')) return 'coinbase';
  if (uriString.contains('binance')) return 'binance';
  if (uriString.contains('rainbow')) return 'rainbow';
  
  // Query parameter identification
  final walletParam = uri.queryParameters['wallet'] ?? 
                    uri.queryParameters['wallet_type'] ??
                    uri.queryParameters['provider'];
                    
  if (walletParam != null) {
    return walletParam.toLowerCase();
  }
  
  return 'generic';
}

void _logWalletDeepLinkData(Uri uri) {
  debugPrint('📊 ===== WALLET DEEP LINK DATA ANALYSIS =====');
  
  // Log basic URI components
  debugPrint('🔗 Full URI: ${uri.toString()}');
  debugPrint('📋 Scheme: ${uri.scheme}');
  debugPrint('📋 Host: ${uri.host}');
  debugPrint('📋 Path: ${uri.path}');
  debugPrint('📋 Query: ${uri.query}');
  
  // Log all query parameters
  if (uri.queryParameters.isNotEmpty) {
    debugPrint('📋 Query Parameters:');
    uri.queryParameters.forEach((key, value) {
      debugPrint('   - $key: $value');
    });
  }
  
  // Log fragment data
  if (uri.fragment.isNotEmpty) {
    debugPrint('📋 Fragment: ${uri.fragment}');
    
    // Try to parse fragment as query parameters
    try {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      if (fragmentParams.isNotEmpty) {
        debugPrint('📋 Fragment Parameters:');
        fragmentParams.forEach((key, value) {
          debugPrint('   - $key: $value');
        });
      }
    } catch (e) {
      debugPrint('⚠️ Could not parse fragment as query parameters');
    }
  }
  
  // Log path segments
  if (uri.pathSegments.isNotEmpty) {
    debugPrint('📋 Path Segments: ${uri.pathSegments.join(' / ')}');
  }
  
  // Look for address patterns
  final addressPatterns = [
    RegExp(r'0x[a-fA-F0-9]{40}'), // Ethereum
    RegExp(r'[1-9A-HJ-NP-Za-km-z]{32,44}'), // Solana/Bitcoin
  ];
  
  for (final pattern in addressPatterns) {
    final matches = pattern.allMatches(uri.toString());
    for (final match in matches) {
      debugPrint('💰 Found potential address: ${match.group(0)}');
    }
  }
  
  debugPrint('📊 ===== END WALLET DEEP LINK ANALYSIS =====');
}

void _handleOtherDeepLinks(Uri uri, ProviderContainer container) {
  debugPrint('🔗 Handling non-wallet deep link: ${uri.toString()}');
  
  // Handle other app deep links here
  // For example: navigation deep links, share links, etc.
  
  if (uri.path.contains('share')) {
    debugPrint('📤 Share deep link detected');
    // Handle share functionality
  } else if (uri.path.contains('invite')) {
    debugPrint('📨 Invite deep link detected');
    // Handle invite functionality
  } else {
    debugPrint('ℹ️ Unknown deep link type, ignoring');
  }
}