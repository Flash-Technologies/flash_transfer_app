import 'package:dio/dio.dart';
import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../models/exchange_calculation.dart';
import '../api/endpoints.dart';

class ExchangeService {
  final Dio _dio;

  ExchangeService(this._dio);

  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await _dio.get(Endpoints.currencies);
      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        print("the data is ${data}");
        return data.map((json) => Currency.fromJson(json)).toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to load currencies');
      }
    } catch (e) {
      throw Exception('Failed to load currencies: $e');
    }
  }

  Future<ExchangeRate> getExchangeRate(
      String fromCurrency, String toCurrency, {int? userId, String? network}) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final queryParams = <String, dynamic>{
          'from': fromCurrency,
          'to': toCurrency,
        };
        
        // Add userId if provided
        if (userId != null) {
          queryParams['userId'] = userId.toString();
        }
        
        // Add network if provided, otherwise use default based on currency
        if (network != null) {
          queryParams['network'] = network;
        } else if (fromCurrency == 'ETH' || toCurrency == 'ETH') {
          queryParams['network'] = 'Ethereum';
        } else if (fromCurrency == 'BNB' || toCurrency == 'BNB') {
          queryParams['network'] = 'BSC';
        } else if (fromCurrency == 'MATIC' || toCurrency == 'MATIC') {
          queryParams['network'] = 'Polygon';
        } else if (fromCurrency == 'SOL' || toCurrency == 'SOL') {
          queryParams['network'] = 'Solana';
        } else if (fromCurrency == 'AVAX' || toCurrency == 'AVAX') {
          queryParams['network'] = 'Avalanche';
        }
        
        print('🚀 Making API call to: ${Endpoints.exchangeRates} (Attempt ${retryCount + 1})');
        print('📊 Query parameters: $queryParams');
        
        final response = await _dio.get(
          Endpoints.exchangeRates,
          queryParameters: queryParams,
        );
        
        print('📱 Response status: ${response.statusCode}');
        print('📱 Response data: ${response.data}');
        
        if (response.statusCode == 200 && response.data is Map && response.data['success'] == true) {
          return ExchangeRate.fromJson(response.data['data']);
        } else {
          final message = response.data is Map 
              ? response.data['message'] ?? 'Server returned an error'
              : 'Invalid response format';
          throw Exception(message);
        }
      } on DioException catch (e) {
        retryCount++;
        print('❌ Attempt ${retryCount} failed: ${e.response?.statusCode} - ${e.message}');
        
        // Handle specific error codes
        if (e.response?.statusCode == 500) {
          if (retryCount >= maxRetries) {
            throw Exception('Server is temporarily unavailable. Please try again later.');
          }
          // Wait before retry for server errors
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else if (e.response?.statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Access denied. Please check your permissions.');
        } else if (e.response?.statusCode == 404) {
          throw Exception('Exchange rate not found for this currency pair.');
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          if (retryCount >= maxRetries) {
            throw Exception('Connection timeout. Please check your internet connection.');
          }
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } catch (e) {
        retryCount++;
        print('❌ Unexpected error on attempt ${retryCount}: $e');
        if (retryCount >= maxRetries) {
          throw Exception('Unable to fetch exchange rate. Please try again later.');
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    throw Exception('Failed to get exchange rate after $maxRetries attempts');
  }

  Future<ExchangeCalculation> calculateExchange(
      String fromCurrency, String toCurrency, double amount, {int? userId, String? network}) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final queryParams = <String, dynamic>{
          'from': fromCurrency,
          'to': toCurrency,
          'amount': amount,
        };
        
        // Add userId if provided
        if (userId != null) {
          queryParams['userId'] = userId.toString();
        }
        
        // Add network if provided, otherwise use default based on currency
        if (network != null) {
          queryParams['network'] = network;
        } else if (fromCurrency == 'ETH' || toCurrency == 'ETH') {
          queryParams['network'] = 'Ethereum';
        } else if (fromCurrency == 'BNB' || toCurrency == 'BNB') {
          queryParams['network'] = 'BSC';
        } else if (fromCurrency == 'MATIC' || toCurrency == 'MATIC') {
          queryParams['network'] = 'Polygon';
        } else if (fromCurrency == 'SOL' || toCurrency == 'SOL') {
          queryParams['network'] = 'Solana';
        } else if (fromCurrency == 'AVAX' || toCurrency == 'AVAX') {
          queryParams['network'] = 'Avalanche';
        }
        
        print('🚀 Making calculation API call to: ${Endpoints.exchangeRates} (Attempt ${retryCount + 1})');
        print('📊 Query parameters: $queryParams');
        
        final response = await _dio.get(
          Endpoints.exchangeRates,
          queryParameters: queryParams,
        );
        
        print('📱 Response status: ${response.statusCode}');
        print('📱 Response data: ${response.data}');
        
        if (response.statusCode == 200 && response.data is Map && response.data['success'] == true) {
          return ExchangeCalculation.fromJson(response.data['data']);
        } else {
          final message = response.data is Map 
              ? response.data['message'] ?? 'Server returned an error'
              : 'Invalid response format';
          throw Exception(message);
        }
      } on DioException catch (e) {
        retryCount++;
        print('❌ Calculation attempt $retryCount failed: ${e.response?.statusCode} - ${e.message}');
        
        // Handle specific error codes
        if (e.response?.statusCode == 500) {
          if (retryCount >= maxRetries) {
            throw Exception('Server is temporarily unavailable. Please try again later.');
          }
          // Wait before retry for server errors
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else if (e.response?.statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Access denied. Please check your permissions.');
        } else if (e.response?.statusCode == 404) {
          throw Exception('Exchange calculation not available for this currency pair.');
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          if (retryCount >= maxRetries) {
            throw Exception('Connection timeout. Please check your internet connection.');
          }
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } catch (e) {
        retryCount++;
        print('❌ Unexpected calculation error on attempt $retryCount: $e');
        if (retryCount >= maxRetries) {
          throw Exception('Unable to calculate exchange. Please try again later.');
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    throw Exception('Failed to calculate exchange after $maxRetries attempts');
  }
}
