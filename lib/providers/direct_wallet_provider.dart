import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/direct_wallet_service.dart';
import '../presentation/common/wallet_selector_sheet.dart';

// Provider for wallet service
final directWalletServiceProvider = Provider<DirectWalletService>((ref) {
  final service = DirectWalletService(
    appPackageName: 'com.flash_transfer_app',
    appUniversalLink: 'https://flashtransfer.app/connect',
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// Wallet connection state
enum WalletConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

// Wallet state
class WalletState {
  final WalletConnectionStatus status;
  final String? walletAddress;
  final String? walletType;
  final String? errorMessage;
  final bool isLoading;

  WalletState({
    required this.status,
    this.walletAddress,
    this.walletType,
    this.errorMessage,
    this.isLoading = false,
  });

  WalletState copyWith({
    WalletConnectionStatus? status,
    String? walletAddress,
    String? walletType,
    String? errorMessage,
    bool? isLoading,
  }) {
    return WalletState(
      status: status ?? this.status,
      walletAddress: walletAddress ?? this.walletAddress,
      walletType: walletType ?? this.walletType,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Wallet notifier
class DirectWalletNotifier extends StateNotifier<WalletState> {
  final DirectWalletService _walletService;

  DirectWalletNotifier(this._walletService)
    : super(WalletState(status: WalletConnectionStatus.disconnected));

  /// Connect to wallet
  Future<bool> connectWallet(BuildContext context) async {
    // If already connected, return true
    if (state.status == WalletConnectionStatus.connected && 
        state.walletAddress != null) {
      return true;
    }
    
    // Update state to connecting
    state = state.copyWith(
      status: WalletConnectionStatus.connecting,
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Call wallet service to connect
      debugPrint("🔄 Initiating direct wallet connection");
      
      final response = await _walletService.connectWallet(context);

      if (response.connected && response.walletAddress != null) {
        debugPrint(
          "✅ Successfully connected with address: ${response.walletAddress}",
        );
        
        // Update state to connected
        state = state.copyWith(
          status: WalletConnectionStatus.connected,
          walletAddress: response.walletAddress,
          walletType: response.walletType,
          isLoading: false,
        );
        
        return true;
      } else {
        debugPrint("❌ Connection failed - ${response.error}");
        
        // Update state to error
        state = state.copyWith(
          status: WalletConnectionStatus.error,
          errorMessage: response.error ?? 'Failed to connect wallet',
          isLoading: false,
        );
        
        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception during connection - $e");
      
      // Update state to error
      state = state.copyWith(
        status: WalletConnectionStatus.error,
        errorMessage: 'Error: ${e.toString()}',
        isLoading: false,
      );
      
      return false;
    }
  }

  /// Disconnect wallet
  Future<bool> disconnectWallet() async {
    state = state.copyWith(isLoading: true);

    try {
      final disconnected = await _walletService.disconnectWallet();

      state = state.copyWith(
        status: WalletConnectionStatus.disconnected,
        walletAddress: null,
        walletType: null,
        isLoading: false,
      );

      return disconnected;
    } catch (e) {
      state = state.copyWith(
        status: WalletConnectionStatus.error,
        errorMessage: 'Error disconnecting: ${e.toString()}',
        isLoading: false,
      );
      
      return false;
    }
  }

  /// Handle deep link from wallet
  Future<void> handleDeepLink(Uri uri) async {
    await _walletService.handleDeepLink(uri);
  }
}

// Provider for wallet state
final directWalletProvider = StateNotifierProvider<DirectWalletNotifier, WalletState>((ref) {
  final walletService = ref.watch(directWalletServiceProvider);
  return DirectWalletNotifier(walletService);
});