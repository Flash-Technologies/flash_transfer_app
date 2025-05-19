import 'package:flash_transfer_app/presentation/review/components/payment_details/cash_payment_details.dart.dart';
import 'package:flutter/material.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';

// Import all payment type components
import 'card_payment_details.dart';
import 'bank_payment_details.dart';
import 'crypto_payment_details.dart';

import 'mobile_payment_details.dart';

/// Factory class that creates the appropriate payment details widget
/// based on the payment type
class PaymentDetailsFactory {
  /// Creates a payment details widget based on the payment type
  static Widget create({
    required PaymentType paymentType,
    required PaymentDetails paymentDetails,
  }) {
    switch (paymentType) {
      case PaymentType.card:
        return CardPaymentDetails(details: paymentDetails);

      case PaymentType.bank:
        return BankPaymentDetails(details: paymentDetails);

      case PaymentType.cash:
        return CashPaymentDetails(details: paymentDetails);

      case PaymentType.crypto:
      case PaymentType.cryptoReceive:
      case PaymentType.cryptoSendMobile:
      case PaymentType.wallet:
        return CryptoPaymentDetails(
          details: paymentDetails,
          paymentType: paymentType,
        );

      case PaymentType.mobile:
        return MobilePaymentDetails(details: paymentDetails);
    }
  }
}
