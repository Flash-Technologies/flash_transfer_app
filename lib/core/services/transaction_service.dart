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

  /// Create cash-to-crypto transaction
  Future<TransactionResponse> createTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String paymentMethod,
    required String walletAddress,
    required Map<String, dynamic> mobileMoneyDetails,
    required Map<String, dynamic> customerInfo,
  }) async {
    try {
      // Convert blockchain network to lowercase for API
      final apiBlockchainNetwork = blockchainNetwork.toLowerCase();
      
      // Convert provider to correct format for API
      String apiPaymentMethod;
      switch (paymentMethod.toLowerCase()) {
        case 'orange':
          apiPaymentMethod = 'ORANGE';
          break;
        case 'wave':
          apiPaymentMethod = 'WAVE';
          break;
        case 'mtn':
          apiPaymentMethod = 'MTN';
          break;
        case 'moov':
          apiPaymentMethod = 'MOOV';
          break;
        default:
          apiPaymentMethod = paymentMethod.toUpperCase();
      }

      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'walletAddress': walletAddress,
        'blockchainNetwork': apiBlockchainNetwork,
        'paymentMethod': apiPaymentMethod,
        'mobileMoneyDetails': {
          'phoneNumber': mobileMoneyDetails['phoneNumber'] ?? customerInfo['phoneNumber'] ?? '12123123',
          'provider': apiPaymentMethod,
        },
        'countryCode': countryCode,
        'customerInfo': {
          'firstName': customerInfo['firstName'] ?? 'Test',
          'lastName': customerInfo['lastName'] ?? 'User',
          'email': customerInfo['email'] ?? 'test@example.com',
          'phoneNumber': customerInfo['phoneNumber'] ?? '12123123',
          'address': customerInfo['address'] ?? 'Test Address',
          'city': customerInfo['city'] ?? 'Test City',
          'country': countryCode,
          'state': countryCode,
          'zipCode': customerInfo['zipCode'] ?? '00000',
        },
      };

      print('🚀 TransactionService: Creating cash-to-crypto transaction with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.createCashToCryptoTransaction,
        data: payload,
      );

      print('📞 TransactionService: Transaction creation response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionResponse.fromJson(response.data['data']);
      } else {
        // Handle TouchPay and server errors with user-friendly messages
        final errorMessage = response.data['message'] ?? 'Transaction failed';
        
        if (errorMessage.contains('TouchPay') || errorMessage.contains('Request failed with status code 300')) {
          throw Exception('Payment service is temporarily unavailable. Please try again later or use a different payment method.');
        } else if (errorMessage.contains('server') || errorMessage.contains('500')) {
          throw Exception('Our servers are currently being updated. Please try your transaction again in a few minutes.');
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print('❌ TransactionService: Error creating transaction: $e');
      
      if (e is Exception) {
        rethrow; // Re-throw our formatted exceptions
      }
      throw Exception('Transaction could not be processed. Please check your connection and try again.');
    }
  }

  /// Get crypto-to-fiat transaction estimate
  Future<TransactionEstimate> getCryptoToCashEstimate({
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

      // Prepare the request payload matching the new API format
      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork.toLowerCase(),
        'withdrawalMethod': 'cash_pickup', // Changed from mobile_money to cash_pickup as TouchCash only supports cash_pickup
        'countryCode': actualCountryCode.toUpperCase(),
        'walletAddress': null,
        'beneficiaryId': 18,
        'senderInfo': {
          'sender_phone_number': phoneNumber ?? '33749928528',
          'sender_first_name': firstName ?? 'Test',
          'sender_last_name': lastName ?? 'User',
          'sender_country_code_piece': actualCountryCode.toUpperCase(),
        },
        'recipientInfo': {
          'recipient_first_name': firstName ?? 'Test',
          'recipient_last_name': lastName ?? 'User',
          'recipient_phone_number': phoneNumber ?? '33749928528',
          'recipient_country_code': actualCountryCode.toUpperCase(),
        },
      };

      print(
          '🚀 TransactionService: Getting crypto-to-fiat estimate with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.cryptoToCashEstimate,
        data: payload,
      );

      print(
          '📞 TransactionService: Crypto-to-fiat estimate response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TransactionEstimate.fromJson(response.data['data']);
      } else {
        throw Exception(
            'Failed to get crypto-to-fiat estimate: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ TransactionService: Error getting crypto-to-fiat estimate: $e');
      throw Exception('Failed to get crypto-to-fiat estimate: ${e.toString()}');
    }
  }

  /// Create crypto-to-fiat transaction
  Future<TransactionResponse> createCryptoToCashTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    required String? firstName,
    required String? lastName,
    required String? email,
    required String? phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      // Convert phone prefix to country code if needed
      String actualCountryCode = countryCode;
      if (countryCode.startsWith('+')) {
        switch (countryCode) {
          case '+225':
            actualCountryCode = 'ci';
            break;
          case '+221':
            actualCountryCode = 'sn';
            break;
          case '+223':
            actualCountryCode = 'ml';
            break;
          case '+226':
            actualCountryCode = 'bf';
            break;
          default:
            actualCountryCode = 'ci';
        }
      }

      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork.toLowerCase(),
        'withdrawalMethod': 'cash_pickup', // Changed from mobile_money to cash_pickup as TouchCash only supports cash_pickup
        'countryCode': actualCountryCode.toUpperCase(),
        'walletAddress': null,
        'beneficiaryId': 18,
        'senderInfo': {
          'sender_phone_number': phoneNumber ?? '33749928528',
          'sender_first_name': firstName ?? 'Test',
          'sender_last_name': lastName ?? 'User',
          'sender_country_code_piece': actualCountryCode.toUpperCase(),
        },
        'recipientInfo': {
          'recipient_first_name': firstName ?? 'Test',
          'recipient_last_name': lastName ?? 'User',
          'recipient_phone_number': phoneNumber ?? '33749928528',
          'recipient_country_code': actualCountryCode.toUpperCase(),
        },
      };

      print(
          '🚀 TransactionService: Creating crypto-to-fiat transaction with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.createCryptoToCashTransaction,
        data: payload,
      );

      print(
          '📞 TransactionService: Crypto-to-fiat creation response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final transactionData = Map<String, dynamic>.from(response.data['data']);
        transactionData['message'] = response.data['message'] ?? '';
        return TransactionResponse.fromJson(transactionData);
      } else {
        throw Exception(
            'Failed to create crypto-to-fiat transaction: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print(
          '❌ TransactionService: Error creating crypto-to-fiat transaction: $e');
      throw Exception(
          'Failed to create crypto-to-fiat transaction: ${e.toString()}');
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

  /// Get crypto-to-cash (cash pickup) transaction estimate
  Future<Map<String, dynamic>> getCryptoToCashPickupEstimate({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    String? walletAddress,
    int? beneficiaryId,
    required Map<String, dynamic> senderInfo,
    required Map<String, dynamic> recipientInfo,
  }) async {
    try {
      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork.toLowerCase(),
        'withdrawalMethod': 'cash_pickup',
        'countryCode': countryCode,
        'walletAddress': walletAddress,
        'beneficiaryId': beneficiaryId,
        'senderInfo': senderInfo,
        'recipientInfo': recipientInfo,
      };

      print('🚀 TransactionService: Getting crypto-to-cash estimate with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.cryptoToCashEstimate,
        data: payload,
      );

      print('📞 TransactionService: Crypto-to-cash estimate response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to get crypto-to-cash estimate');
      }
    } catch (e) {
      print('❌ TransactionService: Error getting crypto-to-cash estimate: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get crypto-to-cash estimate: ${e.toString()}');
    }
  }

  /// Create crypto-to-cash (cash pickup) transaction
  Future<Map<String, dynamic>> createCryptoToCashPickupTransaction({
    required double amount,
    required String sourceCurrency,
    required String destinationCurrency,
    required String blockchainNetwork,
    required String countryCode,
    String? walletAddress,
    int? beneficiaryId,
    required Map<String, dynamic> senderInfo,
    required Map<String, dynamic> recipientInfo,
  }) async {
    try {
      final payload = {
        'amount': amount,
        'sourceCurrency': sourceCurrency,
        'destinationCurrency': destinationCurrency,
        'blockchainNetwork': blockchainNetwork.toLowerCase(),
        'withdrawalMethod': 'cash_pickup',
        'countryCode': countryCode,
        'walletAddress': walletAddress,
        'beneficiaryId': beneficiaryId,
        'senderInfo': senderInfo,
        'recipientInfo': recipientInfo,
      };

      print('🚀 TransactionService: Creating crypto-to-cash transaction with payload: $payload');

      final response = await _apiClient.post(
        Endpoints.createCryptoToCashTransaction,
        data: payload,
      );

      print('📞 TransactionService: Crypto-to-cash transaction response: ${response.statusCode}');
      print('📦 TransactionService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to create crypto-to-cash transaction');
      }
    } catch (e) {
      print('❌ TransactionService: Error creating crypto-to-cash transaction: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create crypto-to-cash transaction: ${e.toString()}');
    }
  }
}
