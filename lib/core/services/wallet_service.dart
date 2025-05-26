// STUB SERVICE - WalletConnect dependencies not available
// This service is kept for compatibility but functionality moved to DirectWalletService

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:reown_walletkit/reown_walletkit.dart'; // NOT AVAILABLE

class WalletService {
  // Stub implementation - actual functionality moved to DirectWalletService
  bool _isInitialized = false;
  bool _isConnectionInProgress = false;
  Timer? _connectionTimeoutTimer;

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
      universalLink: 'https://phantom.app/ul',
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
      universalLink: 'https://www.binance.com/en/wallet-direct',
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
      universalLink: 'https://go.cb-w.com',
      scheme: 'cbwallet://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=org.toshi',
      storeUrlIOS: 'https://apps.apple.com/app/coinbase-wallet/id1278383455',
    ),
  };

  WalletService() {
    debugPrint("⚠️ WalletService is a stub - use DirectWalletService instead");
  }

  /// STUB - Use DirectWalletService instead
  Future<ConnectResponse> connectToMetaMask(BuildContext context) async {
    debugPrint("⚠️ WalletService stub called - use DirectWalletService");
    return ConnectResponse(
      connected: false,
      walletAddress: null,
      error: 'Use DirectWalletService instead',
    );
  }

  /// STUB - Use DirectWalletService instead
  Future<ConnectResponse> connectWallet(BuildContext context) async {
    debugPrint("⚠️ WalletService stub called - use DirectWalletService");
    return ConnectResponse(
      connected: false,
      walletAddress: null,
      error: 'Use DirectWalletService instead',
    );
  }

  /// Check if wallet apps are installed
  Future<List<String>> getInstalledWallets() async {
    List<String> installedWallets = [];

    try {
      debugPrint("🔍 Checking for installed wallet apps");

      if (Platform.isAndroid) {
        for (var entry in _walletApps.entries) {
          final walletId = entry.key;
          final walletApp = entry.value;

          try {
            // Check if the wallet app is installed by trying to launch its scheme
            final canLaunchScheme = await canLaunchUrl(
              Uri.parse(walletApp.scheme),
            );
            if (canLaunchScheme) {
              installedWallets.add(walletId);
              debugPrint(
                "📱 Found installed wallet via scheme: ${walletApp.name}",
              );
              continue;
            }

            // Try to launch the app with package manager query
            final androidIntent = Uri.parse(
              'android-app://${walletApp.androidPackage}',
            );
            final canLaunchApp = await canLaunchUrl(androidIntent);
            if (canLaunchApp) {
              installedWallets.add(walletId);
              debugPrint(
                "📱 Found installed wallet via package: ${walletApp.name}",
              );
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
            final canLaunch = await canLaunchUrl(Uri.parse(walletApp.scheme));
            if (canLaunch) {
              installedWallets.add(walletId);
              debugPrint("📱 Found installed wallet on iOS: ${walletApp.name}");
            }
          } catch (e) {
            debugPrint(
              "⚠️ Error checking if ${walletApp.name} is installed on iOS: $e",
            );
          }
        }
      }

      // If no wallets found, add them all so the user can choose to install
      if (installedWallets.isEmpty) {
        debugPrint("📱 No installed wallets found, showing all options");
        installedWallets = _walletApps.keys.toList();
      }

      debugPrint(
        "📱 Final list of wallet options: ${installedWallets.map((id) => _walletApps[id]?.name).join(', ')}",
      );
    } catch (e) {
      debugPrint("❌ Error detecting installed wallets: $e");
    }

    return installedWallets;
  }

  /// Check if currently connected - STUB
  bool isConnected() {
    debugPrint("⚠️ WalletService stub - use DirectWalletService");
    return false;
  }

  /// Get current wallet address if connected - STUB
  String? getCurrentWalletAddress() {
    debugPrint("⚠️ WalletService stub - use DirectWalletService");
    return null;
  }

  /// Disconnect wallet - STUB
  Future<bool> disconnectWallet() async {
    debugPrint("⚠️ WalletService stub - use DirectWalletService");
    return false;
  }

  /// Clean up resources
  void dispose() {
    debugPrint("🧹 Disposing WalletService stub");
    if (_connectionTimeoutTimer?.isActive == true) {
      _connectionTimeoutTimer!.cancel();
    }
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

/// Response for wallet connection - kept for compatibility
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
