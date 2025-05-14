import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Manages MetaMask connection functionality
class MetaMaskService {
  // Method channel for native integration
  static const _channel = MethodChannel(
    'com.flash_transfer_app.wallet_channel',
  );

  // Callback URL for return deep link (Android vs iOS)
  final String _callbackUrl =
      Platform.isAndroid
          ? 'flashtransferapp://connect'
          : 'https://flashtransfer.app/connect';

  // Completer to handle async wallet connection flow
  Completer<String?>? _connectCompleter;

  // Timeout timer
  Timer? _connectionTimeoutTimer;

  // Connection state
  bool _isConnecting = false;

  // Current connection session
  String? _sessionId;

  // Constructor
  MetaMaskService();

  /// Check if MetaMask is installed on the device
  Future<bool> isMetaMaskInstalled() async {
    try {
      if (Platform.isAndroid) {
        // Try to check package existence via native channel
        try {
          final bool installed =
              await _channel.invokeMethod<bool>('isPackageInstalled', {
                'package_name': 'io.metamask',
              }) ??
              false;

          if (installed) return true;
        } catch (e) {
          debugPrint('Error checking package via native: $e');
          // Fall back to URL launcher check
        }

        // Check if metamask:// URL can be launched
        return await canLaunchUrl(Uri.parse('metamask://'));
      } else if (Platform.isIOS) {
        // Check URL scheme
        return await canLaunchUrl(Uri.parse('metamask://'));
      }
      return false;
    } catch (e) {
      debugPrint('Error checking MetaMask installation: $e');
      return false;
    }
  }

  /// Connect to MetaMask and get the wallet address
  Future<String?> connectToMetaMask(BuildContext context) async {
    // Cancel any existing connection attempt
    if (_isConnecting) {
      _cancelConnection();
    }

    _isConnecting = true;
    _connectCompleter = Completer<String?>();

    // Generate unique session ID for this connection attempt
    _sessionId = _generateSessionId();

    // Start timeout
    _startTimeoutTimer();

    debugPrint('🔑 Starting MetaMask connection process');

    try {
      // Check if MetaMask is installed
      final isInstalled = await isMetaMaskInstalled();
      if (!isInstalled) {
        debugPrint('❌ MetaMask is not installed on this device');
        _completeWithError('MetaMask is not installed');
        return null;
      }

      debugPrint('✅ MetaMask is installed, launching app');

      // Launch MetaMask with specific deep link format
      final launched = await _launchMetaMask();

      if (!launched) {
        debugPrint('❌ Failed to launch MetaMask');
        _completeWithError('Failed to launch MetaMask');
        return null;
      }

      debugPrint('⏳ Waiting for MetaMask to return result');

      // Start a short timer to show the manual input dialog as a fallback
      // This timer is much shorter now since we're having issues with the prompt
      Timer(const Duration(seconds: 3), () {
        if (_isConnecting &&
            _connectCompleter != null &&
            !_connectCompleter!.isCompleted &&
            context.mounted) {
          debugPrint(
            '⏱️ MetaMask prompt not detected - showing manual input dialog',
          );
          _showManualInputDialog(context);
        }
      });

      // Wait for result with timeout
      return await _connectCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          debugPrint('⏱️ Connection timed out after 2 minutes');
          _isConnecting = false;
          if (context.mounted) {
            _showManualInputDialog(context);
          }
          return null;
        },
      );
    } catch (e) {
      debugPrint('❌ Error connecting to MetaMask: $e');
      _completeWithError('Error connecting to MetaMask: $e');
      return null;
    }
  }

  /// Launch MetaMask with the correct deep link format
  Future<bool> _launchMetaMask() async {
    try {
      debugPrint('⭐ MetaMask connect attempt initiated');

      if (Platform.isAndroid) {
        debugPrint('📱 Running on Android');

        // Try with web3 specific format that explicitly requests connection
        // This format is specifically for connecting to a dapp, which is what we need
        final web3ConnectUri =
            'metamask://wc?uri=https://flashtransfer.app/connect';

        debugPrint('🚀 Trying web3 connection format: $web3ConnectUri');

        bool launched = false;
        try {
          launched = await launchUrl(
            Uri.parse(web3ConnectUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ Web3 format launch successful'
                : '❌ Web3 format launch failed',
          );

          if (launched) return true;
        } catch (e) {
          debugPrint('⚠️ Error with web3 format: $e');
        }

        // Try format with explicit ethereum uri
        final ethereumUri = 'ethereum:wc?uri=https://flashtransfer.app/connect';

        debugPrint('🚀 Trying ethereum URI scheme: $ethereumUri');

        try {
          launched = await launchUrl(
            Uri.parse(ethereumUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ Ethereum scheme successful'
                : '❌ Ethereum scheme failed',
          );

          if (launched) return true;
        } catch (e) {
          debugPrint('⚠️ Error with ethereum scheme: $e');
        }

        // Try with basic scheme (should at least open MetaMask)
        final simpleUri = 'metamask://dapp/https://flashtransfer.app';

        debugPrint('🚀 Trying simplified format: $simpleUri');

        try {
          launched = await launchUrl(
            Uri.parse(simpleUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ Simple format launch successful'
                : '❌ Simple format launch failed',
          );

          if (launched) return true;
        } catch (e) {
          debugPrint('⚠️ Error with simple format: $e');
        }

        // Try format with explicit chain ID
        final chainSpecificUri =
            'metamask://dapp/https://flashtransfer.app?chainId=1';

        debugPrint('🚀 Trying with chain specification: $chainSpecificUri');

        try {
          launched = await launchUrl(
            Uri.parse(chainSpecificUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ Chain-specific format successful'
                : '❌ Chain-specific format failed',
          );

          if (launched) return true;
        } catch (e) {
          debugPrint('⚠️ Error with chain-specific format: $e');
        }

        // Try Web-Connect compatible format (works with newer MetaMask versions)
        final wcUri =
            'metamask://wc?uri=wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@1?bridge=https://flashtransfer.app&key=123456789';

        debugPrint('🚀 Trying WalletConnect format: $wcUri');

        try {
          launched = await launchUrl(
            Uri.parse(wcUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ WalletConnect format successful'
                : '❌ WalletConnect format failed',
          );

          if (launched) return true;
        } catch (e) {
          debugPrint('⚠️ Error with WalletConnect format: $e');
        }

        // Try a minimal format known to open MetaMask
        final minimalUri = 'metamask://dapp';

        debugPrint('🚀 Trying minimal format: $minimalUri');

        try {
          launched = await launchUrl(
            Uri.parse(minimalUri),
            mode: LaunchMode.externalApplication,
          );

          debugPrint(
            launched
                ? '✅ Minimal format successful'
                : '❌ Minimal format failed',
          );

          if (launched) {
            // If we get here, we've opened MetaMask but might not have triggered the prompt
            // Immediately show manual address input dialog after a short delay
            Timer(const Duration(seconds: 5), () {
              if (_isConnecting &&
                  _connectCompleter != null &&
                  !_connectCompleter!.isCompleted) {
                debugPrint(
                  '🔍 No prompt detected, showing manual input dialog',
                );
                return; // Will show manual dialog via the timeout in connectToMetaMask
              }
            });
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Error with minimal format: $e');
        }

        return false;
      } else if (Platform.isIOS) {
        debugPrint('📱 Running on iOS');

        // iOS deep linking to MetaMask - try multiple formats
        final formats = [
          'metamask://dapp/flashtransfer.app',
          'metamask://wc?uri=https://flashtransfer.app/connect',
          'https://metamask.app.link/dapp/flashtransfer.app',
          'ethereum:wc?uri=https://flashtransfer.app/connect',
        ];

        for (final uri in formats) {
          debugPrint('🚀 Trying iOS format: $uri');

          try {
            final launched = await launchUrl(
              Uri.parse(uri),
              mode: LaunchMode.externalApplication,
            );

            debugPrint(
              launched ? '✅ Format successful: $uri' : '❌ Format failed: $uri',
            );

            if (launched) return true;
          } catch (e) {
            debugPrint('⚠️ Error with format $uri: $e');
          }
        }

        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error launching MetaMask: $e');
      return false;
    }
  }

  /// Handle incoming deep link from MetaMask
  Future<void> handleDeepLink(Uri uri) async {
    debugPrint('🔄 MetaMask deep link received: ${uri.toString()}');

    if (!_isConnecting ||
        _connectCompleter == null ||
        _connectCompleter!.isCompleted) {
      debugPrint('⚠️ No active MetaMask connection session');
      return;
    }

    try {
      // Debug log entire URI and structure
      debugPrint('🔍 URI scheme: ${uri.scheme}');
      debugPrint('🔍 URI host: ${uri.host}');
      debugPrint('🔍 URI path: ${uri.path}');
      debugPrint('🔍 URI query: ${uri.query}');
      debugPrint('🔍 URI fragment: ${uri.fragment}');

      // Log all query parameters
      debugPrint('🔍 Query parameters:');
      uri.queryParameters.forEach((key, value) {
        debugPrint('  - $key: $value');
      });

      // Extract wallet address from the URI
      String? walletAddress = _extractWalletAddress(uri);

      if (walletAddress == null) {
        debugPrint(
          '⚠️ No wallet address found in URI, checking full URI: ${uri.toString()}',
        );

        // If we can't extract it normally, check if the address might be in the URI string itself
        final uriString = uri.toString();
        final addressPattern = RegExp(r'0x[a-fA-F0-9]{40}');
        final match = addressPattern.firstMatch(uriString);

        if (match != null) {
          walletAddress = match.group(0);
          debugPrint('✅ Found address pattern in URI string: $walletAddress');
        } else {
          debugPrint('❌ No wallet address pattern found in URI string');

          // Immediately show manual dialog since we couldn't find the address
          if (!_connectCompleter!.isCompleted) {
            // No need to wait - show dialog immediately if we can't find address
            // Don't complete the completer yet - the dialog will do that
            debugPrint('📝 Showing manual address input dialog immediately');
            return;
          }
        }
      }

      // Verify it's a valid address
      if (walletAddress != null && _isValidEthereumAddress(walletAddress)) {
        debugPrint('✅ Valid Ethereum address found: $walletAddress');

        // Store the address for later use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wallet_address', walletAddress);
        await prefs.setString('wallet_type', 'metamask');

        // Complete the connection
        if (!_connectCompleter!.isCompleted) {
          debugPrint('✅ Completing connection with address');
          _connectCompleter!.complete(walletAddress);
        }

        _isConnecting = false;
        _cancelTimeoutTimer();
      } else {
        debugPrint('❌ Invalid Ethereum address: $walletAddress');
      }
    } catch (e) {
      debugPrint('❌ Error handling MetaMask deep link: $e');
      _completeWithError('Error handling MetaMask deep link: $e');
    }
  }

  /// Extract the wallet address from the deep link URI
  String? _extractWalletAddress(Uri uri) {
    try {
      debugPrint('Extracting wallet address from URI: ${uri.toString()}');

      // MetaMask mobile commonly returns the address in these query parameters
      final commonParams = [
        'address',
        'wallet_address',
        'account',
        'accounts',
        'result',
        'ethereum_address',
        'selectedAddress',
        'walletaddress',
      ];

      // First check query parameters for common format
      for (final param in commonParams) {
        if (uri.queryParameters.containsKey(param)) {
          final value = uri.queryParameters[param];
          debugPrint('Found in query param $param: $value');
          return value;
        }
      }

      // Check if the address is in the path segments
      // Some versions of MetaMask include the address as a path segment
      final pathSegments = uri.pathSegments;
      for (final segment in pathSegments) {
        if (segment.startsWith('0x') && segment.length == 42) {
          debugPrint('Found in path segment: $segment');
          return segment;
        }
      }

      // Check fragment (hash part of URL)
      if (uri.fragment.isNotEmpty) {
        // If the fragment contains query params
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        for (final param in commonParams) {
          if (fragmentParams.containsKey(param)) {
            final value = fragmentParams[param];
            debugPrint('Found in fragment param $param: $value');
            return value;
          }
        }

        // If fragment itself looks like an address
        if (uri.fragment.startsWith('0x') && uri.fragment.length == 42) {
          debugPrint('Fragment is address: ${uri.fragment}');
          return uri.fragment;
        }
      }

      // Check if there's a JSON structure in any parameter that might contain the address
      for (final entry in uri.queryParameters.entries) {
        try {
          final value = entry.value;
          // Try to parse as JSON
          if (value.startsWith('{') || value.startsWith('[')) {
            final decoded = jsonDecode(value);
            // Check different possible formats
            if (decoded is Map) {
              for (final param in commonParams) {
                if (decoded.containsKey(param)) {
                  final address = decoded[param];
                  debugPrint('Found in JSON param $param: $address');
                  return address.toString();
                }
              }
            } else if (decoded is List && decoded.isNotEmpty) {
              // If it's a list of addresses, take the first one
              final firstItem = decoded[0];
              if (firstItem is String && firstItem.startsWith('0x')) {
                debugPrint('Found in JSON array: $firstItem');
                return firstItem;
              }
            }
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting wallet address: $e');
      return null;
    }
  }

  /// Show manual address input dialog if MetaMask doesn't redirect back
  Future<void> _showManualInputDialog(BuildContext context) async {
    debugPrint('📝 Showing manual address input dialog');
    if (!context.mounted ||
        !_isConnecting ||
        _connectCompleter == null ||
        _connectCompleter!.isCompleted) {
      debugPrint(
        '⚠️ Cannot show dialog: context not mounted or connection already completed',
      );
      return;
    }

    // Controller for the text input
    final TextEditingController controller = TextEditingController();

    // Create alert dialog
    final addressEntered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter MetaMask Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MetaMask did not return your address automatically.\n\n'
                'Please copy your wallet address from MetaMask and paste it below:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );

    debugPrint('📝 Manual dialog result: $addressEntered');

    if (addressEntered == true && controller.text.isNotEmpty) {
      final walletAddress = controller.text.trim();
      debugPrint('📝 Manual address entered: $walletAddress');

      // Validate the wallet address
      if (_isValidEthereumAddress(walletAddress)) {
        debugPrint('✅ Valid address format, completing connection');

        // Complete the connection with the manually entered address
        if (!_connectCompleter!.isCompleted) {
          _connectCompleter!.complete(walletAddress);
        }

        // Store the wallet address
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wallet_address', walletAddress);
        await prefs.setString('wallet_type', 'metamask');

        _isConnecting = false;
        _cancelTimeoutTimer();
      } else {
        // Show error for invalid address format
        debugPrint('❌ Invalid address format');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid wallet address format')),
          );

          // Show the dialog again
          _showManualInputDialog(context);
        }
      }
    } else {
      // User cancelled, complete with error
      debugPrint('❌ User cancelled manual address input');
      _completeWithError('Wallet connection cancelled by user');
    }
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (1000 + DateTime.now().millisecond).toString();
    final data = utf8.encode('$timestamp:$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }

  /// Start connection timeout timer
  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (_isConnecting &&
          _connectCompleter != null &&
          !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete(null);
        _isConnecting = false;
      }
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// Cancel the current connection attempt
  void _cancelConnection() {
    _isConnecting = false;
    _cancelTimeoutTimer();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(null);
    }
  }

  /// Complete with error
  void _completeWithError(String error) {
    debugPrint('MetaMask connection error: $error');
    _isConnecting = false;
    _cancelTimeoutTimer();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(null);
    }
  }

  /// Validate Ethereum address format
  bool _isValidEthereumAddress(String address) {
    // Basic Ethereum address validation (0x followed by 40 hex characters)
    return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
  }

  /// Clean up resources
  void dispose() {
    _cancelTimeoutTimer();
    _cancelConnection();
  }
}
