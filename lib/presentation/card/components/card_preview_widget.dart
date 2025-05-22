import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/models/credit_card_model.dart';

class CardPreviewWidget extends StatefulWidget {
  final CreditCard card;
  final bool showBack;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final bool animated;

  const CardPreviewWidget({
    Key? key,
    required this.card,
    this.showBack = false,
    this.onTap,
    this.margin,
    this.width,
    this.height,
    this.animated = true,
  }) : super(key: key);

  @override
  State<CardPreviewWidget> createState() => _CardPreviewWidgetState();
}

class _CardPreviewWidgetState extends State<CardPreviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _shimmerController;
  late Animation<double> _flipAnimation;
  late Animation<double> _shimmerAnimation;

  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    _showBack = widget.showBack;
    
    if (widget.animated) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(CardPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showBack != oldWidget.showBack) {
      _flipCard();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    
    setState(() {
      _showBack = !_showBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 320.0;
    final cardHeight = widget.height ?? 200.0;
    
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: widget.onTap ?? _flipCard,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * math.pi),
              child: Container(
                width: cardWidth,
                height: cardHeight,
                child: isShowingFront ? _buildCardFront() : _buildCardBack(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _getCardGradient(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          _buildBackgroundPattern(),
          
          // Shimmer effect
          if (widget.animated) _buildShimmerEffect(),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row - Card type and chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardChip(),
                    _buildCardBrandLogo(),
                  ],
                ),
                
                const Spacer(),
                
                // Card number
                _buildCardNumber(),
                
                const SizedBox(height: 16),
                
                // Bottom row - Name and expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardholderName(),
                    _buildExpiryDate(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getCardGradient(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Magnetic stripe
            Container(
              width: double.infinity,
              height: 40,
              color: Colors.black,
            ),
            
            const SizedBox(height: 16),
            
            // CVV section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        widget.card.cvv.isEmpty ? '•••' : widget.card.cvv,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Terms text
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This card is the property of Flash Transfer Bank and must be returned upon request. Use of this card constitutes acceptance of the terms and conditions.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 8,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: CardPatternPainter(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                    _shimmerAnimation.value,
                    (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                  ],
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardChip() {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE8B931),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFD4A017),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A017),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBrandLogo() {
    return Container(
      height: 40,
      child: widget.card.cardType != CardType.unknown
          ? Image.asset(
              widget.card.brandImagePath,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.credit_card,
                  color: Colors.white.withOpacity(0.8),
                  size: 32,
                );
              },
            )
          : Icon(
              Icons.credit_card,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
    );
  }

  Widget _buildCardNumber() {
    final displayNumber = widget.card.cardNumber.isEmpty 
        ? '•••• •••• •••• ••••'
        : widget.card.maskedCardNumber;
    
    return Text(
      displayNumber,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildCardholderName() {
    final displayName = widget.card.cardHolderName.isEmpty 
        ? 'CARDHOLDER NAME'
        : widget.card.cardHolderName.toUpperCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARDHOLDER',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryDate() {
    final displayExpiry = widget.card.expiryMonth == 1 && widget.card.expiryYear == 2025
        ? 'MM/YY'
        : widget.card.formattedExpiryDate;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'VALID THRU',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayExpiry,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  LinearGradient _getCardGradient() {
    switch (widget.card.cardType) {
      case CardType.visa:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1F71),
            Color(0xFF2E3A8A),
            Color(0xFF3B82F6),
          ],
        );
      case CardType.mastercard:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEB001B),
            Color(0xFFF79E1B),
          ],
        );
      case CardType.americanExpress:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006FCF),
            Color(0xFF0088CC),
            Color(0xFF00A0E5),
          ],
        );
      case CardType.discover:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6000),
            Color(0xFFFF8C00),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A5568),
            Color(0xFF2D3748),
            Color(0xFF1A202C),
          ],
        );
    }
  }
}

// Custom painter for card background pattern
class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw circuit-like pattern
    final path = Path();
    
    // Create a tech pattern
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      path.moveTo(0, y);
      path.lineTo(size.width * 0.3, y);
      path.lineTo(size.width * 0.4, y + 10);
      path.lineTo(size.width * 0.6, y + 10);
      path.lineTo(size.width * 0.7, y);
      path.lineTo(size.width, y);
    }

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 7);
      path.moveTo(x, 0);
      path.lineTo(x, size.height * 0.2);
      path.moveTo(x, size.height * 0.8);
      path.lineTo(x, size.height);
    }

    canvas.drawPath(path, paint);

    // Draw circles for nodes
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.2 + i * 0.3),
            size.height * (0.3 + j * 0.4),
          ),
          2,
          circlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}