import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:app_links/app_links.dart';

class WalletService {
  WalletConnect? _connector;
  SessionStatus? _session;
  StreamSubscription? _appLinksSubscription;
  final AppLinks _appLinks = AppLinks();

  // Map of supported wallets with their package/app IDs and schemes
  final Map<String, WalletApp> _walletApps = {
    'metamask': WalletApp(
      name: 'MetaMask',
      icon: Icons.account_balance_wallet,
      androidPackage: 'io.metamask',
      iOSAppId: 'id1438144202',
      universalLink: 'https://metamask.app.link',
      scheme: 'metamask://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=io.metamask',
      storeUrlIOS: 'https://apps.apple.com/app/metamask/id1438144202',
    ),
    'trust': WalletApp(
      name: 'Trust Wallet',
      icon: Icons.security,
      androidPackage: 'com.wallet.crypto.trustapp',
      iOSAppId: 'id1288339409',
      universalLink: 'https://link.trustwallet.com',
      scheme: 'trust://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.wallet.crypto.trustapp',
      storeUrlIOS:
          'https://apps.apple.com/app/trust-crypto-bitcoin-wallet/id1288339409',
    ),
    'phantom': WalletApp(
      name: 'Phantom',
      icon: Icons.wallet,
      androidPackage: 'app.phantom',
      iOSAppId: 'id1598432977',
      universalLink: 'https://phantom.app',
      scheme: 'phantom://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=app.phantom',
      storeUrlIOS:
          'https://apps.apple.com/app/phantom-crypto-wallet/id1598432977',
    ),
    'binance': WalletApp(
      name: 'Binance Wallet',
      icon: Icons.monetization_on,
      androidPackage: 'com.binance.dev',
      iOSAppId: 'id1436799971',
      universalLink: 'https://binance.com',
      scheme: 'bnc://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.binance.dev',
      storeUrlIOS:
          'https://apps.apple.com/app/binance-buy-bitcoin-crypto/id1436799971',
    ),
    'coinbase': WalletApp(
      name: 'Coinbase Wallet',
      icon: Icons.account_balance_wallet,
      androidPackage: 'org.toshi',
      iOSAppId: 'id1278383455',
      universalLink: 'https://wallet.coinbase.com',
      scheme: 'coinbase://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=org.toshi',
      storeUrlIOS: 'https://apps.apple.com/app/coinbase-wallet/id1278383455',
    ),
  };

  // Completer to handle async wallet connection flow
  Completer<ConnectResponse>? _connectCompleter;
  Timer? _connectionTimeoutTimer;
  bool _isConnectionInProgress = false;

  WalletService() {
    _initWalletConnect();
  }

  void _initWalletConnect() {
    try {
      // Create a connector
      _connector = WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        clientMeta: const PeerMeta(
          name: 'Flash Transfer',
          description: 'Flash Transfer Mobile App - Send and Receive Money',
          url: 'https://flash-transfer.com',
          icons: ['https://flash-transfer.com/logo.png'],
        ),
      );

      // Subscribe to session status changes
      _connector?.registerListeners(
        onConnect: (session) {
          debugPrint("✅ WALLET CONNECTED! Session: $session");
          debugPrint("✅ ACCOUNTS: ${session.accounts}");
          _session = session;
          _isConnectionInProgress = false;
          _cancelTimeoutTimer();

          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete(
              ConnectResponse(
                connected: true,
                walletAddress: _getWalletAddress(),
                error: null,
              ),
            );
          }
        },
        onSessionUpdate: (response) {
          debugPrint("🔄 WalletConnect session updated: ${response.accounts}");
          // Just log session updates - we'll handle address through the existing session
        },
        onDisconnect: () {
          debugPrint("❌ WalletConnect session disconnected");
          _session = null;
          _isConnectionInProgress = false;
          _cancelTimeoutTimer();

          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete(
              ConnectResponse(
                connected: false,
                walletAddress: null,
                error: 'Wallet disconnected',
              ),
            );
          }
        },
      );

      // Listen for deep links from wallet apps
      _listenForDeepLinks();
    } catch (e) {
      debugPrint("❌ Error initializing WalletConnect: $e");
    }
  }

  void _listenForDeepLinks() {
    _appLinksSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 App link received: $uri');
      // Handle when app is opened via deep link
      // This can happen when returning from a wallet app
    });
  }

  void _startConnectionTimeoutTimer() {
    _cancelTimeoutTimer();
    _connectionTimeoutTimer = Timer(const Duration(minutes: 2), () {
      debugPrint("⏰ Connection timeout");

      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete(
          ConnectResponse(
            connected: false,
            walletAddress: null,
            error: 'Connection timed out. Please try again.',
          ),
        );
      }

      _isConnectionInProgress = false;
    });
  }

  void _cancelTimeoutTimer() {
    if (_connectionTimeoutTimer != null && _connectionTimeoutTimer!.isActive) {
      _connectionTimeoutTimer!.cancel();
      _connectionTimeoutTimer = null;
    }
  }

  /// Connect to wallet and get account information
  Future<ConnectResponse> connectWallet(BuildContext context) async {
    try {
      // Check if a connection is already in progress
      if (_isConnectionInProgress) {
        return ConnectResponse(
          connected: false,
          walletAddress: null,
          error: 'Connection already in progress. Please wait.',
        );
      }

      // Check if already connected
      if (_session != null && _connector != null && _connector!.connected) {
        final walletAddress = _getWalletAddress();
        if (walletAddress != null) {
          debugPrint("✓ Already connected to wallet: $walletAddress");
          return ConnectResponse(
            connected: true,
            walletAddress: walletAddress,
            error: null,
          );
        }
      }

      // If we had a previous connection, disconnect it first
      if (_connector != null && _connector!.connected) {
        try {
          await _connector!.killSession();
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // Give some time for cleanup
        } catch (e) {
          debugPrint("⚠️ Error killing previous session: $e");
          // Continue anyway
        }
      }

      // Recreate connector to avoid stale state
      _initWalletConnect();

      // Mark connection as in progress
      _isConnectionInProgress = true;

      // Create a completer to handle async connection flow
      _connectCompleter = Completer<ConnectResponse>();

      // Check for installed wallets before creating session
      final installedWallets = await getInstalledWallets();
      debugPrint(
        "📱 Found ${installedWallets.length} installed wallet apps: $installedWallets",
      );

      // Create connection
      if (_connector != null && !_connector!.connected) {
        try {
          debugPrint("🔄 Creating WalletConnect session...");
          _startConnectionTimeoutTimer();

          // Use a standard Ethereum chain ID (1 = Ethereum Mainnet)
          await _connector!.createSession(
            chainId: 1,
            onDisplayUri: (uri) async {
              debugPrint("🔗 WalletConnect URI: $uri");

              // Show dialog to select wallet
              final selectedWallet = await _showWalletSelectionDialog(
                context,
                uri,
                installedWallets,
              );

              if (selectedWallet != null) {
                debugPrint("🔄 Selected wallet: $selectedWallet");
                final walletApp = _walletApps[selectedWallet];

                if (walletApp != null) {
                  final launched = await _launchWalletWithUri(walletApp, uri);
                  if (launched) {
                    debugPrint("✓ Launched wallet: ${walletApp.name}");
                    // Show loading indicator - don't complete here, wait for onConnect callback
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Waiting for approval in ${walletApp.name}...',
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } else {
                    debugPrint("❌ Failed to launch wallet, trying clipboard");
                    final clipboardResult = await _copyToClipboardAndNotify(
                      context,
                      uri,
                    );
                    if (!clipboardResult) {
                      _isConnectionInProgress = false;
                      _cancelTimeoutTimer();
                      _connectCompleter?.complete(
                        ConnectResponse(
                          connected: false,
                          walletAddress: null,
                          error: 'Failed to launch wallet app',
                        ),
                      );
                    }
                  }
                } else {
                  debugPrint("❌ Wallet app configuration not found");
                  _isConnectionInProgress = false;
                  _cancelTimeoutTimer();
                  _connectCompleter?.complete(
                    ConnectResponse(
                      connected: false,
                      walletAddress: null,
                      error: 'Wallet configuration not found',
                    ),
                  );
                }
              } else {
                // No wallet selected, cancel connection
                debugPrint("❌ No wallet selected, cancelling connection");
                _isConnectionInProgress = false;
                _cancelTimeoutTimer();
                _connectCompleter?.complete(
                  ConnectResponse(
                    connected: false,
                    walletAddress: null,
                    error: 'No wallet selected',
                  ),
                );
              }
            },
          );
        } catch (e) {
          debugPrint("❌ Error creating session: $e");
          _isConnectionInProgress = false;
          _cancelTimeoutTimer();
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete(
              ConnectResponse(
                connected: false,
                walletAddress: null,
                error: 'Error connecting to wallet: ${e.toString()}',
              ),
            );
          }
        }
      }

      // Wait for connection to complete
      return await _connectCompleter!.future;
    } catch (e) {
      debugPrint("❌ Error in connectWallet: $e");
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
      return ConnectResponse(
        connected: false,
        walletAddress: null,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Get wallet address from session
  String? _getWalletAddress() {
    if (_session?.accounts != null && _session!.accounts.isNotEmpty) {
      final address = _session!.accounts[0].toLowerCase();
      debugPrint("📋 Wallet address: $address");
      return address;
    }
    return null;
  }

  /// Check if a wallet app is installed - more robust implementation
  Future<List<String>> getInstalledWallets() async {
    List<String> installedWallets = [];

    try {
      if (Platform.isAndroid) {
        for (var entry in _walletApps.entries) {
          final walletId = entry.key;
          final walletApp = entry.value;

          try {
            // Try to launch the app with package manager query
            final androidIntent = Uri.parse(
              'android-app://${walletApp.androidPackage}',
            );
            if (await canLaunchUrl(androidIntent)) {
              installedWallets.add(walletId);
              debugPrint("📱 Found installed wallet: ${walletApp.name}");
            } else {
              // Try scheme detection as fallback
              if (await canLaunchUrl(Uri.parse(walletApp.scheme))) {
                installedWallets.add(walletId);
                debugPrint(
                  "📱 Found installed wallet via scheme: ${walletApp.name}",
                );
              }
            }
          } catch (e) {
            debugPrint(
              "⚠️ Error checking if ${walletApp.name} is installed: $e",
            );
          }
        }
      } else if (Platform.isIOS) {
        // iOS doesn't allow direct package checking, we can only use URL schemes
        for (var entry in _walletApps.entries) {
          final walletId = entry.key;
          final walletApp = entry.value;

          try {
            if (await canLaunchUrl(Uri.parse(walletApp.scheme))) {
              installedWallets.add(walletId);
              debugPrint("📱 Found installed wallet: ${walletApp.name}");
            }
          } catch (e) {
            debugPrint(
              "⚠️ Error checking if ${walletApp.name} is installed: $e",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error detecting installed wallets: $e");
    }

    return installedWallets;
  }

  /// Launch wallet app with WalletConnect URI
  Future<bool> _launchWalletWithUri(WalletApp wallet, String uri) async {
    try {
      // Encode the URI
      final encodedUri = Uri.encodeComponent(uri);

      if (Platform.isAndroid) {
        // First try direct intent with wc: scheme
        try {
          final wcUri = Uri.parse('wc:${uri.split('wc:')[1]}');
          if (await launchUrl(wcUri, mode: LaunchMode.externalApplication)) {
            debugPrint("🚀 Launched using wc: scheme");
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch with wc: scheme: $e");
        }

        // Try package-specific intent
        try {
          final intentUri = Uri.parse(
            'intent://wc?uri=$encodedUri#Intent;package=${wallet.androidPackage};scheme=wc;end;',
          );
          if (await launchUrl(
            intentUri,
            mode: LaunchMode.externalApplication,
          )) {
            debugPrint("🚀 Launched using Android intent");
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch Android intent: $e");
        }

        // Try wallet-specific scheme
        try {
          final schemeUri = Uri.parse('${wallet.scheme}wc?uri=$encodedUri');
          if (await launchUrl(
            schemeUri,
            mode: LaunchMode.externalApplication,
          )) {
            debugPrint("🚀 Launched using wallet scheme");
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch using wallet scheme: $e");
        }

        // Try direct app launch as last resort
        try {
          final appUri = Uri.parse('android-app://${wallet.androidPackage}');
          if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
            debugPrint(
              "🚀 Launched app directly - you'll need to paste the code",
            );
            await _copyToClipboardAndNotify(null, uri);
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch app directly: $e");
        }
      } else if (Platform.isIOS) {
        // Try universal link first
        try {
          final universalUri = Uri.parse(
            '${wallet.universalLink}/wc?uri=$encodedUri',
          );
          if (await launchUrl(
            universalUri,
            mode: LaunchMode.externalApplication,
          )) {
            debugPrint("🚀 Launched using universal link");
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch iOS universal link: $e");
        }

        // Fallback to scheme
        try {
          final schemeUri = Uri.parse('${wallet.scheme}wc?uri=$encodedUri');
          if (await launchUrl(
            schemeUri,
            mode: LaunchMode.externalApplication,
          )) {
            debugPrint("🚀 Launched using iOS scheme");
            return true;
          }
        } catch (e) {
          debugPrint("⚠️ Failed to launch iOS scheme: $e");
        }
      }

      // If all methods failed, just try to launch the URI directly
      try {
        if (await launchUrl(
          Uri.parse(uri),
          mode: LaunchMode.externalApplication,
        )) {
          debugPrint("🚀 Launched using direct URI");
          return true;
        }
      } catch (e) {
        debugPrint("⚠️ Failed to launch direct URI: $e");
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error launching wallet: $e");
      return false;
    }
  }

  /// Copy the URI to clipboard and notify user
  Future<bool> _copyToClipboardAndNotify(
    BuildContext? context,
    String uri,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: uri));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WalletConnect link copied to clipboard. Please paste it in your wallet app.',
            ),
            duration: Duration(seconds: 8),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint("❌ Error copying to clipboard: $e");
      return false;
    }
  }

  /// Show dialog to select wallet
  Future<String?> _showWalletSelectionDialog(
    BuildContext context,
    String uri,
    List<String> installedWallets,
  ) async {
    // Handle the case where no wallets are installed
    if (installedWallets.isEmpty) {
      return await _showNoWalletsDialog(context);
    } else {
      // Show dialog with installed wallets
      return await _showWalletPickerDialog(context, installedWallets);
    }
  }

  /// Show dialog when no wallets are installed
  Future<String?> _showNoWalletsDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Wallet Found'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No crypto wallet apps found on your device. Please install one of the following:',
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        _walletApps.entries.map((entry) {
                          final wallet = entry.value;
                          return ListTile(
                            leading: Icon(wallet.icon),
                            title: Text(wallet.name),
                            onTap: () {
                              Navigator.of(context).pop(entry.key);
                              _openWalletStore(wallet);
                            },
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog to pick from installed wallets
  Future<String?> _showWalletPickerDialog(
    BuildContext context,
    List<String> installedWallets,
  ) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Wallet'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose a wallet to connect:'),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: installedWallets.length,
                    itemBuilder: (context, index) {
                      final walletId = installedWallets[index];
                      final wallet = _walletApps[walletId];
                      if (wallet == null) return const SizedBox.shrink();

                      return ListTile(
                        leading: Icon(wallet.icon),
                        title: Text(wallet.name),
                        onTap: () => Navigator.of(context).pop(walletId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Install More Wallets'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                _walletApps.entries
                                    .where(
                                      (entry) =>
                                          !installedWallets.contains(entry.key),
                                    )
                                    .map((entry) {
                                      final wallet = entry.value;
                                      return ListTile(
                                        leading: Icon(wallet.icon),
                                        title: Text(wallet.name),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop(entry.key);
                                          _openWalletStore(wallet);
                                        },
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('More Wallets'),
            ),
          ],
        );
      },
    );
  }

  /// Open wallet store page
  Future<void> _openWalletStore(WalletApp wallet) async {
    try {
      Uri url;
      if (Platform.isAndroid) {
        url = Uri.parse(wallet.storeUrlAndroid);
      } else {
        url = Uri.parse(wallet.storeUrlIOS);
      }

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint("❌ Could not open store for ${wallet.name}");
      }
    } catch (e) {
      debugPrint("❌ Error opening store: $e");
    }
  }

  /// Check if currently connected
  bool isConnected() {
    return _connector != null && _connector!.connected && _session != null;
  }

  /// Get current wallet address if connected
  String? getCurrentWalletAddress() {
    return _getWalletAddress();
  }

  /// Disconnect wallet
  Future<bool> disconnectWallet() async {
    try {
      _cancelTimeoutTimer();
      _isConnectionInProgress = false;

      if (_connector != null && _connector!.connected) {
        await _connector!.killSession();
        _session = null;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error disconnecting wallet: $e");
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _cancelTimeoutTimer();
    _appLinksSubscription?.cancel();
    disconnectWallet();
  }
}

/// Wallet app configuration
class WalletApp {
  final String name;
  final IconData icon;
  final String androidPackage;
  final String iOSAppId;
  final String universalLink;
  final String scheme;
  final String storeUrlAndroid;
  final String storeUrlIOS;

  WalletApp({
    required this.name,
    required this.icon,
    required this.androidPackage,
    required this.iOSAppId,
    required this.universalLink,
    required this.scheme,
    required this.storeUrlAndroid,
    required this.storeUrlIOS,
  });
}

/// Response for wallet connection
class ConnectResponse {
  final bool connected;
  final String? walletAddress;
  final String? error;

  ConnectResponse({
    required this.connected,
    required this.walletAddress,
    required this.error,
  });
}
