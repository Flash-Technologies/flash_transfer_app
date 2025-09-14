import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/nft_model.dart';
import '../../core/services/nft_service.dart';
import '../../core/api/api_client.dart';
import 'components/nft_card_widget.dart';
import 'components/nft_filters_bar.dart';
import '../../config/theme.dart';
import '../../providers/nft_provider.dart';

class NFTScreen extends ConsumerStatefulWidget {
  const NFTScreen({super.key});

  @override
  ConsumerState<NFTScreen> createState() => _NFTScreenState();
}

class _NFTScreenState extends ConsumerState<NFTScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late NFTService _nftService;
  
  NFTRarity? _selectedRarity;
  Blockchain? _selectedBlockchain;
  bool _showOnlyEligible = false;
  
  List<NFTModel> _allNFTs = [];
  bool _isLoading = true;
  String? _errorMessage;
  DiscountSummary? _discountSummary;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playEntryAnimation();
    _initializeService();
    _loadNFTs();
  }
  
  void _initializeService() {
    _nftService = ref.read(nftServiceProvider);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  void _playEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadNFTs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await _nftService.getUserNFTs(
        network: 'POLYGON',
        testnet: false,
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _allNFTs = response.data!.nfts;
          _discountSummary = response.data!.discountSummary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load NFTs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading NFTs: $e';
        _isLoading = false;
      });
    }
  }
  
  // Sample NFT data for fallback
  List<NFTModel> get _sampleNFTs => [
    const NFTModel(
      tokenId: "0x001",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.polygon,
      name: "Flash Bronze Pass",
      description:
          "Entry-level membership providing basic transaction fee discounts for Flash Transfer users.",
      imageUrl:
          "https://via.placeholder.com/300x400/9CA3AF/FFFFFF?text=Bronze+Pass",
      rarity: NFTRarity.common,
      discountRate: 2.5,
      rankBoost: 10,
      isEligible: true,
      attributes: [
        NFTAttribute(traitType: "Tier", value: "Bronze"),
        NFTAttribute(traitType: "Discount", value: "2.5%"),
        NFTAttribute(traitType: "Rank Boost", value: 10),
      ],
    ),
    const NFTModel(
      tokenId: "0x002",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.ethereum,
      name: "Flash Silver Membership",
      description:
          "Premium membership offering enhanced benefits and priority support for dedicated users.",
      imageUrl:
          "https://via.placeholder.com/300x450/6B7280/FFFFFF?text=Silver+Member",
      rarity: NFTRarity.uncommon,
      discountRate: 5.0,
      rankBoost: 25,
      isEligible: true,
      attributes: [
        NFTAttribute(traitType: "Tier", value: "Silver"),
        NFTAttribute(traitType: "Discount", value: "5.0%"),
        NFTAttribute(traitType: "Rank Boost", value: 25),
      ],
    ),
    const NFTModel(
      tokenId: "0x003",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.ethereum,
      name: "Flash Gold Elite",
      description:
          "Elite tier membership with substantial discounts and exclusive access to new features.",
      imageUrl:
          "https://via.placeholder.com/300x380/F59E0B/FFFFFF?text=Gold+Elite",
      rarity: NFTRarity.rare,
      discountRate: 10.0,
      rankBoost: 50,
      isEligible: true,
      attributes: [
        NFTAttribute(traitType: "Tier", value: "Gold"),
        NFTAttribute(traitType: "Discount", value: "10.0%"),
        NFTAttribute(traitType: "Rank Boost", value: 50),
      ],
    ),
    const NFTModel(
      tokenId: "0x004",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.arbitrum,
      name: "Flash Diamond VIP",
      description:
          "Ultimate VIP experience with maximum benefits and personalized service.",
      imageUrl:
          "https://via.placeholder.com/300x420/8B5CF6/FFFFFF?text=Diamond+VIP",
      rarity: NFTRarity.epic,
      discountRate: 15.0,
      rankBoost: 100,
      isEligible: true,
      attributes: [
        NFTAttribute(traitType: "Tier", value: "Diamond"),
        NFTAttribute(traitType: "Discount", value: "15.0%"),
        NFTAttribute(traitType: "Rank Boost", value: 100),
      ],
    ),
    const NFTModel(
      tokenId: "0x005",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.ethereum,
      name: "Flash Founding Member",
      description:
          "Exclusive founding member NFT with legendary status and unmatched privileges.",
      imageUrl:
          "https://via.placeholder.com/300x500/EF4444/FFFFFF?text=Founding+Member",
      rarity: NFTRarity.legendary,
      discountRate: 25.0,
      rankBoost: 250,
      isEligible: true,
      attributes: [
        NFTAttribute(traitType: "Tier", value: "Founder"),
        NFTAttribute(traitType: "Discount", value: "25.0%"),
        NFTAttribute(traitType: "Rank Boost", value: 250),
        NFTAttribute(traitType: "Limited Edition", value: "Yes"),
      ],
    ),
    const NFTModel(
      tokenId: "0x006",
      contractAddress: "0xb858041a2f4e5ff2772cd55774d784fdcddae88a",
      blockchain: Blockchain.polygon,
      name: "Flash Community Badge",
      description:
          "Community recognition badge for active participants in the Flash ecosystem.",
      imageUrl:
          "https://via.placeholder.com/300x350/10B981/FFFFFF?text=Community+Badge",
      rarity: NFTRarity.common,
      discountRate: 1.0,
      rankBoost: 5,
      isEligible: false,
      attributes: [
        NFTAttribute(traitType: "Type", value: "Community"),
        NFTAttribute(traitType: "Discount", value: "1.0%"),
        NFTAttribute(traitType: "Participation", value: "Active"),
      ],
    ),
  ];

  List<NFTModel> get _filteredNFTs {
    final nfts = _allNFTs.isEmpty ? _sampleNFTs : _allNFTs;
    return nfts.where((nft) {
      if (_selectedRarity != null && nft.rarity != _selectedRarity) {
        return false;
      }
      if (_selectedBlockchain != null &&
          nft.blockchain != _selectedBlockchain) {
        return false;
      }
      if (_showOnlyEligible && !nft.isEligible) {
        return false;
      }
      return true;
    }).toList();
  }

  void _onFilterChanged({
    NFTRarity? rarity,
    Blockchain? blockchain,
    bool? eligibleOnly,
  }) {
    setState(() {
      _selectedRarity = rarity;
      _selectedBlockchain = blockchain;
      _showOnlyEligible = eligibleOnly ?? _showOnlyEligible;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _onNFTTapped(NFTModel nft) {
    HapticFeedback.mediumImpact();
    context.push('/nft-detail', extra: nft);
  }

  void _showBenefitsScreen() {
    context.push('/nft-benefits');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildFiltersSection(),
                Expanded(child: _buildNFTGrid()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildBenefitsButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation header
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Back',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title and stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My NFT Collection',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredNFTs.length} items',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              _buildCollectionStats(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStats() {
    double totalDiscount = 0;
    
    if (_discountSummary != null) {
      totalDiscount = _discountSummary!.currentStackedDiscount;
    } else {
      final nfts = _allNFTs.isEmpty ? _sampleNFTs : _allNFTs;
      totalDiscount = nfts
          .where((nft) => nft.isEligible)
          .map((nft) => nft.discountRate)
          .fold<double>(0, (sum, rate) => sum + rate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '${totalDiscount.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Total Discount',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NFTFiltersBar(
        selectedRarity: _selectedRarity,
        selectedBlockchain: _selectedBlockchain,
        showOnlyEligible: _showOnlyEligible,
        onFilterChanged: _onFilterChanged,
      ),
    );
  }

  Widget _buildNFTGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_filteredNFTs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNFTs,
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: _filteredNFTs.length,
        itemBuilder: (context, index) {
          final nft = _filteredNFTs[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 100)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: NFTCardWidget(
                    nft: nft,
                    onTap: () => _onNFTTapped(nft),
                    animationDelay: index * 100,
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading NFTs',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNFTs,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No NFTs Found',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or\nacquire some NFTs to get started',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showBenefitsScreen,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.star_outline, color: Colors.white),
        label: const Text(
          'Benefits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
