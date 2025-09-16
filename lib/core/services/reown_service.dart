import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

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
  bool get isConnected => _appKitModal?.isConnected ?? false;
  String? get walletAddress {
    if (!isConnected || _appKitModal?.session == null) return null;
    
    final chainId = _appKitModal!.selectedChain?.chainId;
    if (chainId == null) return null;
    
    final namespace = NamespaceUtils.getNamespaceFromChain(chainId);
    final accounts = _appKitModal!.session!.getAccounts(namespace: namespace) ?? [];
    
    if (accounts.isEmpty) return null;
    
    // Extract address from account string (format: "eip155:1:0x...")
    return accounts.first.split(':').last;
  }
  
  String? get selectedNetwork => _appKitModal?.selectedChain?.name;
  
  Future<void> initialize(BuildContext context) async {
    if (_appKitModal != null) {
      print('ReownService already initialized');
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
            universal: 'https://flash-transfer.com',
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
      
      print('ReownAppKitModal initialized successfully');
      print('Is connected: ${_appKitModal!.isConnected}');
      
    } catch (e) {
      print('Error initializing ReownAppKitModal: $e');
      _appKitModal = null;
      rethrow;
    }
  }
  
  void _setupEventListeners() {
    if (_appKitModal == null) return;
    
    // Listen to connection status changes
    _appKitModal!.onModalConnect.subscribe((ModalConnect? event) {
      print('Wallet connected: ${event?.session.topic}');
    });
    
    _appKitModal!.onModalDisconnect.subscribe((ModalDisconnect? event) {
      print('Wallet disconnected: ${event?.topic}');
    });
    
    _appKitModal!.onModalError.subscribe((ModalError? event) {
      print('Modal error: ${event?.message}');
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
  Future<String?> connectForAuth() async {
    if (!isInitialized) {
      throw Exception('ReownService not initialized');
    }
    
    try {
      print('Opening wallet modal for authentication...');
      
      // If already connected, return the address
      if (isConnected && walletAddress != null) {
        print('Already connected, returning address: $walletAddress');
        return walletAddress;
      }
      
      // Open modal and wait for connection
      await _appKitModal!.openModalView();
      
      // Wait a bit for the connection to establish
      int attempts = 0;
      while (!isConnected && attempts < 30) {
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }
      
      if (isConnected && walletAddress != null) {
        print('Wallet connected successfully: $walletAddress');
        return walletAddress;
      } else {
        print('Wallet connection failed or timed out');
        return null;
      }
    } catch (e) {
      print('Error in wallet authentication: $e');
      return null;
    }
  }
  
  Future<void> disconnect() async {
    if (!isInitialized || !isConnected) return;
    
    try {
      print('Disconnecting wallet...');
      await _appKitModal!.disconnect();
    } catch (e) {
      print('Error disconnecting wallet: $e');
      rethrow;
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
  
  void dispose() {
    _appKitModal?.closeModal();
    _appKitModal = null;
    _instance = null;
  }
}