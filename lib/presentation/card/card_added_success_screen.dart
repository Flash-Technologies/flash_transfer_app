import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../common/celebration_widget.dart';
import '../../providers/language_provider.dart';

class CardAddedSuccessScreen extends ConsumerStatefulWidget {
  const CardAddedSuccessScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CardAddedSuccessScreen> createState() =>
      _CardAddedSuccessScreenState();
}

class _CardAddedSuccessScreenState extends ConsumerState<CardAddedSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late ConfettiController _confettiController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start animations sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start confetti immediately
    _confettiController.play();

    // Scale animation for success icon
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    // Slide animation for content
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    // Fade animation for buttons
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFC000).withOpacity(0.1),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFC000),
                Color(0xFF2475FF),
                Color(0xFF00C735),
                Color(0xFFFF3E24),
                Color(0xFF6E757D),
              ],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 5,
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Success icon and animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildSuccessIcon(),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Success content
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildSuccessContent(theme),
                  ),

                  const Spacer(flex: 3),

                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildActionButtons(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF00C735),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C735).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 60),
    );
  }

  Widget _buildSuccessContent(ThemeData theme) {
    return Column(
      children: [
        Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationHelperProvider);
            return Text(
              tr('card.success.title'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),

        const SizedBox(height: 16),

        Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationHelperProvider);
            return Text(
              tr('card.success.description'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),

        const SizedBox(height: 32),

        // Benefits section
        _buildBenefitsSection(theme),
      ],
    );
  }

  Widget _buildBenefitsSection(ThemeData theme) {
    final tr = ref.watch(translationHelperProvider);
    final benefits = [
      {
        'icon': Icons.security,
        'title': tr('card.success.benefits.secureStorage.title'),
        'description': tr('card.success.benefits.secureStorage.description'),
      },
      {
        'icon': Icons.flash_on,
        'title': tr('card.success.benefits.quickPayments.title'),
        'description': tr('card.success.benefits.quickPayments.description'),
      },
      {
        'icon': Icons.savings,
        'title': tr('card.success.benefits.saveMoney.title'),
        'description': tr('card.success.benefits.saveMoney.description'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final tr = ref.watch(translationHelperProvider);
              return Text(
                tr('card.success.whatYouCanDo'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          ...benefits
              .map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC000).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          benefit['icon'] as IconData,
                          color: const Color(0xFFFFC000),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit['title'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              benefit['description'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action - Make a transfer
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.send),
            label: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.success.actions.makeTransfer'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                );
              },
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC000),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary action - View cards
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/cards');
            },
            icon: const Icon(Icons.credit_card),
            label: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.success.actions.viewCards'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                );
              },
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2475FF),
              side: const BorderSide(color: Color(0xFF2475FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Skip action
        TextButton(
          onPressed: () {
            context.go('/home');
          },
          child: Consumer(
            builder: (context, ref, child) {
              final tr = ref.watch(translationHelperProvider);
              return Text(
                tr('card.success.actions.skipForNow'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Custom celebration widget for card success
class CardSuccessCelebration extends StatefulWidget {
  final VoidCallback? onComplete;

  const CardSuccessCelebration({Key? key, this.onComplete}) : super(key: key);

  @override
  State<CardSuccessCelebration> createState() => _CardSuccessCelebrationState();
}

class _CardSuccessCelebrationState extends State<CardSuccessCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF00C735),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C735).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
        );
      },
    );
  }
}
