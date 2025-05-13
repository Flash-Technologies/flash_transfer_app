import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../presentation/common/wallet_selector_sheet.dart';

/// Response class for wallet connection attempts
class WalletConnectionResponse {
  final bool connected;
  final String? walletAddress;
  final String? walletType;
  final String? error;
  final String? signature;

  WalletConnectionResponse({
    required this.connected,
    this.walletAddress,
    this.walletType,
    this.error,
    this.signature,
  });
}

/// Service for direct wallet connections
class DirectWalletService {
  // Completer to handle async wallet connection flow
  Completer<WalletConnectionResponse>? _connectCompleter;
  
  // Connection timeout timer
  Timer? _connectionTimeoutTimer;
  
  // Flag to track if connection is in progress
  bool _isConnectionInProgress = false;
  
  // Selected wallet during connection attempt
  WalletApp? _selectedWallet;
  
  // Random nonce for authentication (to be signed by wallet)
  String? _currentNonce;
  
  // Package name of our app for deep linking back
  final String _appPackageName;
  
  // Universal link of our app for deep linking back
  final String _appUniversalLink;
  
  // Method channel for native integration
  static const _channel = MethodChannel('com.flash_transfer_app.wallet_channel');

  DirectWalletService({
    required String appPackageName,
    required String appUniversalLink,
  }) : _appPackageName = appPackageName,
       _appUniversalLink = appUniversalLink;

  /// Check if a connection is in progress
  bool get isConnecting => _isConnectionInProgress;

  /// Connect to a wallet using direct deep linking
  Future<WalletConnectionResponse> connectWallet(BuildContext context) async {
    // Check if a connection is already in progress
    if (_isConnectionInProgress) {
      return WalletConnectionResponse(
        connected: false,
        error: 'A wallet connection is already in progress',
      );
    }

    // Mark connection as in progress
    _isConnectionInProgress = true;
    
    try {
      // Show wallet selector bottom sheet
      final selectedWallet = await WalletSelectorSheet.show(context);
      
      // If no wallet was selected, cancel the connection
      if (selectedWallet == null) {
        _isConnectionInProgress = false;
        return WalletConnectionResponse(
          connected: false,
          error: 'No wallet selected',
        );
      }
      
      _selectedWallet = selectedWallet;
      
      // Generate a nonce for this connection attempt
      _currentNonce = _generateNonce();
      
      // Create a completer to handle the async connection flow
      _connectCompleter = Completer<WalletConnectionResponse>();
      
      // Start timeout timer (2 minutes)
      _startConnectionTimeoutTimer();
      
      // Launch the selected wallet app
      final launchResult = await _launchWalletApp(selectedWallet);
      
      if (!launchResult) {
        _isConnectionInProgress = false;
        _cancelTimeoutTimer();
        return WalletConnectionResponse(
          connected: false,
          error: 'Failed to launch ${selectedWallet.name}',
        );
      }
      
      // Wait for connection to complete with a timeout
      return await _connectCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _isConnectionInProgress = false;
          return WalletConnectionResponse(
            connected: false,
            error: 'Connection timed out. Please try again.',
          );
        },
      );
    } catch (e) {
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
      return WalletConnectionResponse(
        connected: false,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Handle incoming deep link from wallet app
  Future<void> handleDeepLink(Uri uri) async {
    if (!_isConnectionInProgress || _connectCompleter == null) {
      debugPrint('Received deep link but no connection is in progress');
      return;
    }

    try {
      // Parse the deep link to get wallet address and potentially signature
      final walletAddress = _extractWalletAddressFromUri(uri);
      final signature = _extractSignatureFromUri(uri);

      if (walletAddress == null) {
        _completeWithError('No wallet address found in response');
        return;
      }

      // Complete the connection with success
      if (!_connectCompleter!.isCompleted) {
        _connectCompleter!.complete(
          WalletConnectionResponse(
            connected: true,
            walletAddress: walletAddress,
            walletType: _selectedWallet?.id,
            signature: signature,
          ),
        );
      }
      
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
    } catch (e) {
      _completeWithError('Error processing wallet response: ${e.toString()}');
    }
  }

  /// Check if a specific wallet is installed
  Future<bool> isWalletInstalled(WalletApp wallet) async {
    try {
      if (Platform.isAndroid) {
        // Try with scheme
        final canLaunchScheme = await canLaunchUrl(Uri.parse(wallet.scheme));
        if (canLaunchScheme) return true;
        
        // Try with package manager query
        final androidIntent = Uri.parse('android-app://${wallet.androidPackage}');
        return await canLaunchUrl(androidIntent);
      } else if (Platform.isIOS) {
        // iOS doesn't allow direct package checking, we can only use URL schemes
        return await canLaunchUrl(Uri.parse(wallet.scheme));
      }
      return false;
    } catch (e) {
      debugPrint("Error checking if ${wallet.name} is installed: $e");
      return false;
    }
  }

  /// Check which wallets are installed
  Future<Map<String, bool>> getInstalledWallets(List<WalletApp> wallets) async {
    Map<String, bool> results = {};
    
    for (var wallet in wallets) {
      final isInstalled = await isWalletInstalled(wallet);
      results[wallet.id] = isInstalled;
    }
    
    return results;
  }

  /// Disconnect wallet (clear any stored state)
  Future<bool> disconnectWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_address');
      await prefs.remove('wallet_type');
      
      return true;
    } catch (e) {
      debugPrint('Error disconnecting wallet: $e');
      return false;
    }
  }

  /// Launch the selected wallet app
  Future<bool> _launchWalletApp(WalletApp wallet) async {
    try {
      // Construct deep link parameters
      final params = {
        'action': 'connect',
        'nonce': _currentNonce,
        'callback': Platform.isAndroid
            ? 'flashtransferapp://'  // Android app scheme
            : _appUniversalLink,  // iOS universal link
      };
      
      // ATTEMPT 1: Try direct WalletConnect-style URI
      final encodedParams = Uri.encodeComponent(jsonEncode(params));
      final wcUri = 'wc:${encodedParams}';
      
      debugPrint('Trying direct WalletConnect URI: $wcUri');
      
      bool launched = false;
      
      try {
        launched = await launchUrl(
          Uri.parse(wcUri),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Direct WalletConnect URI failed: $e');
      }
      
      // ATTEMPT 2: Try wallet-specific scheme with parameters
      if (!launched) {
        try {
          final schemeUri = Uri.parse(
            '${wallet.scheme}connect?${Uri.encodeQueryComponent(jsonEncode(params))}',
          );
          
          debugPrint('Trying wallet-specific scheme: ${schemeUri.toString()}');
          
          launched = await launchUrl(
            schemeUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Wallet-specific scheme failed: $e');
        }
      }
      
      // ATTEMPT 3: Try simple wallet scheme without parameters
      if (!launched) {
        try {
          debugPrint('Trying simple wallet scheme: ${wallet.scheme}');
          
          launched = await launchUrl(
            Uri.parse(wallet.scheme),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Simple wallet scheme failed: $e');
        }
      }
      
      // ATTEMPT 4: Try universal link (iOS) or direct app launch (Android)
      if (!launched) {
        if (Platform.isIOS && wallet.universalLink.isNotEmpty) {
          try {
            final universalUri = Uri.parse(
              '${wallet.universalLink}/connect?${Uri.encodeQueryComponent(jsonEncode(params))}',
            );
            
            debugPrint('Trying universal link: ${universalUri.toString()}');
            
            launched = await launchUrl(
              universalUri,
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            debugPrint('Universal link failed: $e');
          }
        } else if (Platform.isAndroid) {
          try {
            final appUri = Uri.parse('android-app://${wallet.androidPackage}');
            
            debugPrint('Trying direct app launch: ${appUri.toString()}');
            
            launched = await launchUrl(
              appUri,
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            debugPrint('Direct app launch failed: $e');
          }
        }
      }
      
      // ATTEMPT 5: Try native platform channel for custom implementation
      if (!launched) {
        try {
          final Map<String, dynamic> args = {
            'wallet_id': wallet.id,
            'wallet_package': wallet.androidPackage,
            'wallet_scheme': wallet.scheme,
            'params': params,
          };
          
          final result = await _channel.invokeMethod('launchWallet', args);
          launched = result == true;
          
          debugPrint('Native channel launch result: $launched');
        } catch (e) {
          debugPrint('Native channel launch failed: $e');
        }
      }
      
      // If all attempts failed, copy connection info to clipboard as fallback
      if (!launched) {
        final clipboardData = 'Flash Transfer Wallet Connect Request:\n'
            'Nonce: $_currentNonce\n'
            'Please connect your wallet and enter this address manually in the app.';
            
        await Clipboard.setData(ClipboardData(text: clipboardData));
        
        debugPrint('All wallet launch attempts failed. Copied data to clipboard.');
      }
      
      return launched;
    } catch (e) {
      debugPrint('Error launching wallet: $e');
      return false;
    }
  }

  /// Extract wallet address from URI
  String? _extractWalletAddressFromUri(Uri uri) {
    try {
      // Handle different URI formats based on wallet type
      if (uri.scheme == 'flashtransferapp') {
        // Our app's custom scheme
        return uri.queryParameters['address'];
      } else if (uri.path.contains('connect') || uri.path.contains('callback')) {
        // Standard callback format
        return uri.queryParameters['address'];
      } else {
        // Try to find address in any query parameter
        return uri.queryParameters['address'] ?? 
               uri.queryParameters['wallet_address'] ?? 
               uri.queryParameters['account'];
      }
    } catch (e) {
      debugPrint('Error extracting address from URI: $e');
      return null;
    }
  }

  /// Extract signature from URI
  String? _extractSignatureFromUri(Uri uri) {
    try {
      return uri.queryParameters['signature'];
    } catch (e) {
      debugPrint('Error extracting signature from URI: $e');
      return null;
    }
  }

  /// Generate random nonce for connection security
  String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (1000 + DateTime.now().millisecond).toString();
    final data = utf8.encode('$timestamp:$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }

  /// Start connection timeout timer
  void _startConnectionTimeoutTimer() {
    _cancelTimeoutTimer();
    _connectionTimeoutTimer = Timer(const Duration(minutes: 2), () {
      _completeWithError('Connection timed out. Please try again.');
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    if (_connectionTimeoutTimer != null && _connectionTimeoutTimer!.isActive) {
      _connectionTimeoutTimer!.cancel();
      _connectionTimeoutTimer = null;
    }
  }

  /// Complete with error
  void _completeWithError(String error) {
    _isConnectionInProgress = false;
    _cancelTimeoutTimer();
    
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(
        WalletConnectionResponse(
          connected: false,
          error: error,
        ),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _cancelTimeoutTimer();
  }
}