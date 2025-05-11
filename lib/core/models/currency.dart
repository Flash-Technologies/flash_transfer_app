class Currency {
  final String code;
  final String name;
  final String type; // FIAT, CRYPTO
  final String? logo;
  final List<String>? networks;

  Currency({
    required this.code,
    required this.name,
    required this.type,
    this.logo,
    this.networks,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      type: json['type'],
      logo: json['icon'],
      networks: json['networks'] != null
          ? List<String>.from(json['networks'])
          : null,
    );
  }
}