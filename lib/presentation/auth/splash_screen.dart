import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onInitialized;

  const SplashScreen({Key? key, this.onInitialized}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set up fade-in animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Wait for both animation and auth initialization to complete
    _initializeSplash();
  }

  Future<void> _initializeSplash() async {
    print("💫 [SPLASH] Starting splash initialization");
    // Wait for minimum splash duration (for UX)
    final splashDuration = Future.delayed(const Duration(milliseconds: 2500));
    
    // Wait for auth initialization to complete
    while (mounted) {
      final authState = ref.read(authProvider);
      print("💫 [SPLASH] Auth state check - loading: ${authState.isLoading}, status: ${authState.status}");
      if (!authState.isLoading) {
        print("💫 [SPLASH] Auth initialization complete");
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Ensure minimum splash time has passed
    print("💫 [SPLASH] Waiting for minimum splash duration");
    await splashDuration;
    
    if (mounted) {
      print("💫 [SPLASH] Calling onInitialized callback");
      widget.onInitialized?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 130,
                        height: 130,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Flash Transfer',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181F30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your Best Money Transfer Partner',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6E757D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                // Footer text
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Secured by ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF878787),
                        ),
                      ),
                      Text(
                        'flash-transfer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2475FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
