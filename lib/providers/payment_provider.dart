import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/transaction_service.dart';
import '../core/models/transaction_estimate.dart';
import '../core/models/transaction_response.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import 'auth_provider.dart'; // Import auth provider

enum PaymentType {
  cash,
  wallet,
  card,
  bank,
  mobile,
  crypto,
  cryptoReceive,
  cryptoSendMobile,
}

enum PaymentStatus {
  idle,
  loading,
  success,
  error,
}

class PaymentState {
  final String activePay;
  final String activeReceive;
  final String? selectedProvider;
  final PaymentType? selectedPaymentType;
  final String? selectedWalletAddress;
  final TransactionEstimate? estimateData;
  final TransactionResponse? transactionData;
  final PaymentStatus estimateStatus;
  final PaymentStatus transactionStatus;
  final String? errorMessage;
  final Map<String, dynamic>? mobileMoneyDetails;

  PaymentState({
    this.activePay = 'cash',
    this.activeReceive = 'cash',
    this.selectedProvider,
    this.selectedPaymentType,
    this.selectedWalletAddress,
    this.estimateData,
    this.transactionData,
    this.estimateStatus = PaymentStatus.idle,
    this.transactionStatus = PaymentStatus.idle,
    this.errorMessage,
    this.mobileMoneyDetails,
  });

  PaymentState copyWith({
    String? activePay,
    String? activeReceive,
    String? selectedProvider,
    PaymentType? selectedPaymentType,
    String? selectedWalletAddress,
    TransactionEstimate? estimateData,
    TransactionResponse? transactionData,
    PaymentStatus? estimateStatus,
    PaymentStatus? transactionStatus,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? mobileMoneyDetails,
  }) {
    return PaymentState(
      activePay: activePay ?? this.activePay,
      activeReceive: activeReceive ?? this.activeReceive,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
      selectedWalletAddress:
          selectedWalletAddress ?? this.selectedWalletAddress,
      estimateData: estimateData ?? this.estimateData,
      transactionData: transactionData ?? this.transactionData,
      estimateStatus: estimateStatus ?? this.estimateStatus,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mobileMoneyDetails: mobileMoneyDetails ?? this.mobileMoneyDetails,
    );
  }

  bool get isEstimateLoading => estimateStatus == PaymentStatus.loading;
  bool get isTransactionLoading => transactionStatus == PaymentStatus.loading;
  bool get hasEstimateData => estimateData != null;
  bool get hasTransactionData => transactionData != null;
  bool get hasError => errorMessage != null;
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final TransactionService _transactionService;

  PaymentNotifier(this._transactionService) : super(PaymentState());

  void setActivePay(String method) {
    state = state.copyWith(activePay: method);
  }

  void setActiveReceive(String method) {
    state = state.copyWith(activeReceive: method);
  }

  void setSelectedProvider(String providerId) {
    state = state.copyWith(selectedProvider: providerId);
  }

  void setSelectedPaymentType(PaymentType paymentType) {
    state = state.copyWith(selectedPaymentType: paymentType);
  }

  void setSelectedWalletAddress(String walletAddress) {
    state = state.copyWith(selectedWalletAddress: walletAddress);
  }

  void setMobileMoneyDetails(Map<String, dynamic> details) {
    state = state.copyWith(mobileMoneyDetails: details);
  }

  /// Get transaction estimate for fiat to crypto flow
  Future<bool> getTransactionEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required String phoneNumber,
    required String provider,
    required String walletAddress,
  }) async {
    print('PaymentProvider: Starting getTransactionEstimate');
    print(
        'PaymentProvider: Parameters - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');

    state = state.copyWith(
      estimateStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      final estimate = await _transactionService.getTransactionEstimate(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        sourceType: 'MOBILE_MONEY',
        destinationType: 'CRYPTO_WALLET',
        blockchainNetwork: blockchainNetwork,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        mobileMoneyDetails: state.mobileMoneyDetails ?? {
          'phoneNumber': phoneNumber.toString(),
          'provider': provider,
          'firstName': 'Test',
          'lastName': 'User',
          'email': 'test@example.com',
        },
        walletAddress: walletAddress,
      );

      print(
          'PaymentProvider: Successfully got estimate: ${estimate.toString()}');

      state = state.copyWith(
        estimateData: estimate,
        estimateStatus: PaymentStatus.success,
        selectedWalletAddress: walletAddress,
      );

      print('PaymentProvider: State updated, returning true');
      return true;
    } catch (e) {
      print('PaymentProvider: Error in getTransactionEstimate: $e');
      state = state.copyWith(
        estimateStatus: PaymentStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Create transaction for fiat to crypto flow
  Future<bool> createTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required String language,
    required String phoneNumber,
    required String provider,
    required String walletAddress,
  }) async {
    print('PaymentProvider: Starting createTransaction');
    print(
        'PaymentProvider: Data - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');
    print(
        'PaymentProvider: Network: $blockchainNetwork, Country: $countryCode, PaymentMethod: $paymentMethod');
    print(
        'PaymentProvider: Phone: $phoneNumber, Provider: $provider, Wallet: $walletAddress');

    state = state.copyWith(
      transactionStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      final transaction = await _transactionService.createTransaction(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        language: language,
        paymentChannel: 'web',
        mobileMoneyDetails: {
          'phoneNumber': phoneNumber,
          'provider': provider,
        },
        walletAddress: walletAddress,
      );

      print(
          'PaymentProvider: Transaction created successfully: ${transaction.transactionId}');

      state = state.copyWith(
        transactionData: transaction,
        transactionStatus: PaymentStatus.success,
      );

      return true;
    } catch (e) {
      print('PaymentProvider: Error in createTransaction: $e');

      // Parse error message for better user feedback
      String errorMessage = e.toString();
      if (errorMessage.contains('503')) {
        errorMessage =
            'Service temporarily unavailable. Please try again in a few minutes.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (errorMessage.contains('400')) {
        errorMessage = 'Invalid transaction data. Please check your inputs.';
      }

      state = state.copyWith(
        transactionStatus: PaymentStatus.error,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  /// Get transaction estimate for crypto to cash flow
  Future<bool> getCryptoToCashEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String walletAddress,
    required String countryCode,
    required String paymentMethod,
  }) async {
    print('PaymentProvider: Starting getCryptoToCashEstimate');
    print(
        'PaymentProvider: Parameters - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');

    state = state.copyWith(
      estimateStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      // Get phone number from mobile money details
      final phoneNumber = state.mobileMoneyDetails?['phoneNumber'];

      final estimate = await _transactionService.getCryptoToCashEstimate(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        walletAddress: walletAddress,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
      );

      print(
          'PaymentProvider: Successfully got crypto-to-cash estimate: ${estimate.toString()}');

      state = state.copyWith(
        estimateData: estimate,
        estimateStatus: PaymentStatus.success,
        selectedWalletAddress: walletAddress,
      );

      print('PaymentProvider: State updated, returning true');
      return true;
    } catch (e) {
      print('PaymentProvider: Error in getCryptoToCashEstimate: $e');
      state = state.copyWith(
        estimateStatus: PaymentStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Create crypto to cash transaction
  Future<bool> createCryptoToCashTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String walletAddress,
    required String countryCode,
    required String paymentMethod,
    required String language,
    required String phoneNumber,
    required String provider,
  }) async {
    print('PaymentProvider: Starting createCryptoToCashTransaction');
    print(
        'PaymentProvider: Data - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');
    print(
        'PaymentProvider: Network: $blockchainNetwork, Wallet: $walletAddress');

    state = state.copyWith(
      transactionStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      // Use mobile money details from state if available
      final mobileDetails = state.mobileMoneyDetails ??
          {
            'phoneNumber': phoneNumber,
            'provider': provider,
            'country': countryCode,
          };

      final transaction =
          await _transactionService.createCryptoToCashTransaction(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        walletAddress: walletAddress,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        language: language,
        paymentChannel: 'web',
        mobileMoneyDetails: mobileDetails,
      );

      print(
          'PaymentProvider: Crypto-to-cash transaction created successfully: ${transaction.transactionId}');

      state = state.copyWith(
        transactionData: transaction,
        transactionStatus: PaymentStatus.success,
      );

      return true;
    } catch (e) {
      print('PaymentProvider: Error in createCryptoToCashTransaction: $e');

      // Parse error message for better user feedback
      String errorMessage = e.toString();
      if (errorMessage.contains('503')) {
        errorMessage =
            'Service temporarily unavailable. Please try again in a few minutes.';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (errorMessage.contains('400')) {
        errorMessage = 'Invalid transaction data. Please check your inputs.';
      }

      state = state.copyWith(
        transactionStatus: PaymentStatus.error,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = PaymentState();
  }
}

// Provider for authenticated API client (reuse the existing one from auth)
final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);

  // Watch auth state to set token when user is authenticated
  ref.listen(authProvider, (previous, next) {
    if (next.user?.token != null) {
      apiClient.setToken(next.user!.token!);
    }
  });

  // Set token immediately if user is already authenticated
  final authState = ref.read(authProvider);
  if (authState.user?.token != null) {
    apiClient.setToken(authState.user!.token!);
  }

  return apiClient;
});

// Provider for TransactionService with authenticated API client
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return TransactionService(apiClient);
});

// Provider for PaymentNotifier
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  final transactionService = ref.watch(transactionServiceProvider);
  return PaymentNotifier(transactionService);
});
