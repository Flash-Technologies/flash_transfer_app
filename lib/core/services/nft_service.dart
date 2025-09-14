import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/api_response.dart';
import '../models/nft_model.dart';

class NFTService {
  final ApiClient _apiClient;

  NFTService(this._apiClient);

  // Get user's NFT collection with optional network filter
  Future<NFTResponse> getUserNFTs({
    String network = 'POLYGON',
    bool testnet = false,
  }) async {
    try {
      final response = await _apiClient.get(
        Endpoints.userNFTs,
        queryParameters: {
          'network': network,
          'testnet': testnet.toString(),
        },
      );

      return NFTResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch user NFTs: $e');
    }
  }

  // Calculate total discount from NFTs
  double calculateTotalDiscount(List<NFTModel> nfts) {
    final eligibleNFTs = nfts.where((nft) => nft.isEligible);
    double totalDiscount = 0;
    
    for (var nft in eligibleNFTs) {
      totalDiscount += nft.discountRate;
    }
    
    // Apply stacking rules if needed
    return totalDiscount;
  }

  // Get NFTs filtered by rarity
  List<NFTModel> filterByRarity(List<NFTModel> nfts, NFTRarity rarity) {
    return nfts.where((nft) => nft.rarity == rarity).toList();
  }

  // Get NFTs filtered by blockchain
  List<NFTModel> filterByBlockchain(List<NFTModel> nfts, Blockchain blockchain) {
    return nfts.where((nft) => nft.blockchain == blockchain).toList();
  }

  // Get eligible NFTs only
  List<NFTModel> getEligibleNFTs(List<NFTModel> nfts) {
    return nfts.where((nft) => nft.isEligible).toList();
  }
}

// Response model for NFT API
class NFTResponse {
  final bool success;
  final NFTData? data;
  final String? message;

  NFTResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory NFTResponse.fromJson(Map<String, dynamic> json) {
    return NFTResponse(
      success: json['success'] as bool,
      data: json['data'] != null ? NFTData.fromJson(json['data']) : null,
      message: json['message'] as String?,
    );
  }
}

class NFTData {
  final List<NFTModel> nfts;
  final DiscountSummary? discountSummary;
  final Map<String, RarityInfo>? rarityBreakdown;
  final NFTMetadata? metadata;
  final Map<String, BenefitTier>? benefitsTiers;

  NFTData({
    required this.nfts,
    this.discountSummary,
    this.rarityBreakdown,
    this.metadata,
    this.benefitsTiers,
  });

  factory NFTData.fromJson(Map<String, dynamic> json) {
    // Parse NFTs
    List<NFTModel> nfts = [];
    if (json['nfts'] != null) {
      nfts = (json['nfts'] as List)
          .map((nft) => NFTModel.fromJson(nft))
          .toList();
    }

    // Parse discount summary
    DiscountSummary? discountSummary;
    if (json['discountSummary'] != null) {
      discountSummary = DiscountSummary.fromJson(json['discountSummary']);
    }

    // Parse rarity breakdown
    Map<String, RarityInfo>? rarityBreakdown;
    if (json['rarityBreakdown'] != null) {
      rarityBreakdown = {};
      final breakdown = json['rarityBreakdown'] as Map<String, dynamic>;
      breakdown.forEach((key, value) {
        rarityBreakdown![key] = RarityInfo.fromJson(value);
      });
    }

    // Parse metadata
    NFTMetadata? metadata;
    if (json['metadata'] != null) {
      metadata = NFTMetadata.fromJson(json['metadata']);
    }

    // Parse benefits tiers
    Map<String, BenefitTier>? benefitsTiers;
    if (json['benefitsTiers'] != null) {
      benefitsTiers = {};
      final tiers = json['benefitsTiers'] as Map<String, dynamic>;
      tiers.forEach((key, value) {
        benefitsTiers![key] = BenefitTier.fromJson(value);
      });
    }

    return NFTData(
      nfts: nfts,
      discountSummary: discountSummary,
      rarityBreakdown: rarityBreakdown,
      metadata: metadata,
      benefitsTiers: benefitsTiers,
    );
  }
}

class DiscountSummary {
  final double currentStackedDiscount;
  final double maxPossibleDiscount;
  final int stackedNFTsUsed;
  final int maxStackableNFTs;

  DiscountSummary({
    required this.currentStackedDiscount,
    required this.maxPossibleDiscount,
    required this.stackedNFTsUsed,
    required this.maxStackableNFTs,
  });

  factory DiscountSummary.fromJson(Map<String, dynamic> json) {
    return DiscountSummary(
      currentStackedDiscount: (json['currentStackedDiscount'] as num).toDouble(),
      maxPossibleDiscount: (json['maxPossibleDiscount'] as num).toDouble(),
      stackedNFTsUsed: json['stackedNFTsUsed'] as int,
      maxStackableNFTs: json['maxStackableNFTs'] as int,
    );
  }
}

class RarityInfo {
  final int count;
  final double averageDiscount;
  final double totalDiscount;

  RarityInfo({
    required this.count,
    required this.averageDiscount,
    required this.totalDiscount,
  });

  factory RarityInfo.fromJson(Map<String, dynamic> json) {
    return RarityInfo(
      count: json['count'] as int,
      averageDiscount: (json['averageDiscount'] as num).toDouble(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
    );
  }
}

class NFTMetadata {
  final String? walletAddress;
  final String? network;
  final bool isMainnet;
  final int totalFound;
  final int eligibleForBenefits;
  final int collections;
  final bool discountsEnabled;
  final String? lastUpdated;

  NFTMetadata({
    this.walletAddress,
    this.network,
    required this.isMainnet,
    required this.totalFound,
    required this.eligibleForBenefits,
    required this.collections,
    required this.discountsEnabled,
    this.lastUpdated,
  });

  factory NFTMetadata.fromJson(Map<String, dynamic> json) {
    return NFTMetadata(
      walletAddress: json['walletAddress'] as String?,
      network: json['network'] as String?,
      isMainnet: json['isMainnet'] as bool? ?? true,
      totalFound: json['totalFound'] as int? ?? 0,
      eligibleForBenefits: json['eligibleForBenefits'] as int? ?? 0,
      collections: json['collections'] as int? ?? 0,
      discountsEnabled: json['discountsEnabled'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] as String?,
    );
  }
}

class BenefitTier {
  final double feeDiscount;
  final int rankingBoost;
  final String description;

  BenefitTier({
    required this.feeDiscount,
    required this.rankingBoost,
    required this.description,
  });

  factory BenefitTier.fromJson(Map<String, dynamic> json) {
    return BenefitTier(
      feeDiscount: (json['feeDiscount'] as num).toDouble(),
      rankingBoost: json['rankingBoost'] as int,
      description: json['description'] as String,
    );
  }
}