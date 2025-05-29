class TransactionEstimate {
  final ExchangeRateData exchangeRate;
  final FeesBreakdown fees;
  final NetworkInfo networkInfo;
  final TransactionResults results;

  TransactionEstimate({
    required this.exchangeRate,
    required this.fees,
    required this.networkInfo,
    required this.results,
  });

  factory TransactionEstimate.fromJson(Map<String, dynamic> json) {
    return TransactionEstimate(
      exchangeRate: ExchangeRateData.fromJson(json['exchangeRate']),
      fees: FeesBreakdown.fromJson(json['fees']),
      networkInfo: NetworkInfo.fromJson(json['networkInfo']),
      results: TransactionResults.fromJson(json['results']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exchangeRate': exchangeRate.toJson(),
      'fees': fees.toJson(),
      'networkInfo': networkInfo.toJson(),
      'results': results.toJson(),
    };
  }
}

class ExchangeRateData {
  final double rate;
  final int timestamp;

  ExchangeRateData({
    required this.rate,
    required this.timestamp,
  });

  factory ExchangeRateData.fromJson(Map<String, dynamic> json) {
    return ExchangeRateData(
      rate: (json['rate'] as num).toDouble(),
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'timestamp': timestamp,
    };
  }
}

class FeesBreakdown {
  final double baseFee;
  final double providerFee;
  final double gasFee;
  final double totalFee;
  final double discounts;

  FeesBreakdown({
    required this.baseFee,
    required this.providerFee,
    required this.gasFee,
    required this.totalFee,
    required this.discounts,
  });

  factory FeesBreakdown.fromJson(Map<String, dynamic> json) {
    return FeesBreakdown(
      baseFee: (json['baseFee'] as num).toDouble(),
      providerFee: (json['providerFee'] as num).toDouble(),
      gasFee: (json['gasFee'] as num).toDouble(),
      totalFee: (json['totalFee'] as num).toDouble(),
      discounts: (json['discounts'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFee': baseFee,
      'providerFee': providerFee,
      'gasFee': gasFee,
      'totalFee': totalFee,
      'discounts': discounts,
    };
  }

  double get totalFees => totalFee;
}

class NetworkInfo {
  final int estimatedTimeSeconds;
  final String humanReadableTime;
  final double networkCongestion;

  NetworkInfo({
    required this.estimatedTimeSeconds,
    required this.humanReadableTime,
    required this.networkCongestion,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInfo(
      estimatedTimeSeconds: json['estimatedTimeSeconds'] as int,
      humanReadableTime: json['humanReadableTime'] as String,
      networkCongestion: (json['networkCongestion'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimatedTimeSeconds': estimatedTimeSeconds,
      'humanReadableTime': humanReadableTime,
      'networkCongestion': networkCongestion,
    };
  }
}

class TransactionResults {
  final double cryptoAmountToReceive;
  final double totalAmountToPay;
  final String paymentCurrency;

  TransactionResults({
    required this.cryptoAmountToReceive,
    required this.totalAmountToPay,
    required this.paymentCurrency,
  });

  factory TransactionResults.fromJson(Map<String, dynamic> json) {
    return TransactionResults(
      cryptoAmountToReceive: (json['cryptoAmountToReceive'] as num).toDouble(),
      totalAmountToPay: (json['totalAmountToPay'] as num).toDouble(),
      paymentCurrency: json['paymentCurrency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cryptoAmountToReceive': cryptoAmountToReceive,
      'totalAmountToPay': totalAmountToPay,
      'paymentCurrency': paymentCurrency,
    };
  }
}
