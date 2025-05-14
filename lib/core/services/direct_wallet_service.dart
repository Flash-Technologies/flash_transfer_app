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

  WalletConnectionResponse({
    required this.connected,
    this.walletAddress,
    this.walletType,
    this.error,
    this.signature,
  });
}

class DirectWalletService {
  Completer<WalletConnectionResponse>? _connectCompleter;

  Timer? _connectionTimeoutTimer;

  bool _isConnectionInProgress = false;

  WalletApp? _selectedWallet;

  String? _currentNonce;

  final String _appPackageName;

  final String _appUniversalLink;

  static const _channel = MethodChannel(
    'com.flash_transfer_app.wallet_channel',
  );

  DirectWalletService({
    required String appPackageName,
    required String appUniversalLink,
  }) : _appPackageName = appPackageName,
       _appUniversalLink = appUniversalLink;

  bool get isConnecting => _isConnectionInProgress;

  Future<WalletConnectionResponse> connectWallet(BuildContext context) async {
    if (_isConnectionInProgress) {
      return WalletConnectionResponse(
        connected: false,
        error: 'A wallet connection is already in progress',
      );
    }

    _isConnectionInProgress = true;

    try {
      final selectedWallet = await WalletSelectorSheet.show(context);

      if (selectedWallet == null) {
        _isConnectionInProgress = false;
        return WalletConnectionResponse(
          connected: false,
          error: 'No wallet selected',
        );
      }

      _selectedWallet = selectedWallet;

      _currentNonce = _generateNonce();

      _connectCompleter = Completer<WalletConnectionResponse>();

      _startConnectionTimeoutTimer();

      final launchResult = await _launchWalletApp(selectedWallet);

      if (!launchResult) {
        _isConnectionInProgress = false;
        _cancelTimeoutTimer();
        return WalletConnectionResponse(
          connected: false,
          error: 'Failed to launch ${selectedWallet.name}',
        );
      }

      if (selectedWallet.id == 'metamask') {
        Future.delayed(const Duration(seconds: 15), () {
          if (_isConnectionInProgress &&
              _connectCompleter != null &&
              !_connectCompleter!.isCompleted) {
            _showManualAddressInputDialog(context);
          }
        });
      }

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

  Future<void> handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link from wallet: ${uri.toString()}');

    if (!_isConnectionInProgress || _connectCompleter == null) {
      debugPrint(
        'Received deep link but no connection is in progress. Checking for wallet data anyway.',
      );

      try {
        String? walletAddressNullable = _extractAddressFromUri(uri);
        if (walletAddressNullable != null) {
          String walletAddress = walletAddressNullable;
          if (_isValidWalletAddress(walletAddress)) {
            debugPrint(
              'Found valid wallet address from passive connection: $walletAddress',
            );

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('wallet_address', walletAddress);

            String? walletType;
            if (uri.scheme == 'metamask' ||
                uri.toString().contains('metamask')) {
              walletType = 'metamask';
            } else if (uri.scheme == 'trust' ||
                uri.toString().contains('trust')) {
              walletType = 'trust';
            } else if (uri.scheme == 'phantom' ||
                uri.toString().contains('phantom')) {
              walletType = 'phantom';
            }

            if (walletType != null) {
              await prefs.setString('wallet_type', walletType);
            }
          }
        }
      } catch (e) {
        debugPrint('Error handling passive wallet connection: $e');
      }

      return;
    }

    try {
      String? walletAddressNullable = _extractAddressFromUri(uri);
      String? signature;

      if (walletAddressNullable != null) {
        final possibleSignatureParams = [
          'signature',
          'sig',
          'signed',
          'message',
        ];
        for (final param in possibleSignatureParams) {
          final value = uri.queryParameters[param];
          if (value != null && value.isNotEmpty) {
            signature = value;
            debugPrint('Found signature in param "$param": $signature');
            break;
          }
        }
      }

      String? walletAddress;
      if (walletAddressNullable != null) {
        walletAddress = walletAddressNullable;
      } else {
        debugPrint(
          'No wallet address found in response. URI: ${uri.toString()}',
        );

        if (uri.toString().contains('metamask') ||
            (_selectedWallet?.id == 'metamask')) {
          debugPrint(
            'MetaMask detected, trying to retrieve address via clipboard fallback...',
          );

          ClipboardData? clipboardData = await Clipboard.getData(
            Clipboard.kTextPlain,
          );
          if (clipboardData?.text != null) {
            String clipText = clipboardData!.text!;

            if (clipText.startsWith('0x') && clipText.length == 42) {
              walletAddress = clipText;
              debugPrint(
                'Found potential wallet address in clipboard: $walletAddress',
              );
            }
          }

          if (walletAddress == null) {
            _completeWithError(
              'No wallet address found from MetaMask. Please try connecting again or enter address manually.',
            );
            return;
          }
        } else {
          _completeWithError(
            'No wallet address found in response. URI: ${uri.toString()}',
          );
          return;
        }
      }

      if (walletAddress == null) {
        _completeWithError('Wallet address is null');
        return;
      }

      if (!_isValidWalletAddress(walletAddress)) {
        _completeWithError('Invalid wallet address format: $walletAddress');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wallet_address', walletAddress);
      if (_selectedWallet != null) {
        await prefs.setString('wallet_type', _selectedWallet!.id);
      }

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

  bool _isValidWalletAddress(String address) {
    if (address.startsWith('0x') && address.length == 42) {
      return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address);
    }

    if (address.length >= 32) {
      return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(address);
    }

    debugPrint('Warning: Wallet address has unexpected format: $address');
    return true;
  }

  Future<bool> isWalletInstalled(WalletApp wallet) async {
    try {
      if (Platform.isAndroid) {
        final canLaunchScheme = await canLaunchUrl(Uri.parse(wallet.scheme));
        if (canLaunchScheme) return true;

        final androidIntent = Uri.parse(
          'android-app://${wallet.androidPackage}',
        );
        return await canLaunchUrl(androidIntent);
      } else if (Platform.isIOS) {
        return await canLaunchUrl(Uri.parse(wallet.scheme));
      }
      return false;
    } catch (e) {
      debugPrint("Error checking if ${wallet.name} is installed: $e");
      return false;
    }
  }

  Future<Map<String, bool>> getInstalledWallets(List<WalletApp> wallets) async {
    Map<String, bool> results = {};

    for (var wallet in wallets) {
      final isInstalled = await isWalletInstalled(wallet);
      results[wallet.id] = isInstalled;
    }

    return results;
  }

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

  Future<bool> _launchWalletApp(WalletApp wallet) async {
    try {
      final nonce = _currentNonce;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final callbackUrl =
          Platform.isAndroid ? 'flashtransferapp://connect' : _appUniversalLink;

      Map<String, dynamic> params = {
        'action': 'connect',
        'nonce': nonce,
        'callback': callbackUrl,
        'timestamp': timestamp,
        'app_id': 'com.flash_transfer_app',
        'app_name': 'Flash Transfer',
      };

      debugPrint(
        'Attempting to launch ${wallet.name} with params: ${jsonEncode(params)}',
      );

      bool launched = false;

      if (wallet.id == 'metamask') {
        try {
          if (Platform.isAndroid) {
            final String uri = '${wallet.scheme}dapp/https://flashtransfer.app';
            debugPrint('Launching MetaMask with correct URI format: $uri');

            launched = await launchUrl(
              Uri.parse(uri),
              mode: LaunchMode.externalApplication,
            );
            debugPrint('MetaMask launch result: $launched');

            if (launched) {
              return true;
            }

            final String minimalUri = '${wallet.scheme}dapp';
            debugPrint('Trying minimal URI format: $minimalUri');

            launched = await launchUrl(
              Uri.parse(minimalUri),
              mode: LaunchMode.externalApplication,
            );

            if (launched) {
              debugPrint('Minimal URI launch successful');
              return true;
            }
          } else if (Platform.isIOS) {
            final String uri = '${wallet.scheme}dapp/flashtransfer.app';
            debugPrint('Launching MetaMask iOS with URI: $uri');

            launched = await launchUrl(
              Uri.parse(uri),
              mode: LaunchMode.externalApplication,
            );

            if (launched) {
              return true;
            }
          }
        } catch (e) {
          debugPrint('MetaMask specific launch failed: $e');
        }
      } else if (wallet.id == 'trust') {
        try {
          final String uri =
              '${wallet.scheme}open_url?url=${Uri.encodeComponent('https://flashtransfer.app/connect?params=${Uri.encodeComponent(jsonEncode(params))}')}';

          launched = await launchUrl(
            Uri.parse(uri),
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            return true;
          }
        } catch (e) {
          debugPrint('Trust wallet specific launch failed: $e');
        }
      } else if (wallet.id == 'phantom') {
        try {
          params['solana'] = true;

          final String uri =
              '${wallet.scheme}connect?ref=${Uri.encodeComponent(callbackUrl)}&app=Flash%20Transfer&redirect=${Uri.encodeComponent(callbackUrl)}';

          launched = await launchUrl(
            Uri.parse(uri),
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            return true;
          }
        } catch (e) {
          debugPrint('Phantom specific launch failed: $e');
        }
      }

      if (!launched) {
        final paramsJson = jsonEncode(params);

        try {
          String scheme = wallet.scheme;
          if (!scheme.endsWith('/') && !scheme.endsWith('//')) {
            scheme += '//';
          }

          final schemeUri = Uri.parse(
            '${scheme}connect?${Uri.encodeQueryComponent(paramsJson)}',
          );
          launched = await launchUrl(
            schemeUri,
            mode: LaunchMode.externalApplication,
          );
          debugPrint('Wallet-specific scheme launch result: $launched');
        } catch (e) {
          debugPrint('Wallet-specific scheme failed: $e');
        }
      }

      if (!launched) {
        try {
          final Map<String, dynamic> args = {
            'wallet_id': wallet.id,
            'wallet_package': wallet.androidPackage,
            'wallet_scheme': wallet.scheme,
            'params': jsonEncode(params),
          };

          final result = await _channel.invokeMethod('launchWallet', args);
          launched = result == true;
          debugPrint('Native channel launch result: $launched');
        } catch (e) {
          debugPrint('Native channel launch failed: $e');
        }
      }

      if (!launched) {
        final clipboardData =
            'Flash Transfer Wallet Connect Request:\n'
            'Nonce: $_currentNonce\n'
            'Please connect your wallet and enter this address manually in the app.';

        await Clipboard.setData(ClipboardData(text: clipboardData));
        debugPrint(
          'All wallet launch attempts failed. Copied data to clipboard.',
        );
      }

      return launched;
    } catch (e) {
      debugPrint('Error launching wallet: $e');
      return false;
    }
  }

  String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (1000 + DateTime.now().millisecond).toString();
    final data = utf8.encode('$timestamp:$random');
    final hash = sha256.convert(data);
    return hash.toString().substring(0, 16);
  }

  void _startConnectionTimeoutTimer() {
    _cancelTimeoutTimer();
    _connectionTimeoutTimer = Timer(const Duration(minutes: 2), () {
      _completeWithError('Connection timed out. Please try again.');
    });
  }

  void _cancelTimeoutTimer() {
    if (_connectionTimeoutTimer != null && _connectionTimeoutTimer!.isActive) {
      _connectionTimeoutTimer!.cancel();
      _connectionTimeoutTimer = null;
    }
  }

  void _completeWithError(String error) {
    _isConnectionInProgress = false;
    _cancelTimeoutTimer();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(
        WalletConnectionResponse(connected: false, error: error),
      );
    }
  }

  void dispose() {
    _cancelTimeoutTimer();
  }

  String? _extractAddressFromUri(Uri uri) {
    try {
      final possibleAddressParams = [
        'address',
        'wallet_address',
        'account',
        'accountId',
        'publicAddress',
        'public_address',
      ];

      for (final param in possibleAddressParams) {
        final value = uri.queryParameters[param];
        if (value != null && value.isNotEmpty) {
          debugPrint('Found wallet address in param "$param": $value');
          return value;
        }
      }

      if (uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        for (final param in possibleAddressParams) {
          final value = fragmentParams[param];
          if (value != null && value.isNotEmpty) {
            debugPrint(
              'Found wallet address in fragment param "$param": $value',
            );
            return value;
          }
        }
      }

      if (uri.pathSegments.isNotEmpty) {
        for (final segment in uri.pathSegments) {
          if (segment.startsWith('0x') && segment.length >= 40) {
            debugPrint('Found wallet address in path segment: $segment');
            return segment;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting address from URI: $e');
      return null;
    }
  }

  Future<void> _showManualAddressInputDialog(BuildContext context) async {
    if (!_isConnectionInProgress ||
        _connectCompleter == null ||
        _connectCompleter!.isCompleted) {
      return;
    }

    final TextEditingController controller = TextEditingController();

    final addressEntered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Wallet Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'It seems MetaMask didn\'t redirect back automatically.\n\n'
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

    if (addressEntered == true && controller.text.isNotEmpty) {
      final walletAddress = controller.text.trim();

      if (_isValidWalletAddress(walletAddress)) {
        if (!_connectCompleter!.isCompleted) {
          _connectCompleter!.complete(
            WalletConnectionResponse(
              connected: true,
              walletAddress: walletAddress,
              walletType: _selectedWallet?.id,
            ),
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wallet_address', walletAddress);
        if (_selectedWallet != null) {
          await prefs.setString('wallet_type', _selectedWallet!.id);
        }

        _isConnectionInProgress = false;
        _cancelTimeoutTimer();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid wallet address format')),
          );

          _showManualAddressInputDialog(context);
        }
      }
    } else {
      _completeWithError('Wallet connection cancelled by user');
    }
  }
}
