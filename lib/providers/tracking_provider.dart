import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/transaction_model.dart';
import '../core/services/tracking_service.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';
import 'package:flutter/material.dart';

// Enhanced Tracking Types
enum TrackingType { send, receive }

enum TransferStatus {
  pending,
  processing,
  inTransit,
  delivered,
  completed,
  failed,
  cancelled,
}

// Enhanced Tracking State
class TrackingState {
  final bool isLoading;
  final bool isValidating;
  final String? error;
  final String? message;
  final TrackingType trackingType;
  final String? trackingNumber;
  final Transaction? transaction;
  final StatusDetails? statusDetails;
  final List<Transaction> recentTransactions;
  final Map<String, String>? validationErrors;
  final bool isNetworkAvailable;

  const TrackingState({
    this.isLoading = false,
    this.isValidating = false,
    this.error,
    this.message,
    this.trackingType = TrackingType.send,
    this.trackingNumber,
    this.transaction,
    this.statusDetails,
    this.recentTransactions = const [],
    this.validationErrors,
    this.isNetworkAvailable = true,
  });

  TrackingState copyWith({
    bool? isLoading,
    bool? isValidating,
    String? error,
    String? message,
    TrackingType? trackingType,
    String? trackingNumber,
    Transaction? transaction,
    StatusDetails? statusDetails,
    List<Transaction>? recentTransactions,
    Map<String, String>? validationErrors,
    bool? isNetworkAvailable,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      isValidating: isValidating ?? this.isValidating,
      error: error,
      message: message,
      trackingType: trackingType ?? this.trackingType,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      transaction: transaction ?? this.transaction,
      statusDetails: statusDetails ?? this.statusDetails,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      validationErrors: validationErrors,
      isNetworkAvailable: isNetworkAvailable ?? this.isNetworkAvailable,
    );
  }

  bool get hasValidationErrors => validationErrors?.isNotEmpty == true;
  bool get isProcessing => isLoading || isValidating;
  bool get hasTransaction => transaction != null;
}

// Tracking Service Provider
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  // Ensure token is set if user is authenticated
  final authState = ref.watch(authProvider);
  if (authState.user?.token != null) {
    apiClient.setToken(authState.user!.token!);
  }

  return TrackingService(apiClient);
});

// Enhanced Tracking Notifier
class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingService _trackingService;
  final Ref _ref;

  TrackingNotifier(this._trackingService, this._ref)
      : super(const TrackingState()) {
    _loadRecentTransactions();
  }

  // Clear all states
  void clearState() {
    state = const TrackingState();
  }

  // Clear specific error
  void clearError() {
    state = state.copyWith(error: null, validationErrors: null);
  }

  // Set tracking type
  void setTrackingType(TrackingType type) {
    state = state.copyWith(
      trackingType: type,
      error: null,
      validationErrors: null,
    );
  }

  // Real-time validation for tracking number
  void validateTrackingNumber(String trackingNumber) {
    final errors = <String, String>{};
    final cleanNumber = trackingNumber.trim().toUpperCase();

    if (cleanNumber.isEmpty) {
      errors['trackingNumber'] = 'Tracking number is required';
    } else if (cleanNumber.length < 10) {
      errors['trackingNumber'] =
          'Tracking number must be at least 10 characters';
    } else if (!RegExp(r'^[A-Z0-9-]{10,25}$').hasMatch(cleanNumber)) {
      errors['trackingNumber'] = 'Invalid tracking number format';
    }

    state = state.copyWith(
      validationErrors: errors.isEmpty ? null : errors,
      trackingNumber: cleanNumber,
    );
  }

  // Track transfer with enhanced error handling
  Future<bool> trackTransfer({required String trackingNumber}) async {
    final cleanNumber = trackingNumber.trim().toUpperCase();

    print('🎯 Starting tracking for: $cleanNumber');

    // Validate first
    validateTrackingNumber(cleanNumber);
    if (state.hasValidationErrors) {
      print('❌ Validation failed: ${state.validationErrors}');
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      transaction: null,
      statusDetails: null,
    );

    try {
      // Call tracking API directly (removed problematic connectivity check)
      print('📡 Calling tracking service...');
      final response = await _trackingService.trackTransfer(cleanNumber);

      print(
          '✅ Got response: success=${response.success}, data=${response.data != null}');

      if (response.success && response.data != null) {
        print('📋 Parsing transaction data...');
        final transactionData = TransactionData.fromJson(response.data!);

        print(
            '🎉 Transaction found: ${transactionData.transaction.trackingNumber}');

        // Add to recent transactions if not already present
        _addToRecentTransactions(transactionData.transaction);

        state = state.copyWith(
          isLoading: false,
          transaction: transactionData.transaction,
          statusDetails: transactionData.statusDetails,
          message: 'Transfer found successfully',
          trackingNumber: cleanNumber,
        );

        return true;
      } else {
        print('❌ Response not successful or no data');
        // Handle specific error codes
        String errorMessage = response.message ?? 'Transfer not found';

        if (response.data != null && response.data!['errorCode'] != null) {
          errorMessage = _getErrorMessage(response.data!['errorCode']);
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      print('💥 Exception in tracking: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to track transfer. Please try again later.',
      );
      return false;
    }
  }

  // Get specific error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'TRACKING_NOT_FOUND':
        return 'No transfer found with this tracking number';
      case 'TRACKING_EXPIRED':
        return 'This tracking number has expired';
      case 'TRACKING_INVALID_FORMAT':
        return 'Invalid tracking number format';
      case 'TRACKING_ACCESS_DENIED':
        return 'You do not have permission to view this transfer';
      case 'SERVICE_UNAVAILABLE':
        return 'Tracking service is temporarily unavailable';
      default:
        return 'Unable to track transfer at this time';
    }
  }

  // Load recent transactions
  Future<void> _loadRecentTransactions() async {
    try {
      // This would be implemented with a proper API endpoint
      // For now, we'll keep it empty
      state = state.copyWith(recentTransactions: []);
    } catch (e) {
      // Silently handle error for recent transactions
    }
  }

  // Add to recent transactions
  void _addToRecentTransactions(Transaction transaction) {
    final recent = List<Transaction>.from(state.recentTransactions);

    // Remove if already exists
    recent.removeWhere((t) => t.trackingNumber == transaction.trackingNumber);

    // Add to beginning
    recent.insert(0, transaction);

    // Keep only last 10
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }

    state = state.copyWith(recentTransactions: recent);
  }

  // Refresh transfer details
  Future<void> refreshTransactionDetails() async {
    if (state.trackingNumber == null) return;

    await trackTransfer(trackingNumber: state.trackingNumber!);
  }
}

// Enhanced Tracking Provider
final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) {
    final trackingService = ref.watch(trackingServiceProvider);
    return TrackingNotifier(trackingService, ref);
  },
);

// Computed providers for specific states
final trackingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(trackingProvider).isProcessing;
});

final trackingErrorProvider = Provider<String?>((ref) {
  return ref.watch(trackingProvider).error;
});

final transactionProvider = Provider<Transaction?>((ref) {
  return ref.watch(trackingProvider).transaction;
});

final statusDetailsProvider = Provider<StatusDetails?>((ref) {
  return ref.watch(trackingProvider).statusDetails;
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(trackingProvider).recentTransactions;
});

final trackingValidationErrorsProvider = Provider<Map<String, String>?>((ref) {
  return ref.watch(trackingProvider).validationErrors;
});

final isNetworkAvailableProvider = Provider<bool>((ref) {
  return ref.watch(trackingProvider).isNetworkAvailable;
});

// Transfer status color provider
final transferStatusColorProvider = Provider.family<Color, String>((
  ref,
  status,
) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'processing':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    case 'failed':
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
});

// Import statements needed
