class TransactionEstimate {
  final ExchangeRateData exchangeRate;
  final FeesBreakdown fees;
  final NetworkInfo networkInfo;
  final TransactionResults results;
  final DiscountsBreakdown discounts;
  final TransactionRequest request;

  TransactionEstimate({
    required this.exchangeRate,
    required this.fees,
    required this.networkInfo,
    required this.results,
    required this.discounts,
    required this.request,
  });

  factory TransactionEstimate.fromJson(Map<String, dynamic> json) {
    return TransactionEstimate(
      exchangeRate: ExchangeRateData.fromJson(json['exchangeRate']),
      fees: FeesBreakdown.fromJson(json['fees']),
      networkInfo: NetworkInfo.fromJson(json['networkInfo']),
      results: TransactionResults.fromJson(json['results']),
      discounts: DiscountsBreakdown.fromJson(json['discounts'] ?? {}),
      request: TransactionRequest.fromJson(json['request'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exchangeRate': exchangeRate.toJson(),
      'fees': fees.toJson(),
      'networkInfo': networkInfo.toJson(),
      'results': results.toJson(),
      'discounts': discounts.toJson(),
      'request': request.toJson(),
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
  final double platformCharges;
  final double aggregatorCharges;
  final double gasFee;
  final double totalFee;
  final double loyaltyDiscount;
  final double nftDiscount;
  final double totalDiscount;
  final double? gasFeeInCrypto;
  final bool enhancedFeatures;

  FeesBreakdown({
    required this.baseFee,
    required this.providerFee,
    required this.platformCharges,
    required this.aggregatorCharges,
    required this.gasFee,
    required this.totalFee,
    required this.loyaltyDiscount,
    required this.nftDiscount,
    required this.totalDiscount,
    this.gasFeeInCrypto,
    required this.enhancedFeatures,
  });

  factory FeesBreakdown.fromJson(Map<String, dynamic> json) {
    return FeesBreakdown(
      baseFee: _safeParseDouble(json['baseFee']),
      providerFee: _safeParseDouble(json['providerFee']),
      platformCharges: _safeParseDouble(json['platformCharges']),
      aggregatorCharges: _safeParseDouble(json['aggregatorCharges']),
      gasFee: _safeParseDouble(json['gasFee']),
      totalFee: _safeParseDouble(json['totalFee']),
      loyaltyDiscount: _safeParseDouble(json['loyaltyDiscount']),
      nftDiscount: _safeParseDouble(json['nftDiscount']),
      totalDiscount: _safeParseDouble(json['totalDiscount']),
      gasFeeInCrypto: _safeParseDouble(json['gasFeeInCrypto']),
      enhancedFeatures: json['enhancedFeatures'] ?? false,
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
      'platformCharges': platformCharges,
      'aggregatorCharges': aggregatorCharges,
      'gasFee': gasFee,
      'totalFee': totalFee,
      'loyaltyDiscount': loyaltyDiscount,
      'nftDiscount': nftDiscount,
      'totalDiscount': totalDiscount,
      'gasFeeInCrypto': gasFeeInCrypto,
      'enhancedFeatures': enhancedFeatures,
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

class DiscountsBreakdown {
  final LoyaltyDiscount loyalty;
  final NFTDiscount nft;

  DiscountsBreakdown({
    required this.loyalty,
    required this.nft,
  });

  factory DiscountsBreakdown.fromJson(Map<String, dynamic> json) {
    return DiscountsBreakdown(
      loyalty: LoyaltyDiscount.fromJson(json['loyalty'] ?? {}),
      nft: NFTDiscount.fromJson(json['nft'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loyalty': loyalty.toJson(),
      'nft': nft.toJson(),
    };
  }
}

class LoyaltyDiscount {
  final bool applied;
  final double amount;
  final String rank;

  LoyaltyDiscount({
    required this.applied,
    required this.amount,
    required this.rank,
  });

  factory LoyaltyDiscount.fromJson(Map<String, dynamic> json) {
    return LoyaltyDiscount(
      applied: json['applied'] ?? false,
      amount: FeesBreakdown._safeParseDouble(json['amount']),
      rank: json['rank'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applied': applied,
      'amount': amount,
      'rank': rank,
    };
  }
}

class NFTDiscount {
  final bool applied;
  final double amount;
  final String rarity;

  NFTDiscount({
    required this.applied,
    required this.amount,
    required this.rarity,
  });

  factory NFTDiscount.fromJson(Map<String, dynamic> json) {
    return NFTDiscount(
      applied: json['applied'] ?? false,
      amount: FeesBreakdown._safeParseDouble(json['amount']),
      rarity: json['rarity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applied': applied,
      'amount': amount,
      'rarity': rarity,
    };
  }
}

class TransactionRequest {
  final double amount;
  final String sourceCurrency;
  final String destinationCurrency;
  final String blockchainNetwork;
  final String paymentMethod;
  final String countryCode;

  TransactionRequest({
    required this.amount,
    required this.sourceCurrency,
    required this.destinationCurrency,
    required this.blockchainNetwork,
    required this.paymentMethod,
    required this.countryCode,
  });

  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      amount: FeesBreakdown._safeParseDouble(json['amount']),
      sourceCurrency: json['sourceCurrency'] ?? '',
      destinationCurrency: json['destinationCurrency'] ?? '',
      blockchainNetwork: json['blockchainNetwork'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      countryCode: json['countryCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'sourceCurrency': sourceCurrency,
      'destinationCurrency': destinationCurrency,
      'blockchainNetwork': blockchainNetwork,
      'paymentMethod': paymentMethod,
      'countryCode': countryCode,
    };
  }
}
