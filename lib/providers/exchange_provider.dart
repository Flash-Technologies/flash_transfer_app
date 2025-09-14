import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/exchange_service.dart';
import '../core/models/currency.dart';
import '../core/models/exchange_rate.dart';
import '../core/models/exchange_calculation.dart';
import 'auth_provider.dart';

// Provider for authenticated Dio client
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl = 'https://flash-transfer.com';
  dio.options.connectTimeout = const Duration(seconds: 15);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  dio.options.responseType = ResponseType.json;
  
  // Get current user token for authentication
  final authState = ref.watch(authProvider);
  if (authState.user?.token != null) {
    print('🔐 Setting auth token: Bearer ${authState.user!.token}');
    dio.options.headers['Authorization'] = 'Bearer ${authState.user!.token}';
  } else {
    print('⚠️  No auth token found! User: ${authState.user?.id}');
  }
  
  return dio;
});

// Provider for the ExchangeService with authenticated Dio
final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
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
    this.sendAmount = '0',
    this.receiveAmount = '0',
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
  final Ref _ref;
  
  ExchangeFormNotifier(this._exchangeService, this._ref) : super(ExchangeFormState()) {
    // Set default currencies: XOF -> ETH
    _setDefaultCurrencies();
  }
  
  void _setDefaultCurrencies() {
    final xofCurrency = Currency(code: 'XOF', name: 'West African CFA Franc', type: 'FIAT');
    final ethCurrency = Currency(code: 'ETH', name: 'Ethereum', type: 'CRYPTO');
    
    state = state.copyWith(
      fromCurrency: xofCurrency,
      toCurrency: ethCurrency,
      sendAmount: '0',
      receiveAmount: '0',
    );
    
    // Don't fetch exchange rate on initial load - only when user enters amount > 0
  }
  
  void setFromCurrency(Currency currency) {
    state = state.copyWith(
      fromCurrency: currency,
      clearError: true,
    );
    // Only fetch rate if user has entered an amount > 0
    final amount = double.tryParse(state.sendAmount) ?? 0;
    if (amount > 0) {
      _calculateExchange();
    }
  }
  
  void setToCurrency(Currency currency) {
    state = state.copyWith(
      toCurrency: currency,
      clearError: true,
    );
    // Only fetch rate if user has entered an amount > 0
    final amount = double.tryParse(state.sendAmount) ?? 0;
    if (amount > 0) {
      _calculateExchange();
    }
  }
  
  void setSendAmount(String amount) {
    state = state.copyWith(
      sendAmount: amount,
      clearError: true,
    );
    // Only calculate exchange if amount > 0
    final amountValue = double.tryParse(amount) ?? 0;
    if (amountValue > 0) {
      _calculateExchange();
    } else {
      // Reset receive amount to 0 when send amount is 0 or empty
      state = state.copyWith(receiveAmount: '0');
    }
  }
  
  Future<void> _fetchExchangeRate() async {
    if (state.fromCurrency == null || state.toCurrency == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Get current user for userId
      final authState = _ref.read(authProvider);
      final userId = authState.user?.id;
      print('👤 Using userId: $userId for exchange rate call');
      
      final rate = await _exchangeService.getExchangeRate(
        state.fromCurrency!.code,
        state.toCurrency!.code,
        userId: userId,
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
      
      // Get current user for userId
      final authState = _ref.read(authProvider);
      final userId = authState.user?.id;
      print('👤 Using userId: $userId for exchange rate call');
      
      final calculation = await _exchangeService.calculateExchange(
        state.fromCurrency!.code,
        state.toCurrency!.code,
        amount,
        userId: userId,
      );
      
      state = state.copyWith(
        calculation: calculation,
        receiveAmount: _formatNumber(calculation.receivedAmount),
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
  
  String _formatNumber(double number) {
    if (number == 0) return '0';
    
    // For very small numbers, use fixed decimal places instead of scientific notation
    if (number < 0.000001) {
      // Format with up to 12 decimal places, removing trailing zeros
      String formatted = number.toStringAsFixed(12);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      return formatted;
    } else if (number < 0.01) {
      return number.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    } else if (number < 1) {
      return number.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      return number.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }
}

// Provider for the exchange form
final exchangeFormProvider = StateNotifierProvider<ExchangeFormNotifier, ExchangeFormState>((ref) {
  final exchangeService = ref.watch(exchangeServiceProvider);
  return ExchangeFormNotifier(exchangeService, ref);
});