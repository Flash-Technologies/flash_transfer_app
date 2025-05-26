// lib/core/services/enhanced_direct_wallet_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../presentation/common/wallet_selector_sheet.dart';

class WalletConnectionResponse {
  final bool connected;
  final String? walletAddress;
  final String? walletType;
  final String? error;
  final String? signature;
  final Map<String, dynamic>? metadata;

  WalletConnectionResponse({
    required this.connected,
    this.walletAddress,
    this.walletType,
    this.error,
    this.signature,
    this.metadata,
  });

  @override
  String toString() {
    return 'WalletConnectionResponse(connected: $connected, address: $walletAddress, type: $walletType, error: $error)';
  }
}

class EnhancedDirectWalletService {
  Completer<WalletConnectionResponse>? _connectCompleter;
  Timer? _connectionTimeoutTimer;
  bool _isConnectionInProgress = false;
  WalletApp? _selectedWallet;
  String? _currentNonce;
  String? _currentSessionId;

  final String _appPackageName;
  final String _appUniversalLink;

  static const _channel = MethodChannel(
    'com.flash_transfer_app.wallet_channel',
  );

  EnhancedDirectWalletService({
    required String appPackageName,
    required String appUniversalLink,
  }) : _appPackageName = appPackageName,
       _appUniversalLink = appUniversalLink;

  bool get isConnecting => _isConnectionInProgress;

  Future<WalletConnectionResponse> connectWallet(BuildContext context) async {
    if (_isConnectionInProgress) {
      debugPrint('⚠️ Connection already in progress');
      return WalletConnectionResponse(
        connected: false,
        error: 'A wallet connection is already in progress',
      );
    }

    _isConnectionInProgress = true;
    _currentSessionId = _generateSessionId();

    try {
      debugPrint('🔄 Enhanced wallet service: Starting connection process');
      
      final selectedWallet = await WalletSelectorSheet.show(context);

      if (selectedWallet == null) {
        _isConnectionInProgress = false;
        debugPrint('❌ No wallet selected by user');
        return WalletConnectionResponse(
          connected: false,
          error: 'No wallet selected',
        );
      }

      _selectedWallet = selectedWallet;
      _currentNonce = _generateNonce();
      _connectCompleter = Completer<WalletConnectionResponse>();

      _startConnectionTimeoutTimer();

      debugPrint('🔄 Starting connection to ${selectedWallet.name}');
      debugPrint('📱 Session ID: $_currentSessionId');
      debugPrint('🔑 Nonce: $_currentNonce');

      // Use enhanced launch strategy based on wallet type
      final launchResult = await _launchWalletWithCorrectFormat(selectedWallet);

      if (!launchResult) {
        _isConnectionInProgress = false;
        _cancelTimeoutTimer();
        debugPrint('❌ Failed to launch ${selectedWallet.name}');
        return WalletConnectionResponse(
          connected: false,
          error: 'Failed to launch ${selectedWallet.name}. Please ensure it is installed.',
        );
      }

      // Show user guidance
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Please connect your wallet in ${selectedWallet.name}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 8),
            backgroundColor: selectedWallet.color,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      // Set up fallback manual input for problematic wallets
      if (selectedWallet.id == 'metamask') {
        Timer(const Duration(seconds: 25), () {
          if (_isConnectionInProgress &&
              _connectCompleter != null &&
              !_connectCompleter!.isCompleted &&
              context.mounted) {
            debugPrint('⏰ MetaMask manual input timeout reached');
            _showManualAddressInputDialog(context);
          }
        });
      }

      final result = await _connectCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          debugPrint('⏰ Connection timeout after 3 minutes');
          _isConnectionInProgress = false;
          _cancelTimeoutTimer();
          return WalletConnectionResponse(
            connected: false,
            error: 'Connection timed out. Please try again.',
          );
        },
      );

      debugPrint('✅ Connection process completed: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Exception in connectWallet: $e');
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
      return WalletConnectionResponse(
        connected: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  Future<bool> _launchWalletWithCorrectFormat(WalletApp wallet) async {
    try {
      debugPrint('🚀 Launching ${wallet.name} with enhanced format');

      // Try native channel first for Android
      if (Platform.isAndroid) {
        try {
          debugPrint('📱 Trying Android native channel launch');
          final result = await _channel.invokeMethod('launchWallet', {
            'wallet_id': wallet.id,
            'wallet_package': wallet.androidPackage,
            'wallet_scheme': wallet.scheme,
            'params': jsonEncode(_getConnectionParams()),
          });

          if (result == true) {
            debugPrint('✅ Native channel launch successful for ${wallet.name}');
            return true;
          } else {
            debugPrint('❌ Native channel returned false for ${wallet.name}');
          }
        } catch (e) {
          debugPrint('❌ Native channel failed for ${wallet.name}: $e');
        }
      }

      // Fallback to URL-based launching with corrected formats
      debugPrint('🔄 Falling back to URL scheme launch');
      return await _launchWithUrlScheme(wallet);
    } catch (e) {
      debugPrint('❌ Error launching ${wallet.name}: $e');
      return false;
    }
  }

  Future<bool> _launchWithUrlScheme(WalletApp wallet) async {
    final callbackUrl = Platform.isAndroid 
        ? 'flashtransferapp://connect' 
        : _appUniversalLink;

    debugPrint('🔗 Using callback URL: $callbackUrl');

    switch (wallet.id) {
      case 'metamask':
        return await _launchMetaMaskWithCorrectFormat(wallet, callbackUrl);
      case 'trust':
        return await _launchTrustWalletWithCorrectFormat(wallet, callbackUrl);
      case 'phantom':
        return await _launchPhantomWithCorrectFormat(wallet, callbackUrl);
      case 'coinbase':
        return await _launchCoinbaseWithCorrectFormat(wallet, callbackUrl);
      case 'binance':
        return await _launchBinanceWithCorrectFormat(wallet, callbackUrl);
      default:
        return await _launchGenericWallet(wallet, callbackUrl);
    }
  }

  Future<bool> _launchMetaMaskWithCorrectFormat(WalletApp wallet, String callbackUrl) async {
    final encodedCallback = Uri.encodeComponent(callbackUrl);
    
    final formats = [
      // Primary format: dApp connection with address request
      'metamask://dapp/flashtransfer.app?address_request=true&callback=$encodedCallback&app_name=Flash%20Transfer&session=${_currentSessionId}',
      
      // Alternative format for different MetaMask versions
      'metamask://wc?uri=${Uri.encodeComponent('https://flashtransfer.app/connect?callback=$callbackUrl&session=${_currentSessionId}')}',
      
      // Simplified dApp format
      'metamask://dapp/flashtransfer.app',
      
      // Minimal format that opens MetaMask
      'metamask://dapp',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('🦊 Trying MetaMask format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ MetaMask launched with format ${i + 1}: $format');
          return true;
        } else {
          debugPrint('❌ MetaMask format ${i + 1} launch returned false');
        }
      } catch (e) {
        debugPrint('❌ MetaMask format ${i + 1} failed: $e');
      }
    }

    debugPrint('❌ All MetaMask formats failed');
    return false;
  }

  Future<bool> _launchTrustWalletWithCorrectFormat(WalletApp wallet, String callbackUrl) async {
    final connectUrl = 'https://flashtransfer.app/connect?callback=${Uri.encodeComponent(callbackUrl)}&session=${_currentSessionId}&wallet=trust';
    final encodedConnectUrl = Uri.encodeComponent(connectUrl);
    
    final formats = [
      'trust://open_url?url=$encodedConnectUrl',
      'trust://dapp_connect?url=$encodedConnectUrl',
      'trust://connect?callback=${Uri.encodeComponent(callbackUrl)}&app=Flash%20Transfer',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('🛡️ Trying Trust Wallet format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ Trust Wallet launched with format ${i + 1}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Trust Wallet format ${i + 1} failed: $e');
      }
    }

    return false;
  }

  Future<bool> _launchPhantomWithCorrectFormat(WalletApp wallet, String callbackUrl) async {
    final encodedCallback = Uri.encodeComponent(callbackUrl);
    
    final formats = [
      'phantom://connect?ref=$encodedCallback&app=Flash%20Transfer&redirect=$encodedCallback&session=${_currentSessionId}',
      'phantom://dapp/flashtransfer.app?callback=$encodedCallback',
      'phantom://connect?callback=$encodedCallback',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('👻 Trying Phantom format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ Phantom launched with format ${i + 1}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Phantom format ${i + 1} failed: $e');
      }
    }

    return false;
  }

  Future<bool> _launchCoinbaseWithCorrectFormat(WalletApp wallet, String callbackUrl) async {
    final encodedCallback = Uri.encodeComponent(callbackUrl);
    
    final formats = [
      'cbwallet://dapp/flashtransfer.app?callback=$encodedCallback&session=${_currentSessionId}',
      'cbwallet://connect?callback=$encodedCallback&app=Flash%20Transfer',
      'https://go.cb-w.com/dapp?cb_url=${Uri.encodeComponent('https://flashtransfer.app/connect?callback=$callbackUrl')}',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('🔵 Trying Coinbase format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ Coinbase launched with format ${i + 1}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Coinbase format ${i + 1} failed: $e');
      }
    }

    return false;
  }

  Future<bool> _launchBinanceWithCorrectFormat(WalletApp wallet, String callbackUrl) async {
    final encodedCallback = Uri.encodeComponent(callbackUrl);
    
    final formats = [
      'bnc://dapp?url=${Uri.encodeComponent('https://flashtransfer.app/connect?callback=$callbackUrl&session=${_currentSessionId}')}',
      'bnc://connect?callback=$encodedCallback&app=Flash%20Transfer',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('🟡 Trying Binance format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ Binance launched with format ${i + 1}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Binance format ${i + 1} failed: $e');
      }
    }

    return false;
  }

  Future<bool> _launchGenericWallet(WalletApp wallet, String callbackUrl) async {
    final encodedCallback = Uri.encodeComponent(callbackUrl);
    
    final formats = [
      '${wallet.scheme}connect?callback=$encodedCallback&app=Flash%20Transfer&session=${_currentSessionId}',
      '${wallet.scheme}dapp/flashtransfer.app?callback=$encodedCallback',
      '${wallet.scheme}open?url=${Uri.encodeComponent('https://flashtransfer.app/connect?callback=$callbackUrl')}',
    ];

    for (int i = 0; i < formats.length; i++) {
      final format = formats[i];
      debugPrint('🔗 Trying ${wallet.name} format ${i + 1}/${formats.length}: $format');
      
      try {
        final launched = await launchUrl(
          Uri.parse(format),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ ${wallet.name} launched with format ${i + 1}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ ${wallet.name} format ${i + 1} failed: $e');
      }
    }

    return false;
  }

  Map<String, dynamic> _getConnectionParams() {
    return {
      'action': 'connect',
      'nonce': _currentNonce,
      'session_id': _currentSessionId,
      'app_name': 'Flash Transfer',
      'app_id': _appPackageName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'request_address': true,
      'callback_url': Platform.isAndroid 
          ? 'flashtransferapp://connect' 
          : _appUniversalLink,
    };
  }

  Future<void> handleDeepLink(Uri uri) async {
    debugPrint('🔗 Enhanced deep link handler: ${uri.toString()}');
    debugPrint('📋 Query parameters: ${uri.queryParameters}');
    debugPrint('📋 Fragment: ${uri.fragment}');
    debugPrint('📋 Path segments: ${uri.pathSegments}');

    if (!_isConnectionInProgress || _connectCompleter == null) {
      debugPrint('⚠️ No active connection, but checking for passive wallet data');
      await _handlePassiveWalletData(uri);
      return;
    }

    try {
      final extractedData = _extractWalletDataFromUri(uri);
      
      if (extractedData == null) {
        debugPrint('❌ No wallet data extracted from URI');
        _completeWithError('No wallet address found in response');
        return;
      }

      final walletAddress = extractedData['address'];
      final signature = extractedData['signature'];
      final metadata = extractedData['metadata'];

      if (walletAddress == null || !_isValidWalletAddress(walletAddress)) {
        debugPrint('❌ Invalid wallet address: $walletAddress');
        _completeWithError('Invalid wallet address format');
        return;
      }

      // Save wallet data
      await _saveWalletData(walletAddress, _selectedWallet?.id, signature, metadata);

      // Complete connection
      if (!_connectCompleter!.isCompleted) {
        _connectCompleter!.complete(
          WalletConnectionResponse(
            connected: true,
            walletAddress: walletAddress,
            walletType: _selectedWallet?.id,
            signature: signature,
            metadata: metadata,
          ),
        );
      }

      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
      
      debugPrint('✅ Wallet connection completed successfully');
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
      _completeWithError('Error processing wallet response: ${e.toString()}');
    }
  }

  Map<String, dynamic>? _extractWalletDataFromUri(Uri uri) {
    try {
      Map<String, dynamic> extractedData = {};

      // Enhanced address extraction patterns
      final addressParams = [
        'address', 'wallet_address', 'account', 'accounts', 
        'publicAddress', 'public_address', 'accountId',
        'selectedAddress', 'walletaddress', 'eth_address',
        'solana_address', 'result', 'data', 'response'
      ];

      // Check query parameters
      for (final param in addressParams) {
        final value = uri.queryParameters[param];
        if (value != null && value.isNotEmpty) {
          extractedData['address'] = value;
          debugPrint('✅ Found address in query param "$param": $value');
          break;
        }
      }

      // Check fragment parameters
      if (extractedData['address'] == null && uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        for (final param in addressParams) {
          final value = fragmentParams[param];
          if (value != null && value.isNotEmpty) {
            extractedData['address'] = value;
            debugPrint('✅ Found address in fragment param "$param": $value');
            break;
          }
        }

        // Check if fragment itself is an address
        if (extractedData['address'] == null) {
          if (_isValidWalletAddress(uri.fragment)) {
            extractedData['address'] = uri.fragment;
            debugPrint('✅ Fragment is wallet address: ${uri.fragment}');
          }
        }
      }

      // Check path segments for addresses
      if (extractedData['address'] == null) {
        for (final segment in uri.pathSegments) {
          if (_isValidWalletAddress(segment)) {
            extractedData['address'] = segment;
            debugPrint('✅ Found address in path segment: $segment');
            break;
          }
        }
      }

      // Look for address patterns in the entire URI string
      if (extractedData['address'] == null) {
        final addressPatterns = [
          RegExp(r'0x[a-fA-F0-9]{40}'), // Ethereum
          RegExp(r'[1-9A-HJ-NP-Za-km-z]{32,44}'), // Solana/Bitcoin
        ];

        for (final pattern in addressPatterns) {
          final match = pattern.firstMatch(uri.toString());
          if (match != null) {
            extractedData['address'] = match.group(0);
            debugPrint('✅ Found address pattern: ${match.group(0)}');
            break;
          }
        }
      }

      // Extract signature if present
      final signatureParams = ['signature', 'sig', 'signed', 'message', 'sign'];
      for (final param in signatureParams) {
        final value = uri.queryParameters[param];
        if (value != null && value.isNotEmpty) {
          extractedData['signature'] = value;
          debugPrint('✅ Found signature: $value');
          break;
        }
      }

      // Extract session validation
      final sessionId = uri.queryParameters['session'] ?? uri.queryParameters['session_id'];
      if (sessionId == _currentSessionId) {
        debugPrint('✅ Session ID validated');
      } else if (sessionId != null) {
        debugPrint('⚠️ Session ID mismatch: expected $_currentSessionId, got $sessionId');
      }

      // Extract metadata
      extractedData['metadata'] = {
        'wallet_type': _identifyWalletFromUri(uri),
        'session_id': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'uri': uri.toString(),
      };

      return extractedData.isNotEmpty ? extractedData : null;
    } catch (e) {
      debugPrint('❌ Error extracting wallet data: $e');
      return null;
    }
  }

  String? _identifyWalletFromUri(Uri uri) {
    final uriString = uri.toString().toLowerCase();
    
    if (uriString.contains('metamask') || uri.scheme == 'metamask') return 'metamask';
    if (uriString.contains('trust') || uri.scheme == 'trust') return 'trust';
    if (uriString.contains('phantom') || uri.scheme == 'phantom') return 'phantom';
    if (uriString.contains('coinbase') || uri.scheme == 'cbwallet') return 'coinbase';
    if (uriString.contains('binance') || uri.scheme == 'bnc') return 'binance';
    
    return _selectedWallet?.id;
  }

  bool _isValidWalletAddress(String address) {
    // Ethereum address
    if (address.startsWith('0x') && address.length == 42) {
      return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
    }
    
    // Solana/Bitcoin address (more flexible validation)
    if (address.length >= 26 && address.length <= 44) {
      return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{26,44}$').hasMatch(address);
    }
    
    return false;
  }

  Future<void> _saveWalletData(String address, String? walletType, String? signature, Map<String, dynamic>? metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_address', address);
      
      if (walletType != null) {
        await prefs.setString('wallet_type', walletType);
      }
      
      if (signature != null) {
        await prefs.setString('wallet_signature', signature);
      }
      
      if (metadata != null) {
        await prefs.setString('wallet_metadata', jsonEncode(metadata));
      }
      
      debugPrint('💾 Wallet data saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving wallet data: $e');
    }
  }

  Future<void> _handlePassiveWalletData(Uri uri) async {
    try {
      final extractedData = _extractWalletDataFromUri(uri);
      if (extractedData != null && extractedData['address'] != null) {
        await _saveWalletData(
          extractedData['address'],
          extractedData['metadata']?['wallet_type'],
          extractedData['signature'],
          extractedData['metadata'],
        );
        debugPrint('💾 Passive wallet data saved');
      }
    } catch (e) {
      debugPrint('❌ Error handling passive wallet data: $e');
    }
  }

  Future<void> _showManualAddressInputDialog(BuildContext context) async {
    if (!_isConnectionInProgress || 
        _connectCompleter == null || 
        _connectCompleter!.isCompleted ||
        !context.mounted) {
      return;
    }

    debugPrint('📝 Showing manual address input dialog for ${_selectedWallet?.name}');

    final TextEditingController controller = TextEditingController();
    bool isValidating = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: _selectedWallet?.color ?? Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Connect ${_selectedWallet?.name ?? 'Wallet'}'),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedWallet?.name ?? 'Your wallet'} didn\'t return your address automatically.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please copy your wallet address and paste it below:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: _selectedWallet?.id == 'phantom' 
                          ? 'Solana address...' 
                          : '0x... (Ethereum address)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      suffixIcon: isValidating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (value.length > 10) {
                        setState(() {
                          isValidating = true;
                        });
                        
                        // Simulate validation delay
                        Timer(const Duration(milliseconds: 500), () {
                          if (context.mounted) {
                            setState(() {
                              isValidating = false;
                            });
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.blue.shade600, 
                             size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Open ${_selectedWallet?.name ?? 'your wallet'} app, copy your address, and paste it here.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isValidating || controller.text.trim().isEmpty
                      ? null
                      : () {
                          if (controller.text.trim().isNotEmpty) {
                            Navigator.of(context).pop(true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedWallet?.color ?? Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Connect'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final address = controller.text.trim();
      
      if (_isValidWalletAddress(address)) {
        debugPrint('✅ Manual address validated: $address');
        
        await _saveWalletData(address, _selectedWallet?.id, null, {
          'manual_entry': true,
          'timestamp': DateTime.now().toIso8601String(),
        });

        if (!_connectCompleter!.isCompleted) {
          _connectCompleter!.complete(
            WalletConnectionResponse(
              connected: true,
              walletAddress: address,
              walletType: _selectedWallet?.id,
              metadata: {'manual_entry': true},
            ),
          );
        }

        _isConnectionInProgress = false;
        _cancelTimeoutTimer();
      } else {
        debugPrint('❌ Invalid manual address: $address');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Invalid wallet address format. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          // Show dialog again
          await _showManualAddressInputDialog(context);
        }
      }
    } else {
      debugPrint('❌ Manual address input cancelled');
      _completeWithError('Connection cancelled by user');
    }
  }

  String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecond % 10000).toString();
    final data = utf8.encode('$timestamp:$random:${_currentSessionId}');
    return sha256.convert(data).toString().substring(0, 16);
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecond % 10000).toString();
    final data = utf8.encode('flash_transfer:$timestamp:$random');
    return sha256.convert(data).toString().substring(0, 12);
  }

  void _startConnectionTimeoutTimer() {
    _cancelTimeoutTimer();
    debugPrint('⏰ Starting connection timeout timer (3 minutes)');
    _connectionTimeoutTimer = Timer(const Duration(minutes: 3), () {
      if (_isConnectionInProgress) {
        debugPrint('⏰ Connection timeout reached');
        _completeWithError('Connection timed out after 3 minutes. Please try again.');
      }
    });
  }

  void _cancelTimeoutTimer() {
    if (_connectionTimeoutTimer != null && _connectionTimeoutTimer!.isActive) {
      _connectionTimeoutTimer!.cancel();
      _connectionTimeoutTimer = null;
      debugPrint('⏰ Connection timeout timer cancelled');
    }
  }

  void _completeWithError(String error) {
    debugPrint('❌ Connection error: $error');
    _isConnectionInProgress = false;
    _cancelTimeoutTimer();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(
        WalletConnectionResponse(connected: false, error: error),
      );
    }
  }

  Future<bool> disconnectWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_address');
      await prefs.remove('wallet_type');
      await prefs.remove('wallet_signature');
      await prefs.remove('wallet_metadata');
      
      debugPrint('✅ Wallet disconnected and data cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error disconnecting wallet: $e');
      return false;
    }
  }

  void dispose() {
    debugPrint('🧹 Disposing EnhancedDirectWalletService');
    _cancelTimeoutTimer();
    _isConnectionInProgress = false;
    
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(
        WalletConnectionResponse(connected: false, error: 'Service disposed'),
      );
    }
  }
}