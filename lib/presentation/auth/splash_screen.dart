import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to sign in screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      context.go('/sign-in');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                      style: TextStyle(fontSize: 16, color: Color(0xFF6E757D)),
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
                      style: TextStyle(fontSize: 16, color: Color(0xFF878787)),
                    ),
                    Text(
                      'flash-transfer',
                      style: TextStyle(fontSize: 16, color: Color(0xFF2475FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
