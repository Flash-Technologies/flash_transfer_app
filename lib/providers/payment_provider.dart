import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final String activePay;
  final String activeReceive;
  final String? selectedProvider;

  PaymentState({
    this.activePay = 'cash',
    this.activeReceive = 'cash',
    this.selectedProvider,
  });

  PaymentState copyWith({
    String? activePay,
    String? activeReceive,
    String? selectedProvider,
  }) {
    return PaymentState(
      activePay: activePay ?? this.activePay,
      activeReceive: activeReceive ?? this.activeReceive,
      selectedProvider: selectedProvider ?? this.selectedProvider,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  void setActivePay(String method) {
    state = state.copyWith(activePay: method);
  }

  void setActiveReceive(String method) {
    state = state.copyWith(activeReceive: method);
  }

  void setSelectedProvider(String providerId) {
    state = state.copyWith(selectedProvider: providerId);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});