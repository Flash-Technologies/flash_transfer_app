import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/exchange_service.dart';
import '../core/models/currency.dart';
import '../core/models/exchange_rate.dart';
import '../core/models/exchange_calculation.dart';

// Provider for Dio client
final dioProvider = Provider<Dio>((ref) => Dio());

// Provider for the ExchangeService
final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  final dio = ref.watch(dioProvider);
  return ExchangeService(dio);
});

// Provider for available currencies
final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final exchangeService = ref.watch(exchangeServiceProvider);
  try {
    return await exchangeService.getCurrencies();
  } catch (e) {
    // Fallback data if API fails
    return [
      Currency(code: 'BTC', name: 'Bitcoin', type: 'CRYPTO'),
      Currency(code: 'ETH', name: 'Ethereum', type: 'CRYPTO'),
      Currency(code: 'USD', name: 'US Dollar', type: 'FIAT'),
      Currency(code: 'EUR', name: 'Euro', type: 'FIAT'),
    ];
  }
});

// State class for the exchange form
class ExchangeFormState {
  final Currency? fromCurrency;
  final Currency? toCurrency;
  final String sendAmount;
  final String receiveAmount;
  final bool isLoading;
  final String? error;
  final ExchangeRate? exchangeRate;
  final ExchangeCalculation? calculation;

  ExchangeFormState({
    this.fromCurrency,
    this.toCurrency,
    this.sendAmount = '',
    this.receiveAmount = '',
    this.isLoading = false,
    this.error,
    this.exchangeRate,
    this.calculation,
  });

  ExchangeFormState copyWith({
    Currency? fromCurrency,
    Currency? toCurrency,
    String? sendAmount,
    String? receiveAmount,
    bool? isLoading,
    String? error,
    ExchangeRate? exchangeRate,
    ExchangeCalculation? calculation,
    bool clearError = false,
  }) {
    return ExchangeFormState(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      sendAmount: sendAmount ?? this.sendAmount,
      receiveAmount: receiveAmount ?? this.receiveAmount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      exchangeRate: exchangeRate ?? this.exchangeRate,
      calculation: calculation ?? this.calculation,
    );
  }
}

// Notifier for the exchange form
class ExchangeFormNotifier extends StateNotifier<ExchangeFormState> {
  final ExchangeService _exchangeService;
  
  ExchangeFormNotifier(this._exchangeService) : super(ExchangeFormState());
  
  void setFromCurrency(Currency currency) {
    state = state.copyWith(
      fromCurrency: currency,
      clearError: true,
    );
    _fetchExchangeRate();
  }
  
  void setToCurrency(Currency currency) {
    state = state.copyWith(
      toCurrency: currency,
      clearError: true,
    );
    _fetchExchangeRate();
  }
  
  void setSendAmount(String amount) {
    state = state.copyWith(
      sendAmount: amount,
      clearError: true,
    );
    _calculateExchange();
  }
  
  Future<void> _fetchExchangeRate() async {
    if (state.fromCurrency == null || state.toCurrency == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final rate = await _exchangeService.getExchangeRate(
        state.fromCurrency!.code,
        state.toCurrency!.code,
      );
      state = state.copyWith(
        exchangeRate: rate,
        isLoading: false,
      );
      
      // If we have a send amount, recalculate the exchange
      if (state.sendAmount.isNotEmpty) {
        _calculateExchange();
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  
  Future<void> _calculateExchange() async {
    if (state.fromCurrency == null || 
        state.toCurrency == null || 
        state.sendAmount.isEmpty) return;
    
    try {
      final amount = double.tryParse(state.sendAmount);
      if (amount == null) return;
      
      state = state.copyWith(isLoading: true, clearError: true);
      
      final calculation = await _exchangeService.calculateExchange(
        state.fromCurrency!.code,
        state.toCurrency!.code,
        amount,
      );
      
      state = state.copyWith(
        calculation: calculation,
        receiveAmount: calculation.receivedAmount.toString(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  
  void swapCurrencies() {
    if (state.fromCurrency == null || state.toCurrency == null) return;
    
    final temp = state.fromCurrency;
    state = state.copyWith(
      fromCurrency: state.toCurrency,
      toCurrency: temp,
      clearError: true,
    );
    
    _fetchExchangeRate();
  }
}

// Provider for the exchange form
final exchangeFormProvider = StateNotifierProvider<ExchangeFormNotifier, ExchangeFormState>((ref) {
  final exchangeService = ref.watch(exchangeServiceProvider);
  return ExchangeFormNotifier(exchangeService);
});