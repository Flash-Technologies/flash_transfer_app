import 'exchange_rate.dart';

class ExchangeCalculation {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double rate;
  final double fee;
  final String feeCurrency;
  final String feeType;
  final double receivedAmount;
  final TransferTime transferTime;
  final NetworkInfo? networkInfo;

  ExchangeCalculation({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.rate,
    required this.fee,
    required this.feeCurrency,
    required this.feeType,
    required this.receivedAmount,
    required this.transferTime,
    this.networkInfo,
  });

  factory ExchangeCalculation.fromJson(Map<String, dynamic> json) {
    return ExchangeCalculation(
      fromCurrency: json['fromCurrency'],
      toCurrency: json['toCurrency'],
      amount: json['amount'].toDouble(),
      rate: json['rate'].toDouble(),
      fee: json['fee'].toDouble(),
      feeCurrency: json['feeCurrency'],
      feeType: json['feeType'],
      receivedAmount: json['receivedAmount'] ?? json['receivedAmount'].toDouble(),
      transferTime: TransferTime.fromJson(json['transferTime']),
      networkInfo: json['networkInfo'] != null
          ? NetworkInfo.fromJson(json['networkInfo'])
          : null,
    );
  }
}