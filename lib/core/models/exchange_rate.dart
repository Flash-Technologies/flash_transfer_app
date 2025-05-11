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
      from: json['from'],
      to: json['to'],
      rate: json['rate'].toDouble(),
      timestamp: json['timestamp'],
      transferTime: TransferTime.fromJson(json['transferTime']),
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
      time: json['time'],
      unit: json['unit'],
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
      fee: json['fee'].toDouble(),
      feeUSD: json['feeUSD'].toDouble(),
      estimatedTimeSeconds: json['estimatedTimeSeconds'],
      networkCongestion: json['networkCongestion'].toDouble(),
      humanReadableTime: json['humanReadableTime'],
    );
  }
}