import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/metamask_service.dart';

// Provider for the MetaMask service
final metamaskServiceProvider = Provider<MetaMaskService>((ref) {
  final service = MetaMaskService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// MetaMask connection state
enum MetaMaskConnectionStatus { disconnected, connecting, connected, error }

// MetaMask state
class MetaMaskState {
  final MetaMaskConnectionStatus status;
  final String? walletAddress;
  final String? errorMessage;
  final bool isLoading;

  MetaMaskState({
    required this.status,
    this.walletAddress,
    this.errorMessage,
    this.isLoading = false,
  });

  MetaMaskState copyWith({
    MetaMaskConnectionStatus? status,
    String? walletAddress,
    String? errorMessage,
    bool? isLoading,
  }) {
    return MetaMaskState(
      status: status ?? this.status,
      walletAddress: walletAddress ?? this.walletAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// MetaMask notifier
class MetaMaskNotifier extends StateNotifier<MetaMaskState> {
  final MetaMaskService _metamaskService;

  MetaMaskNotifier(this._metamaskService)
    : super(MetaMaskState(status: MetaMaskConnectionStatus.disconnected));

  /// Connect to MetaMask
  Future<bool> connectMetaMask(BuildContext context) async {
    // If already connected, return true
    if (state.status == MetaMaskConnectionStatus.connected &&
        state.walletAddress != null) {
      return true;
    }

    // Update state to connecting
    state = state.copyWith(
      status: MetaMaskConnectionStatus.connecting,
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Check if MetaMask is installed
      final isInstalled = await _metamaskService.isMetaMaskInstalled();

      if (!isInstalled) {
        state = state.copyWith(
          status: MetaMaskConnectionStatus.error,
          errorMessage: 'MetaMask is not installed on your device',
          isLoading: false,
        );
        return false;
      }

      // Connect to MetaMask
      debugPrint("🔄 Initiating MetaMask connection");

      final walletAddress = await _metamaskService.connectToMetaMask(context);

      if (walletAddress != null) {
        debugPrint("✅ Successfully connected with address: $walletAddress");

        // Update state to connected
        state = state.copyWith(
          status: MetaMaskConnectionStatus.connected,
          walletAddress: walletAddress,
          isLoading: false,
        );

        return true;
      } else {
        debugPrint("❌ MetaMask connection failed");

        // Update state to error
        state = state.copyWith(
          status: MetaMaskConnectionStatus.error,
          errorMessage: 'Failed to connect to MetaMask',
          isLoading: false,
        );

        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception during MetaMask connection - $e");

      // Update state to error
      state = state.copyWith(
        status: MetaMaskConnectionStatus.error,
        errorMessage: 'Error: ${e.toString()}',
        isLoading: false,
      );

      return false;
    }
  }

  /// Disconnect MetaMask
  Future<bool> disconnectMetaMask() async {
    state = state.copyWith(isLoading: true);

    try {
      state = state.copyWith(
        status: MetaMaskConnectionStatus.disconnected,
        walletAddress: null,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        status: MetaMaskConnectionStatus.error,
        errorMessage: 'Error disconnecting: ${e.toString()}',
        isLoading: false,
      );

      return false;
    }
  }

  /// Handle deep link from MetaMask
  Future<void> handleDeepLink(Uri uri) async {
    await _metamaskService.handleDeepLink(uri);
  }
}

// Provider for MetaMask state
final metamaskProvider = StateNotifierProvider<MetaMaskNotifier, MetaMaskState>(
  (ref) {
    final metamaskService = ref.watch(metamaskServiceProvider);
    return MetaMaskNotifier(metamaskService);
  },
);
