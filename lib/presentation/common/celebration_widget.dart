import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

enum CelebrationType {
  subtle,      // Minimal animation for professional contexts
  standard,    // Balanced celebration
  festive,     // More energetic for major achievements
}

class CelebrationWidget extends StatefulWidget {
  final bool trigger;
  final CelebrationType type;
  final VoidCallback? onComplete;
  final Widget? child;
  final Duration duration;
  final bool showSuccessIcon;
  final Color? primaryColor;
  final Color? accentColor;

  const CelebrationWidget({
    Key? key,
    required this.trigger,
    this.type = CelebrationType.standard,
    this.onComplete,
    this.child,
    this.duration = const Duration(seconds: 3),
    this.showSuccessIcon = true,
    this.primaryColor,
    this.accentColor,
  }) : super(key: key);

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget>
    with TickerProviderStateMixin {
  late List<ConfettiController> _confettiControllers;
  late AnimationController _successIconController;
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeConfetti();
  }

  void _initializeAnimations() {
    // Success icon animations
    _successIconController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Ripple effect animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation for background
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle trail animation
    _particleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create animations
    _successScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successIconController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _successOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successIconController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeConfetti() {
    // Create multiple confetti controllers for layered effects
    _confettiControllers = [
      // Main confetti burst
      ConfettiController(duration: const Duration(milliseconds: 2000)),
      // Secondary confetti for depth
      ConfettiController(duration: const Duration(milliseconds: 1500)),
      // Subtle particle trail
      ConfettiController(duration: const Duration(milliseconds: 3000)),
    ];
  }

  @override
  void didUpdateWidget(CelebrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger && !_hasTriggered) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    if (_hasTriggered) return;
    _hasTriggered = true;

    _executeCelebrationSequence();
  }

  Future<void> _executeCelebrationSequence() async {
    final intensity = _getIntensitySettings();

    // Step 1: Success icon appears (immediate)
    if (widget.showSuccessIcon) {
      _successIconController.forward();
    }

    // Step 2: Ripple effect starts (200ms delay)
    await Future.delayed(const Duration(milliseconds: 200));
    _rippleController.forward();

    // Step 3: Main confetti burst (300ms delay)
    await Future.delayed(const Duration(milliseconds: 100));
    _confettiControllers[0].play();

    // Step 4: Secondary effects (staggered)
    await Future.delayed(const Duration(milliseconds: 200));
    _pulseController.repeat(reverse: true);
    
    if (intensity.useSecondaryConfetti) {
      _confettiControllers[1].play();
    }

    // Step 5: Particle trail (500ms delay)
    await Future.delayed(const Duration(milliseconds: 300));
    _particleController.forward();
    
    if (intensity.useParticleTrail) {
      _confettiControllers[2].play();
    }

    // Step 6: Completion callback
    await Future.delayed(widget.duration);
    widget.onComplete?.call();
    
    // Reset for potential reuse
    await Future.delayed(const Duration(seconds: 1));
    _resetAnimations();
  }

  void _resetAnimations() {
    setState(() {
      _hasTriggered = false;
    });
    
    _successIconController.reset();
    _rippleController.reset();
    _pulseController.reset();
    _particleController.reset();
    
    for (final controller in _confettiControllers) {
      controller.stop();
    }
  }

  CelebrationIntensity _getIntensitySettings() {
    switch (widget.type) {
      case CelebrationType.subtle:
        return CelebrationIntensity(
          particleCount: 15,
          maxBlastForce: 15,
          useSecondaryConfetti: false,
          useParticleTrail: false,
          rippleIntensity: 0.5,
        );
      case CelebrationType.standard:
        return CelebrationIntensity(
          particleCount: 25,
          maxBlastForce: 25,
          useSecondaryConfetti: true,
          useParticleTrail: true,
          rippleIntensity: 0.7,
        );
      case CelebrationType.festive:
        return CelebrationIntensity(
          particleCount: 40,
          maxBlastForce: 35,
          useSecondaryConfetti: true,
          useParticleTrail: true,
          rippleIntensity: 1.0,
        );
    }
  }

  @override
  void dispose() {
    _successIconController.dispose();
    _rippleController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    
    for (final controller in _confettiControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base content
        if (widget.child != null) widget.child!,
        
        // Pulse background effect
        if (_hasTriggered) _buildPulseBackground(),
        
        // Ripple effects
        if (_hasTriggered) _buildRippleEffects(),
        
        // Confetti layers
        ..._buildConfettiLayers(),
        
        // Success icon
        if (widget.showSuccessIcon && _hasTriggered) _buildSuccessIcon(),
        
        // Particle trails
        if (_hasTriggered) _buildParticleTrails(),
      ],
    );
  }

  Widget _buildPulseBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8 + 0.4 * _pulseAnimation.value,
                colors: [
                  (widget.primaryColor ?? const Color(0xFFFFC000))
                      .withOpacity(0.1 * (1 - _pulseAnimation.value)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRippleEffects() {
    final intensity = _getIntensitySettings();
    
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: RipplePainter(
              progress: _rippleAnimation.value,
              color: widget.primaryColor ?? const Color(0xFFFFC000),
              intensity: intensity.rippleIntensity,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConfettiLayers() {
    final intensity = _getIntensitySettings();
    final colors = _getColorScheme();
    
    return [
      // Main confetti layer
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiControllers[0],
          blastDirectionality: BlastDirectionality.explosive,
          blastDirection: -math.pi / 2,
          emissionFrequency: 0.02,
          numberOfParticles: intensity.particleCount,
          maxBlastForce: intensity.maxBlastForce.toDouble(),
          minBlastForce: (intensity.maxBlastForce * 0.6).toDouble(),
          gravity: 0.3,
          colors: colors,
          createParticlePath: _createProfessionalParticle,
        ),
      ),
      
      // Secondary confetti (if enabled)
      if (intensity.useSecondaryConfetti)
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiControllers[1],
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: (intensity.particleCount * 0.6).round(),
            maxBlastForce: (intensity.maxBlastForce * 0.7).toDouble(),
            minBlastForce: (intensity.maxBlastForce * 0.4).toDouble(),
            gravity: 0.2,
            colors: colors.take(3).toList(),
            createParticlePath: _createSmallParticle,
          ),
        ),
      
      // Particle trail (if enabled)
      if (intensity.useParticleTrail)
        Align(
          alignment: Alignment.bottomCenter,
          child: ConfettiWidget(
            confettiController: _confettiControllers[2],
            blastDirectionality: BlastDirectionality.directional,
            blastDirection: -math.pi / 2,
            emissionFrequency: 0.1,
            numberOfParticles: 8,
            maxBlastForce: 10,
            minBlastForce: 5,
            gravity: 0.1,
            colors: [colors.first, colors.last],
            createParticlePath: _createTrailParticle,
          ),
        ),
    ];
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _successScaleAnimation,
          _successOpacityAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _successScaleAnimation.value,
            child: Opacity(
              opacity: _successOpacityAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C735),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C735).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticleTrails() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: ParticleTrailPainter(
              progress: _particleAnimation.value,
              color: widget.accentColor ?? const Color(0xFF2475FF),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getColorScheme() {
    return [
      widget.primaryColor ?? const Color(0xFFFFC000), // Gold
      widget.accentColor ?? const Color(0xFF2475FF),  // Blue
      const Color(0xFF00C735), // Green
      const Color(0xFFFFFFFF), // White
      const Color(0xFFF8F9FA), // Light gray
    ];
  }

  Path _createProfessionalParticle(Size size) {
    final path = Path();
    // Create rounded rectangle with professional proportions
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width / 4),
      ),
    );
    return path;
  }

  Path _createSmallParticle(Size size) {
    final path = Path();
    // Create small circles for secondary layer
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  Path _createTrailParticle(Size size) {
    final path = Path();
    // Create diamond-like shapes for trails
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }
}

// Helper class for celebration intensity settings
class CelebrationIntensity {
  final int particleCount;
  final int maxBlastForce;
  final bool useSecondaryConfetti;
  final bool useParticleTrail;
  final double rippleIntensity;

  CelebrationIntensity({
    required this.particleCount,
    required this.maxBlastForce,
    required this.useSecondaryConfetti,
    required this.useParticleTrail,
    required this.rippleIntensity,
  });
}

// Custom painter for ripple effects
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double intensity;

  RipplePainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.7;

    // Create multiple ripples with different timing
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress - i * 0.1).clamp(0.0, 1.0);
      if (rippleProgress > 0) {
        final radius = maxRadius * rippleProgress * intensity;
        final opacity = (1 - rippleProgress) * 0.3 * intensity;

        final paint = Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for particle trails
class ParticleTrailPainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticleTrailPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * (1 - progress))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Create animated particles that move outward in a spiral pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (progress * math.pi / 6);
      final distance = progress * 100;
      final particleSize = 4.0 * (1 - progress);
      
      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Draw trailing particle
      canvas.drawCircle(particleCenter, particleSize, paint);
      
      // Draw smaller trailing particles for motion blur effect
      for (int j = 1; j <= 3; j++) {
        final trailDistance = distance - (j * 15);
        if (trailDistance > 0) {
          final trailCenter = Offset(
            center.dx + math.cos(angle) * trailDistance,
            center.dy + math.sin(angle) * trailDistance,
          );
          
          final trailPaint = Paint()
            ..color = color.withOpacity(0.3 * (1 - progress) / j)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(trailCenter, particleSize / j, trailPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}