import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/nft_model.dart';
import '../core/services/nft_service.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';

// NFT state classes
abstract class NFTState {}

class NFTInitial extends NFTState {}

class NFTLoading extends NFTState {}

class NFTLoaded extends NFTState {
  final List<NFTModel> nfts;
  final NFTStats stats;

  NFTLoaded({
    required this.nfts,
    required this.stats,
  });
}

class NFTError extends NFTState {
  final String message;
  final Exception? exception;

  NFTError({
    required this.message,
    this.exception,
  });
}

// NFT stats model
class NFTStats {
  final int totalNFTs;
  final int eligibleNFTs;
  final double totalDiscount;
  final int totalRankBoost;
  final Map<NFTRarity, int> rarityDistribution;
  final Map<Blockchain, int> blockchainDistribution;

  const NFTStats({
    required this.totalNFTs,
    required this.eligibleNFTs,
    required this.totalDiscount,
    required this.totalRankBoost,
    required this.rarityDistribution,
    required this.blockchainDistribution,
  });

  factory NFTStats.fromNFTs(List<NFTModel> nfts) {
    final rarityDistribution = <NFTRarity, int>{};
    final blockchainDistribution = <Blockchain, int>{};
    
    for (final rarity in NFTRarity.values) {
      rarityDistribution[rarity] = 0;
    }
    
    for (final blockchain in Blockchain.values) {
      blockchainDistribution[blockchain] = 0;
    }

    double totalDiscount = 0;
    int totalRankBoost = 0;
    int eligibleCount = 0;

    for (final nft in nfts) {
      rarityDistribution[nft.rarity] = 
          (rarityDistribution[nft.rarity] ?? 0) + 1;
      blockchainDistribution[nft.blockchain] = 
          (blockchainDistribution[nft.blockchain] ?? 0) + 1;
      
      if (nft.isEligible) {
        eligibleCount++;
        totalDiscount += nft.discountRate;
        totalRankBoost += nft.rankBoost;
      }
    }

    return NFTStats(
      totalNFTs: nfts.length,
      eligibleNFTs: eligibleCount,
      totalDiscount: totalDiscount,
      totalRankBoost: totalRankBoost,
      rarityDistribution: rarityDistribution,
      blockchainDistribution: blockchainDistribution,
    );
  }
}

// NFT Provider
class NFTNotifier extends StateNotifier<NFTState> {
  final NFTService _nftService;

  NFTNotifier(this._nftService) : super(NFTInitial());

  // Load user's NFT collection
  Future<void> loadUserNFTs() async {
    state = NFTLoading();
    
    try {
      final response = await _nftService.getUserNFTs();
      if (response.success && response.data != null) {
        final nfts = response.data!.nfts;
        final stats = NFTStats.fromNFTs(nfts);
        
        state = NFTLoaded(nfts: nfts, stats: stats);
      } else {
        state = NFTError(
          message: response.message ?? 'Failed to load NFT collection',
        );
      }
    } catch (e, stackTrace) {
      print('Error loading NFTs: $e');
      print('Stack trace: $stackTrace');
      
      state = NFTError(
        message: 'Failed to load NFT collection',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // Verify NFT ownership
  Future<bool> verifyNFTOwnership(String contractAddress, String tokenId) async {
    try {
      // This method would need to be implemented in the service if needed
      // For now, return true for owned NFTs
      if (state is NFTLoaded) {
        final loadedState = state as NFTLoaded;
        return loadedState.nfts.any((nft) => 
          nft.contractAddress == contractAddress && 
          nft.tokenId == tokenId
        );
      }
      return false;
    } catch (e) {
      print('Error verifying NFT ownership: $e');
      return false;
    }
  }

  // Calculate fee discount with NFTs
  Future<double> calculateFeeDiscount(double originalFee) async {
    try {
      if (state is NFTLoaded) {
        final loadedState = state as NFTLoaded;
        final totalDiscount = _nftService.calculateTotalDiscount(loadedState.nfts);
        final discountAmount = originalFee * (totalDiscount / 100);
        return originalFee - discountAmount;
      }
      return originalFee;
    } catch (e) {
      print('Error calculating fee discount: $e');
      return originalFee;
    }
  }

  // Get tier benefits
  Future<Map<String, dynamic>> getTierBenefits() async {
    try {
      // Return hardcoded benefits for now
      // This could be expanded to use the benefitsTiers from the API response
      return {
        'tiers': [
          {
            'name': 'Common',
            'discount': 1.5,
            'boost': 10,
          },
          {
            'name': 'Uncommon',
            'discount': 3.0,
            'boost': 20,
          },
          {
            'name': 'Rare',
            'discount': 6.0,
            'boost': 40,
          },
          {
            'name': 'Epic',
            'discount': 10.0,
            'boost': 75,
          },
          {
            'name': 'Legendary',
            'discount': 15.0,
            'boost': 150,
          },
        ],
      };
    } catch (e) {
      print('Error getting tier benefits: $e');
      return {};
    }
  }

  // Refresh collection
  Future<void> refreshCollection() async {
    await loadUserNFTs();
  }

  // Filter NFTs
  List<NFTModel> filterNFTs({
    NFTRarity? rarity,
    Blockchain? blockchain,
    bool? eligibleOnly,
  }) {
    if (state is! NFTLoaded) return [];
    
    final loadedState = state as NFTLoaded;
    return loadedState.nfts.where((nft) {
      if (rarity != null && nft.rarity != rarity) return false;
      if (blockchain != null && nft.blockchain != blockchain) return false;
      if (eligibleOnly == true && !nft.isEligible) return false;
      return true;
    }).toList();
  }
}

// Providers
final nftServiceProvider = Provider<NFTService>((ref) {
  final authState = ref.watch(authProvider);
  // Get the API client from the app's main configuration
  final apiClient = ApiClient(baseUrl: 'https://flash-transfer.com');
  
  // Set token if user is authenticated
  if (authState.status == AuthStatus.authenticated && authState.user?.token != null) {
    apiClient.setToken(authState.user!.token!);
  }
  
  return NFTService(apiClient);
});

final nftProvider = StateNotifierProvider<NFTNotifier, NFTState>((ref) {
  final nftService = ref.watch(nftServiceProvider);
  return NFTNotifier(nftService);
});

// Computed providers
final nftStatsProvider = Provider<NFTStats?>((ref) {
  final nftState = ref.watch(nftProvider);
  if (nftState is NFTLoaded) {
    return nftState.stats;
  }
  return null;
});

final eligibleNFTsProvider = Provider<List<NFTModel>>((ref) {
  final nftState = ref.watch(nftProvider);
  if (nftState is NFTLoaded) {
    return nftState.nfts.where((nft) => nft.isEligible).toList();
  }
  return [];
});

final totalDiscountProvider = Provider<double>((ref) {
  final eligibleNFTs = ref.watch(eligibleNFTsProvider);
  return eligibleNFTs.fold<double>(
    0,
    (sum, nft) => sum + nft.discountRate,
  );
});
