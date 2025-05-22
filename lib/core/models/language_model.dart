import 'package:equatable/equatable.dart';

class LanguageModel extends Equatable {
  final String code;
  final String name;
  final String nativeName;
  final String flagAsset;
  final bool isRTL;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagAsset,
    this.isRTL = false,
  });

  LanguageModel copyWith({
    String? code,
    String? name,
    String? nativeName,
    String? flagAsset,
    bool? isRTL,
  }) {
    return LanguageModel(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      flagAsset: flagAsset ?? this.flagAsset,
      isRTL: isRTL ?? this.isRTL,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nativeName': nativeName,
      'flagAsset': flagAsset,
      'isRTL': isRTL,
    };
  }

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nativeName: json['nativeName'] ?? '',
      flagAsset: json['flagAsset'] ?? '',
      isRTL: json['isRTL'] ?? false,
    );
  }

  @override
  List<Object> get props => [code, name, nativeName, flagAsset, isRTL];

  @override
  String toString() => 'LanguageModel(code: $code, name: $name, nativeName: $nativeName)';
}