import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/nft_model.dart';
import 'nft_rarity_badge.dart';
import 'nft_glow_effect.dart';

class NFTCardWidget extends StatefulWidget {
  final NFTModel nft;
  final VoidCallback onTap;
  final int animationDelay;

  const NFTCardWidget({
    super.key,
    required this.nft,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<NFTCardWidget> createState() => _NFTCardWidgetState();
}

class _NFTCardWidgetState extends State<NFTCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startFloatingAnimation();
  }

  void _setupAnimations() {
    // Floating animation
    _floatingController = AnimationController(
      duration: Duration(milliseconds: 2000 + (widget.animationDelay % 1000)),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for interactions
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Glow animation for legendary items
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  void _startFloatingAnimation() async {
    await Future.delayed(Duration(milliseconds: widget.animationDelay));
    _floatingController.repeat();
    
    if (widget.nft.rarity == NFTRarity.legendary) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatingAnimation,
        _scaleAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_floatingAnimation.value) * 3,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: NFTGlowEffect(
                rarity: widget.nft.rarity,
                glowIntensity: _glowAnimation.value,
                child: _buildCard(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.08),
            blurRadius: _isPressed ? 12 : 8,
            offset: Offset(0, _isPressed ? 6 : 4),
          ),
          if (widget.nft.rarity == NFTRarity.legendary)
            BoxShadow(
              color: widget.nft.rarityColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          _buildContentSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: _getCardHeight(),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.nft.rarityGradient,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Stack(
          children: [
            // Placeholder with shimmer effect
            if (!_isImageLoaded) _buildImagePlaceholder(),
            
            // Actual image
            Image.network(
              widget.nft.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _isImageLoaded = true);
                    }
                  });
                  return child;
                }
                return _buildImagePlaceholder();
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            ),
            
            // Top badges
            Positioned(
              top: 12,
              left: 12,
              child: NFTRarityBadge(rarity: widget.nft.rarity),
            ),
            
            Positioned(
              top: 12,
              right: 12,
              child: _buildBlockchainBadge(),
            ),
            
            // Eligibility indicator
            if (widget.nft.isEligible)
              Positioned(
                bottom: 12,
                right: 12,
                child: _buildEligibilityBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade100,
            Colors.red.shade200,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildBlockchainBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.nft.blockchainColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.nft.blockchainName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEligibilityBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nft.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181F30),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.nft.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildBenefitsRow(),
        ],
      ),
    );
  }

  Widget _buildBenefitsRow() {
    return Row(
      children: [
        if (widget.nft.discountRate > 0) ...[
          _buildBenefitChip(
            icon: Icons.percent,
            label: '${widget.nft.discountRate}%',
            color: Colors.green,
          ),
          const SizedBox(width: 8),
        ],
        if (widget.nft.rankBoost > 0)
          _buildBenefitChip(
            icon: Icons.trending_up,
            label: '+${widget.nft.rankBoost}',
            color: Colors.blue,
          ),
      ],
    );
  }

  Widget _buildBenefitChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _getCardHeight() {
    // Vary card heights for masonry effect
    switch (widget.nft.rarity) {
      case NFTRarity.common:
        return 160;
      case NFTRarity.uncommon:
        return 180;
      case NFTRarity.rare:
        return 200;
      case NFTRarity.epic:
        return 220;
      case NFTRarity.legendary:
        return 240;
    }
  }
}