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
      rate: FeesBreakdown._safeParseDouble(json['rate']),
      timestamp: json['timestamp']?.toInt() ?? 0,
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
  final double? gasFeeInCrypto;

  FeesBreakdown({
    required this.baseFee,
    required this.providerFee,
    required this.gasFee,
    required this.totalFee,
    required this.discounts,
    this.gasFeeInCrypto,
  });

  factory FeesBreakdown.fromJson(Map<String, dynamic> json) {
    return FeesBreakdown(
      baseFee: _safeParseDouble(json['baseFee']),
      providerFee: _safeParseDouble(json['providerFee']),
      gasFee: _safeParseDouble(json['gasFee']),
      totalFee: _safeParseDouble(json['totalFee']),
      discounts: _safeParseDouble(json['discounts']),
      gasFeeInCrypto: _safeParseDouble(json['gasFeeInCrypto']),
    );
  }

  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFee': baseFee,
      'providerFee': providerFee,
      'gasFee': gasFee,
      'totalFee': totalFee,
      'discounts': discounts,
      'gasFeeInCrypto': gasFeeInCrypto,
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
      estimatedTimeSeconds: json['estimatedTimeSeconds']?.toInt() ?? 0,
      humanReadableTime: json['humanReadableTime']?.toString() ?? '',
      networkCongestion:
          FeesBreakdown._safeParseDouble(json['networkCongestion']),
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
  final double? fiatAmountToReceive; // For crypto-to-cash
  final String? cryptoCurrency; // For crypto-to-cash
  final String? fiatCurrency; // For crypto-to-cash

  TransactionResults({
    required this.cryptoAmountToReceive,
    required this.totalAmountToPay,
    required this.paymentCurrency,
    this.fiatAmountToReceive,
    this.cryptoCurrency,
    this.fiatCurrency,
  });

  factory TransactionResults.fromJson(Map<String, dynamic> json) {
    // Handle both crypto-to-cash and cash-to-crypto responses
    double cryptoAmount = 0.0;
    double totalToPay = 0.0;
    String currency = '';

    if (json['fiatAmountToReceive'] != null) {
      // Crypto-to-cash response
      cryptoAmount =
          FeesBreakdown._safeParseDouble(json['fiatAmountToReceive']);
      totalToPay = FeesBreakdown._safeParseDouble(json['totalAmountToPay']);
      currency = json['fiatCurrency'] ?? json['cryptoCurrency'] ?? '';
    } else {
      // Cash-to-crypto response (existing format)
      cryptoAmount =
          FeesBreakdown._safeParseDouble(json['cryptoAmountToReceive']);
      totalToPay = FeesBreakdown._safeParseDouble(json['totalAmountToPay']);
      currency = json['paymentCurrency'] ?? '';
    }

    return TransactionResults(
      cryptoAmountToReceive: cryptoAmount,
      totalAmountToPay: totalToPay,
      paymentCurrency: currency,
      fiatAmountToReceive:
          FeesBreakdown._safeParseDouble(json['fiatAmountToReceive']),
      cryptoCurrency: json['cryptoCurrency'],
      fiatCurrency: json['fiatCurrency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cryptoAmountToReceive': cryptoAmountToReceive,
      'totalAmountToPay': totalAmountToPay,
      'paymentCurrency': paymentCurrency,
      'fiatAmountToReceive': fiatAmountToReceive,
      'cryptoCurrency': cryptoCurrency,
      'fiatCurrency': fiatCurrency,
    };
  }

  // Helper getters for display
  double get receiveAmount => fiatAmountToReceive ?? cryptoAmountToReceive;
  String get receiveCurrency =>
      fiatCurrency ?? cryptoCurrency ?? paymentCurrency;
}
