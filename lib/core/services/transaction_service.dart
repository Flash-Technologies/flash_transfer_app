import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../api/api_client.dart';
import '../models/transaction_estimate.dart';
import '../models/transaction_response.dart';
import '../models/transaction_model.dart';

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
      // Convert blockchain network to lowercase for API
      final apiBlockchainNetwork = blockchainNetwork.toLowerCase();
      
      final response = await _apiClient.post(
        Endpoints.transactionEstimate,
        data: {
          'amount': amount,
          'sourceCurrency': sourceCurrency,
          'destinationCurrency': destinationCurrency,
          'blockchainNetwork': apiBlockchainNetwork,
          'paymentMethod': paymentMethod,
          'countryCode': countryCode,
          'customerInfo': {
            'firstName': mobileMoneyDetails['firstName'] ?? 'Test',
            'lastName': mobileMoneyDetails['lastName'] ?? 'User', 
            'email': mobileMoneyDetails['email'] ?? 'test@example.com',
            'phoneNumber': mobileMoneyDetails['phoneNumber'] ?? '123123123',
            'address': mobileMoneyDetails['address'] ?? 'Test Address',
            'city': mobileMoneyDetails['city'] ?? 'Test City',
            'country': countryCode,
            'state': countryCode,
            'zipCode': mobileMoneyDetails['zipCode'] ?? '00000',
          },
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

  /// Get crypto-to-cash transaction estimate
  Future<TransactionEstimate> getCryptoToCashEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String walletAddress,
    required String countryCode,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      // Convert phone prefix to country code if needed
      String actualCountryCode = countryCode;
      if (countryCode.startsWith('+')) {
        // Map common phone prefixes to country codes
        switch (countryCode) {
          case '+225':
            actualCountryCode = 'ci'; // Côte d'Ivoire
            break;
          case '+221':
            actualCountryCode = 'sn'; // Senegal
            break;
          case '+223':
            actualCountryCode = 'ml'; // Mali
            break;
          case '+226':
            actualCountryCode = 'bf'; // Burkina Faso
            break;
          default:
            actualCountryCode = 'ci'; // Default fallback
        }
      }

      // Prepare the request payload matching the expected API format
      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork,
        'withdrawalMethod': 'mobile_money',
        'countryCode': actualCountryCode,
        'mobileMoneyDetails': {
          'phoneNumber':
              phoneNumber?.toString() ?? '7977596822', // Ensure string format
          'provider': paymentMethod.toUpperCase(),
          'country': actualCountryCode,
        }
      };

      print(
          '🚀 TransactionService: Getting crypto-to-cash estimate with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.cryptoToCashEstimate,
        data: payload,
      );

      print(
          '📞 TransactionService: Crypto-to-cash estimate response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionEstimate.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to get crypto-to-cash estimate: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ TransactionService: Error getting crypto-to-cash estimate: $e');
      throw Exception('Failed to get crypto-to-cash estimate: ${e.toString()}');
    }
  }

  /// Create crypto-to-cash transaction
  Future<TransactionResponse> createCryptoToCashTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String walletAddress,
    required String countryCode,
    required String paymentMethod,
    required String language,
    required String paymentChannel,
    required Map<String, dynamic> mobileMoneyDetails,
  }) async {
    try {
      // Use the same payload format as the estimate API
      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork,
        'withdrawalMethod': 'mobile_money',
        'countryCode': countryCode,
        'mobileMoneyDetails': {
          'phoneNumber':
              mobileMoneyDetails['phoneNumber']?.toString() ?? '7977596822',
          'provider': paymentMethod.toUpperCase(),
          'country': countryCode,
        }
      };

      print(
          '🚀 TransactionService: Creating crypto-to-cash transaction with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.createCryptoToCashTransaction,
        data: payload,
      );

      print(
          '📞 TransactionService: Crypto-to-cash creation response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionResponse.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to create crypto-to-cash transaction: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print(
          '❌ TransactionService: Error creating crypto-to-cash transaction: $e');
      throw Exception(
          'Failed to create crypto-to-cash transaction: ${e.toString()}');
    }
  }

  /// Get user transactions list
  Future<List<Transaction>> getTransactions() async {
    try {
      print('🚀 Fetching transactions from API...');
      print('🔍 Using endpoint: ${Endpoints.transactions}');
      
      final response = await _apiClient.get(Endpoints.transactions);
      
      print('📱 Transactions Response status: ${response.statusCode}');
      print('📱 Transactions Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> transactionsData = response.data['data']['data'];
        
        final transactions = <Transaction>[];
        for (int i = 0; i < transactionsData.length; i++) {
          try {
            final transaction = Transaction.fromJson(transactionsData[i]);
            transactions.add(transaction);
          } catch (e) {
            print('❌ Error parsing transaction $i: $e');
            print('❌ Transaction data: ${transactionsData[i]}');
            rethrow;
          }
        }
            
        print('✅ Successfully parsed ${transactions.length} transactions');
        return transactions;
      } else {
        final message = response.data['message'] ?? 'Failed to load transactions';
        print('❌ API Error: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      print('❌ DioException Details:');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response Data: ${e.response?.data}');
      print('   Request Headers: ${e.requestOptions.headers}');
      print('   Request URI: ${e.requestOptions.uri}');
      
      if (e.response?.statusCode == 401) {
        final errorMsg = e.response?.data?['message'] ?? 'Authentication failed';
        print('❌ 401 Error: $errorMsg');
        throw Exception('Please log in to view your transactions. ($errorMsg)');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Transactions not found.');
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Unable to fetch transactions. Please try again later.');
    }
  }

  /// Get single transaction by ID
  Future<Transaction> getTransactionById(String transactionId) async {
    try {
      print('🚀 Fetching transaction $transactionId from API...');
      
      final response = await _apiClient.get('${Endpoints.transactions}/$transactionId');
      
      print('📱 Transaction Response status: ${response.statusCode}');
      print('📱 Transaction Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Transaction.fromJson(response.data['data']);
      } else {
        final message = response.data['message'] ?? 'Failed to load transaction';
        throw Exception(message);
      }
    } on DioException catch (e) {
      print('❌ Network error: ${e.response?.statusCode} - ${e.message}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Transaction not found.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Unable to fetch transaction. Please try again later.');
    }
  }
}
