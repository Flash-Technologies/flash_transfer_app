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

// Transfer Details Model
class TransferDetails {
  final String trackingNumber;
  final TransferStatus status;
  final String senderName;
  final String receiverName;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String receivingMethod;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<TrackingEvent> events;
  final Map<String, dynamic>? metadata;

  const TransferDetails({
    required this.trackingNumber,
    required this.status,
    required this.senderName,
    required this.receiverName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.receivingMethod,
    required this.createdAt,
    this.estimatedDelivery,
    this.actualDelivery,
    required this.events,
    this.metadata,
  });

  factory TransferDetails.fromJson(Map<String, dynamic> json) {
    return TransferDetails(
      trackingNumber: json['trackingNumber'] ?? '',
      status: TransferStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      senderName: json['senderName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentMethod: json['paymentMethod'] ?? '',
      receivingMethod: json['receivingMethod'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      estimatedDelivery:
          json['estimatedDelivery'] != null
              ? DateTime.parse(json['estimatedDelivery'])
              : null,
      actualDelivery:
          json['actualDelivery'] != null
              ? DateTime.parse(json['actualDelivery'])
              : null,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => TrackingEvent.fromJson(e))
              .toList() ??
          [],
      metadata: json['metadata'],
    );
  }

  String get statusDisplayName {
    switch (status) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.processing:
        return 'Processing';
      case TransferStatus.inTransit:
        return 'In Transit';
      case TransferStatus.delivered:
        return 'Delivered';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      ![
        TransferStatus.completed,
        TransferStatus.failed,
        TransferStatus.cancelled,
      ].contains(status);
}

// Tracking Event Model
class TrackingEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String location;
  final bool isCompleted;

  const TrackingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.isCompleted,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

// Enhanced Tracking State
class TrackingState {
  final bool isLoading;
  final bool isValidating;
  final String? error;
  final String? message;
  final TrackingType trackingType;
  final String? trackingNumber;
  final TransferDetails? transferDetails;
  final List<TransferDetails> recentTransfers;
  final Map<String, String>? validationErrors;
  final bool isNetworkAvailable;

  const TrackingState({
    this.isLoading = false,
    this.isValidating = false,
    this.error,
    this.message,
    this.trackingType = TrackingType.send,
    this.trackingNumber,
    this.transferDetails,
    this.recentTransfers = const [],
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
    TransferDetails? transferDetails,
    List<TransferDetails>? recentTransfers,
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
      transferDetails: transferDetails ?? this.transferDetails,
      recentTransfers: recentTransfers ?? this.recentTransfers,
      validationErrors: validationErrors,
      isNetworkAvailable: isNetworkAvailable ?? this.isNetworkAvailable,
    );
  }

  bool get hasValidationErrors => validationErrors?.isNotEmpty == true;
  bool get isProcessing => isLoading || isValidating;
}

// Tracking Service Provider
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrackingService(apiClient);
});

// Enhanced Tracking Notifier
class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingService _trackingService;
  final Ref _ref;

  TrackingNotifier(this._trackingService, this._ref)
    : super(const TrackingState()) {
    _loadRecentTransfers();
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
    } else if (cleanNumber.length != 10) {
      errors['trackingNumber'] =
          'Tracking number must be exactly 10 characters';
    } else if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(cleanNumber)) {
      errors['trackingNumber'] =
          'Tracking number can only contain letters and numbers';
    } else if (!_isValidFTNFormat(cleanNumber)) {
      errors['trackingNumber'] = 'Invalid Flash Tracking Number (FTN) format';
    }

    state = state.copyWith(
      validationErrors: errors.isEmpty ? null : errors,
      trackingNumber: cleanNumber,
    );
  }

  // Validate FTN format (Flash Tracking Number)
  bool _isValidFTNFormat(String trackingNumber) {
    // FTN format: 2 letters + 8 digits (example: FT12345678)
    return RegExp(r'^[A-Z]{2}[0-9]{8}$').hasMatch(trackingNumber);
  }

  // Track transfer with enhanced error handling
  Future<bool> trackTransfer({required String trackingNumber}) async {
    final cleanNumber = trackingNumber.trim().toUpperCase();

    // Validate first
    validateTrackingNumber(cleanNumber);
    if (state.hasValidationErrors) {
      return false;
    }

    state = state.copyWith(isLoading: true, error: null, transferDetails: null);

    try {
      // Check network connectivity
      final isConnected = await _checkNetworkConnectivity();
      if (!isConnected) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please check your network settings.',
          isNetworkAvailable: false,
        );
        return false;
      }

      // Call tracking API
      final response = await _trackingService.trackTransfer(cleanNumber);

      if (response.success && response.data != null) {
        final transferDetails = TransferDetails.fromJson(response.data!);

        // Add to recent transfers if not already present
        _addToRecentTransfers(transferDetails);

        state = state.copyWith(
          isLoading: false,
          transferDetails: transferDetails,
          message: 'Transfer found successfully',
          trackingNumber: cleanNumber,
        );

        return true;
      } else {
        // Handle specific error codes
        String errorMessage = response.message ?? 'Transfer not found';

        if (response.data != null && response.data!['errorCode'] != null) {
          errorMessage = _getErrorMessage(response.data!['errorCode']);
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
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

  // Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple connectivity check
      await _trackingService.ping();
      state = state.copyWith(isNetworkAvailable: true);
      return true;
    } catch (e) {
      state = state.copyWith(isNetworkAvailable: false);
      return false;
    }
  }

  // Load recent transfers
  Future<void> _loadRecentTransfers() async {
    try {
      final recentTransfers = await _trackingService.getRecentTransfers(
        limit: 5,
      );
      state = state.copyWith(recentTransfers: recentTransfers);
    } catch (e) {
      // Silently handle error for recent transfers
    }
  }

  // Add to recent transfers
  void _addToRecentTransfers(TransferDetails transfer) {
    final recent = List<TransferDetails>.from(state.recentTransfers);

    // Remove if already exists
    recent.removeWhere((t) => t.trackingNumber == transfer.trackingNumber);

    // Add to beginning
    recent.insert(0, transfer);

    // Keep only last 10
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }

    state = state.copyWith(recentTransfers: recent);
  }

  // Refresh transfer details
  Future<void> refreshTransferDetails() async {
    if (state.trackingNumber == null) return;

    await trackTransfer(trackingNumber: state.trackingNumber!);
  }

  // Get transfer updates in real-time
  Stream<TransferDetails> watchTransferUpdates(String trackingNumber) {
    return _trackingService.watchTransferUpdates(trackingNumber);
  }

  // Search transfers by criteria
  Future<List<TransferDetails>> searchTransfers({
    String? senderName,
    String? receiverName,
    DateTimeRange? dateRange,
    TransferStatus? status,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final transfers = await _trackingService.searchTransfers(
        senderName: senderName,
        receiverName: receiverName,
        dateRange: dateRange,
        status: status,
      );

      state = state.copyWith(isLoading: false);
      return transfers;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search transfers',
      );
      return [];
    }
  }

  // Get transfer statistics
  Future<Map<String, dynamic>> getTransferStatistics() async {
    try {
      return await _trackingService.getTransferStatistics();
    } catch (e) {
      return {};
    }
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

final transferDetailsProvider = Provider<TransferDetails?>((ref) {
  return ref.watch(trackingProvider).transferDetails;
});

final recentTransfersProvider = Provider<List<TransferDetails>>((ref) {
  return ref.watch(trackingProvider).recentTransfers;
});

final trackingValidationErrorsProvider = Provider<Map<String, String>?>((ref) {
  return ref.watch(trackingProvider).validationErrors;
});

final isNetworkAvailableProvider = Provider<bool>((ref) {
  return ref.watch(trackingProvider).isNetworkAvailable;
});

// Transfer status color provider
final transferStatusColorProvider = Provider.family<Color, TransferStatus>((
  ref,
  status,
) {
  switch (status) {
    case TransferStatus.pending:
      return Colors.orange;
    case TransferStatus.processing:
      return Colors.blue;
    case TransferStatus.inTransit:
      return Colors.purple;
    case TransferStatus.delivered:
    case TransferStatus.completed:
      return Colors.green;
    case TransferStatus.failed:
    case TransferStatus.cancelled:
      return Colors.red;
  }
});

// Import statements needed
