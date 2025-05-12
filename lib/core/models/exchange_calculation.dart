class ExchangeCalculation {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double amount;
  final double convertedAmount; // API returns this as convertedAmount, not receivedAmount
  final double fee;
  final String feeCurrency;
  final double totalAmount;
  final int timestamp;
  final NetworkInfo? networkInfo;

  ExchangeCalculation({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.amount,
    required this.convertedAmount,
    required this.fee,
    required this.feeCurrency,
    required this.totalAmount,
    required this.timestamp,
    this.networkInfo,
  });

  // This is a getter to maintain compatibility with your existing code
  double get receivedAmount => convertedAmount;

  factory ExchangeCalculation.fromJson(Map<String, dynamic> json) {
    return ExchangeCalculation(
      fromCurrency: json['fromCurrency'] ?? '',
      toCurrency: json['toCurrency'] ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      convertedAmount: (json['convertedAmount'] ?? 0.0).toDouble(),
      fee: (json['fee'] ?? 0.0).toDouble(),
      feeCurrency: json['feeCurrency'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] ?? 0,
      networkInfo: json['networkInfo'] != null 
          ? NetworkInfo.fromJson(json['networkInfo']) 
          : null,
    );
  }
}

class NetworkInfo {
  final double fee;
  final double feeUSD;
  final int estimatedTimeSeconds;
  final double networkCongestion;
  final String humanReadableTime;

  NetworkInfo({
    required this.fee,
    required this.feeUSD,
    required this.estimatedTimeSeconds,
    required this.networkCongestion,
    required this.humanReadableTime,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInfo(
      fee: (json['fee'] ?? 0.0).toDouble(),
      feeUSD: (json['feeUSD'] ?? 0.0).toDouble(),
      estimatedTimeSeconds: json['estimatedTimeSeconds'] ?? 0,
      networkCongestion: (json['networkCongestion'] ?? 0.0).toDouble(),
      humanReadableTime: json['humanReadableTime'] ?? '',
    );
  }
}