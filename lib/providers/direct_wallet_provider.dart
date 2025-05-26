// lib/providers/direct_wallet_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/common/wallet_selector_sheet.dart';
import '../core/services/direct_wallet_service.dart';

// Provider for enhanced wallet service
final directWalletServiceProvider = Provider<EnhancedDirectWalletService>((
  ref,
) {
  final service = EnhancedDirectWalletService(
    appPackageName: 'com.example.flash_transfer_app',
    appUniversalLink: 'https://flash.closedsource.in/connect',
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Enhanced wallet connection state
enum WalletConnectionStatus {
  disconnected,
  detecting, // Checking wallet installation
  connecting,
  connected,
  error,
  timeout, // Connection timeout
  cancelled, // User cancelled
}

// Enhanced wallet state
class WalletState {
  final WalletConnectionStatus status;
  final String? walletAddress;
  final String? walletType;
  final String? errorMessage;
  final bool isLoading;
  final String? signature;
  final Map<String, dynamic>? metadata;
  final DateTime? connectedAt;
  final bool _forceSelection; // Internal flag to force wallet selection

  WalletState({
    required this.status,
    this.walletAddress,
    this.walletType,
    this.errorMessage,
    this.isLoading = false,
    this.signature,
    this.metadata,
    this.connectedAt,
    bool forceSelection = false,
  }) : _forceSelection = forceSelection;

  WalletState copyWith({
    WalletConnectionStatus? status,
    String? walletAddress,
    String? walletType,
    String? errorMessage,
    bool? isLoading,
    String? signature,
    Map<String, dynamic>? metadata,
    DateTime? connectedAt,
    bool? forceSelection,
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
      forceSelection: forceSelection ?? this._forceSelection,
    );
  }

  // Helper methods
  bool get isConnected =>
      status == WalletConnectionStatus.connected &&
      walletAddress != null &&
      walletAddress!.isNotEmpty &&
      !_forceSelection; // Don't consider connected if forcing selection

  bool get isConnecting =>
      status == WalletConnectionStatus.connecting ||
      status == WalletConnectionStatus.detecting;

  bool get hasError =>
      status == WalletConnectionStatus.error ||
      status == WalletConnectionStatus.timeout;

  String get displayAddress {
    if (walletAddress == null || walletAddress!.isEmpty) return '';
    if (walletAddress!.length <= 10) return walletAddress!;
    return '${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)}';
  }

  String get statusDescription {
    switch (status) {
      case WalletConnectionStatus.disconnected:
        return 'Not connected';
      case WalletConnectionStatus.detecting:
        return 'Detecting wallets...';
      case WalletConnectionStatus.connecting:
        return 'Connecting to wallet...';
      case WalletConnectionStatus.connected:
        return 'Connected to ${walletType ?? 'wallet'}';
      case WalletConnectionStatus.error:
        return errorMessage ?? 'Connection error';
      case WalletConnectionStatus.timeout:
        return 'Connection timed out';
      case WalletConnectionStatus.cancelled:
        return 'Connection cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case WalletConnectionStatus.connected:
        return Colors.green;
      case WalletConnectionStatus.connecting:
      case WalletConnectionStatus.detecting:
        return Colors.orange;
      case WalletConnectionStatus.error:
      case WalletConnectionStatus.timeout:
        return Colors.red;
      case WalletConnectionStatus.cancelled:
        return Colors.grey;
      case WalletConnectionStatus.disconnected:
        return Colors.grey.shade600;
    }
  }

  @override
  String toString() {
    return 'WalletState(status: $status, address: $displayAddress, type: $walletType, error: $errorMessage, forceSelection: $_forceSelection)';
  }
}

// Enhanced wallet notifier
class DirectWalletNotifier extends StateNotifier<WalletState> {
  final EnhancedDirectWalletService _walletService;

  DirectWalletNotifier(this._walletService)
    : super(WalletState(status: WalletConnectionStatus.disconnected)) {
    // Load cached wallet data on initialization
    _loadCachedWalletData();
  }

  /// Load cached wallet data from SharedPreferences
  Future<void> _loadCachedWalletData() async {
    try {
      debugPrint('🔄 DirectWalletNotifier: Loading cached wallet data');
      final prefs = await SharedPreferences.getInstance();

      final cachedAddress = prefs.getString('wallet_address');
      final cachedType = prefs.getString('wallet_type');
      final cachedSignature = prefs.getString('wallet_signature');
      final cachedMetadataString = prefs.getString('wallet_metadata');

      if (cachedAddress != null &&
          cachedAddress.isNotEmpty &&
          cachedType != null) {
        Map<String, dynamic>? cachedMetadata;
        if (cachedMetadataString != null) {
          try {
            cachedMetadata = Map<String, dynamic>.from(
              jsonDecode(cachedMetadataString),
            );
          } catch (e) {
            debugPrint('⚠️ Error parsing cached metadata: $e');
          }
        }

        // Load cached data but mark for forced selection on next connect
        state = state.copyWith(
          status: WalletConnectionStatus.connected,
          walletAddress: cachedAddress,
          walletType: cachedType,
          signature: cachedSignature,
          metadata: cachedMetadata,
          connectedAt: DateTime.now(),
          forceSelection: true, // Force fresh connection attempt
        );

        debugPrint(
          '✅ DirectWalletNotifier: Loaded cached wallet data - ${cachedType}: ${state.displayAddress} (will force selection on next connect)',
        );
      } else {
        debugPrint('ℹ️ DirectWalletNotifier: No cached wallet data found');
      }
    } catch (e) {
      debugPrint(
        '❌ DirectWalletNotifier: Error loading cached wallet data - $e',
      );
    }
  }

  /// Clear all cached wallet data
  Future<void> _clearCachedData() async {
    try {
      debugPrint('🔄 DirectWalletNotifier: Clearing cached wallet data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_address');
      await prefs.remove('wallet_type');
      await prefs.remove('wallet_signature');
      await prefs.remove('wallet_metadata');
      debugPrint('✅ DirectWalletNotifier: Cached wallet data cleared');
    } catch (e) {
      debugPrint('❌ DirectWalletNotifier: Error clearing cached data - $e');
    }
  }

  /// Connect to wallet with enhanced error handling and state management
  Future<bool> connectWallet(
    BuildContext context, {
    bool forceNewConnection = false,
  }) async {
    debugPrint(
      "🔄 DirectWalletNotifier: Starting enhanced wallet connection (forceNew: $forceNewConnection)",
    );

    // CRITICAL FIX: Always clear cache and force fresh wallet selection
    // This prevents the cached address bug
    await _clearCachedData();

    // Always reset state and force fresh selection
    state = state.copyWith(
      status: WalletConnectionStatus.detecting,
      isLoading: true,
      errorMessage: null,
      walletAddress: null,
      walletType: null,
      signature: null,
      metadata: null,
      connectedAt: null,
      forceSelection: false,
    );

    debugPrint(
      "🔄 DirectWalletNotifier: Cache cleared, forcing fresh wallet selection",
    );

    try {
      // Update to connecting state
      state = state.copyWith(
        status: WalletConnectionStatus.connecting,
        isLoading: true,
      );

      final response = await _walletService.connectWallet(context);

      if (response.connected && response.walletAddress != null) {
        debugPrint(
          "✅ DirectWalletNotifier: Successfully connected with address: ${response.walletAddress}",
        );

        // Update state to connected with full response data
        state = state.copyWith(
          status: WalletConnectionStatus.connected,
          walletAddress: response.walletAddress,
          walletType: response.walletType,
          signature: response.signature,
          metadata: response.metadata,
          connectedAt: DateTime.now(),
          isLoading: false,
          errorMessage: null,
          forceSelection: false, // Clear force selection flag
        );

        // Show success feedback if context is still mounted
        if (context.mounted) {
          _showSuccessSnackBar(context, response.walletType ?? 'Wallet');
        }

        return true;
      } else {
        debugPrint(
          "❌ DirectWalletNotifier: Connection failed - ${response.error}",
        );

        // Determine appropriate status based on error
        final status = _determineErrorStatus(response.error);

        // Update state to error with detailed message
        state = state.copyWith(
          status: status,
          errorMessage: response.error ?? 'Failed to connect wallet',
          isLoading: false,
        );

        // Show error feedback if context is still mounted
        if (context.mounted) {
          _showErrorSnackBar(context, response.error ?? 'Connection failed');
        }

        return false;
      }
    } catch (e) {
      debugPrint("❌ DirectWalletNotifier: Exception during connection - $e");

      // Handle different exception types
      final errorMessage = _getErrorMessage(e);
      final status = _determineErrorStatus(errorMessage);

      // Update state to error
      state = state.copyWith(
        status: status,
        errorMessage: errorMessage,
        isLoading: false,
      );

      // Show error feedback if context is still mounted
      if (context.mounted) {
        _showErrorSnackBar(context, errorMessage);
      }

      return false;
    }
  }

  /// Disconnect wallet with proper cleanup
  Future<bool> disconnectWallet() async {
    debugPrint('🔄 DirectWalletNotifier: Disconnecting wallet');

    state = state.copyWith(isLoading: true);

    try {
      // Clear cached data first
      await _clearCachedData();

      // Call service disconnect
      final disconnected = await _walletService.disconnectWallet();

      // Always reset state regardless of service result
      state = state.copyWith(
        status: WalletConnectionStatus.disconnected,
        walletAddress: null,
        walletType: null,
        signature: null,
        metadata: null,
        connectedAt: null,
        isLoading: false,
        errorMessage: null,
        forceSelection: false,
      );

      debugPrint(
        '✅ DirectWalletNotifier: Wallet disconnected and cache cleared',
      );
      return disconnected;
    } catch (e) {
      debugPrint('❌ DirectWalletNotifier: Error during disconnect - $e');

      // Still reset state and clear cache even if service call failed
      await _clearCachedData();
      state = state.copyWith(
        status: WalletConnectionStatus.disconnected,
        walletAddress: null,
        walletType: null,
        signature: null,
        metadata: null,
        connectedAt: null,
        isLoading: false,
        errorMessage: null,
        forceSelection: false,
      );

      return false;
    }
  }

  /// Handle deep link from wallet with enhanced logging
  Future<void> handleDeepLink(Uri uri) async {
    debugPrint(
      '🔗 DirectWalletNotifier: Handling deep link - ${uri.toString()}',
    );

    try {
      await _walletService.handleDeepLink(uri);
      debugPrint('✅ DirectWalletNotifier: Deep link handled successfully');
    } catch (e) {
      debugPrint('❌ DirectWalletNotifier: Error handling deep link - $e');

      state = state.copyWith(
        status: WalletConnectionStatus.error,
        errorMessage: 'Deep link handling failed: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Retry connection with exponential backoff
  Future<bool> retryConnection(BuildContext context, {int attempt = 1}) async {
    if (state.isConnecting) {
      debugPrint(
        '⚠️ DirectWalletNotifier: Connection already in progress, skipping retry',
      );
      return false;
    }

    debugPrint(
      '🔄 DirectWalletNotifier: Retrying wallet connection (attempt $attempt)',
    );

    // Add progressive delay for retries
    if (attempt > 1) {
      final delayMs = (attempt - 1) * 1000; // 1s, 2s, 3s, etc.
      debugPrint('⏱️ Waiting ${delayMs}ms before retry...');
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    return await connectWallet(context, forceNewConnection: true);
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      debugPrint('🔄 DirectWalletNotifier: Clearing error state');
      state = state.copyWith(
        status: WalletConnectionStatus.disconnected,
        errorMessage: null,
      );
    }
  }

  /// Force refresh wallet connection state
  Future<void> refreshConnection() async {
    debugPrint('🔄 DirectWalletNotifier: Refreshing connection state');

    if (state.isConnected && state.walletAddress != null) {
      // Validate that the connection is still valid
      // This could include checking if the wallet app is still responsive
      state = state.copyWith(
        metadata: {
          ...?state.metadata,
          'last_refreshed': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Get detailed connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'status': state.status.toString(),
      'wallet_type': state.walletType,
      'wallet_address': state.walletAddress,
      'connected_at': state.connectedAt?.toIso8601String(),
      'has_signature': state.signature != null,
      'metadata': state.metadata,
      'error_message': state.errorMessage,
      'force_selection': state._forceSelection,
    };
  }

  // Private helper methods
  WalletConnectionStatus _determineErrorStatus(String? error) {
    if (error == null) return WalletConnectionStatus.error;

    final errorLower = error.toLowerCase();

    if (errorLower.contains('timeout') || errorLower.contains('timed out')) {
      return WalletConnectionStatus.timeout;
    }

    if (errorLower.contains('cancel') || errorLower.contains('cancelled')) {
      return WalletConnectionStatus.cancelled;
    }

    return WalletConnectionStatus.error;
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    }

    if (error is PlatformException) {
      return 'Platform error: ${error.message ?? error.code}';
    }

    final errorString = error.toString();

    // Common error patterns with user-friendly messages
    if (errorString.contains('No wallet selected')) {
      return 'Please select a wallet to connect';
    }

    if (errorString.contains('Failed to launch')) {
      return 'Could not open wallet app. Please ensure it is installed.';
    }

    if (errorString.contains('User cancelled') ||
        errorString.contains('cancelled')) {
      return 'Connection cancelled';
    }

    if (errorString.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }

    if (errorString.contains('not installed')) {
      return 'Wallet app is not installed on your device';
    }

    if (errorString.contains('permission')) {
      return 'Permission required to connect to wallet';
    }

    // Generic fallback
    return 'Connection failed. Please try again.';
  }

  void _showSuccessSnackBar(BuildContext context, String walletName) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Connected to $walletName successfully!')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not show success snackbar: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              retryConnection(context);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not show error snackbar: $e');
    }
  }
}

// Provider for enhanced wallet state
final directWalletProvider =
    StateNotifierProvider<DirectWalletNotifier, WalletState>((ref) {
      final walletService = ref.watch(directWalletServiceProvider);
      return DirectWalletNotifier(walletService);
    });

// Convenience providers for common state checks
final isWalletConnectedProvider = Provider<bool>((ref) {
  final walletState = ref.watch(directWalletProvider);
  return walletState.isConnected;
});

final walletAddressProvider = Provider<String?>((ref) {
  final walletState = ref.watch(directWalletProvider);
  return walletState.walletAddress;
});

final walletTypeProvider = Provider<String?>((ref) {
  final walletState = ref.watch(directWalletProvider);
  return walletState.walletType;
});

final isWalletLoadingProvider = Provider<bool>((ref) {
  final walletState = ref.watch(directWalletProvider);
  return walletState.isLoading;
});
