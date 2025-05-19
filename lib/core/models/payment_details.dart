class PaymentDetails {
  final String methodName;
  final String? methodIcon;
  final String? networkName;
  final String? networkIcon;
  final String? fundSource;
  final String? purpose;
  final String? phoneNumber;
  final String? cryptoAddress;

  PaymentDetails({
    required this.methodName,
    this.methodIcon,
    this.networkName,
    this.networkIcon,
    this.fundSource,
    this.purpose,
    this.phoneNumber,
    this.cryptoAddress,
  });

  // If you need to create from JSON
  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      methodName: json['methodName'] ?? '',
      methodIcon: json['methodIcon'],
      networkName: json['networkName'],
      networkIcon: json['networkIcon'],
      fundSource: json['fundSource'],
      purpose: json['purpose'],
      phoneNumber: json['phoneNumber'],
      cryptoAddress: json['cryptoAddress'],
    );
  }

  // If you need to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'methodName': methodName,
      'methodIcon': methodIcon,
      'networkName': networkName,
      'networkIcon': networkIcon,
      'fundSource': fundSource,
      'purpose': purpose,
      'phoneNumber': phoneNumber,
      'cryptoAddress': cryptoAddress,
    };
  }
}