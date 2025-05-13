import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WalletService {
  // Reown WalletKit instance
  ReownWalletKit? _walletKit;
  bool _isInitialized = false;
  bool _isConnectionInProgress = false;
  Timer? _connectionTimeoutTimer;

  // Completer to handle async wallet connection flow
  Completer<ConnectResponse>? _connectCompleter;

  // Track if we've received a session proposal
  bool _hasReceivedSessionProposal = false;

  // Store required namespaces for session proposal
  Map<String, Namespace>? _requiredNamespaces;

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
    _initWalletKit();
  }

  Future<void> _initWalletKit() async {
    if (_isInitialized) return;

    try {
      debugPrint("🔄 Initializing WalletKit");

      // Define mainnet chain ID for Ethereum
      final mainnetChainId = "eip155:1";

      // Initialize the Reown WalletKit with proper project ID and metadata
      final walletKit = ReownWalletKit(
        core: ReownCore(
          projectId:
              '9e4a9ad5bac5592cdf5d141436c97d53', // Your WalletConnect project ID
        ),
        metadata: PairingMetadata(
          name: 'Flash Transfer',
          description: 'Flash Transfer Mobile App - Send and Receive Money',
          url: 'https://walletconnect.com',
          icons: ['https://walletconnect.com/logo.png'],
          redirect: Redirect(
            native: 'com.example.flash_transfer_app://',
            universal: 'https://walletconnect.com',
          ),
        ),
      );

      // Initialize WalletKit
      await walletKit.init();

      debugPrint("📡 Registering event listeners");

      // Set up event listeners - each with detailed logging
      walletKit.onSessionProposal.subscribe((event) {
        debugPrint("🔵 SESSION PROPOSAL RECEIVED: ${event.id}");
        debugPrint("🔵 PROPOSAL DETAILS: ${event.params.requiredNamespaces}");
        _hasReceivedSessionProposal = true;
        _onSessionProposal(event);
      });

      walletKit.onSessionConnect.subscribe((event) {
        debugPrint("🟢 SESSION CONNECTED");
        _onSessionConnect(event);
      });

      walletKit.onSessionDelete.subscribe((event) {
        debugPrint("🔴 SESSION DELETED");
        _onSessionDelete(event);
      });

      walletKit.onSessionExpire.subscribe((event) {
        debugPrint("🟠 SESSION EXPIRED");
        _onSessionExpire(event);
      });

      // Register standard session request handler
      walletKit.onSessionRequest.subscribe((event) {
        debugPrint("🟣 SESSION REQUEST: ${event.method}");
      });

      // Register Ethereum request handler
      walletKit.registerRequestHandler(
        chainId: mainnetChainId,
        method: '*', // Catch all methods
        handler: _handleEthereumRequest,
      );

      // Listen for errors to help with debugging
      // walletKit.on('error', (error) {
      //   debugPrint("🔴 WALLETKIT ERROR: $error");
      // });

      _walletKit = walletKit;
      _isInitialized = true;
      debugPrint("✅ WalletKit initialized successfully");
    } catch (e, stacktrace) {
      debugPrint("❌ Error initializing WalletKit: $e");
      debugPrint("📜 Stack trace: $stacktrace");
      _isInitialized = false;
    }
  }

  // Handle Ethereum request
  Future<void> _handleEthereumRequest(String topic, dynamic params) async {
    debugPrint("🔄 Ethereum request handler called: $topic, $params");
    try {
      // Get the pending request
      final pendingRequests = _walletKit!.pendingRequests.getAll();
      if (pendingRequests.isEmpty) {
        debugPrint("⚠️ No pending requests found");
        return;
      }

      final pendingRequest = pendingRequests.last;
      final requestId = pendingRequest.id;

      debugPrint("🔄 Pending request: $requestId, ${pendingRequest.method}");

      // In a production app, you would show UI to approve/reject
      // Here we automatically approve with a mock response
      await _walletKit!.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          result: '0x1234567890abcdef', // Mock signature
        ),
      );

      debugPrint("✅ Responded to Ethereum request: $requestId");
    } catch (e) {
      debugPrint("❌ Error handling Ethereum request: $e");
    }
  }

  // Handle session proposal event
  void _onSessionProposal(SessionProposalEvent event) {
    debugPrint("🔵 Processing session proposal: ${event.id}");

    try {
      if (_walletKit == null) {
        debugPrint("❌ WalletKit is null during session proposal");
        return;
      }

      // Log details of the proposal
      debugPrint("📋 Proposal details:");
      debugPrint("   ID: ${event.id}");
      debugPrint("   Proposer: ${event.params.proposer.metadata.name}");
      debugPrint("   Required namespaces: ${event.params.requiredNamespaces}");
      debugPrint(
        "   Generated namespaces: ${event.params.generatedNamespaces}",
      );

      // If we have generated namespaces, use them
      if (event.params.generatedNamespaces != null) {
        debugPrint("✓ Using generated namespaces to approve session");

        // Auto-approve the session with generated namespaces
        _walletKit!.approveSession(
          id: event.id,
          namespaces: event.params.generatedNamespaces!,
        );
        debugPrint("✅ Session proposal approved with ID: ${event.id}");
      } else {
        // We need generated namespaces to proceed
        debugPrint("❌ No generated namespaces available");
        _rejectSession(
          event.id,
          "WalletConnect session requires generated namespaces",
        );
      }
    } catch (e, stacktrace) {
      debugPrint("❌ Error approving session: $e");
      debugPrint("📜 Stack trace: $stacktrace");
      _rejectSession(event.id, "Error approving session: $e");
    }
  }

  // Helper method to reject a session
  void _rejectSession(int id, String reason) {
    try {
      if (_walletKit != null) {
        _walletKit!.rejectSession(
          id: id,
          reason: ReownSignError(code: 4001, message: reason),
        );
        debugPrint("✅ Session rejected with ID: $id");
      }
    } catch (e) {
      debugPrint("❌ Error rejecting session: $e");
    }
  }

  // Handle session connect event
  void _onSessionConnect(SessionConnect event) {
    debugPrint("🟢 Processing session connect");

    try {
      // Get the sessions
      final sessions = _walletKit?.sessions.getAll();
      if (sessions == null || sessions.isEmpty) {
        debugPrint("⚠️ No active sessions found");
        _completeWithError("No active sessions found");
        return;
      }

      // Use the most recently connected session
      final session = sessions.last;
      debugPrint("✅ SESSION DATA: Topic: ${session.topic}");

      // Log session details
      debugPrint("📋 Session details:");
      debugPrint("   Topic: ${session.topic}");
      debugPrint("   Expiry: ${session.expiry}");

      // Log available namespaces
      final namespaces = session.namespaces;
      debugPrint("🔄 Available namespaces: ${namespaces.keys.join(', ')}");

      for (final entry in namespaces.entries) {
        debugPrint("   Namespace: ${entry.key}");
        debugPrint("     Accounts: ${entry.value.accounts}");
        debugPrint("     Methods: ${entry.value.methods}");
        debugPrint("     Events: ${entry.value.events}");
      }

      String? walletAddress;

      // Try to get EVM address
      if (namespaces.containsKey('eip155')) {
        final accounts = namespaces['eip155']?.accounts ?? [];
        debugPrint("🔄 EIP-155 accounts found: ${accounts.length}");

        if (accounts.isNotEmpty) {
          for (final account in accounts) {
            debugPrint("   Account: $account");
          }

          // Parse the account string (format: "eip155:1:0x...")
          final account = accounts.first;
          final parts = account.split(':');

          if (parts.length >= 3) {
            walletAddress = parts[2].toLowerCase();
            debugPrint("✅ Found EVM address: $walletAddress");
          } else {
            debugPrint("⚠️ Account format unexpected: $account");
          }
        } else {
          debugPrint("⚠️ No accounts in eip155 namespace");
        }
      } else {
        debugPrint("⚠️ No eip155 namespace found");
      }

      // If EVM address not found, try Solana
      if (walletAddress == null && namespaces.containsKey('solana')) {
        final accounts = namespaces['solana']?.accounts ?? [];
        debugPrint("🔄 Solana accounts found: ${accounts.length}");

        if (accounts.isNotEmpty) {
          final parts = accounts.first.split(':');
          if (parts.length >= 3) {
            walletAddress = parts[2].toLowerCase();
            debugPrint("✅ Found Solana address: $walletAddress");
          }
        }
      }

      // Log final result
      debugPrint("✅ FINAL EXTRACTED WALLET ADDRESS: $walletAddress");

      // Connection complete
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();

      // Complete the connection with the wallet address
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        if (walletAddress != null) {
          _connectCompleter!.complete(
            ConnectResponse(
              connected: true,
              walletAddress: walletAddress,
              error: null,
            ),
          );
        } else {
          _connectCompleter!.complete(
            ConnectResponse(
              connected: false,
              walletAddress: null,
              error: 'No wallet address found in session',
            ),
          );
        }
      }
    } catch (e, stacktrace) {
      debugPrint("❌ Error extracting wallet address: $e");
      debugPrint("📜 Stack trace: $stacktrace");
      _completeWithError("Error extracting wallet address: $e");
    }
  }

  // Helper to complete with error
  void _completeWithError(String error) {
    _isConnectionInProgress = false;
    _cancelTimeoutTimer();

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.complete(
        ConnectResponse(connected: false, walletAddress: null, error: error),
      );
    }
  }

  // Handle session delete event
  void _onSessionDelete(SessionDelete event) {
    debugPrint("🔴 WALLET DISCONNECTED! Session deleted: ${event.topic}");
    _completeWithError("Wallet disconnected");
  }

  // Handle session expire event
  void _onSessionExpire(SessionExpire event) {
    debugPrint("🟠 Session expired: ${event.topic}");
    _completeWithError("Session expired");
  }

  // Start connection timeout timer
  void _startConnectionTimeoutTimer() {
    _cancelTimeoutTimer();
    debugPrint("⏰ Starting connection timeout timer (2 minutes)");
    _connectionTimeoutTimer = Timer(const Duration(minutes: 2), () {
      debugPrint("⏰ Connection timeout reached");
      _completeWithError("Connection timed out. Please try again.");
    });
  }

  // Cancel timeout timer
  void _cancelTimeoutTimer() {
    if (_connectionTimeoutTimer != null && _connectionTimeoutTimer!.isActive) {
      _connectionTimeoutTimer!.cancel();
      _connectionTimeoutTimer = null;
    }
  }

  /// Connect to wallet and get account information
  Future<ConnectResponse> connectWallet(BuildContext context) async {
    try {
      // Make sure WalletKit is initialized
      if (!_isInitialized) {
        debugPrint("⚠️ WalletKit not initialized, initializing now...");
        await _initWalletKit();
      }

      if (_walletKit == null) {
        debugPrint("❌ WalletKit initialization failed - still null");
        return ConnectResponse(
          connected: false,
          walletAddress: null,
          error: 'WalletKit initialization failed',
        );
      }

      // Check if a connection is already in progress
      if (_isConnectionInProgress) {
        debugPrint("⚠️ Connection already in progress");
        return ConnectResponse(
          connected: false,
          walletAddress: null,
          error: 'Connection already in progress. Please wait.',
        );
      }

      // Check if already connected
      final sessions = _walletKit!.sessions.getAll();
      if (sessions.isNotEmpty) {
        debugPrint("🔄 Found ${sessions.length} existing sessions");
        final walletAddress = _getWalletAddressFromSession(sessions.first);
        if (walletAddress != null) {
          debugPrint("✓ Already connected to wallet: $walletAddress");
          return ConnectResponse(
            connected: true,
            walletAddress: walletAddress,
            error: null,
          );
        } else {
          debugPrint(
            "⚠️ Session exists but no wallet address found, disconnecting",
          );
          await disconnectWallet();
        }
      }

      // Mark connection as in progress
      _isConnectionInProgress = true;
      _hasReceivedSessionProposal = false;
      debugPrint("🔄 Starting new wallet connection process");

      // Create a completer to handle async connection flow
      _connectCompleter = Completer<ConnectResponse>();

      // Start timeout timer
      _startConnectionTimeoutTimer();

      try {
        // Clear any existing sessions first to ensure a fresh start
        final existingSessions = _walletKit!.sessions.getAll();
        for (final session in existingSessions) {
          try {
            await _walletKit!.disconnectSession(
              topic: session.topic,
              reason: ReownSignError(
                code: 6000,
                message: 'Refreshing connection',
              ),
            );
            debugPrint("🔄 Cleared existing session: ${session.topic}");
          } catch (e) {
            debugPrint("⚠️ Error clearing session: $e");
          }
        }

        // Create URI using the correct API
        debugPrint("🔄 Creating pairing...");
        final pairingResponse = await _walletKit!.core.pairing.create();
        final wcUri = pairingResponse.uri.toString();

        debugPrint("🔗 WalletConnect URI generated: $wcUri");
        debugPrint("🔗 Pairing topic: ${pairingResponse.topic}");

        // Define required namespaces for the connection
        final requiredNamespaces = {
          'eip155': Namespace(
            chains: ['eip155:1'],
            methods: [
              'eth_sendTransaction',
              'personal_sign',
              'eth_signTransaction',
              'eth_sign',
            ],
            events: ['chainChanged', 'accountsChanged'],
            accounts: [],
          ),
        };

        // Store the required namespaces for later use in session proposal
        _requiredNamespaces = requiredNamespaces;

        // Get installed wallets
        final installedWallets = await getInstalledWallets();
        debugPrint("📱 Found ${installedWallets.length} installed wallet apps");

        // Get selected wallet from user
        final selectedWallet = await _showWalletSelectionDialog(
          context,
          installedWallets,
        );

        if (selectedWallet != null) {
          debugPrint("🔄 User selected wallet: $selectedWallet");
          final walletApp = _walletApps[selectedWallet];

          if (walletApp != null) {
            // Copy URI to clipboard as backup
            await Clipboard.setData(ClipboardData(text: wcUri));

            // Launch the selected wallet
            debugPrint("🚀 Launching wallet: ${walletApp.name}");

            // First try to launch with direct WalletConnect URI
            bool launched = false;

            try {
              launched = await launchUrl(
                Uri.parse(wcUri),
                mode: LaunchMode.externalApplication,
              );

              if (launched) {
                debugPrint(
                  "✅ Successfully launched with direct WalletConnect URI",
                );
              }
            } catch (e) {
              debugPrint("⚠️ Error launching direct URI: $e");
            }

            // If direct URI launch failed, try wallet-specific scheme
            if (!launched) {
              try {
                final encodedUri = Uri.encodeComponent(wcUri);
                final schemeUri = Uri.parse(
                  '${walletApp.scheme}wc?uri=$encodedUri',
                );

                debugPrint(
                  "🔄 Trying wallet-specific scheme: ${schemeUri.toString()}",
                );

                launched = await launchUrl(
                  schemeUri,
                  mode: LaunchMode.externalApplication,
                );

                if (launched) {
                  debugPrint(
                    "✅ Successfully launched with wallet-specific scheme",
                  );
                }
              } catch (e) {
                debugPrint("⚠️ Error launching with wallet scheme: $e");
              }
            }

            // If that also failed, try universal link (iOS) or direct app launch (Android)
            if (!launched) {
              if (Platform.isIOS && walletApp.universalLink.isNotEmpty) {
                try {
                  final encodedUri = Uri.encodeComponent(wcUri);
                  final universalUri = Uri.parse(
                    '${walletApp.universalLink}/wc?uri=$encodedUri',
                  );

                  debugPrint(
                    "🔄 Trying universal link: ${universalUri.toString()}",
                  );

                  launched = await launchUrl(
                    universalUri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (launched) {
                    debugPrint("✅ Successfully launched with universal link");
                  }
                } catch (e) {
                  debugPrint("⚠️ Error launching with universal link: $e");
                }
              } else if (Platform.isAndroid) {
                try {
                  final appUri = Uri.parse(
                    'android-app://${walletApp.androidPackage}',
                  );

                  debugPrint(
                    "🔄 Trying direct app launch: ${appUri.toString()}",
                  );

                  launched = await launchUrl(
                    appUri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (launched) {
                    debugPrint("✅ Successfully launched app directly");
                  }
                } catch (e) {
                  debugPrint("⚠️ Error launching app directly: $e");
                }
              }
            }

            if (launched) {
              // Show snackbar with instructions
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please approve the connection in ${walletApp.name}. WalletConnect URI copied to clipboard.',
                  ),
                  duration: const Duration(seconds: 8),
                ),
              );

              // Wait for a session proposal to be received
              int waitTimeSeconds = 0;
              const maxWaitTime = 120; // Max wait time in seconds

              while (!_hasReceivedSessionProposal &&
                  waitTimeSeconds < maxWaitTime) {
                await Future.delayed(const Duration(seconds: 1));
                waitTimeSeconds++;

                if (waitTimeSeconds % 5 == 0) {
                  debugPrint(
                    "⏱️ Waiting for session proposal... ($waitTimeSeconds seconds)",
                  );

                  // Every 15 seconds, try to re-launch the wallet with the URI
                  if (waitTimeSeconds % 15 == 0 && waitTimeSeconds < 45) {
                    debugPrint("🔄 Attempting to relaunch wallet with URI...");
                    try {
                      final encodedUri = Uri.encodeComponent(wcUri);
                      final schemeUri = Uri.parse(
                        '${walletApp.scheme}wc?uri=$encodedUri',
                      );
                      await launchUrl(
                        schemeUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      debugPrint("⚠️ Error relaunching wallet: $e");
                    }
                  }
                }
              }

              if (_hasReceivedSessionProposal) {
                debugPrint(
                  "✅ Session proposal received after $waitTimeSeconds seconds",
                );
              } else {
                debugPrint(
                  "⚠️ No session proposal received after $waitTimeSeconds seconds",
                );

                // If no session proposal received, try to launch again
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Connection taking longer than expected. Please check ${walletApp.name} or try pasting the URI manually.',
                    ),
                    duration: const Duration(seconds: 8),
                  ),
                );
              }
            } else {
              // If all launch attempts failed, inform user to paste URI manually
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not open ${walletApp.name} automatically. Please open it manually and paste the copied WalletConnect URI.',
                  ),
                  duration: const Duration(seconds: 8),
                ),
              );
            }
          } else {
            _completeWithError('Wallet configuration not found');
          }
        } else {
          // No wallet selected, cancel connection
          _completeWithError('No wallet selected');
        }
      } catch (e, stacktrace) {
        debugPrint("❌ Error in wallet connection flow: $e");
        debugPrint("📜 Stack trace: $stacktrace");
        _completeWithError('Error connecting to wallet: ${e.toString()}');
      }

      // Wait for connection to complete with a timeout
      return await _connectCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          debugPrint("⏰ Connection future timed out");
          _isConnectionInProgress = false;
          return ConnectResponse(
            connected: false,
            walletAddress: null,
            error: 'Connection timed out. Please try again.',
          );
        },
      );
    } catch (e, stacktrace) {
      debugPrint("❌ Error in connectWallet: $e");
      debugPrint("📜 Stack trace: $stacktrace");
      _isConnectionInProgress = false;
      _cancelTimeoutTimer();
      return ConnectResponse(
        connected: false,
        walletAddress: null,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Extract wallet address from session
  String? _getWalletAddressFromSession(SessionData session) {
    try {
      final namespaces = session.namespaces;

      // Log namespaces for debugging
      debugPrint("🔍 Getting wallet address from session ${session.topic}");
      debugPrint("🔍 Namespaces: ${namespaces.keys.join(', ')}");

      // Try to get EVM address
      if (namespaces.containsKey('eip155')) {
        final accounts = namespaces['eip155']?.accounts ?? [];
        debugPrint("🔍 EIP-155 accounts: $accounts");

        if (accounts.isNotEmpty) {
          // Parse the account string (format: "eip155:1:0x...")
          final parts = accounts.first.split(':');
          if (parts.length >= 3) {
            return parts[2].toLowerCase();
          }
        }
      }

      // If EVM address not found, try Solana
      if (namespaces.containsKey('solana')) {
        final accounts = namespaces['solana']?.accounts ?? [];
        debugPrint("🔍 Solana accounts: $accounts");

        if (accounts.isNotEmpty) {
          final parts = accounts.first.split(':');
          if (parts.length >= 3) {
            return parts[2].toLowerCase();
          }
        }
      }

      debugPrint("⚠️ No wallet address found in session");
      return null;
    } catch (e) {
      debugPrint("❌ Error extracting wallet address from session: $e");
      return null;
    }
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

  /// Show dialog to select wallet
  Future<String?> _showWalletSelectionDialog(
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
                // Show additional wallets that can be installed
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
    final connected =
        _walletKit != null && _walletKit!.sessions.getAll().isNotEmpty;
    debugPrint(
      "🔍 Wallet connection status: ${connected ? 'Connected' : 'Disconnected'}",
    );
    return connected;
  }

  /// Get current wallet address if connected
  String? getCurrentWalletAddress() {
    if (_walletKit == null) {
      debugPrint("⚠️ WalletKit is null when checking current wallet address");
      return null;
    }

    final sessions = _walletKit!.sessions.getAll();
    if (sessions.isEmpty) {
      debugPrint("⚠️ No active sessions when checking current wallet address");
      return null;
    }

    final address = _getWalletAddressFromSession(sessions.first);
    debugPrint("🔍 Current wallet address: $address");
    return address;
  }

  /// Disconnect wallet
  Future<bool> disconnectWallet() async {
    try {
      _cancelTimeoutTimer();
      _isConnectionInProgress = false;

      if (_walletKit == null) {
        debugPrint("⚠️ WalletKit is null when disconnecting");
        return false;
      }

      final sessions = _walletKit!.sessions.getAll();
      if (sessions.isEmpty) {
        debugPrint("⚠️ No active sessions to disconnect");
        return false;
      }

      debugPrint("🔄 Disconnecting ${sessions.length} sessions");

      // Disconnect all sessions
      for (final session in sessions) {
        try {
          await _walletKit!.disconnectSession(
            topic: session.topic,
            reason: ReownSignError(code: 6000, message: 'User disconnected'),
          );
          debugPrint("✅ Successfully disconnected session: ${session.topic}");
        } catch (e) {
          debugPrint("❌ Error disconnecting session: $e");
        }
      }

      return true;
    } catch (e) {
      debugPrint("❌ Error disconnecting wallet: $e");
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    debugPrint("🧹 Disposing WalletService");
    _cancelTimeoutTimer();
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
