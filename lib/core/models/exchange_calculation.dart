class ExchangeCalculation {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double amount;
  final double convertedAmount; // recipientGets from API
  final double fee;
  final String feeCurrency;
  final double totalAmount;
  final int timestamp;
  final NetworkInfo? networkInfo;
  final FeeBreakdown? feeBreakdown;

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
    this.feeBreakdown,
  });

  // This is a getter to maintain compatibility with your existing code
  double get receivedAmount => convertedAmount;

  factory ExchangeCalculation.fromJson(Map<String, dynamic> json) {
    final feeBreakdownJson = json['feeBreakdown'];
    final totalFee = feeBreakdownJson != null ? 
        (feeBreakdownJson['fees']?['totalFee'] ?? 0.0).toDouble() : 0.0;
    final totalAmountWithFees = feeBreakdownJson != null ?
        (feeBreakdownJson['totalAmountWithFees'] ?? 0.0).toDouble() : 
        (json['amount'] ?? 0.0).toDouble();
    
    return ExchangeCalculation(
      fromCurrency: json['fromCurrency'] ?? json['from'] ?? '',
      toCurrency: json['toCurrency'] ?? json['to'] ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      convertedAmount: (json['recipientGets'] ?? json['convertedAmount'] ?? 0.0).toDouble(),
      fee: totalFee,
      feeCurrency: feeBreakdownJson?['currency'] ?? json['fromCurrency'] ?? '',
      totalAmount: totalAmountWithFees,
      timestamp: json['timestamp'] ?? 0,
      networkInfo: json['networkInfo'] != null
          ? NetworkInfo.fromJson(json['networkInfo'])
          : null,
      feeBreakdown: feeBreakdownJson != null 
          ? FeeBreakdown.fromJson(feeBreakdownJson)
          : null,
    );
  }
}

class NetworkInfo {
  final String network;
  final double fee;
  final double feeUSD;
  final int estimatedTimeSeconds;
  final double networkCongestion;
  final String humanReadableTime;
  final String networkStatus;

  NetworkInfo({
    required this.network,
    required this.fee,
    required this.feeUSD,
    required this.estimatedTimeSeconds,
    required this.networkCongestion,
    required this.humanReadableTime,
    required this.networkStatus,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInfo(
      network: json['network'] ?? '',
      fee: (json['fee'] ?? 0.0).toDouble(),
      feeUSD: (json['feeUSD'] ?? 0.0).toDouble(),
      estimatedTimeSeconds: json['estimatedTimeSeconds'] ?? 0,
      networkCongestion: (json['networkCongestion'] ?? 0.0).toDouble(),
      humanReadableTime: json['humanReadableTime'] ?? '',
      networkStatus: _getNetworkStatus(json['networkCongestion'] ?? 0.0),
    );
  }

  static String _getNetworkStatus(double congestion) {
    if (congestion <= 0.3) return 'Low';
    if (congestion <= 0.7) return 'Medium';
    return 'High';
  }

  factory NetworkInfo.fromGasFeeDetails(Map<String, dynamic> gasFeeDetails) {
    return NetworkInfo(
      network: gasFeeDetails['network'] ?? '',
      fee: (gasFeeDetails['gasFeeAmount'] ?? 0.0).toDouble(),
      feeUSD: (gasFeeDetails['gasFeeUSD'] ?? 0.0).toDouble(),
      estimatedTimeSeconds: gasFeeDetails['estimatedTimeSeconds'] ?? 0,
      networkCongestion: (gasFeeDetails['networkCongestion'] ?? 0.0).toDouble(),
      humanReadableTime: gasFeeDetails['humanReadableTime'] ?? '',
      networkStatus: _getNetworkStatus((gasFeeDetails['networkCongestion'] ?? 0.0).toDouble()),
    );
  }
}

class FeeBreakdown {
  final double amount;
  final String currency;
  final double totalFee;
  final double totalAmountWithFees;
  final double effectiveRate;
  final FeeDetails fees;
  
  FeeBreakdown({
    required this.amount,
    required this.currency,
    required this.totalFee,
    required this.totalAmountWithFees,
    required this.effectiveRate,
    required this.fees,
  });
  
  factory FeeBreakdown.fromJson(Map<String, dynamic> json) {
    return FeeBreakdown(
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? '',
      totalFee: (json['fees']?['totalFee'] ?? 0.0).toDouble(),
      totalAmountWithFees: (json['totalAmountWithFees'] ?? 0.0).toDouble(),
      effectiveRate: (json['effectiveRate'] ?? 0.0).toDouble(),
      fees: FeeDetails.fromJson(json['fees'] ?? {}),
    );
  }
}

class FeeDetails {
  final double platformCharges;
  final double aggregatorCharges;
  final double gasFee;
  final double loyaltyDiscount;
  final double nftDiscount;
  final double totalDiscount;
  final double totalFee;
  
  FeeDetails({
    required this.platformCharges,
    required this.aggregatorCharges,
    required this.gasFee,
    required this.loyaltyDiscount,
    required this.nftDiscount,
    required this.totalDiscount,
    required this.totalFee,
  });
  
  factory FeeDetails.fromJson(Map<String, dynamic> json) {
    return FeeDetails(
      platformCharges: (json['platformCharges'] ?? 0.0).toDouble(),
      aggregatorCharges: (json['aggregatorCharges'] ?? 0.0).toDouble(),
      gasFee: (json['gasFee'] ?? 0.0).toDouble(),
      loyaltyDiscount: (json['loyaltyDiscount'] ?? 0.0).toDouble(),
      nftDiscount: (json['nftDiscount'] ?? 0.0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0.0).toDouble(),
      totalFee: (json['totalFee'] ?? 0.0).toDouble(),
    );
  }
}
