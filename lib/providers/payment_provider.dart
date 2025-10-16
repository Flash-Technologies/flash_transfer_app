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
  final String? selectedNetwork;
  final PaymentType? selectedPaymentType;
  final String? selectedWalletAddress;
  final TransactionEstimate? estimateData;
  final TransactionResponse? transactionData;
  final Map<String, dynamic>? cryptoToCashEstimate; // For crypto-to-cash estimate
  final PaymentStatus estimateStatus;
  final PaymentStatus transactionStatus;
  final String? errorMessage;
  final Map<String, dynamic>? mobileMoneyDetails;
  final Map<String, dynamic>? cashSenderInfo;
  final Map<String, dynamic>? cashRecipientInfo;

  PaymentState({
    this.activePay = 'cash',
    this.activeReceive = 'cash',
    this.selectedProvider,
    this.selectedNetwork,
    this.selectedPaymentType,
    this.selectedWalletAddress,
    this.estimateData,
    this.transactionData,
    this.cryptoToCashEstimate,
    this.estimateStatus = PaymentStatus.idle,
    this.transactionStatus = PaymentStatus.idle,
    this.errorMessage,
    this.mobileMoneyDetails,
    this.cashSenderInfo,
    this.cashRecipientInfo,
  });

  PaymentState copyWith({
    String? activePay,
    String? activeReceive,
    String? selectedProvider,
    String? selectedNetwork,
    PaymentType? selectedPaymentType,
    String? selectedWalletAddress,
    TransactionEstimate? estimateData,
    TransactionResponse? transactionData,
    Map<String, dynamic>? cryptoToCashEstimate,
    PaymentStatus? estimateStatus,
    PaymentStatus? transactionStatus,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? mobileMoneyDetails,
    Map<String, dynamic>? cashSenderInfo,
    Map<String, dynamic>? cashRecipientInfo,
  }) {
    return PaymentState(
      activePay: activePay ?? this.activePay,
      activeReceive: activeReceive ?? this.activeReceive,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
      selectedWalletAddress:
          selectedWalletAddress ?? this.selectedWalletAddress,
      estimateData: estimateData ?? this.estimateData,
      transactionData: transactionData ?? this.transactionData,
      cryptoToCashEstimate: cryptoToCashEstimate ?? this.cryptoToCashEstimate,
      estimateStatus: estimateStatus ?? this.estimateStatus,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mobileMoneyDetails: mobileMoneyDetails ?? this.mobileMoneyDetails,
      cashSenderInfo: cashSenderInfo ?? this.cashSenderInfo,
      cashRecipientInfo: cashRecipientInfo ?? this.cashRecipientInfo,
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

  void setSelectedNetwork(String network) {
    state = state.copyWith(selectedNetwork: network);
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
        walletAddress: walletAddress,
        mobileMoneyDetails: {
          'phoneNumber': phoneNumber,
          'provider': provider,
        },
        customerInfo: {
          'firstName': 'Test',
          'lastName': 'User',
          'email': 'test@example.com',
          'phoneNumber': phoneNumber,
          'address': 'Test Address',
          'city': 'Test City',
          'country': countryCode,
          'state': countryCode,
          'zipCode': '00000',
        },
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
      if (errorMessage.contains('TouchPay') || errorMessage.contains('Request failed with status code 300')) {
        errorMessage = 'Payment service is temporarily unavailable. Please try again later or use a different payment method.';
      } else if (errorMessage.contains('Payment service is temporarily unavailable')) {
        errorMessage = 'Our payment system is currently being updated. Please try your transaction again in a few minutes.';
      } else if (errorMessage.contains('Our servers are currently being updated')) {
        errorMessage = 'Service maintenance in progress. Please wait a moment and try again.';
      } else if (errorMessage.contains('503')) {
        errorMessage = 'Service temporarily unavailable. Please try again in a few minutes.';
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

  /// Get transaction estimate for crypto to fiat flow
  Future<bool> getCryptoToCashEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    String? walletAddress,
    required String countryCode,
    required String paymentMethod,
    required String? firstName,
    required String? lastName,
    required String? email,
    required String? phoneNumber,
  }) async {
    print('PaymentProvider: Starting getCryptoToCashEstimate');
    print(
        'PaymentProvider: Parameters - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');

    state = state.copyWith(
      estimateStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      final estimate = await _transactionService.getCryptoToCashEstimate(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        walletAddress: walletAddress,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );

      print(
          'PaymentProvider: Successfully got crypto-to-cash estimate: ${estimate.toString()}');

      state = state.copyWith(
        estimateData: estimate,
        estimateStatus: PaymentStatus.success,
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

  /// Create crypto to fiat transaction
  Future<bool> createCryptoToCashTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required String? firstName,
    required String? lastName,
    required String? email,
    required String? phoneNumber,
  }) async {
    print('PaymentProvider: Starting createCryptoToCashTransaction');
    print(
        'PaymentProvider: Data - amount: $amount, sourceCurrency: $sourceCurrency, destinationCurrency: $destinationCurrency');
    print(
        'PaymentProvider: Network: $blockchainNetwork, Country: $countryCode');

    state = state.copyWith(
      transactionStatus: PaymentStatus.loading,
      clearError: true,
    );

    try {
      final transaction =
          await _transactionService.createCryptoToCashTransaction(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        countryCode: countryCode,
        paymentMethod: paymentMethod,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
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

  /// Fetch crypto-to-cash (cash pickup) estimate
  Future<void> fetchCryptoToCashEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required Map<String, dynamic> senderInfo,
    required Map<String, dynamic> recipientInfo,
  }) async {
    try {
      state = state.copyWith(estimateStatus: PaymentStatus.loading);

      final estimate = await _transactionService.getCryptoToCashPickupEstimate(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        countryCode: countryCode,
        walletAddress: null,
        beneficiaryId: null,
        senderInfo: senderInfo,
        recipientInfo: recipientInfo,
      );

      state = state.copyWith(
        cryptoToCashEstimate: estimate,
        estimateStatus: PaymentStatus.success,
      );
    } catch (e) {
      print('PaymentProvider: Error fetching crypto-to-cash estimate: $e');
      state = state.copyWith(
        estimateStatus: PaymentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setCashSenderInfo(Map<String, dynamic> senderInfo) {
    state = state.copyWith(cashSenderInfo: senderInfo);
  }

  void setCashRecipientInfo(Map<String, dynamic> recipientInfo) {
    state = state.copyWith(cashRecipientInfo: recipientInfo);
  }

  /// Create crypto-to-cash (cash pickup) transaction
  Future<bool> createCryptoToCashPickupTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required Map<String, dynamic> senderInfo,
    required Map<String, dynamic> recipientInfo,
  }) async {
    try {
      state = state.copyWith(transactionStatus: PaymentStatus.loading);

      final transactionData = await _transactionService.createCryptoToCashPickupTransaction(
        amount: amount,
        sourceCurrency: sourceCurrency,
        destinationCurrency: destinationCurrency,
        blockchainNetwork: blockchainNetwork,
        countryCode: countryCode,
        walletAddress: null,
        beneficiaryId: null,
        senderInfo: senderInfo,
        recipientInfo: recipientInfo,
      );

      print('PaymentProvider: Crypto-to-cash pickup transaction created successfully: $transactionData');

      // Parse the transaction response using fromJson
      final transaction = TransactionResponse.fromJson(transactionData);

      state = state.copyWith(
        transactionData: transaction,
        transactionStatus: PaymentStatus.success,
      );

      return true;
    } catch (e) {
      print('PaymentProvider: Error creating crypto-to-cash pickup transaction: $e');

      String errorMessage = e.toString();
      if (errorMessage.contains('503')) {
        errorMessage = 'Service temporarily unavailable. Please try again in a few minutes.';
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
