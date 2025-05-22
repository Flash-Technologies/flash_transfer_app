import 'package:flutter/material.dart';
import 'dart:math' as math;

class CardScannerOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  final String? instructionText;
  final bool isScanning;
  final double? scanProgress;

  const CardScannerOverlay({
    Key? key,
    this.onClose,
    this.instructionText,
    this.isScanning = false,
    this.scanProgress,
  }) : super(key: key);

  @override
  State<CardScannerOverlay> createState() => _CardScannerOverlayState();
}

class _CardScannerOverlayState extends State<CardScannerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _cornerController;
  
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cornerAnimation;

  @override
  void initState() {
    super.initState();
    
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _cornerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cornerController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _scanLineController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _cornerController.forward();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cornerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.85;
    final cardHeight = cardWidth * 0.63; // Standard card aspect ratio
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Background overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.7),
          ),
          
          // Close button
          SafeArea(
            child: Positioned(
              top: 16,
              right: 16,
              child: _buildCloseButton(),
            ),
          ),
          
          // Instructions
          SafeArea(
            child: Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: _buildInstructions(),
            ),
          ),
          
          // Card scanning frame
          Center(
            child: _buildScanningFrame(cardWidth, cardHeight),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildBottomControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        onPressed: widget.onClose,
        icon: const Icon(
          Icons.close,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          widget.instructionText ?? 'Position your card within the frame',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure your card is well-lit and clearly visible',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScanningFrame(double cardWidth, double cardHeight) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scanLineAnimation,
        _pulseAnimation,
        _cornerAnimation,
      ]),
      builder: (context, child) {
        return Container(
          width: cardWidth + 40,
          height: cardHeight + 40,
          child: Stack(
            children: [
              // Pulse effect
              if (widget.isScanning)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFC000).withOpacity(
                          0.3 + 0.4 * _pulseAnimation.value,
                        ),
                        width: 2 + 2 * _pulseAnimation.value,
                      ),
                    ),
                  ),
                ),
              
              // Main frame
              Center(
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      ..._buildCornerIndicators(cardWidth, cardHeight),
                      
                      // Scanning line
                      if (widget.isScanning) _buildScanningLine(cardHeight),
                      
                      // Progress indicator
                      if (widget.scanProgress != null)
                        _buildProgressIndicator(cardWidth, cardHeight),
                      
                      // Card outline helper
                      _buildCardOutline(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerIndicators(double cardWidth, double cardHeight) {
    const cornerSize = 24.0;
    const cornerThickness = 3.0;
    
    return [
      // Top-left corner
      Positioned(
        top: -cornerThickness,
        left: -cornerThickness,
        child: Transform.scale(
          scale: _cornerAnimation.value,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
                left: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Top-right corner
      Positioned(
        top: -cornerThickness,
        right: -cornerThickness,
        child: Transform.scale(
          scale: _cornerAnimation.value,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
                right: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Bottom-left corner
      Positioned(
        bottom: -cornerThickness,
        left: -cornerThickness,
        child: Transform.scale(
          scale: _cornerAnimation.value,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
                left: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
      ),
      
      // Bottom-right corner
      Positioned(
        bottom: -cornerThickness,
        right: -cornerThickness,
        child: Transform.scale(
          scale: _cornerAnimation.value,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
                right: BorderSide(
                  color: const Color(0xFFFFC000),
                  width: cornerThickness,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildScanningLine(double cardHeight) {
    return Positioned(
      left: 0,
      right: 0,
      top: cardHeight * _scanLineAnimation.value - 1,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFFC000),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC000).withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double cardWidth, double cardHeight) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: widget.scanProgress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
          ),
          const SizedBox(height: 4),
          Text(
            '${(widget.scanProgress! * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOutline() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.credit_card_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scanning status
          if (widget.isScanning)
            Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scanning card...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: const Color(0xFFFFC000),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips for better scanning:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Ensure good lighting\n• Keep card flat and steady\n• Avoid glare and shadows',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom animated scanner border
class AnimatedScannerBorder extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Duration animationDuration;

  const AnimatedScannerBorder({
    Key? key,
    required this.child,
    this.borderColor = const Color(0xFFFFC000),
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.animationDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimatedScannerBorder> createState() => _AnimatedScannerBorderState();
}

class _AnimatedScannerBorderState extends State<AnimatedScannerBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedBorderPainter(
            progress: _animation.value,
            borderColor: widget.borderColor,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  AnimatedBorderPainter({
    required this.progress,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    final totalLength = 2 * (size.width + size.height);
    final currentLength = totalLength * progress;
    
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics().first;
    
    final extractPath = pathMetrics.extractPath(0, currentLength);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}