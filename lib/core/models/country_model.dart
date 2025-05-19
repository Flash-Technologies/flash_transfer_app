// lib/core/models/country_model.dart
class CountryModel {
  final String name;
  final String code;
  final String flagUrl;

  CountryModel({
    required this.name,
    required this.code,
    required this.flagUrl,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    String flagUrl = '';
    
    // Try to get PNG flag URL from the flags object
    if (json['flags'] != null && json['flags']['png'] != null) {
      flagUrl = json['flags']['png'];
    }
    
    return CountryModel(
      name: json['name']['common'] ?? '',
      code: json['cca2'] ?? '',
      flagUrl: flagUrl,
    );
  }
}