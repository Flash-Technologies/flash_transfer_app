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
        // Handle API response with success: false
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

  List<NFTModel> get _filteredNFTs {
    return _allNFTs.where((nft) {
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
      totalDiscount = _allNFTs
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
    // Check if the error is related to no wallet connection
    final errorLower = _errorMessage?.toLowerCase() ?? '';
    bool isNoWalletError = errorLower == 'user has no connected wallet' ||
                          errorLower == 'no wallet connected' ||
                          errorLower.contains('no connected wallet') ||
                          errorLower.contains('user has no connected wallet') ||
                          errorLower.contains('no wallet') ||
                          errorLower.contains('connect wallet') ||
                          errorLower.contains('wallet not connected') ||
                          errorLower.contains('has no connected wallet');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNoWalletError 
                    ? [Colors.orange.shade200, Colors.orange.shade300]
                    : [Colors.red.shade200, Colors.red.shade300],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              isNoWalletError ? Icons.account_balance_wallet_outlined : Icons.error_outline,
              size: 48,
              color: isNoWalletError ? Colors.orange.shade600 : Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isNoWalletError ? 'No Wallet Connected' : 'Error Loading NFTs',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNoWalletError 
                ? 'Please connect your wallet to view your NFT collection and unlock exclusive benefits.'
                : _errorMessage ?? 'An error occurred while loading your NFTs',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isNoWalletError 
                ? () {
                    // Navigate to wallet connection or show wallet connection modal
                    context.push('/profile'); // Assuming profile has wallet connection
                  }
                : _loadNFTs,
            icon: Icon(
              isNoWalletError ? Icons.account_balance_wallet : Icons.refresh,
              color: Colors.white,
            ),
            label: Text(
              isNoWalletError ? 'Connect Wallet' : 'Retry',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNoWalletError ? Colors.orange.shade600 : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
