import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentType {
  cash,
  wallet,
  card,
  bank,
  mobile,
  crypto,
  cryptoReceive,
  cryptoSendMobile,
}

class PaymentState {
  final String activePay;
  final String activeReceive;
  final String? selectedProvider;
  final PaymentType? selectedPaymentType;

  PaymentState({
    this.activePay = 'cash',
    this.activeReceive = 'cash',
    this.selectedProvider,
    this.selectedPaymentType,
  });

  PaymentState copyWith({
    String? activePay,
    String? activeReceive,
    String? selectedProvider,
    PaymentType? selectedPaymentType,
  }) {
    return PaymentState(
      activePay: activePay ?? this.activePay,
      activeReceive: activeReceive ?? this.activeReceive,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
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

  void setSelectedPaymentType(PaymentType paymentType) {
    state = state.copyWith(selectedPaymentType: paymentType);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier();
});
