class ExchangeRate {
  final String from;
  final String to;
  final double rate;
  final int timestamp;
  final TransferTime transferTime;
  final NetworkInfo? networkInfo;

  ExchangeRate({
    required this.from,
    required this.to,
    required this.rate,
    required this.timestamp,
    required this.transferTime,
    this.networkInfo,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      from: json['fromCurrency'] ?? json['from'] ?? '',
      to: json['toCurrency'] ?? json['to'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? 0,
      transferTime: json['transferTime'] != null 
          ? TransferTime.fromJson(json['transferTime'])
          : TransferTime(time: 0, unit: 'seconds'),
      networkInfo: json['networkInfo'] != null
          ? NetworkInfo.fromJson(json['networkInfo'])
          : null,
    );
  }
}

class TransferTime {
  final int time;
  final String unit;

  TransferTime({
    required this.time,
    required this.unit,
  });

  factory TransferTime.fromJson(Map<String, dynamic> json) {
    return TransferTime(
      time: json['time'] ?? 0,
      unit: json['unit'] ?? 'seconds',
    );
  }
}

class NetworkInfo {
  final double fee;
  final double feeUSD;
  final int estimatedTimeSeconds;
  final double networkCongestion;
  final String? humanReadableTime;

  NetworkInfo({
    required this.fee,
    required this.feeUSD,
    required this.estimatedTimeSeconds,
    required this.networkCongestion,
    this.humanReadableTime,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return NetworkInfo(
      fee: (json['fee'] ?? 0).toDouble(),
      feeUSD: (json['feeUSD'] ?? 0).toDouble(),
      estimatedTimeSeconds: json['estimatedTimeSeconds'] ?? 0,
      networkCongestion: (json['networkCongestion'] ?? 0).toDouble(),
      humanReadableTime: json['humanReadableTime'],
    );
  }
}