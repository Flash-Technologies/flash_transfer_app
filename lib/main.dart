import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'core/services/reown_service.dart';
import 'providers/auth_provider.dart';
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
void _handleDeepLink(Uri uri) async {
  debugPrint('🔗 Enhanced deep link handler: ${uri.toString()}');
  debugPrint('📋 Scheme: ${uri.scheme}');
  debugPrint('📋 Host: ${uri.host}');
  debugPrint('📋 Path: ${uri.path}');
  debugPrint('📋 Query: ${uri.query}');
  debugPrint('📋 Fragment: ${uri.fragment}');

  // Enhanced wallet connection detection
  final isWalletConnection = _isWalletConnectionDeepLink(uri);

  if (isWalletConnection) {
    debugPrint('✅ Detected wallet connection callback');
    
    // Log all available data for debugging
    _logWalletDeepLinkData(uri);

    // For Reown-based connections, pass the deep link to Reown service
    debugPrint('🔄 Passing wallet connection callback to Reown service...');
    
    try {
      // Handle the deep link and get the wallet address
      final walletAddress = await ReownService.instance.handleDeepLink(uri);
      
      if (walletAddress != null && walletAddress.isNotEmpty) {
        debugPrint('✅ Wallet connected! Address: $walletAddress');
        
        // Trigger authentication flow with the wallet address
        _triggerWalletAuthentication(walletAddress);
      } else {
        debugPrint('❌ No wallet address received from deep link');
      }
    } catch (e) {
      debugPrint('❌ Error passing deep link to Reown: $e');
    }
    return;
  }

  // Handle non-wallet deep links
  debugPrint('ℹ️ Not a wallet connection deep link');
  
  // Safely access ProviderScope only for non-wallet deep links
  Future.delayed(const Duration(milliseconds: 100), () {
    try {
      // Check if we have a valid root element and ProviderScope
      final rootElement = WidgetsBinding.instance.rootElement;
      if (rootElement == null) {
        debugPrint('⚠️ Root element not available, delaying deep link handling...');
        Future.delayed(const Duration(milliseconds: 500), () => _handleDeepLink(uri));
        return;
      }

      final container = ProviderScope.containerOf(rootElement, listen: false);
      _handleOtherDeepLinks(uri, container);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in non-wallet deep link handler: $e');
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

// Trigger wallet authentication flow when wallet address is obtained from deep link
Future<void> _triggerWalletAuthentication(String walletAddress) async {
  debugPrint('🚀 Triggering wallet authentication with address: $walletAddress');
  
  try {
    // Wait a bit to ensure the app UI is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get the root element and container
    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement == null) {
      debugPrint('❌ Root element not available for wallet authentication');
      return;
    }
    
    final container = ProviderScope.containerOf(rootElement, listen: false);
    
    // Get user country for API call
    String countryName = 'Unknown';
    try {
      // Note: You might want to import http package for this
      // For now, we'll use a default country
      countryName = 'Unknown';
      debugPrint('🌍 Using country: $countryName');
    } catch (e) {
      debugPrint('❌ Failed to get country: $e');
    }
    
    debugPrint('🔐 Calling wallet authentication API...');
    
    // Call the auth provider to authenticate with the wallet address
    final success = await container
        .read(authProvider.notifier)
        .loginWithWalletAddress(walletAddress, countryName);
    
    if (success) {
      debugPrint('✅ Wallet authentication successful!');
      debugPrint('🏠 Navigating to home screen...');
      
      // Navigate to home screen
      // You might need to get the router context differently
      // For now, this will help us see if the authentication worked
    } else {
      debugPrint('❌ Wallet authentication failed');
      final errorMessage = container.read(authProvider).message ?? 'Authentication failed';
      debugPrint('Error: $errorMessage');
    }
    
  } catch (e, stackTrace) {
    debugPrint('💥 Error in wallet authentication: $e');
    debugPrint('📜 Stack trace: $stackTrace');
  }
}