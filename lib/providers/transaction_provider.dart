import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/transaction_service.dart';
import '../core/models/transaction_model.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';

// Provider for the TransactionService (using the working auth provider's client)
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(authenticatedApiClientProvider);
  return TransactionService(apiClient);
});

// State class for transactions
class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;

  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// Notifier for managing transactions state
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionService _transactionService;
  
  TransactionsNotifier(this._transactionService) : super(const TransactionsState());
  
  // Fetch transactions from API
  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else if (state.isLoading) {
      return; // Already loading
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    
    try {
      final transactions = await _transactionService.getTransactions();
      
      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasMore: false, // Assuming single page for now
      );
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  
  // Fetch single transaction by ID
  Future<Transaction?> fetchTransactionById(String transactionId) async {
    try {
      return await _transactionService.getTransactionById(transactionId);
    } catch (e) {
      print('❌ Error fetching transaction $transactionId: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
  
  // Filter transactions by status
  List<Transaction> getTransactionsByStatus(String status) {
    return state.transactions.where((t) => t.status.toLowerCase() == status.toLowerCase()).toList();
  }
  
  // Filter transactions by type
  List<Transaction> getTransactionsByType(String type) {
    return state.transactions.where((t) => t.type.toLowerCase() == type.toLowerCase()).toList();
  }
  
  // Get recent transactions (last 30 days)
  List<Transaction> getRecentTransactions() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return state.transactions.where((t) => t.createdAt.isAfter(thirtyDaysAgo)).toList();
  }
  
  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider for transactions state
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return TransactionsNotifier(transactionService);
});

// Convenience providers for filtered data
final completedTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsNotifier = ref.watch(transactionsProvider.notifier);
  return transactionsNotifier.getTransactionsByStatus('completed');
});

final pendingTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsNotifier = ref.watch(transactionsProvider.notifier);
  return transactionsNotifier.getTransactionsByStatus('pending');
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsNotifier = ref.watch(transactionsProvider.notifier);
  return transactionsNotifier.getRecentTransactions();
});