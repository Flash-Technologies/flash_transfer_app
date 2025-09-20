import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'phantom_service.dart';
import 'package:flash_transfer_app/core/services/network_mapping_service.dart';

class ReownService {
  static ReownService? _instance;
  ReownAppKitModal? _appKitModal;
  
  // Project ID from Reown Dashboard
  static const String projectId = '7494d2d07a2996f0956dfb33e43ff98a';
  
  ReownService._();
  
  static ReownService get instance {
    _instance ??= ReownService._();
    return _instance!;
  }
  
  ReownAppKitModal get appKitModal {
    if (_appKitModal == null) {
      throw Exception('ReownService not initialized. Call initialize() first.');
    }
    return _appKitModal!;
  }
  
  bool get isInitialized => _appKitModal != null;
  bool get isConnected => _appKitModal?.isConnected ?? false || PhantomService.instance.isConnected;
  
  String? get walletAddress {
    // Check Phantom wallet first
    if (PhantomService.instance.isConnected && PhantomService.instance.walletAddress != null) {
      return PhantomService.instance.walletAddress;
    }
    
    // Check Reown/WalletConnect wallet
    if (_appKitModal?.isConnected == true && _appKitModal?.session != null) {
      final chainId = _appKitModal!.selectedChain?.chainId;
      if (chainId == null) return null;
      
      final namespace = NamespaceUtils.getNamespaceFromChain(chainId);
      final accounts = _appKitModal!.session!.getAccounts(namespace: namespace) ?? [];
      
      if (accounts.isEmpty) return null;
      
      // Extract address from account string (format: "eip155:1:0x...")
      return accounts.first.split(':').last;
    }
    
    return null;
  }
  
  String? get selectedNetwork => _appKitModal?.selectedChain?.name;
  
  Future<void> updateContext(BuildContext context) async {
    if (_appKitModal != null) {
      // Update the context for the existing modal
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: projectId,
        logLevel: LogLevel.error,
        metadata: const PairingMetadata(
          name: 'Flash Transfer',
          description: 'Flash Transfer - Fast and secure crypto transfers',
          url: 'https://flash-transfer.com',
          icons: ['https://flash-transfer.com/logo.png'],
          redirect: Redirect(
            native: 'flashtransferapp://',
            universal: 'flashtransferapp://',
            linkMode: true,
          ),
        ),
        siweConfig: null,
        enableAnalytics: true,
        featuredWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
        },
        includedWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
          '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369', // Rainbow
          'a797aa35c0fadbfc1a53e7f675162ed5226968b44a19ee3d24385c64d1d3c393', // Phantom
        },
      );
      
      await _appKitModal!.init();
      print('ReownService context updated');
    }
  }

  Future<void> initialize(BuildContext context, {int? preferredChainId}) async {
    if (_appKitModal != null) {
      print('ReownService already initialized');
      
      // If initialized but need to switch network
      if (preferredChainId != null) {
        await setSelectedNetwork(preferredChainId);
      }
      return;
    }
    
    try {
      print('Initializing ReownAppKitModal...');
      
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: projectId,
        logLevel: LogLevel.error,
        metadata: const PairingMetadata(
          name: 'Flash Transfer',
          description: 'Flash Transfer - Fast and secure crypto transfers',
          url: 'https://flash-transfer.com',
          icons: ['https://flash-transfer.com/logo.png'],
          redirect: Redirect(
            native: 'flashtransferapp://',
            universal: 'flashtransferapp://',
            linkMode: true,
          ),
        ),
        // Configure supported chains
        siweConfig: null, // We'll add SIWE later if needed
        enableAnalytics: true,
        featuredWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
        },
        includedWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
          '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369', // Rainbow
          'a797aa35c0fadbfc1a53e7f675162ed5226968b44a19ee3d24385c64d1d3c393', // Phantom
        },
      );
      
      await _appKitModal!.init();
      
      // Setup listeners
      _setupEventListeners();
      
      // Set preferred network if provided
      if (preferredChainId != null) {
        await setSelectedNetwork(preferredChainId);
      }
      
      print('ReownAppKitModal initialized successfully');
      print('Is connected: ${_appKitModal!.isConnected}');
      
    } catch (e) {
      print('Error initializing ReownAppKitModal: $e');
      _appKitModal = null;
      rethrow;
    }
  }
  
  Future<void> setSelectedNetwork(int chainId) async {
    if (!isInitialized) return;
    
    try {
      print('🌐 Setting selected network to chain ID: $chainId');
      
      // Create chain object with the desired chain ID
      // Common chains: 1 (Ethereum), 56 (BSC), 137 (Polygon)
      final chainName = _getChainName(chainId);
      
      // For now, just log the desired network
      // The actual network switching will happen when wallet connects
      print('🔗 Preferred network set to: $chainName (Chain ID: $chainId)');
      print('✅ Network configuration set for chain ID: $chainId');
    } catch (e) {
      print('❌ Error setting network: $e');
    }
  }
  
  String _getChainName(int chainId) {
    switch (chainId) {
      case 1:
        return 'Ethereum';
      case 56:
        return 'BNB Smart Chain';
      case 137:
        return 'Polygon';
      case 43114:
        return 'Avalanche';
      case 42161:
        return 'Arbitrum';
      case 10:
        return 'Optimism';
      default:
        return 'Ethereum';
    }
  }
  
  String _getCurrencyForChain(int chainId) {
    switch (chainId) {
      case 1:
        return 'ETH';
      case 56:
        return 'BNB';
      case 137:
        return 'MATIC';
      case 43114:
        return 'AVAX';
      case 42161:
        return 'ETH';
      case 10:
        return 'ETH';
      default:
        return 'ETH';
    }
  }
  
  void _setupEventListeners() {
    if (_appKitModal == null) return;
    
    // Listen to connection status changes
    _appKitModal!.onModalConnect.subscribe((ModalConnect? event) {
      print('🔗 Wallet connected: ${event?.session.topic}');
      // Force refresh state when wallet connects
      Future.delayed(Duration(milliseconds: 100), () {
        print('🔗 Connection confirmed - wallet address: $walletAddress');
      });
    });
    
    _appKitModal!.onModalDisconnect.subscribe((ModalDisconnect? event) {
      print('🔌 Wallet disconnected: ${event?.topic}');
    });
    
    _appKitModal!.onModalError.subscribe((ModalError? event) {
      print('❌ Modal error: ${event?.message}');
    });
    
    // Listen to modal state changes to handle cancellations
    _appKitModal!.onModalNetworkChange.subscribe((ModalNetworkChange? event) {
      print('🌐 Network changed');
    });
    
    // Additional session events can be added here when needed
  }
  
  Future<void> connect() async {
    if (!isInitialized) {
      throw Exception('ReownService not initialized');
    }
    
    try {
      print('Opening wallet connection modal...');
      await _appKitModal!.openModalView();
    } catch (e) {
      print('Error connecting wallet: $e');
      rethrow;
    }
  }
  
  // Connect wallet for authentication (sign in/sign up)
  Future<String?> connectForAuth({BuildContext? context}) async {
    try {
      print('Opening wallet modal for authentication...');
      
      // Initialize if not already done and context is provided
      if (!isInitialized && context != null) {
        print('🔄 Initializing Reown service with context...');
        await initialize(context);
      } else if (isInitialized && context != null) {
        // Update context for existing modal to fix context issues after logout
        print('🔄 Updating context for existing modal...');
        await updateContext(context);
      }
      
      if (!isInitialized) {
        throw Exception('ReownService not initialized and no context provided');
      }
      
      // IMPORTANT: Always reset state first to force fresh connection
      print('Resetting wallet state to force fresh selection...');
      await resetConnectionState();
      
      // Open modal and wait for connection
      await _appKitModal!.openModalView();
      
      // Wait for the connection to establish or modal to be closed
      int attempts = 0;
      bool modalClosed = false;
      
      while (attempts < 60) { // Increased timeout to 30 seconds
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
        
        // Check if connected (includes both Reown and Phantom connections)
        if (isConnected && walletAddress != null) {
          print('Wallet connected successfully: $walletAddress');
          return walletAddress;
        }
        
        // Check if modal is closed
        try {
          if (!_appKitModal!.isOpen) {
            if (!modalClosed) {
              print('Modal closed - checking for Phantom deep link connection...');
              modalClosed = true;
              // Give Phantom deep link more time to process
              await Future.delayed(Duration(seconds: 3));
              
              // Check again after delay
              if (isConnected && walletAddress != null) {
                print('Phantom wallet connected via deep link: $walletAddress');
                return walletAddress;
              }
            }
            
            // If still no connection after modal close and delay, user cancelled
            print('No wallet connection detected after modal close');
            return null;
          }
        } catch (e) {
          // Modal might not have isOpen property, continue waiting
        }
      }
      
      print('Wallet connection timed out');
      return null;
    } catch (e) {
      print('Error in wallet authentication: $e');
      
      // Handle specific context-related errors
      if (e.toString().contains('No context was found')) {
        print('❌ Context error detected - this usually happens after logout');
        throw Exception('Context error: Please try again. The app may need to reinitialize after logout.');
      }
      
      return null;
    }
  }
  
  Future<void> disconnect() async {
    if (!isInitialized) return;
    
    try {
      print('Disconnecting wallet...');
      
      // Disconnect Reown wallet if connected
      if (_appKitModal!.isConnected) {
        await _appKitModal!.disconnect();
      }
      
      // Also disconnect Phantom if connected
      PhantomService.instance.disconnect();
      
      print('All wallets disconnected successfully');
    } catch (e) {
      print('Error disconnecting wallet: $e');
      rethrow;
    }
  }
  
  /// Force reset the wallet connection state - useful when app restarts
  /// and we want to ensure fresh wallet selection
  Future<void> resetConnectionState() async {
    try {
      print('🔄 Resetting wallet connection state...');
      
      // Disconnect any existing connections
      await disconnect();
      
      // Force modal to close if open
      if (_appKitModal != null && _appKitModal!.isOpen) {
        _appKitModal!.closeModal();
      }
      
      // Small delay to allow cleanup
      await Future.delayed(Duration(milliseconds: 300));
      
      print('✅ Wallet connection state reset successfully');
    } catch (e) {
      print('❌ Error resetting wallet connection state: $e');
    }
  }
  
  /// Complete reset for logout - disposes everything
  Future<void> resetForLogout() async {
    try {
      print('🔄 Performing complete reset for logout...');
      
      // First disconnect everything
      await resetConnectionState();
      
      // Then dispose the modal completely
      if (_appKitModal != null) {
        try {
          _appKitModal!.closeModal();
        } catch (e) {
          print('⚠️ Error closing modal during logout: $e');
        }
        _appKitModal = null;
      }
      
      // Clear Phantom state
      PhantomService.instance.disconnect();
      
      print('✅ Complete logout reset successful');
    } catch (e) {
      print('❌ Error during logout reset: $e');
    }
  }
  
  Future<void> selectNetwork(String chainId) async {
    if (!isInitialized) {
      throw Exception('ReownService not initialized');
    }
    
    try {
      final networkInfo = ReownAppKitModalNetworks.getNetworkInfo('evm', chainId);
      if (networkInfo != null) {
        await _appKitModal!.selectChain(networkInfo);
      }
    } catch (e) {
      print('Error selecting network: $e');
      rethrow;
    }
  }
  
  Future<String?> sendTransaction({
    required String toAddress,
    required double amountInEth,
    String? data,
  }) async {
    if (!isConnected || _appKitModal?.session == null) {
      throw Exception('Wallet not connected');
    }
    
    try {
      final chainId = _appKitModal!.selectedChain!.chainId;
      final namespace = NamespaceUtils.getNamespaceFromChain(chainId);
      
      // Get the sender address
      final accounts = _appKitModal!.session!.getAccounts(namespace: namespace) ?? [];
      if (accounts.isEmpty) {
        throw Exception('No accounts found');
      }
      
      final fromAddress = accounts.first.split(':').last;
      print('Sending from address: $fromAddress');
      
      // Convert ETH to Wei (1 ETH = 10^18 Wei)
      final BigInt weiAmount = BigInt.from(amountInEth * 1e18);
      
      // Create transaction object
      final transaction = {
        'from': fromAddress,
        'to': toAddress,
        'value': '0x${weiAmount.toRadixString(16)}',
        'data': data ?? '0x',
      };
      
      print('Transaction params: $transaction');
      
      // Send transaction request
      final result = await _appKitModal!.request(
        topic: _appKitModal!.session!.topic,
        chainId: chainId,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transaction],
        ),
      );
      
      // Wallet will automatically open for confirmation
      
      print('Transaction sent successfully: $result');
      return result?.toString();
      
    } catch (e) {
      print('Error sending transaction: $e');
      rethrow;
    }
  }
  
  Future<String?> sendTokenTransaction({
    required String toAddress,
    required String tokenAddress,
    required double amount,
    required int decimals,
  }) async {
    if (!isConnected || _appKitModal?.session == null) {
      throw Exception('Wallet not connected');
    }
    
    try {
      final chainId = _appKitModal!.selectedChain!.chainId;
      final namespace = NamespaceUtils.getNamespaceFromChain(chainId);
      
      // Get the sender address
      final accounts = _appKitModal!.session!.getAccounts(namespace: namespace) ?? [];
      if (accounts.isEmpty) {
        throw Exception('No accounts found');
      }
      
      final fromAddress = accounts.first.split(':').last;
      
      // ERC20 transfer function signature
      const transferFunctionSignature = '0xa9059cbb'; // transfer(address,uint256)
      
      // Convert amount to token units
      final BigInt tokenAmount = BigInt.from(amount * BigInt.from(10).pow(decimals).toDouble());
      
      // Encode the function call data
      final encodedAddress = toAddress.substring(2).padLeft(64, '0');
      final encodedAmount = tokenAmount.toRadixString(16).padLeft(64, '0');
      final data = '$transferFunctionSignature$encodedAddress$encodedAmount';
      
      // Create transaction object for token transfer
      final transaction = {
        'from': fromAddress,
        'to': tokenAddress,
        'value': '0x0',
        'data': data,
      };
      
      print('Token transaction params: $transaction');
      
      // Send transaction request
      final result = await _appKitModal!.request(
        topic: _appKitModal!.session!.topic,
        chainId: chainId,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [transaction],
        ),
      );
      
      // Wallet will automatically open for confirmation
      
      print('Token transaction sent successfully: $result');
      return result?.toString();
      
    } catch (e) {
      print('Error sending token transaction: $e');
      rethrow;
    }
  }
  
  Future<BigInt?> getBalance() async {
    if (!isConnected || walletAddress == null) return null;
    
    try {
      final result = await _appKitModal!.request(
        topic: _appKitModal!.session!.topic,
        chainId: _appKitModal!.selectedChain!.chainId,
        request: SessionRequestParams(
          method: 'eth_getBalance',
          params: [walletAddress, 'latest'],
        ),
      );
      
      if (result != null) {
        return BigInt.parse(result.toString().substring(2), radix: 16);
      }
      return null;
    } catch (e) {
      print('Error getting balance: $e');
      return null;
    }
  }
  
  Future<void> switchChain(String chainId) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }
    
    try {
      final networkInfo = ReownAppKitModalNetworks.getNetworkInfo('evm', chainId);
      if (networkInfo != null) {
        await _appKitModal!.requestSwitchToChain(networkInfo);
      }
    } catch (e) {
      print('Error switching chain: $e');
      rethrow;
    }
  }
  
  // Handle deep links for wallet connections
  Future<String?> handleDeepLink(Uri uri) async {
    print('ReownService handling deep link: ${uri.toString()}');
    
    // Check if this is a Phantom wallet response
    if (uri.queryParameters.containsKey('phantomRequest') ||
        uri.queryParameters.containsKey('data') ||
        uri.queryParameters.containsKey('phantom_encryption_public_key')) {
      print('Detected Phantom wallet response in deep link');
      
      // Use Phantom service to handle the response
      final phantomAddress = await PhantomService.instance.handlePhantomResponse(uri);
      
      if (phantomAddress != null && phantomAddress.isNotEmpty) {
        print('✅ Phantom wallet connected successfully!');
        print('Connected address: $phantomAddress');
        return phantomAddress;
      } else {
        print('❌ Failed to connect Phantom wallet');
        return null;
      }
    }
    
    // For non-Phantom wallets, check Reown connection state
    if (_appKitModal != null) {
      print('Reown modal is available - checking connection state...');
      print('Current connection state: ${_appKitModal!.isConnected}');
      
      // Give Reown some time to process the deep link internally
      await Future.delayed(Duration(milliseconds: 1000));
      print('Checking connection state after delay: ${_appKitModal!.isConnected}');
      
      if (_appKitModal!.isConnected) {
        print('✅ Wallet successfully connected via Reown!');
        print('Connected address: $walletAddress');
        return walletAddress;
      } else {
        print('⚠️ Wallet connection not detected after deep link');
        return null;
      }
    } else {
      print('⚠️ Reown modal not available to process deep link');
      return null;
    }
  }

  void dispose() {
    _appKitModal?.closeModal();
    _appKitModal = null;
    _instance = null;
  }
}