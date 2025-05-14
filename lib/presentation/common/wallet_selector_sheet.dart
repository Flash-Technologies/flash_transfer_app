import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class WalletApp {
  final String id;
  final String name;
  final String iconPath;
  final String androidPackage;
  final String iOSAppId;
  final String universalLink;
  final String scheme;
  final String storeUrlAndroid;
  final String storeUrlIOS;
  final Color color;

  WalletApp({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.androidPackage,
    required this.iOSAppId,
    required this.universalLink,
    required this.scheme,
    required this.storeUrlAndroid,
    required this.storeUrlIOS,
    required this.color,
  });
}

class WalletSelectorSheet extends StatefulWidget {
  final Function(WalletApp wallet) onWalletSelected;

  const WalletSelectorSheet({Key? key, required this.onWalletSelected})
    : super(key: key);

  static Future<WalletApp?> show(BuildContext context) async {
    return await showModalBottomSheet<WalletApp>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return WalletSelectorSheet(
                onWalletSelected: (wallet) {
                  Navigator.pop(context, wallet);
                },
              );
            },
          ),
    );
  }

  @override
  State<WalletSelectorSheet> createState() => _WalletSelectorSheetState();
}

class _WalletSelectorSheetState extends State<WalletSelectorSheet> {
  final List<WalletApp> _wallets = [
    WalletApp(
      id: 'metamask',
      name: 'MetaMask',
      iconPath: 'assets/images/wallets/metamask.png',
      androidPackage: 'io.metamask',
      iOSAppId: 'id1438144202',
      universalLink: 'https://metamask.app.link',
      scheme: 'metamask://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=io.metamask',
      storeUrlIOS: 'https://apps.apple.com/app/metamask/id1438144202',
      color: const Color(0xFFE2761B),
    ),
    WalletApp(
      id: 'trust',
      name: 'Trust Wallet',
      iconPath: 'assets/images/wallets/trust.png',
      androidPackage: 'com.wallet.crypto.trustapp',
      iOSAppId: 'id1288339409',
      universalLink: 'https://link.trustwallet.com',
      scheme: 'trust://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.wallet.crypto.trustapp',
      storeUrlIOS:
          'https://apps.apple.com/app/trust-crypto-bitcoin-wallet/id1288339409',
      color: const Color(0xFF3375BB),
    ),
    WalletApp(
      id: 'phantom',
      name: 'Phantom',
      iconPath: 'assets/images/wallets/phantom.png',
      androidPackage: 'app.phantom',
      iOSAppId: 'id1598432977',
      universalLink: 'https://phantom.app/ul',
      scheme: 'phantom://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=app.phantom',
      storeUrlIOS:
          'https://apps.apple.com/app/phantom-crypto-wallet/id1598432977',
      color: const Color(0xFF551BF9),
    ),
    WalletApp(
      id: 'coinbase',
      name: 'Coinbase Wallet',
      iconPath: 'assets/images/wallets/coinbase.png',
      androidPackage: 'org.toshi',
      iOSAppId: 'id1278383455',
      universalLink: 'https://go.cb-w.com',
      scheme: 'cbwallet://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=org.toshi',
      storeUrlIOS: 'https://apps.apple.com/app/coinbase-wallet/id1278383455',
      color: const Color(0xFF0052FF),
    ),
    WalletApp(
      id: 'binance',
      name: 'Binance Wallet',
      iconPath: 'assets/images/wallets/binance.png',
      androidPackage: 'com.binance.dev',
      iOSAppId: 'id1436799971',
      universalLink: 'https://www.binance.com/en/wallet-direct',
      scheme: 'bnc://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.binance.dev',
      storeUrlIOS:
          'https://apps.apple.com/app/binance-buy-bitcoin-crypto/id1436799971',
      color: const Color(0xFFF3BA2F),
    ),
    WalletApp(
      id: 'rainbow',
      name: 'Rainbow',
      iconPath: 'assets/images/wallets/rainbow.png',
      androidPackage: 'me.rainbow',
      iOSAppId: 'id1457119021',
      universalLink: 'https://rainbow.me',
      scheme: 'rainbow://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=me.rainbow',
      storeUrlIOS:
          'https://apps.apple.com/app/rainbow-ethereum-wallet/id1457119021',
      color: const Color(0xFF001F54),
    ),
    WalletApp(
      id: 'zengo',
      name: 'ZenGo',
      iconPath: 'assets/images/wallets/zengo.png',
      androidPackage: 'com.zengo.wallet',
      iOSAppId: 'id1440147115',
      universalLink: 'https://get.zengo.com',
      scheme: 'zengo://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=com.zengo.wallet',
      storeUrlIOS:
          'https://apps.apple.com/app/zengo-crypto-bitcoin-wallet/id1440147115',
      color: const Color(0xFF0099FF),
    ),
    WalletApp(
      id: 'alpha',
      name: 'Alpha Wallet',
      iconPath: 'assets/images/wallets/alpha.png',
      androidPackage: 'io.alphawallet.android',
      iOSAppId: 'id1358230430',
      universalLink: 'https://aw.app',
      scheme: 'awallet://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=io.alphawallet.android',
      storeUrlIOS:
          'https://apps.apple.com/app/alphawallet-ethereum-wallet/id1358230430',
      color: const Color(0xFF2044F5),
    ),
    WalletApp(
      id: 'argent',
      name: 'Argent',
      iconPath: 'assets/images/wallets/argent.png',
      androidPackage: 'im.argent.contractwalletclient',
      iOSAppId: 'id1358741926',
      universalLink: 'https://argent.link',
      scheme: 'argent://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=im.argent.contractwalletclient',
      storeUrlIOS: 'https://apps.apple.com/app/argent/id1358741926',
      color: const Color(0xFFFF875B),
    ),
    WalletApp(
      id: 'imtoken',
      name: 'imToken',
      iconPath: 'assets/images/wallets/imtoken.png',
      androidPackage: 'im.token.app',
      iOSAppId: 'id1384798940',
      universalLink: 'https://token.im',
      scheme: 'imtokenv2://',
      storeUrlAndroid:
          'https://play.google.com/store/apps/details?id=im.token.app',
      storeUrlIOS:
          'https://apps.apple.com/app/imtoken-2-0-bitcoin-ethereum/id1384798940',
      color: const Color(0xFF0697F8),
    ),
  ];

  Map<String, bool> _installedWallets = {};
  bool _isCheckingInstalled = true;

  @override
  void initState() {
    super.initState();
    _checkInstalledWallets();
  }

  Future<void> _checkInstalledWallets() async {
    setState(() {
      _isCheckingInstalled = true;
    });

    Map<String, bool> results = {};

    for (var wallet in _wallets) {
      bool isInstalled = await _isWalletInstalled(wallet);
      results[wallet.id] = isInstalled;
    }

    setState(() {
      _installedWallets = results;
      _isCheckingInstalled = false;
    });
  }

  Future<bool> _isWalletInstalled(WalletApp wallet) async {
    try {
      if (Platform.isAndroid) {
        // First attempt: Check using package manager via Java channel
        try {
          final MethodChannel channel = const MethodChannel(
            'com.flash_transfer_app.wallet_channel',
          );
          final bool isInstalled =
              await channel.invokeMethod<bool>('isPackageInstalled', {
                'package_name': wallet.androidPackage,
              }) ??
              false;

          if (isInstalled) return true;
        } catch (e) {
          debugPrint("Error checking package with native channel: $e");
        }

        // Second attempt: Try with URI scheme
        try {
          final canLaunchScheme = await canLaunchUrl(Uri.parse(wallet.scheme));
          if (canLaunchScheme) return true;
        } catch (e) {
          debugPrint("Error checking scheme: $e");
        }

        // Third attempt: Try using android intent
        try {
          final androidIntent = Uri.parse(
            'android-app://${wallet.androidPackage}',
          );
          return await canLaunchUrl(androidIntent);
        } catch (e) {
          debugPrint("Error checking android intent: $e");
          return false;
        }
      } else if (Platform.isIOS) {
        // iOS method: Try multiple approaches

        // First: Try universal link if available
        if (wallet.universalLink.isNotEmpty) {
          try {
            final canLaunchUniversal = await canLaunchUrl(
              Uri.parse(wallet.universalLink),
            );
            if (canLaunchUniversal) return true;
          } catch (e) {
            debugPrint("Error checking universal link: $e");
          }
        }

        // Second: Try URL scheme - most reliable for iOS
        try {
          return await canLaunchUrl(Uri.parse(wallet.scheme));
        } catch (e) {
          debugPrint("Error checking URL scheme: $e");
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error checking if ${wallet.name} is installed: $e");
      return false;
    }
  }

  Future<void> _openAppStore(WalletApp wallet) async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open store for ${wallet.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening store: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar at the top
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Connect Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181F30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Select a wallet to connect to Flash Transfer',
              style: TextStyle(fontSize: 14, color: Color(0xFF6E757D)),
            ),
          ),
          const SizedBox(height: 16),

          // Wallet list
          Expanded(
            child:
                _isCheckingInstalled
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        final isInstalled =
                            _installedWallets[wallet.id] ?? false;

                        return _buildWalletItem(
                          wallet: wallet,
                          isInstalled: isInstalled,
                        );
                      },
                    ),
          ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWalletItem({
    required WalletApp wallet,
    required bool isInstalled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEBECED)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap:
                isInstalled
                    ? () => widget.onWalletSelected(wallet)
                    : () => _openAppStore(wallet),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Wallet Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        wallet.iconPath,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: wallet.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                size: 24,
                                color: wallet.color,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Wallet Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181F30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    isInstalled
                                        ? Colors.green
                                        : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isInstalled ? 'Installed' : 'Not installed',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isInstalled
                                        ? Colors.green
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isInstalled
                              ? const Color(0xFFFFC000)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      isInstalled ? 'Connect' : 'Install',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            isInstalled
                                ? const Color(0xFF181F30)
                                : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
