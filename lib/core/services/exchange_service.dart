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
        return data.map((json) => Currency.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load currencies');
      }
    } catch (e) {
      throw Exception('Failed to load currencies: $e');
    }
  }

  Future<ExchangeRate> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      final response = await _dio.get(
        Endpoints.exchangeRates,
        queryParameters: {
          'from': fromCurrency,
          'to': toCurrency,
        },
      );
      if (response.statusCode == 200 && response.data['success']) {
        return ExchangeRate.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load exchange rate');
      }
    } catch (e) {
      throw Exception('Failed to load exchange rate: $e');
    }
  }

  Future<ExchangeCalculation> calculateExchange(
      String fromCurrency, String toCurrency, double amount) async {
    try {
      final response = await _dio.post(
        Endpoints.exchangeCalculate,
        data: {
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amount': amount,
          'includeNetworkInfo': true,
        },
      );
      print("the reponse for the exchange calculation is ${response.data}");
      if (response.statusCode == 200 && response.data['success']) {
        return ExchangeCalculation.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to calculate exchange');
      }
    } catch (e) {
      throw Exception('Failed to calculate exchange: $e');
    }
  }
}