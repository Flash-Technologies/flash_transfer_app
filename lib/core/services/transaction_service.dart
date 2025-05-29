import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../api/api_client.dart';
import '../models/transaction_estimate.dart';
import '../models/transaction_response.dart';

class TransactionService {
  final ApiClient _apiClient;

  TransactionService(this._apiClient);

  /// Get transaction estimate before review
  Future<TransactionEstimate> getTransactionEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String sourceType,
    required String destinationType,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required Map<String, dynamic> mobileMoneyDetails,
    required String walletAddress,
  }) async {
    try {
      final response = await _apiClient.post(
        Endpoints.transactionEstimate,
        data: {
          'amount': amount,
          'sourceCurrency': sourceCurrency,
          'destinationCurrency': destinationCurrency,
          'sourceType': sourceType,
          'destinationType': destinationType,
          'blockchainNetwork': blockchainNetwork,
          'countryCode': countryCode,
          'paymentMethod': paymentMethod,
          'mobileMoneyDetails': mobileMoneyDetails,
          'walletAddress': walletAddress,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionEstimate.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to get transaction estimate');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Re-throw our formatted exceptions
      }
      throw Exception('Failed to get transaction estimate: $e');
    }
  }

  /// Create transaction
  Future<TransactionResponse> createTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required String language,
    required String paymentChannel,
    required Map<String, dynamic> mobileMoneyDetails,
    required String walletAddress,
  }) async {
    try {
      final response = await _apiClient.post(
        Endpoints.createCashToCryptoTransaction,
        data: {
          'amount': amount,
          'sourceCurrency': sourceCurrency,
          'destinationCurrency': destinationCurrency,
          'blockchainNetwork': blockchainNetwork,
          'countryCode': countryCode,
          'paymentMethod': paymentMethod,
          'language': language,
          'paymentChannel': paymentChannel,
          'mobileMoneyDetails': mobileMoneyDetails,
          'walletAddress': walletAddress,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionResponse.fromJson(response.data['data']);
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create transaction');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Re-throw our formatted exceptions
      }
      throw Exception('Failed to create transaction: $e');
    }
  }
}
