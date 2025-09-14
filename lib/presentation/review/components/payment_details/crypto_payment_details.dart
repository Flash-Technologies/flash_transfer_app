import 'package:flutter/material.dart';
import 'package:flash_transfer_app/config/theme.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';
import 'package:flash_transfer_app/providers/payment_provider.dart';
import '../comprehensive_crypto_details.dart';

class CryptoPaymentDetails extends StatefulWidget {
  final PaymentDetails details;
  final PaymentType paymentType;

  const CryptoPaymentDetails({
    Key? key,
    required this.details,
    required this.paymentType,
  }) : super(key: key);

  @override
  State<CryptoPaymentDetails> createState() => _CryptoPaymentDetailsState();
}

class _CryptoPaymentDetailsState extends State<CryptoPaymentDetails> {

  @override
  Widget build(BuildContext context) {
    return const ComprehensiveCryptoDetails();
  }
}