
import 'package:flutter/material.dart';

enum NFTRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

enum Blockchain {
  ethereum,
  polygon,
  binance,
  arbitrum,
  optimism,
}

class NFTModel {
  final String tokenId;
  final String contractAddress;
  final Blockchain blockchain;
  final String name;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> metadata;
  final List<NFTAttribute> attributes;
  final NFTRarity rarity;
  final double discountRate;
  final int rankBoost;
  final bool isEligible;
  final bool isExternal;
  final DateTime? acquiredDate;

  const NFTModel({
    required this.tokenId,
    required this.contractAddress,
    required this.blockchain,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.metadata = const {},
    this.attributes = const [],
    required this.rarity,
    this.discountRate = 0.0,
    this.rankBoost = 0,
    this.isEligible = false,
    this.isExternal = true,
    this.acquiredDate,
  });

  // Rarity-based styling
  Color get rarityColor {
    switch (rarity) {
      case NFTRarity.common:
        return Colors.grey.shade400;
      case NFTRarity.uncommon:
        return Colors.green.shade400;
      case NFTRarity.rare:
        return Colors.blue.shade400;
      case NFTRarity.epic:
        return Colors.purple.shade400;
      case NFTRarity.legendary:
        return Colors.amber.shade400;
    }
  }

  List<Color> get rarityGradient {
    switch (rarity) {
      case NFTRarity.common:
        return [Colors.grey.shade300, Colors.grey.shade500];
      case NFTRarity.uncommon:
        return [Colors.green.shade300, Colors.green.shade600];
      case NFTRarity.rare:
        return [Colors.blue.shade300, Colors.blue.shade600];
      case NFTRarity.epic:
        return [Colors.purple.shade300, Colors.purple.shade600];
      case NFTRarity.legendary:
        return [
          Colors.red.shade400,
          Colors.amber.shade400,
          Colors.green.shade400,
          Colors.blue.shade400,
          Colors.purple.shade400,
        ];
    }
  }

  String get rarityName {
    switch (rarity) {
      case NFTRarity.common:
        return 'Common';
      case NFTRarity.uncommon:
        return 'Uncommon';
      case NFTRarity.rare:
        return 'Rare';
      case NFTRarity.epic:
        return 'Epic';
      case NFTRarity.legendary:
        return 'Legendary';
    }
  }

  String get blockchainName {
    switch (blockchain) {
      case Blockchain.ethereum:
        return 'Ethereum';
      case Blockchain.polygon:
        return 'Polygon';
      case Blockchain.binance:
        return 'BSC';
      case Blockchain.arbitrum:
        return 'Arbitrum';
      case Blockchain.optimism:
        return 'Optimism';
    }
  }

  Color get blockchainColor {
    switch (blockchain) {
      case Blockchain.ethereum:
        return const Color(0xFF627EEA);
      case Blockchain.polygon:
        return const Color(0xFF8247E5);
      case Blockchain.binance:
        return const Color(0xFFF3BA2F);
      case Blockchain.arbitrum:
        return const Color(0xFF28A0F0);
      case Blockchain.optimism:
        return const Color(0xFFFF0420);
    }
  }

  NFTModel copyWith({
    String? tokenId,
    String? contractAddress,
    Blockchain? blockchain,
    String? name,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    List<NFTAttribute>? attributes,
    NFTRarity? rarity,
    double? discountRate,
    int? rankBoost,
    bool? isEligible,
    bool? isExternal,
    DateTime? acquiredDate,
  }) {
    return NFTModel(
      tokenId: tokenId ?? this.tokenId,
      contractAddress: contractAddress ?? this.contractAddress,
      blockchain: blockchain ?? this.blockchain,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      attributes: attributes ?? this.attributes,
      rarity: rarity ?? this.rarity,
      discountRate: discountRate ?? this.discountRate,
      rankBoost: rankBoost ?? this.rankBoost,
      isEligible: isEligible ?? this.isEligible,
      isExternal: isExternal ?? this.isExternal,
      acquiredDate: acquiredDate ?? this.acquiredDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'contractAddress': contractAddress,
      'blockchain': blockchain.name,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'rarity': rarity.name,
      'discountRate': discountRate,
      'rankBoost': rankBoost,
      'isEligible': isEligible,
      'isExternal': isExternal,
      'acquiredDate': acquiredDate?.toIso8601String(),
    };
  }

  factory NFTModel.fromJson(Map<String, dynamic> json) {
    return NFTModel(
      tokenId: json['tokenId'] as String,
      contractAddress: json['contractAddress'] as String,
      blockchain: Blockchain.values.firstWhere(
        (e) => e.name == json['blockchain'],
        orElse: () => Blockchain.ethereum,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((attr) => NFTAttribute.fromJson(attr))
              .toList() ??
          [],
      rarity: NFTRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => NFTRarity.common,
      ),
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      rankBoost: json['rankBoost'] as int? ?? 0,
      isEligible: json['isEligible'] as bool? ?? false,
      isExternal: json['isExternal'] as bool? ?? true,
      acquiredDate: json['acquiredDate'] != null
          ? DateTime.parse(json['acquiredDate'])
          : null,
    );
  }
}

class NFTAttribute {
  final String traitType;
  final dynamic value;
  final String? displayType;
  final int? maxValue;

  const NFTAttribute({
    required this.traitType,
    required this.value,
    this.displayType,
    this.maxValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'trait_type': traitType,
      'value': value,
      'display_type': displayType,
      'max_value': maxValue,
    };
  }

  factory NFTAttribute.fromJson(Map<String, dynamic> json) {
    return NFTAttribute(
      traitType: json['trait_type'] as String,
      value: json['value'],
      displayType: json['display_type'] as String?,
      maxValue: json['max_value'] as int?,
    );
  }
}