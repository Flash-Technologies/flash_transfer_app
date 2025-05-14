import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitialized;

  const SplashScreen({Key? key, this.onInitialized}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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

    // Wait for 2.5 seconds and then notify router that splash is complete
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onInitialized?.call();
      }
    });
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
