import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/beneficiary_service.dart';
import '../core/models/beneficiary.dart';
import '../providers/auth_provider.dart';

// Service provider - Updated to use authenticated API client
final beneficiaryServiceProvider = Provider<BeneficiaryService>((ref) {
  final apiClient =
      ref.watch(apiClientProvider); // Use the authenticated API client
  return BeneficiaryService(apiClient);
});

// State for beneficiaries list
class BeneficiariesState {
  final List<Beneficiary> beneficiaries;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final BeneficiaryPagination? pagination;
  final bool isCreating;

  BeneficiariesState({
    this.beneficiaries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.pagination,
    this.isCreating = false,
  });

  BeneficiariesState copyWith({
    List<Beneficiary>? beneficiaries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    BeneficiaryPagination? pagination,
    bool? isCreating,
  }) {
    return BeneficiariesState(
      beneficiaries: beneficiaries ?? this.beneficiaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      pagination: pagination ?? this.pagination,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  List<Beneficiary> get filteredBeneficiaries {
    if (searchQuery.isEmpty) {
      return beneficiaries;
    }

    return beneficiaries.where((beneficiary) {
      final query = searchQuery.toLowerCase();
      return beneficiary.displayName.toLowerCase().contains(query) ||
          beneficiary.email.toLowerCase().contains(query) ||
          beneficiary.mobileNumber.contains(query) ||
          beneficiary.country.toLowerCase().contains(query) ||
          beneficiary.city.toLowerCase().contains(query);
    }).toList();
  }
}

// Notifier for managing beneficiaries state
class BeneficiariesNotifier extends StateNotifier<BeneficiariesState> {
  final BeneficiaryService _service;

  BeneficiariesNotifier(this._service) : super(BeneficiariesState());

  Future<void> loadBeneficiaries({bool refresh = false}) async {
    if (refresh || state.beneficiaries.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _service.getBeneficiaries(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      if (response.success) {
        state = state.copyWith(
          beneficiaries: response.data.data,
          pagination: response.data.pagination,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load beneficiaries',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    // Debounce search - in real implementation you might want to add a timer
    if (query.length >= 2 || query.isEmpty) {
      // Use Future.microtask to avoid provider modification during build
      Future.microtask(() => loadBeneficiaries(refresh: true));
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    Future.microtask(() => loadBeneficiaries(refresh: true));
  }

  Future<void> refresh() async {
    await loadBeneficiaries(refresh: true);
  }

  Future<Beneficiary?> createBeneficiary(
      Map<String, dynamic> beneficiaryData) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      final newBeneficiary = await _service.createBeneficiary(beneficiaryData);

      // Add the new beneficiary to the list
      final updatedBeneficiaries = [newBeneficiary, ...state.beneficiaries];

      state = state.copyWith(
        beneficiaries: updatedBeneficiaries,
        isCreating: false,
        error: null,
      );

      return newBeneficiary;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

// Provider for beneficiaries state
final beneficiariesProvider =
    StateNotifierProvider<BeneficiariesNotifier, BeneficiariesState>((ref) {
  final service = ref.watch(beneficiaryServiceProvider);
  return BeneficiariesNotifier(service);
});

// Selected beneficiary provider
final selectedBeneficiaryProvider = StateProvider<Beneficiary?>((ref) => null);

// Provider for checking if modal should be shown
final showContactModalProvider = StateProvider<bool>((ref) => false);
