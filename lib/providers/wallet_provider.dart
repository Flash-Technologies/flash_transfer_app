import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/wallet_service.dart';

// Provider for wallet service
final walletServiceProvider = Provider<WalletService>((ref) {
  final service = WalletService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Wallet connection state
enum WalletConnectionStatus { disconnected, connecting, connected, error }

// Wallet state
class WalletState {
  final WalletConnectionStatus status;
  final String? walletAddress;
  final String? walletType;
  final String? errorMessage;
  final bool isLoading;
  final String? signature;
  final Map<String, dynamic>? metadata;
  final DateTime? connectedAt;

  WalletState({
    required this.status,
    this.walletAddress,
    this.walletType,
    this.errorMessage,
    this.isLoading = false,
    this.signature,
    this.metadata,
    this.connectedAt,
  });

  WalletState copyWith({
    WalletConnectionStatus? status,
    String? walletAddress,
    String? walletType,
    String? errorMessage,
    bool? isLoading,
    String? signature,
    Map<String, dynamic>? metadata,
    DateTime? connectedAt,
  }) {
    return WalletState(
      status: status ?? this.status,
      walletAddress: walletAddress ?? this.walletAddress,
      walletType: walletType ?? this.walletType,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      signature: signature ?? this.signature,
      metadata: metadata ?? this.metadata,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  // Helper methods
  bool get isConnected => status == WalletConnectionStatus.connected && walletAddress != null;
  bool get isConnecting => status == WalletConnectionStatus.connecting;
  bool get hasError => status == WalletConnectionStatus.error;
  
  String get displayAddress {
    if (walletAddress == null) return '';
    if (walletAddress!.length <= 10) return walletAddress!;
    return '${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)}';
  }
}

// Wallet notifier
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletService _walletService;

  WalletNotifier(this._walletService)
    : super(WalletState(status: WalletConnectionStatus.disconnected));

  Future<bool> connectWallet(BuildContext context) async {
    state = state.copyWith(
      status: WalletConnectionStatus.connecting,
      isLoading: true,
      errorMessage: null,
    );

    try {
      debugPrint("🔄 WalletProvider: Initiating wallet connection");
      final response = await _walletService.connectWallet(context);

      if (response.connected && response.walletAddress != null) {
        debugPrint(
          "✅ WalletProvider: Successfully connected with address: ${response.walletAddress}",
        );
        state = state.copyWith(
          status: WalletConnectionStatus.connected,
          walletAddress: response.walletAddress,
          isLoading: false,
        );
        return true;
      } else {
        debugPrint("❌ WalletProvider: Connection failed - ${response.error}");
        state = state.copyWith(
          status: WalletConnectionStatus.error,
          errorMessage: response.error ?? 'Failed to connect wallet',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ WalletProvider: Exception during connection - $e");
      state = state.copyWith(
        status: WalletConnectionStatus.error,
        errorMessage: 'Error: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> disconnectWallet() async {
    state = state.copyWith(isLoading: true);

    try {
      final disconnected = await _walletService.disconnectWallet();

      state = state.copyWith(
        status: WalletConnectionStatus.disconnected,
        walletAddress: null,
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
}

// Provider for wallet state
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  final walletService = ref.watch(walletServiceProvider);
  return WalletNotifier(walletService);
});
