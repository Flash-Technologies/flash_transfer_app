import 'package:flash_transfer_app/core/models/user.dart';
import 'package:flash_transfer_app/core/models/payment_details.dart';

class TransactionDetails {
  final User sender;
  final User receiver;
  final PaymentDetails paymentDetails;
  final double sendAmount;
  final String sendCurrency;
  final double receiveAmount;
  final String receiveCurrency;
  final double fee;
  final String feeCurrency;
  final double totalAmount;
  final String receiverCountry;
  final bool isImmediate;

  TransactionDetails({
    required this.sender,
    required this.receiver,
    required this.paymentDetails,
    required this.sendAmount,
    required this.sendCurrency,
    required this.receiveAmount,
    required this.receiveCurrency,
    required this.fee,
    required this.feeCurrency,
    required this.totalAmount,
    required this.receiverCountry,
    this.isImmediate = true,
  });
}
