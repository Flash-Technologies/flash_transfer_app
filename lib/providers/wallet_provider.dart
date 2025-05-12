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
  final String? errorMessage;
  final bool isLoading;

  WalletState({
    required this.status,
    this.walletAddress,
    this.errorMessage,
    this.isLoading = false,
  });

  WalletState copyWith({
    WalletConnectionStatus? status,
    String? walletAddress,
    String? errorMessage,
    bool? isLoading,
  }) {
    return WalletState(
      status: status ?? this.status,
      walletAddress: walletAddress ?? this.walletAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
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
      final response = await _walletService.connectWallet(context);

      if (response.connected && response.walletAddress != null) {
        state = state.copyWith(
          status: WalletConnectionStatus.connected,
          walletAddress: response.walletAddress,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          status: WalletConnectionStatus.error,
          errorMessage: response.error ?? 'Failed to connect wallet',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
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
